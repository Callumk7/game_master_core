---
id: doc-002
title: Image Upload System Documentation
type: other
created_date: '2025-10-15 17:26'
---
# Image Upload System Documentation

The Game Master Core application includes a comprehensive image upload system that allows users to upload and manage images for various game entities including characters, factions, locations, and quests.

## System Overview

The image upload system provides:

- **Multi-entity support**: Upload images for characters, factions, locations, and quests
- **Pluggable storage**: Configurable storage adapters supporting local filesystem and S3-compatible storage
- **Primary image functionality**: Each entity can have one designated primary image
- **Complete REST API**: Full CRUD operations for image management
- **File size and type validation**: Enforces limits and supported formats
- **Automatic cleanup**: Removes associated files when images are deleted
- **Polymorphic associations**: Flexible entity relationships via entity_type/entity_id pattern
- **Scoped access**: All operations are scoped to games and authenticated users

### Supported Entity Types

- `character` - Character portraits and images
- `faction` - Faction emblems and banners
- `location` - Location maps and illustrations
- `quest` - Quest-related imagery

### Supported File Types

- JPEG (`.jpg`, `.jpeg`)
- PNG (`.png`)
- WebP (`.webp`)
- GIF (`.gif`)

### File Size Limit

- Maximum file size: **20MB** per image

## Database Schema

The images table stores metadata and associations for uploaded images:

```sql
CREATE TABLE images (
  id UUID PRIMARY KEY,
  filename VARCHAR NOT NULL,
  file_path VARCHAR NOT NULL,
  file_url VARCHAR NOT NULL,
  file_size BIGINT NOT NULL,
  content_type VARCHAR NOT NULL,
  alt_text VARCHAR,
  is_primary BOOLEAN DEFAULT FALSE NOT NULL,
  entity_type VARCHAR NOT NULL,
  entity_id UUID NOT NULL,
  metadata JSONB DEFAULT '{}',
  game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### Key Fields

- **`id`**: Unique identifier for the image
- **`filename`**: Original filename as uploaded by the user
- **`file_path`**: Storage key/path used by the storage adapter
- **`file_url`**: Public URL for accessing the image
- **`file_size`**: File size in bytes
- **`content_type`**: MIME type (e.g., "image/jpeg")
- **`alt_text`**: Optional accessibility text
- **`is_primary`**: Whether this is the primary image for the entity
- **`entity_type`**: Type of entity ("character", "faction", etc.)
- **`entity_id`**: UUID of the associated entity
- **`metadata`**: Additional storage-specific metadata (JSON)
- **`game_id`**: Associated game (for access control)
- **`user_id`**: User who uploaded the image

### Indexes

- **Game scoping**: `(game_id)`
- **User scoping**: `(user_id)`
- **Entity association**: `(entity_type, entity_id)`
- **Primary image lookup**: `(entity_type, entity_id, is_primary)`
- **Combined lookup**: `(game_id, entity_type, entity_id)`

### Constraints

- **Unique primary images**: Only one image per entity can be marked as primary
- **Foreign key cascades**: Images are deleted when games or users are deleted

## Image Schema and Validation

The `GameMasterCore.Images.Image` schema handles validation and data integrity:

### Changeset Types

1. **Initial changeset** (`changeset/4`): Creates image record before file upload
2. **File changeset** (`file_changeset/2`): Updates record after successful file storage
3. **Complete changeset** (`complete_changeset/4`): Creates record with all file info at once
4. **Update changeset** (`update_changeset/2`): Updates metadata only

### Validation Rules

- **Entity types**: Must be one of the supported entity types
- **Content types**: Must be a valid image MIME type
- **File size**: Must be between 1 byte and 20MB
- **Filename**: Must have valid image extension and be 1-255 characters
- **Alt text**: Optional, maximum 255 characters

### Constants

```elixir
# Supported entity types
@valid_entity_types ["character", "faction", "location", "quest"]

# Supported image content types
@valid_content_types [
  "image/jpeg",
  "image/jpg", 
  "image/png",
  "image/webp",
  "image/gif"
]

# Maximum file size (20MB)
@max_file_size 20 * 1024 * 1024
```

## Storage Architecture

The system uses a pluggable storage architecture with a behavior interface and multiple adapters:

### Storage Behavior

**`GameMasterCore.Storage.Behaviour`** defines the contract:

```elixir
@callback store(file_path :: String.t(), key :: String.t(), opts :: Keyword.t()) ::
            {:ok, %{url: String.t(), metadata: map()}} | {:error, term()}

@callback retrieve(key :: String.t()) :: {:ok, binary()} | {:error, term()}

@callback delete(key :: String.t()) :: :ok | {:error, term()}

@callback get_url(key :: String.t()) :: String.t()

@callback exists?(key :: String.t()) :: boolean()
```

### Main Storage Module

**`GameMasterCore.Storage`** provides the unified interface:

- Delegates to configured storage adapter
- Default adapter: `GameMasterCore.Storage.Local`
- Configured via `:storage_adapter` application setting

### Local Filesystem Adapter

**`GameMasterCore.Storage.Local`** stores files on the local filesystem:

#### Features:
- Stores files in configurable upload directory
- Automatic directory creation
- Empty directory cleanup on deletion
- Public URL generation for web serving
- File existence checking

#### Configuration:
```elixir
config :game_master_core,
  uploads_directory: "uploads",
  uploads_base_url: "/uploads"
```

### S3-Compatible Storage Adapter

**`GameMasterCore.Storage.S3`** works with AWS S3 and S3-compatible services:

#### Features:
- AWS S3 support
- S3-compatible services (MinIO, DigitalOcean Spaces, etc.)
- Custom endpoint support
- CDN integration via custom public URLs
- Uses existing `Req` library for HTTP requests

#### Configuration:
```elixir
# AWS S3
config :game_master_core,
  s3_bucket: "my-game-images",
  s3_region: "us-west-2",
  s3_access_key_id: "AKIA...",
  s3_secret_access_key: "...",
  s3_public_url: "https://cdn.example.com"

# MinIO or other S3-compatible
config :game_master_core,
  s3_bucket: "game-images",
  s3_endpoint: "https://minio.example.com",
  s3_access_key_id: "minioadmin",
  s3_secret_access_key: "minioadmin"
```

### Key Generation Utility

**`GameMasterCore.Storage.KeyGenerator`** generates consistent storage keys:

#### Standard Key Format:
```
games/{game_id}/{entity_type}/{entity_id}/{uuid}.{extension}
```

#### Date-Based Key Format:
```
games/{game_id}/{entity_type}/{entity_id}/{year}/{month}/{day}/{uuid}.{extension}
```

#### Features:
- UUID-based unique filenames
- Hierarchical organization
- Key parsing utilities
- Temporary key generation

## Context Module

**`GameMasterCore.Images`** provides the business logic layer:

### Key Functions

#### Image Querying
- `list_images_for_entity/4` - Get all images for an entity
- `get_primary_image/3` - Get the primary image for an entity
- `get_image_for_game/2` - Get image by ID within game scope
- `get_image_stats/3` - Get statistics for entity images

#### Image Management
- `create_image_for_entity/3` - Upload and create image
- `update_image/3` - Update image metadata
- `set_as_primary/2` - Set image as primary
- `delete_image/2` - Delete image and cleanup file

### Upload Flow

1. **File Storage**: Store uploaded file using storage adapter
2. **Database Record**: Create database record with complete file info
3. **Primary Management**: Unset other primary images if needed
4. **Transaction Safety**: All operations wrapped in database transactions
5. **Cleanup**: Remove stored file if database operations fail

### Primary Image Logic

- Only one primary image allowed per entity
- Setting a new primary automatically unsets existing primary
- Primary images appear first in listings when requested

## REST API Endpoints

The `GameMasterCoreWeb.ImageController` provides comprehensive REST endpoints:

### Route Structure

Images are nested under entity routes:
```
/api/games/{game_id}/{entity_type}s/{entity_id}/images
```

For example:
```
/api/games/123/characters/456/images
/api/games/123/factions/789/images
```

### Available Endpoints

| Method | Path | Action | Description |
|--------|------|--------|-------------|
| GET | `/{entity_type}s/{entity_id}/images` | `index` | List all images for entity |
| POST | `/{entity_type}s/{entity_id}/images` | `create` | Upload new image |
| GET | `/{entity_type}s/{entity_id}/images/{id}` | `show` | Get specific image |
| PUT | `/{entity_type}s/{entity_id}/images/{id}` | `update` | Update image metadata |
| DELETE | `/{entity_type}s/{entity_id}/images/{id}` | `delete` | Delete image |
| PUT | `/{entity_type}s/{entity_id}/images/{id}/primary` | `set_primary` | Set as primary |
| GET | `/{entity_type}s/{entity_id}/images/stats` | `stats` | Get image statistics |
| GET | `/{entity_type}s/{entity_id}/images/{id}/file` | `serve_file` | Serve/redirect to file |

### Request/Response Formats

#### List Images Response
```json
{
  "data": [
    {
      "id": "uuid",
      "filename": "avatar.jpg",
      "file_url": "/uploads/games/.../avatar.jpg",
      "file_size": 125440,
      "file_size_mb": 0.12,
      "content_type": "image/jpeg",
      "alt_text": "Character portrait",
      "is_primary": true,
      "entity_type": "character",
      "entity_id": "entity-uuid",
      "metadata": {},
      "inserted_at": "2025-01-07T10:30:00Z",
      "updated_at": "2025-01-07T10:30:00Z"
    }
  ],
  "meta": {
    "entity_type": "character",
    "entity_id": "entity-uuid",
    "total_count": 3
  }
}
```

#### Image Statistics Response
```json
{
  "data": {
    "entity_type": "character",
    "entity_id": "entity-uuid",
    "total_count": 3,
    "total_size": 2547200,
    "total_size_mb": 2.43,
    "has_primary": true
  }
}
```

#### Upload Request
```bash
POST /api/games/{game_id}/characters/{character_id}/images
Content-Type: multipart/form-data

image[file]=@avatar.jpg
image[alt_text]="Character portrait"
image[is_primary]=true
```

## Configuration

### Application Configuration

```elixir
# config/config.exs
config :game_master_core,
  # Storage adapter selection
  storage_adapter: GameMasterCore.Storage.Local,
  
  # Local storage settings
  uploads_directory: "uploads",
  uploads_base_url: "/uploads",
  
  # S3 settings (when using S3 adapter)
  s3_bucket: "my-bucket",
  s3_region: "us-east-1",
  s3_endpoint: nil, # Use for S3-compatible services
  s3_access_key_id: nil,
  s3_secret_access_key: nil,
  s3_public_url: nil # Use for CDN integration
```

### Static File Serving

The Phoenix endpoint is configured to serve uploaded files:

```elixir
# lib/game_master_core_web/endpoint.ex
plug Plug.Static,
  at: "/uploads",
  from: "uploads",
  gzip: false
```

### Environment-Specific Settings

#### Development
```elixir
# config/dev.exs
config :game_master_core,
  storage_adapter: GameMasterCore.Storage.Local,
  uploads_directory: "uploads",
  uploads_base_url: "/uploads"
```

#### Production
```elixir
# config/prod.exs
config :game_master_core,
  storage_adapter: GameMasterCore.Storage.S3,
  s3_bucket: {:system, "S3_BUCKET"},
  s3_region: {:system, "S3_REGION"},
  s3_access_key_id: {:system, "S3_ACCESS_KEY_ID"},
  s3_secret_access_key: {:system, "S3_SECRET_ACCESS_KEY"},
  s3_public_url: {:system, "S3_PUBLIC_URL"}
```

## Usage Examples

### HTTPie Examples

#### Upload Image
```bash
# Upload character image
http --form POST localhost:4000/api/games/GAME_ID/characters/CHAR_ID/images \
  image[file]@portrait.jpg \
  image[alt_text]="Main character portrait" \
  image[is_primary]:=true \
  Authorization:"Bearer YOUR_TOKEN"
```

#### List Images
```bash
# List all images for a character
http GET localhost:4000/api/games/GAME_ID/characters/CHAR_ID/images \
  Authorization:"Bearer YOUR_TOKEN"

# List with primary images first
http GET localhost:4000/api/games/GAME_ID/characters/CHAR_ID/images \
  primary_first==true \
  Authorization:"Bearer YOUR_TOKEN"
```

#### Update Image Metadata
```bash
# Update alt text and set as primary
http PUT localhost:4000/api/games/GAME_ID/characters/CHAR_ID/images/IMAGE_ID \
  alt_text="Updated character portrait" \
  is_primary:=true \
  Authorization:"Bearer YOUR_TOKEN"
```

#### Set Primary Image
```bash
# Set specific image as primary
http PUT localhost:4000/api/games/GAME_ID/characters/CHAR_ID/images/IMAGE_ID/primary \
  Authorization:"Bearer YOUR_TOKEN"
```

#### Get Image Statistics
```bash
# Get image statistics for entity
http GET localhost:4000/api/games/GAME_ID/characters/CHAR_ID/images/stats \
  Authorization:"Bearer YOUR_TOKEN"
```

#### Delete Image
```bash
# Delete image and associated file
http DELETE localhost:4000/api/games/GAME_ID/characters/CHAR_ID/images/IMAGE_ID \
  Authorization:"Bearer YOUR_TOKEN"
```

### cURL Examples

#### Upload with cURL
```bash
curl -X POST localhost:4000/api/games/GAME_ID/characters/CHAR_ID/images \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "image[file]=@portrait.jpg" \
  -F "image[alt_text]=Character portrait" \
  -F "image[is_primary]=true"
```

#### Download Image
```bash
curl -L localhost:4000/api/games/GAME_ID/characters/CHAR_ID/images/IMAGE_ID/file \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -o downloaded_image.jpg
```

## File Organization

### Directory Structure

The system organizes files hierarchically:

```
uploads/
└── games/
    └── {game-id}/
        ├── character/
        │   └── {character-id}/
        │       ├── {uuid-1}.jpg
        │       ├── {uuid-2}.png
        │       └── {uuid-3}.webp
        ├── faction/
        │   └── {faction-id}/
        │       └── {uuid-4}.jpg
        ├── location/
        │   └── {location-id}/
        │       └── {uuid-5}.png
        └── quest/
            └── {quest-id}/
                └── {uuid-6}.gif
```

### Optional Date-Based Organization

When using date-based key generation:

```
uploads/
└── games/
    └── {game-id}/
        └── character/
            └── {character-id}/
                └── 2025/
                    └── 01/
                        └── 07/
                            ├── {uuid-1}.jpg
                            └── {uuid-2}.png
```

### Key Benefits

- **Isolation**: Each game's files are completely separate
- **Organization**: Files grouped by entity type and ID
- **Scalability**: Directory structure prevents too many files in one folder
- **Cleanup**: Empty directories are automatically removed
- **Uniqueness**: UUID filenames prevent collisions

## Error Handling

The system provides comprehensive error handling:

### API Error Responses

#### Validation Errors
```json
{
  "errors": {
    "content_type": ["must be a valid image type (JPEG, PNG, WebP, or GIF)"],
    "file_size": ["must be less than 20MB"],
    "entity_type": ["must be one of: character, faction, location, quest"]
  }
}
```

#### Not Found
```json
{
  "errors": {
    "detail": "Image not found"
  }
}
```

#### File Upload Errors
```json
{
  "errors": {
    "file": ["is required"],
    "upload": ["failed to store file"]
  }
}
```

### Storage Errors

- **File not found**: Returns `{:error, :not_found}`
- **Permission errors**: Returns `{:error, :access_denied}`
- **Network errors**: Returns `{:error, reason}` with specific error details
- **Disk space**: Returns `{:error, :no_space}` for filesystem issues

### Transaction Safety

All operations use database transactions to ensure consistency:

- Image creation with file storage
- Primary image updates
- Image deletion with file cleanup

If any step fails, the entire operation is rolled back.

## Security Considerations

### Access Control

- **Game scoping**: All operations scoped to user's accessible games
- **Authentication**: Requires valid JWT token
- **Authorization**: Users can only access images in their games

### File Validation

- **MIME type checking**: Validates actual file content, not just extension
- **File size limits**: Prevents abuse and storage issues
- **Extension validation**: Ensures safe file types only

### File Storage

- **Unique filenames**: UUID-based names prevent directory traversal
- **Isolated storage**: Each game's files stored separately
- **No executable files**: Only image types allowed

### Recommended Production Settings

1. **Use CDN**: Configure S3 with CloudFront or similar CDN
2. **Set CORS**: Configure appropriate CORS headers for image serving
3. **Enable compression**: Use gzip compression for image metadata responses
4. **Rate limiting**: Implement upload rate limiting per user/game
5. **Virus scanning**: Consider integrating virus scanning for uploaded files
6. **Backup strategy**: Ensure uploaded images are included in backup procedures

### Privacy Considerations

- Images are only accessible to members of the associated game
- File URLs include UUIDs making them hard to guess
- Consider implementing signed URLs for additional security in production
- Alt text should not contain sensitive information

---

*This documentation covers the complete image upload system implementation as of the current version. For the latest updates and API changes, refer to the Phoenix Swagger documentation at `/api/swagger`.*
