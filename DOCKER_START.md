# Docker Quick Start

## Prerequisites
- Docker Desktop installed and running

## Start the Project

```bash
# 1. Copy environment file
copy .env.example .env

# 2. Start all services
docker compose up --build
```

Wait 2-3 minutes. When you see `Application deployed successfully!`, open:

**http://localhost:3000**

## Login Credentials

| User | Password | Role |
|------|----------|------|
| admin | admin123 | Admin |
| manager | manager123 | Project Manager |
| user | user123 | Employee |

## Common Commands

```bash
# Start in background
docker compose up -d

# View logs
docker compose logs -f

# Stop
docker compose down

# Reset everything (deletes database)
docker compose down -v
docker compose up --build
```

## Development Mode (Hot Reload)

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

## Ports

| Service | URL |
|---------|-----|
| Frontend | http://localhost:3000 |
| Backend API | http://localhost:8080/ideaboard/api |
| Database | localhost:5432 |
