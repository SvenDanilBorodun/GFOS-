# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GFOS Digital Idea Board is an innovation management platform built for the GFOS Innovation Award 2026. It's a full-stack web application with a Jakarta EE backend and React TypeScript frontend, implementing gamification, surveys, and comprehensive idea management features.

## Architecture

### Technology Stack

**Backend (Jakarta EE)**
- Framework: Jakarta EE 10 on GlassFish 7
- REST API: JAX-RS with Jersey 3.1.3
- ORM: JPA with EclipseLink 4.0.2
- Database: PostgreSQL 15+
- Authentication: JWT (stateless) with refresh tokens
- Build: Maven 3.8+ with Java 17

**Frontend (React + TypeScript)**
- Framework: React 18 with TypeScript
- Build: Vite 5 (dev server on port 3000 with proxy to backend)
- Styling: Tailwind CSS with Material Design
- Routing: React Router v6
- HTTP: Axios with automatic token refresh interceptor
- State: React Context API (AuthContext, ThemeContext)

### Key Architectural Patterns

**Backend Structure** (`backend/src/main/java/com/gfos/ideaboard/`)
- `resource/` - JAX-RS REST endpoints (e.g., IdeaResource, AuthResource)
- `service/` - Business logic layer (e.g., IdeaService, AuthService)
- `entity/` - JPA entities (User, Idea, Comment, etc.)
- `dto/` - Data Transfer Objects for API responses
- `security/` - JWT handling (JwtFilter, JwtUtil, @Secured annotation)
- `config/` - Application configuration, CORS filter, Jackson config
- `exception/` - Global exception handling

**Frontend Structure** (`frontend/src/`)
- `pages/` - Page-level components (DashboardPage, IdeasPage, etc.)
- `components/` - Reusable UI components (Layout, NotificationDropdown)
- `services/` - API client services (ideaService, authService, etc.)
- `context/` - React contexts for global state (AuthContext, ThemeContext)
- `types/` - TypeScript type definitions (shared across frontend)

**Authentication Flow**
1. Login returns both access token (1 day expiry) and refresh token (7 days)
2. Frontend stores tokens in localStorage (`ideaboard_token`, `ideaboard_refresh_token`)
3. Axios interceptor adds `Authorization: Bearer <token>` to all requests
4. On 401 response, interceptor automatically calls `/api/auth/refresh` with refresh token
5. Backend uses `@Secured` annotation + `JwtFilter` to protect endpoints
6. JwtFilter extracts userId, username, role from token and stores in request context
7. Resources use `@Context ContainerRequestContext` to access authenticated user info

**Database Access Pattern**
- JPA persistence unit named "IdeaBoardPU" configured in `persistence.xml`
- JDBC resource: `jdbc/ideaboard` (must be configured in GlassFish)
- Services use `@PersistenceContext` for EntityManager injection
- EclipseLink performs automatic schema management with "create-or-extend-tables"

**API Design**
- Base URL: `/api` (mapped in ApplicationConfig and web.xml)
- RESTful endpoints follow pattern: `/api/{resource}/{id}?{filters}`
- All responses/requests use JSON (Jersey + Jackson)
- CORS enabled for all origins via CorsFilter with @PreMatching priority

## Development Commands

### Backend Development

```bash
# Build and package
cd backend
mvn clean package              # Creates ideaboard.war in target/

# Compile only (faster for checking compilation)
mvn clean compile

# Skip tests during build
mvn clean package -DskipTests

# Deploy to GlassFish (requires JDBC connection pool setup)
asadmin deploy target/ideaboard.war

# Redeploy after code changes
asadmin redeploy --force --name ideaboard target/ideaboard.war

# OR use provided batch script (Windows)
C:\GGFF\redeploy.bat           # Sets JAVA_HOME and redeploys

# Start GlassFish
asadmin start-domain           # Default domain1 on port 8080
# OR use batch script
C:\GGFF\start-backend.bat      # Sets JAVA_HOME and starts domain

# Check deployment
asadmin list-applications

# View logs
tail -f C:\glassfish-7.1.0\glassfish7\glassfish\domains\domain1\logs\server.log
```

### Frontend Development

```bash
cd frontend

# Install dependencies
npm install

# Start dev server (http://localhost:3000)
npm run dev

# Build for production
npm run build                  # Output to dist/

# Preview production build
npm run preview

# Lint TypeScript
npm run lint

# Type check without emitting files (fast)
npx tsc --noEmit
```

### Database Setup

```bash
# Create database and user
psql -U postgres -c "CREATE DATABASE ideaboard;"
psql -U postgres -c "CREATE USER ideaboard_user WITH ENCRYPTED PASSWORD 'your_password';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE ideaboard TO ideaboard_user;"

# Initialize schema and seed data
psql -U postgres -d ideaboard -f database/init.sql

# Access database
PGPASSWORD=your_password psql -U ideaboard_user -d ideaboard
```

### GlassFish JDBC Configuration

```bash
# Create connection pool
asadmin create-jdbc-connection-pool \
  --restype javax.sql.DataSource \
  --datasourceclassname org.postgresql.ds.PGSimpleDataSource \
  --property user=ideaboard_user:password=your_password:serverName=localhost:portNumber=5432:databaseName=ideaboard \
  IdeaBoardPool

# Create JDBC resource (must match persistence.xml jta-data-source)
asadmin create-jdbc-resource --connectionpoolid IdeaBoardPool jdbc/ideaboard

# Test connection
asadmin ping-connection-pool IdeaBoardPool
```

## Important Implementation Details

### JWT Token Handling
- Access tokens are NOT accepted as refresh tokens (checked in JwtFilter)
- Refresh tokens are ONLY accepted at `/api/auth/refresh` endpoint
- Token validation happens in JwtFilter for all `@Secured` endpoints
- User context stored in request properties: `userId`, `username`, `role`

### Role-Based Access Control
- Three roles: `EMPLOYEE`, `PROJECT_MANAGER`, `ADMIN`
- Resources check roles via `ContainerRequestContext.getSecurityContext().isUserInRole()`
- Admin-only endpoints: audit logs, user management, idea deletion
- PM + Admin: export functionality

### Weekly Like System
- Users get 3 likes per week (resets Sunday 00:00)
- Tracked in `Like` entity with `createdAt` timestamp
- LikeService calculates remaining likes based on current week
- Unlike decrements weekly count (allows re-allocation)

### Gamification System
- XP rewards: Submit idea (+50), Receive like (+10), Comment (+5), Completed idea (+100)
- Level thresholds: 0, 100, 300, 600, 1000, 1500 XP
- GamificationService handles XP awarding and badge assignment
- Badge criteria evaluated in GamificationService

### File Upload Constraints
- Max file size: 10MB
- Supported types: images (PNG, JPG, JPEG, GIF), PDFs, documents (DOC, DOCX)
- Files stored in FileAttachment entity with metadata
- FileService handles validation and storage

### Demo Mode Support
- Frontend has demo mode at `/demo-mode.html`
- Sets `ideaboard_demo_mode=true` in localStorage
- AuthContext skips API token verification in demo mode
- Allows UI testing without backend

## Common Workflows

### Adding a New API Endpoint

1. Create method in appropriate Service class (business logic)
2. Add endpoint in corresponding Resource class with `@Path`, `@GET/@POST/@PUT/@DELETE`
3. Add `@Secured` annotation if authentication required
4. Use `@Context ContainerRequestContext` to access user info
5. Return DTO objects (not entities directly)
6. Add corresponding method in frontend service file (e.g., `ideaService.ts`)
7. Update TypeScript types in `frontend/src/types/index.ts` if needed

### Modifying Database Schema

1. Update JPA entity in `backend/src/main/java/com/gfos/ideaboard/entity/`
2. Add entity class to `persistence.xml` if new entity
3. Update `database/init.sql` for clean installations
4. EclipseLink will auto-update schema on next deploy (create-or-extend-tables mode)
5. For manual schema changes, update database directly or via init.sql

### Adding a New Page/Route

1. Create page component in `frontend/src/pages/`
2. Add route in `frontend/src/App.tsx`
3. Add navigation link in `frontend/src/components/Layout.tsx` if needed
4. Create corresponding service methods in `frontend/src/services/` for API calls
5. Use `useAuth()` hook for current user context
6. Protected routes should check `user.role` and conditionally render

## Debugging Tips

**Backend Errors**
- Check GlassFish logs: `glassfish7/glassfish/domains/domain1/logs/server.log`
- Enable SQL logging: Set `eclipselink.logging.level.sql` to `FINE` in persistence.xml
- JWT errors: Token may be expired or malformed (check expiry in JwtUtil)
- 401 errors: Check if endpoint has `@Secured` and token is valid

**Frontend Errors**
- Check browser console and Network tab for API responses
- Token refresh failures: Clear localStorage and re-login
- CORS errors: Verify CorsFilter configuration in backend
- TypeScript errors: Run `npx tsc --noEmit` for detailed type checking

**Database Connection Issues**
- Verify PostgreSQL is running: `pg_isready`
- Test JDBC pool: `asadmin ping-connection-pool IdeaBoardPool`
- Check credentials match persistence.xml configuration
- Ensure database `ideaboard` exists and user has permissions

## Default Test Credentials

After running `database/init.sql`:
- Admin: `admin` / `admin123`
- Employee: `john.doe` / `password123`
- Project Manager: `jane.smith` / `password123`

## Security Considerations

- Passwords hashed with BCrypt (12 rounds) via `PasswordUtil.hashPassword()`
- JWT secret key stored in `JwtUtil` (should be externalized in production)
- Refresh tokens stored in database for revocation capability
- SQL injection prevented via JPA parameterized queries
- XSS mitigated via React's automatic escaping
- CSRF not needed (stateless JWT authentication)

## Configuration Files

- `backend/pom.xml` - Maven dependencies and build config
- `backend/src/main/resources/META-INF/persistence.xml` - JPA configuration
- `backend/src/main/webapp/WEB-INF/web.xml` - Servlet mapping, error pages
- `frontend/package.json` - npm scripts and dependencies
- `frontend/vite.config.ts` - Vite dev server (port 3000, proxies /api to backend)
- `frontend/tailwind.config.js` - Tailwind CSS customization
- `frontend/tsconfig.json` - TypeScript compiler options
