# Deployment Guide

This document covers the production deployment of `game_master_core` on an
[exe.dev](https://exe.dev) VM using Docker.

---

## Overview

The application runs as two Docker containers on a shared private network:

| Container | Image | Role |
|---|---|---|
| `gmc-postgres` | `postgres:16-alpine` | Database |
| `gmc-app` | `game_master_core:latest` | Phoenix app |

Both containers are managed by a **systemd service** (`gmc.service`) that
handles startup ordering, restarts on failure, and boot persistence.

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

| Volume | Mounted at | Contains |
|---|---|---|
| `gmc-pgdata` | `/var/lib/postgresql/data` (in `gmc-postgres`) | All Postgres data files |
| `gmc-uploads` | `/uploads` (in `gmc-app`) | User-uploaded files |

To inspect volumes:
```bash
docker volume ls
docker volume inspect gmc-pgdata
```

### Systemd Service

The service file lives at `/etc/systemd/system/gmc.service`. It:

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

| Variable | Value | Notes |
|---|---|---|
| `PHX_SERVER` | `true` | Tells the release to start the HTTP server |
| `DATABASE_URL` | `ecto://gmc:gmc_secret@gmc-postgres/game_master_core_prod` | Postgres connection string |
| `SECRET_KEY_BASE` | *(64-byte hex string)* | Signs/encrypts cookies and tokens. Keep secret. |
| `PHX_HOST` | `game-master-core.exe.xyz` | Used to build absolute URLs |
| `PORT` | `4000` | Port the app listens on inside the container |
| `RESEND_API_KEY` | `re_...` | Resend API key for transactional email |
| `CLIENT_APP_URL` | `https://gamemaster.callumkloos.dev` | Frontend URL used in email confirmation links |
| `UPLOADS_DIRECTORY` | `/uploads` | Where uploaded files are stored inside the container |

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
  postgres:16-alpine

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
