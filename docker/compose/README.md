# Docker Compose Configurations

This directory contains Docker Compose configurations for the LocalStore Platform.

## Files

- `docker-compose.yml` - Local development environment
- `docker-compose.prod.yml` - Production deployment
- `docker-compose.test.yml` - Testing environment

## Usage

### Local Development

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down
```

### Production

```bash
# Start with production configuration
docker compose -f docker-compose.prod.yml up -d

# View status
docker compose -f docker-compose.prod.yml ps
```

## Services

| Service | Port | Description |
|---------|------|-------------|
| api | 3000 | NestJS API Gateway |
| ai | 8000 | Python FastAPI AI Service |
| postgres | 5432 | PostgreSQL Database |
| redis | 6379 | Redis Cache |
| nginx | 80/443 | Reverse Proxy (prod only) |
