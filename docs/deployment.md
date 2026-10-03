# Deployment Guide

This document covers the production deployment of `game_master_core` on an
[exe.dev](https://exe.dev) VM using Docker.

---

## Overview

The application runs as two Docker containers on a shared private network:

| Container      | Image                     | Role        |
| -------------- | ------------------------- | ----------- |
| `gmc-postgres` | `postgres:17-alpine`      | Database    |
| `gmc-app`      | `game_master_core:latest` | Phoenix app |

The recommended repo-managed setup is `docker-compose.prod.yml`, which defines
both containers, their restart policy, and their persistent volumes. If you
prefer systemd, keep using `gmc.service` as the process supervisor and the same
volume/container layout described below.

The Phoenix container runs as a dedicated non-root `app` user (UID/GID `10001`).
This is safer than running as root and makes upload-volume permissions explicit.

The HTTPS proxy is provided by exe.dev, which terminates TLS and forwards
traffic to port 8000 on the VM.

---

## Infrastructure

### Docker Network

A custom bridge network called `gmc-net` connects the two containers. Docker's
internal DNS resolves container names, so the app can reach the database at the
hostname `gmc-postgres` without knowing its IP address.

```
Internet → exe.dev proxy → VM:8000 → gmc-app:4000
                                          ↓
                                     gmc-net
                                          ↓
                                     gmc-postgres:5432
```

### Named Volumes

Data that must survive container restarts is stored in named Docker volumes on
the host VM's disk. These are completely independent of the containers — you
can delete and recreate every container without losing data.

| Volume        | Mounted at                                     | Contains                |
| ------------- | ---------------------------------------------- | ----------------------- |
| `gmc-pgdata`  | `/var/lib/postgresql/data` (in `gmc-postgres`) | All Postgres data files |
| `gmc-uploads` | `/uploads` (in `gmc-app`)                      | User-uploaded files     |

To inspect volumes:

```bash
docker volume ls
docker volume inspect gmc-pgdata
```

### Docker Compose

A production Compose file is included at `docker-compose.prod.yml`. Create an
environment file from the example and fill in real secrets:

```bash
cp .env.prod.example .env.prod
$EDITOR .env.prod
```

Start or update the app with:

```bash
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
```

Run migrations after the containers are up:

```bash
docker compose --env-file .env.prod -f docker-compose.prod.yml exec app /app/bin/migrate
```

Do **not** use `docker compose down -v` unless you intentionally want to delete
the database and uploads volumes.

### Resetting an empty PostgreSQL 16 database for PostgreSQL 17

Production uses PostgreSQL 17 to match Railway. An existing PostgreSQL 16
volume cannot be reused directly by PostgreSQL 17, even if it has no application
data. For an **empty/disposable destination database only**, reset the database
volume before redeploying:

```bash
# Compose deployment: stop and remove containers, but preserve volumes.
docker compose --env-file .env.prod -f docker-compose.prod.yml down

# Delete ONLY the database volume. This permanently deletes its contents.
docker volume rm gmc-pgdata

# Start PostgreSQL 17 and the app with a fresh database volume.
docker compose --env-file .env.prod -f docker-compose.prod.yml up -d --build
```

Do not use `down -v`: the `gmc-uploads` volume must be preserved. If the destination
contains valuable data, back it up and use a proper dump/restore upgrade instead.

For a systemd deployment, first stop `gmc.service`, remove the `gmc-app` and
`gmc-postgres` containers if they remain, and delete only `gmc-pgdata`. Update the
Postgres image in `/etc/systemd/system/gmc.service` to `postgres:17-alpine`, run
`sudo systemctl daemon-reload`, then start the service. Editing this repository
does not update the VM's systemd service file automatically.

When importing Railway, use PostgreSQL 17 `pg_dump` and restore the full dump
before running application migrations. Keep the app stopped during restoration.
A fresh database can remain unmigrated until the import is complete; the dump
includes the source's migration history.

### Systemd Service

If you choose systemd instead of Compose, the service file lives at
`/etc/systemd/system/gmc.service`. It:

1. Stops and removes any existing containers (so restarts are clean)
2. Starts `gmc-postgres`
3. Waits 3 seconds for Postgres to be ready
4. Starts `gmc-app`

The service is set to `Restart=always`, so if the app crashes it will be
automatically restarted. It is also enabled, meaning it starts automatically
on VM boot.

Useful commands:

```bash
# Check status
sudo systemctl status gmc

# View live logs
journalctl -u gmc -f

# Restart (e.g. after an update)
sudo systemctl restart gmc

# Stop entirely
sudo systemctl stop gmc
```

---

## Environment Variables

The app container is started with the following environment variables hardcoded
into the systemd service file:

| Variable            | Value                                                      | Notes                                                |
| ------------------- | ---------------------------------------------------------- | ---------------------------------------------------- |
| `PHX_SERVER`        | `true`                                                     | Tells the release to start the HTTP server           |
| `DATABASE_URL`      | `ecto://gmc:gmc_secret@gmc-postgres/game_master_core_prod` | Postgres connection string                           |
| `SECRET_KEY_BASE`   | _(64-byte hex string)_                                     | Signs/encrypts cookies and tokens. Keep secret.      |
| `PHX_HOST`          | `game-master-core.exe.xyz`                                 | Used to build absolute URLs                          |
| `PORT`              | `4000`                                                     | Port the app listens on inside the container         |
| `RESEND_API_KEY`    | `re_...`                                                   | Resend API key for transactional email               |
| `CLIENT_APP_URL`    | `https://gamemaster.callumkloos.dev`                       | Frontend URL used in email confirmation links        |
| `UPLOADS_DIRECTORY` | `/uploads`                                                 | Where uploaded files are stored inside the container |

> **Security note:** The `SECRET_KEY_BASE` and `RESEND_API_KEY` are stored in
> plaintext in the systemd service file. This is acceptable for a single-VM
> setup but be aware they are readable by anyone with root access to the VM.
> Do not commit the service file to version control.

---

## Access & Visibility

The exe.dev proxy exposes the app at:

```
https://game-master-core.exe.xyz:8000/
```

By default the proxy is **private** — only users logged into exe.dev who have
access to this VM can reach it. This is fine for personal use but will block
API requests from your client app, which has no exe.dev session.

### Making it public

Run these two commands from your **local machine** (not the VM):

```bash
# Point the default proxy port to 8000
ssh exe.dev share port game-master-core 8000

# Open to the internet (no login required)
ssh exe.dev share set-public game-master-core
```

To revert to private:

```bash
ssh exe.dev share set-private game-master-core
```

---

## Updating the Application

### 1. Pull latest code and rebuild the image

```bash
cd ~/game_master_core
git pull
docker build -t game_master_core:latest .
```

### 2. Restart the service

```bash
sudo systemctl restart gmc
```

Systemd stops the old `gmc-app` container and starts a new one using the
freshly built image. The database and uploads volumes are not touched.

### 3. Run migrations (if needed)

If the update includes new Ecto migrations, run them after the app is back up:

```bash
docker exec gmc-app /app/bin/game_master_core eval "GameMasterCore.Release.migrate()"
```

This is safe to run while the app is live. Phoenix uses advisory locks to
prevent migrations running concurrently.

---

## Database Access

To open a Postgres shell:

```bash
docker exec -it gmc-postgres psql -U gmc -d game_master_core_prod
```

To run a one-off Ecto expression from inside the app container:

```bash
docker exec gmc-app /app/bin/game_master_core eval "YOUR_ELIXIR_EXPRESSION"
```

---

## Logs

**App logs:**

```bash
docker logs gmc-app
docker logs gmc-app -f   # follow
```

**Postgres logs:**

```bash
docker logs gmc-postgres
```

**Systemd journal (covers full lifecycle including restarts):**

```bash
journalctl -u gmc -f
```

---

## Rebuilding from Scratch

If you ever need to completely rebuild the deployment (e.g. moving to a new VM):

```bash
# 1. Clone the repo
git clone https://github.com/Callumk7/game_master_core ~/game_master_core
cd ~/game_master_core

# 2. Create the Docker network
docker network create gmc-net

# 3. Start Postgres
docker run -d \
  --name gmc-postgres \
  --network gmc-net \
  -e POSTGRES_USER=gmc \
  -e POSTGRES_PASSWORD=gmc_secret \
  -e POSTGRES_DB=game_master_core_prod \
  -v gmc-pgdata:/var/lib/postgresql/data \
  postgres:17-alpine

# 4. Build the app image
docker build -t game_master_core:latest .

# 5. Install and start the systemd service
sudo cp /path/to/gmc.service /etc/systemd/system/gmc.service
sudo systemctl daemon-reload
sudo systemctl enable --now gmc

# 6. Run migrations
docker exec gmc-app /app/bin/game_master_core eval "GameMasterCore.Release.migrate()"
```

> **Note:** If migrating an existing deployment, restore the `gmc-pgdata`
> volume from a backup before running migrations.

---

## Backup

To back up the database:

```bash
# Dump to a SQL file
docker exec gmc-postgres pg_dump -U gmc game_master_core_prod > backup_$(date +%Y%m%d).sql

# Restore from a dump
cat backup_20250101.sql | docker exec -i gmc-postgres psql -U gmc -d game_master_core_prod
```

To back up uploaded files, copy the contents of the `gmc-uploads` volume:

```bash
docker run --rm \
  -v gmc-uploads:/uploads \
  -v $(pwd):/backup \
  alpine tar czf /backup/uploads_$(date +%Y%m%d).tar.gz /uploads
```
