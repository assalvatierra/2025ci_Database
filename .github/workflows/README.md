# GitHub Actions Workflows

This directory contains GitHub Actions workflows for the PostgreSQL Schema Runner project.

## Workflows

### 1. `docker-build-push.yml` - Build and Push to Registry
**Triggers:**
- Push to `main` or `master` branch
- Push tags matching `v*.*.*` (e.g., v1.0.0)
- Pull requests (build only, no push)

**What it does:**
- Builds Docker image for multiple platforms (amd64, arm64)
- Pushes to GitHub Container Registry (ghcr.io)
- Generates tags automatically based on branch/tag
- Uses Docker layer caching for faster builds

**Image Tags Generated:**
- `ghcr.io/assalvatierra/2025ci_database/postgresql-schema-runner:main` (from main branch)
- `ghcr.io/assalvatierra/2025ci_database/postgresql-schema-runner:latest` (from main branch)
- `ghcr.io/assalvatierra/2025ci_database/postgresql-schema-runner:v1.0.0` (from tags)
- `ghcr.io/assalvatierra/2025ci_database/postgresql-schema-runner:1.0` (major.minor from tags)
- `ghcr.io/assalvatierra/2025ci_database/postgresql-schema-runner:1` (major from tags)

### 2. `test-build.yml` - Test Build
**Triggers:**
- Pull requests
- Manual workflow dispatch

**What it does:**
- Tests that Docker image builds successfully
- No push to registry (test only)
- Faster feedback for pull requests

## Using the Images

### Pull from GitHub Container Registry
```bash
# Latest version
docker pull ghcr.io/assalvatierra/2025ci_database/postgresql-schema-runner:latest

# Specific version
docker pull ghcr.io/assalvatierra/2025ci_database/postgresql-schema-runner:v1.0.0
```

### Run the Container
```bash
# Using Docker
docker run -p 5432:5432 \
  -e POSTGRES_DB=schemadb \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=YourStrong@Passw0rd \
  ghcr.io/assalvatierra/2025ci_database/postgresql-schema-runner:latest

# Using Docker Compose
# Update docker-compose.yml to use the registry image:
# image: ghcr.io/assalvatierra/2025ci_database/postgresql-schema-runner:latest
```

## Setting Up GitHub Container Registry

### 1. Repository Permissions
The workflow uses `GITHUB_TOKEN` which has the necessary permissions by default.

### 2. Making Images Public (Optional)
By default, packages are private. To make them public:
1. Go to your repository on GitHub
2. Click on "Packages" in the right sidebar
3. Click on the package name
4. Go to "Package settings"
5. Change visibility to "Public"

### 3. Authentication for Pulling Images
For private images, authenticate Docker:
```bash
echo $GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin
```

## Workflow Status

You can check the status of workflows:
- In the repository's "Actions" tab
- Badge in README: `![Docker Build](https://github.com/assalvatierra/2025ci_Database/actions/workflows/docker-build-push.yml/badge.svg)`

## Customization

### Environment Variables in Workflow
You can customize the image by modifying the `env` section in the workflow:
```yaml
env:
  REGISTRY: ghcr.io
  IMAGE_NAME: ${{ github.repository }}/postgresql-schema-runner
```

### Adding Secrets
For additional registries or custom authentication, add secrets in repository settings:
- `DOCKER_REGISTRY_URL`
- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`