# Image Upload System Documentation

## Overview

The Game Master Core application includes a comprehensive image upload system that allows users to upload, manage, and serve images for various game entities including characters, factions, locations, and quests. The system features a pluggable storage architecture that supports both local filesystem and S3-compatible cloud storage.

## Key Features

- **Multi-Entity Support**: Upload images for characters, factions, locations, and quests
- **Primary Image Management**: Mark one image per entity as primary for display
- **Pluggable Storage**: Support for local filesystem and S3-compatible storage backends
- **Security**: File validation, access control, and secure file handling
- **REST API**: Complete CRUD operations via JSON API
- **Metadata Management**: Store file metadata, alt text, and custom metadata
- **Statistics**: Track image counts and storage usage per entity

## Database Schema

### Images Table Structure

```sql
CREATE TABLE images (
  id UUID PRIMARY KEY,
  filename TEXT NOT NULL,
  file_path TEXT NOT NULL,
  file_url TEXT NOT NULL,
  file_size BIGINT NOT NULL,
  content_type TEXT NOT NULL,
  alt_text TEXT,
  is_primary BOOLEAN NOT NULL DEFAULT false,
  entity_type TEXT NOT NULL,
  entity_id UUID NOT NULL,
  metadata JSONB DEFAULT '{}',
  game_id UUID NOT NULL REFERENCES games(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  inserted_at TIMESTAMP NOT NULL,
  updated_at TIMESTAMP NOT NULL
);
```

### Key Indexes and Constraints

- **Unique Primary Image Constraint**: Only one primary image per entity
- **Multi-column Indexes**: Efficient querying by game, entity type, and entity ID
- **Foreign Key Constraints**: Cascade deletion with games and users

```sql
-- Ensure only one primary image per entity
CREATE UNIQUE INDEX images_unique_primary_per_entity 
ON images (entity_type, entity_id, is_primary) 
WHERE is_primary = true;

-- Performance indexes
CREATE INDEX images_game_id_index ON images (game_id);
CREATE INDEX images_user_id_index ON images (user_id);
CREATE INDEX images_entity_type_entity_id_index ON images (entity_type, entity_id);
```

## Image Schema (Ecto)

### Validation Rules

```elixir
# lib/game_master_core/images/image.ex

# Supported entity types
@valid_entity_types ["character", "faction", "location", "quest"]

# Supported content types
@valid_content_types [
  "image/jpeg",
  "image/jpg", 
  "image/png",
  "image/webp",
  "image/gif"
]

# Maximum file size (10MB)
@max_file_size 10 * 1024 * 1024
```

### Changeset Types

1. **Initial Changeset**: Basic validation for entity association
2. **Complete Changeset**: Full validation including file information
3. **File Changeset**: Updates file-related fields after storage
4. **Update Changeset**: Metadata updates (alt text, primary status)

## Storage Architecture

### Storage Behavior Interface

The system uses a behavior-based approach for pluggable storage backends:

```elixir
# lib/game_master_core/storage/behaviour.ex

@callback store(file_path :: String.t(), key :: String.t(), opts :: Keyword.t()) ::
  {:ok, %{url: String.t(), metadata: map()}} | {:error, term()}

@callback retrieve(key :: String.t()) :: {:ok, binary()} | {:error, term()}

@callback delete(key :: String.t()) :: :ok | {:error, term()}

@callback get_url(key :: String.t()) :: String.t()

@callback exists?(key :: String.t()) :: boolean()
```

### Local Filesystem Adapter

**Configuration**:
```elixir
# config/dev.exs
config :game_master_core,
  storage_adapter: GameMasterCore.Storage.Local,
  uploads_directory: "uploads",
  uploads_base_url: "/uploads"
```

**Features**:
- Automatic directory creation
- File copying with error handling
- Empty directory cleanup on deletion
- Static file serving via Phoenix

**File Organization**:
```
uploads/
└── games/
    └── {game_id}/
        └── {entity_type}/
            └── {entity_id}/
                └── {uuid}.{ext}
```

### S3-Compatible Storage Adapter

**Configuration**:
```elixir
# config/prod.exs
config :game_master_core,
  storage_adapter: GameMasterCore.Storage.S3,
  s3_bucket: "my-game-images",
  s3_region: "us-west-2",
  s3_access_key_id: System.get_env("S3_ACCESS_KEY_ID"),
  s3_secret_access_key: System.get_env("S3_SECRET_ACCESS_KEY"),
  s3_public_url: "https://cdn.example.com"  # Optional CDN URL

# For S3-compatible services (MinIO, DigitalOcean Spaces, etc.)
config :game_master_core,
  storage_adapter: GameMasterCore.Storage.S3,
  s3_bucket: "game-images",
  s3_endpoint: "https://minio.example.com",
  s3_access_key_id: "minioadmin",
  s3_secret_access_key: "minioadmin"
```

**Features**:
- Works with AWS S3 and S3-compatible services
- Custom endpoint support for MinIO, DigitalOcean Spaces, etc.
- CDN integration support
- Proper HTTP status code handling

## Key Generation

### Standard Key Generation

```elixir
# Generates: "games/{game_id}/{entity_type}/{entity_id}/{uuid}.{ext}"
KeyGenerator.generate_key(game_id, entity_type, entity_id, filename)
```

### Date-Based Key Generation

```elixir
# Generates: "games/{game_id}/{entity_type}/{entity_id}/2025/01/07/{uuid}.{ext}"
KeyGenerator.generate_key(game_id, entity_type, entity_id, filename, :with_date)
```

### Temporary Keys

```elixir
# For temporary uploads: "temp/{uuid}-{basename}.{ext}"
KeyGenerator.generate_temp_key(filename)
```

### Key Parsing

```elixir
# Extract components from storage key
KeyGenerator.parse_key("games/123/character/456/uuid.jpg")
# => {:ok, %{game_id: "123", entity_type: "character", entity_id: "456", filename: "uuid.jpg"}}
```

## Business Logic (Context)

### Core Functions

```elixir
# lib/game_master_core/images.ex

# Create image with file upload
Images.create_image_for_entity(scope, upload, attrs)

# List images for entity
Images.list_images_for_entity(scope, entity_type, entity_id, opts)

# Get specific image
Images.get_image_for_game(scope, image_id)

# Update image metadata
Images.update_image(scope, image_id, attrs)

# Delete image and file
Images.delete_image(scope, image_id)

# Set as primary image
Images.set_as_primary(scope, image_id)

# Get statistics
Images.get_image_stats(scope, entity_type, entity_id)
```

### Upload Flow

1. **File Storage**: Store file via storage adapter first
2. **Database Record**: Create database record with complete file information
3. **Primary Management**: Handle primary image logic if needed
4. **Transaction Safety**: All operations wrapped in database transactions
5. **Cleanup**: Remove stored files if database operations fail

### Error Handling

- File storage failures are handled gracefully
- Database transactions ensure consistency
- Stored files are cleaned up on database errors
- Detailed error logging for debugging

## REST API Endpoints

### Base URL Structure

All image endpoints follow this pattern:
```
/api/games/{game_id}/{entity_type}s/{entity_id}/images
```

Where `{entity_type}` is one of: `character`, `faction`, `location`, `quest`

### Upload Image

**POST** `/api/games/{game_id}/{entity_type}s/{entity_id}/images`

**Request Format** (multipart/form-data):
```
image[file]: <file>
image[alt_text]: "Description" (optional)
image[is_primary]: true|false (optional, default: false)
```

**Example with HTTPie**:
```bash
http --form POST localhost:4000/api/games/UUID/characters/UUID/images \
  "Authorization:Bearer TOKEN" \
  image[file]@avatar.jpg \
  image[alt_text]="Character portrait"
```

**Response** (201 Created):
```json
{
  "data": {
    "id": "image-uuid",
    "filename": "avatar.jpg",
    "file_url": "/uploads/games/game-id/character/char-id/uuid.jpg",
    "file_size": 45678,
    "content_type": "image/jpeg",
    "alt_text": "Character portrait",
    "is_primary": false,
    "metadata": {
      "path": "/path/to/file",
      "size": 45678,
      "modified_at": "2025-01-07T12:00:00Z"
    },
    "inserted_at": "2025-01-07T12:00:00Z"
  }
}
```

### List Images

**GET** `/api/games/{game_id}/{entity_type}s/{entity_id}/images`

**Query Parameters**:
- `primary_first=true`: Sort primary image first

**Example**:
```bash
http GET localhost:4000/api/games/UUID/characters/UUID/images?primary_first=true \
  "Authorization:Bearer TOKEN"
```

### Get Specific Image

**GET** `/api/games/{game_id}/{entity_type}s/{entity_id}/images/{image_id}`

### Update Image Metadata

**PUT** `/api/games/{game_id}/{entity_type}s/{entity_id}/images/{image_id}`

**Request Body**:
```json
{
  "alt_text": "Updated description",
  "is_primary": true
}
```

### Set Primary Image

**PUT** `/api/games/{game_id}/{entity_type}s/{entity_id}/images/{image_id}/primary`

### Delete Image

**DELETE** `/api/games/{game_id}/{entity_type}s/{entity_id}/images/{image_id}`

### Get Image Statistics

**GET** `/api/games/{game_id}/{entity_type}s/{entity_id}/images/stats`

**Response**:
```json
{
  "data": {
    "total_count": 5,
    "total_size": 2547890,
    "has_primary": true,
    "entity_type": "character",
    "entity_id": "entity-uuid"
  }
}
```

### Serve Image File

**GET** `/api/games/{game_id}/{entity_type}s/{entity_id}/images/{image_id}/file`

Redirects to the actual file URL for downloading/viewing.

## Configuration

### Development Configuration

```elixir
# config/dev.exs
config :game_master_core,
  storage_adapter: GameMasterCore.Storage.Local,
  uploads_directory: "uploads",
  uploads_base_url: "/uploads"
```

### Production Configuration

```elixir
# config/prod.exs
config :game_master_core,
  storage_adapter: GameMasterCore.Storage.S3,
  s3_bucket: System.get_env("S3_BUCKET"),
  s3_region: System.get_env("S3_REGION") || "us-east-1",
  s3_access_key_id: System.get_env("S3_ACCESS_KEY_ID"),
  s3_secret_access_key: System.get_env("S3_SECRET_ACCESS_KEY"),
  s3_public_url: System.get_env("S3_PUBLIC_URL")  # Optional CDN
```

### Static File Serving

For local storage, Phoenix serves files directly:

```elixir
# lib/game_master_core_web/endpoint.ex
plug Plug.Static,
  at: "/uploads",
  from: "uploads",
  gzip: false
```

## Usage Examples

### Complete Upload Workflow

1. **Upload Image**:
```bash
http --form POST localhost:4000/api/games/GAME_ID/characters/CHAR_ID/images \
  "Authorization:Bearer TOKEN" \
  image[file]@portrait.jpg \
  image[alt_text]="Main character portrait"
```

2. **Set as Primary**:
```bash
http PUT localhost:4000/api/games/GAME_ID/characters/CHAR_ID/images/IMAGE_ID/primary \
  "Authorization:Bearer TOKEN"
```

3. **Get Updated Character** (images included in response):
```bash
http GET localhost:4000/api/games/GAME_ID/characters/CHAR_ID \
  "Authorization:Bearer TOKEN"
```

### Entity Integration

Images are automatically included in entity JSON responses:

```json
{
  "data": {
    "id": "character-uuid",
    "name": "Bilbo Baggins",
    "images": [
      {
        "id": "image-uuid",
        "filename": "bilbo.jpg",
        "file_url": "/uploads/games/.../bilbo.jpg",
        "is_primary": true,
        "alt_text": "Bilbo Baggins portrait"
      }
    ],
    "primary_image": {
      "id": "image-uuid",
      "file_url": "/uploads/games/.../bilbo.jpg",
      "alt_text": "Bilbo Baggins portrait"
    }
  }
}
```

### Bulk Operations

**Upload Multiple Images**:
```bash
# Upload first image as primary
http --form POST localhost:4000/api/games/GAME_ID/characters/CHAR_ID/images \
  image[file]@main.jpg image[is_primary]:=true

# Upload additional images
http --form POST localhost:4000/api/games/GAME_ID/characters/CHAR_ID/images \
  image[file]@alt1.jpg image[alt_text]="Alternative view"

http --form POST localhost:4000/api/games/GAME_ID/characters/CHAR_ID/images \
  image[file]@alt2.jpg image[alt_text]="Action shot"
```

## Security Considerations

### File Validation

- **Content Type Validation**: Only image MIME types allowed
- **File Extension Validation**: Filename must match allowed extensions
- **File Size Limits**: Configurable maximum file size (default: 10MB)
- **Filename Sanitization**: Original filenames are not used in storage keys

### Access Control

- **Game Scope**: Users can only access images from games they have access to
- **Authentication**: All endpoints require valid authentication tokens
- **Authorization**: Images are associated with specific users and games

### Security Best Practices

1. **Use UUID-based Storage Keys**: Prevents directory traversal and guessing
2. **Validate Content Types**: Check actual file content, not just extensions
3. **Limit File Sizes**: Prevent storage abuse and DoS attacks
4. **Secure Storage Configuration**: Use proper IAM policies for S3 access
5. **CDN Configuration**: Use signed URLs for private content if needed

## Error Handling

### Common Error Responses

**Invalid File Type**:
```json
{
  "errors": {
    "content_type": ["must be a valid image type (JPEG, PNG, WebP, or GIF)"]
  }
}
```

**File Too Large**:
```json
{
  "errors": {
    "file_size": ["must be less than 10MB"]
  }
}
```

**Missing File**:
```json
{
  "error": "missing_file"
}
```

**Storage Failure**:
```json
{
  "error": "file_storage_failed"
}
```

### Debugging

Enable debug logging to troubleshoot upload issues:

```elixir
# config/dev.exs
config :logger, level: :debug
```

Check logs for:
- File storage operations
- Database transaction details
- Storage adapter specific errors
- File path and permission issues

## Performance Considerations

### Database Optimization

- **Indexes**: Proper indexing on frequently queried columns
- **Pagination**: Use offset/limit for large image lists
- **Preloading**: Preload images when fetching entities to avoid N+1 queries

### Storage Optimization

- **CDN Usage**: Configure CDN for S3 storage in production
- **Image Processing**: Consider adding image resizing/optimization
- **Cleanup Jobs**: Implement background jobs for orphaned file cleanup
- **Caching**: Cache file URLs and metadata where appropriate

### Monitoring

Track key metrics:
- Upload success/failure rates
- Storage usage by game/entity
- File access patterns
- API response times

## Extending the System

### Adding New Entity Types

1. **Update Valid Types**: Add new type to `@valid_entity_types`
2. **Add Routes**: Add routes for new entity type in router
3. **Update Controllers**: Ensure entity controllers include image logic
4. **Update Tests**: Add test coverage for new entity type

### Custom Storage Adapters

Implement the `GameMasterCore.Storage.Behaviour`:

```elixir
defmodule MyApp.Storage.CustomAdapter do
  @behaviour GameMasterCore.Storage.Behaviour
  
  @impl true
  def store(file_path, key, opts), do: # implementation
  
  @impl true
  def retrieve(key), do: # implementation
  
  # ... implement all callbacks
end
```

### Image Processing

Add image processing by creating a wrapper around storage operations:

```elixir
def store_with_processing(file_path, key, opts) do
  with {:ok, processed_path} <- process_image(file_path, opts),
       {:ok, result} <- Storage.store(processed_path, key, opts) do
    File.rm(processed_path)  # cleanup
    {:ok, result}
  end
end
```

## Migration Guide

### From Basic File Storage

If migrating from a basic file storage system:

1. **Run Migration**: `mix ecto.migrate` to create images table
2. **Update Configuration**: Set storage adapter and configuration
3. **Migrate Existing Files**: Create migration script to populate images table
4. **Update Client Code**: Switch to new REST API endpoints

### Testing the System

Comprehensive test coverage is provided for:
- Image CRUD operations
- File upload and storage
- Primary image management
- Storage adapter functionality
- API endpoint integration

Run tests with: `mix test`