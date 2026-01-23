# Docker Setup - GFOS Digital Idea Board

Start the entire project with a single command. No need to install Java, Maven, Node.js, PostgreSQL, or GlassFish.

## Prerequisites

- Docker Desktop installed and running
- Git (to clone the repository)

## Quick Start

```bash
# 1. Copy environment file
copy .env.example .env

# 2. Build and start all services
docker compose up --build

# 3. Wait for startup (about 2-3 minutes on first run)
#    You'll see "Application deployed successfully!" in the logs

# 4. Open the application
#    http://localhost:3000
```

## Default Login

| Username | Password | Role |
|----------|----------|------|
| admin | admin123 | Administrator |
| manager | manager123 | Project Manager |
| user | user123 | Employee |

## Useful Commands

```bash
# Start in background
docker compose up -d

# View logs
docker compose logs -f

# View specific service logs
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f db

# Stop all services
docker compose down

# Stop and remove database data
docker compose down -v

# Rebuild after code changes
docker compose up --build

# Check running containers
docker compose ps

# Access database shell
docker exec -it ideaboard-db psql -U postgres -d ideaboard
```

## Ports

| Service | Port | URL |
|---------|------|-----|
| Frontend | 3000 | http://localhost:3000 |
| Backend API | 8080 | http://localhost:8080/ideaboard/api |
| GlassFish Admin | 4848 | http://localhost:4848 |
| PostgreSQL | 5432 | localhost:5432 |

## Development Mode (Hot Reload)

For frontend hot-reload during development:

```bash
docker compose -f docker compose.yml -f docker compose.dev.yml up --build
```

Changes to frontend files will automatically refresh in the browser.

## Troubleshooting

### "Port already in use"
Stop any existing services using ports 3000, 8080, or 5432:
```bash
docker compose down
# Or change ports in .env file
```

### "Backend health check failed"
The backend takes about 2 minutes to fully start. Wait and check logs:
```bash
docker compose logs -f backend
```

### "Database connection refused"
Ensure the database container is healthy:
```bash
docker compose ps
docker compose logs db
```

### Reset everything
```bash
docker compose down -v
docker compose up --build
```

## Architecture

```
+------------------+     +------------------+     +------------------+
|    Frontend      |     |    Backend       |     |   PostgreSQL     |
|  (nginx:alpine)  |---->|  (GlassFish 7)   |---->|   (postgres:15)  |
|   Port: 3000     |     |   Port: 8080     |     |   Port: 5432     |
+------------------+     +------------------+     +------------------+
```

- **Frontend**: React app served by nginx, proxies /api to backend
- **Backend**: Java/Jakarta EE app on GlassFish 7
- **Database**: PostgreSQL 15 with persistent volume
