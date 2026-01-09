# GFOS Digital Idea B

Innovation management platform for GFOS Innovation Award 2026.

## Technology Stack

### Backend
- **Framework**: Jakarta EE 10 on GlassFish 7
- **REST API**: JAX-RS (Jersey 3.1.3)
- **ORM**: JPA with EclipseLink 4.0.2
- **Database**: PostgreSQL 15+
- **Auth**: JWT (stateless)
- **Build**: Maven 3.8+
- **Java**: JDK 17

### Frontend
- **Framework**: React 18 with TypeScript
- **Build Tool**: Vite 5
- **UI**: Tailwind CSS with Material Design
- **Routing**: React Router v6
- **HTTP Client**: Axios
- **Charts**: Recharts
- **Icons**: Heroicons

## Features

- JWT-based authentication with refresh tokens
- Role-based access control (Employee, Project Manager, Admin)
- Idea management with CRUD operations
- Weekly like system (3 likes per week, resets Sunday)
- Comments with 200 character limit and emoji reactions
- User-created surveys with voting
- Gamification system (XP, levels, badges)
- Real-time notifications
- Dark mode support
- File uploads (images, PDFs, documents - max 10MB)
- CSV/PDF export functionality
- Comprehensive audit logging

## Prerequisites

Before you begin, ensure you have the following installed:

1. **Java 17 JDK**
   - Download: https://adoptium.net/
   - Verify: `java -version`

2. **Apache Maven 3.8+**
   - Download: https://maven.apache.org/download.cgi
   - Verify: `mvn -version`

3. **PostgreSQL 15+**
   - Download: https://www.postgresql.org/download/windows/
   - Verify: `psql --version`

4. **GlassFish 7**
   - Download: https://glassfish.org/download
   - Extract to a directory (e.g., `C:\glassfish7`)

5. **Node.js 18+**
   - Download: https://nodejs.org/
   - Verify: `node --version`

## Installation & Setup

### 1. Database Setup

```bash
# Create database
psql -U postgres
CREATE DATABASE ideaboard;
CREATE USER ideaboard_user WITH ENCRYPTED PASSWORD 'your_password';
GRANT ALL PRIVILEGES ON DATABASE ideaboard TO ideaboard_user;
\q

# Run initialization script
psql -U postgres -d ideaboard -f database/init.sql
```

### 2. GlassFish Configuration

#### Start GlassFish
```bash
# Windows
C:\glassfish7\bin\asadmin start-domain

# Linux/Mac
./glassfish7/bin/asadmin start-domain
```

#### Create JDBC Connection Pool
```bash
asadmin create-jdbc-connection-pool \
  --restype javax.sql.DataSource \
  --datasourceclassname org.postgresql.ds.PGSimpleDataSource \
  --property user=ideaboard_user:password=your_password:serverName=localhost:portNumber=5432:databaseName=ideaboard \
  IdeaBoardPool
```

#### Create JDBC Resource
```bash
asadmin create-jdbc-resource --connectionpoolid IdeaBoardPool jdbc/ideaboard
```

#### Test the connection
```bash
asadmin ping-connection-pool IdeaBoardPool
```

### 3. Backend Setup

```bash
cd backend

# Build the project
mvn clean package

# The WAR file will be created at: target/ideaboard.war
```

#### Deploy to GlassFish
```bash
# Option 1: Using asadmin
asadmin deploy target/ideaboard.war

# Option 2: Copy to autodeploy directory
cp target/ideaboard.war C:\glassfish7\glassfish\domains\domain1\autodeploy\

# Verify deployment
asadmin list-applications
```

The backend will be available at: `http://localhost:8080/ideaboard/api`

### 4. Frontend Setup

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

The frontend will be available at: `http://localhost:5173`

### 5. Verify Your Installation

After setup, verify everything is working correctly:

```powershell
# Run the verification script
.\verify-system.ps1

# For quick checks only (skips full tests)
.\verify-system.ps1 -Quick
```

This will check:
- ✓ Database connectivity and seed data
- ✓ User authentication works correctly
- ✓ GlassFish server is running
- ✓ Backend API is accessible
- ✓ Frontend is running
- ✓ All integration tests pass

**Important**: Always run verification after database initialization or changes!

### Alternative: One-Command Startup

Use the automated startup script that handles everything:

```powershell
# Full startup (database, backend, frontend)
.\start-project.ps1

# Options:
.\start-project.ps1 -SkipChecks        # Skip dependency checks
.\start-project.ps1 -SkipBuild         # Skip Maven build
.\start-project.ps1 -FrontendOnly      # Start only frontend
.\start-project.ps1 -BackendOnly       # Start only backend + database
```

## Default Credentials

After running the database init.sql, these test accounts are available:

| Username | Password | Role |
|----------|----------|------|
| admin | admin123 | ADMIN |
| john.doe | password123 | EMPLOYEE |
| jane.smith | password123 | PROJECT_MANAGER |
| bob.wilson | password123 | EMPLOYEE |

## API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login
- `POST /api/auth/refresh` - Refresh access token

### Ideas
- `GET /api/ideas` - List ideas (with filters, pagination)
- `GET /api/ideas/{id}` - Get idea details
- `POST /api/ideas` - Create idea
- `PUT /api/ideas/{id}` - Update idea
- `DELETE /api/ideas/{id}` - Delete idea (admin only)
- `POST /api/ideas/{id}/like` - Like an idea
- `DELETE /api/ideas/{id}/like` - Unlike an idea
- `POST /api/ideas/{id}/files` - Upload file
- `GET /api/ideas/{id}/files/{fileId}` - Download file
- `DELETE /api/ideas/{id}/files/{fileId}` - Delete file

### Comments
- `GET /api/ideas/{id}/comments` - Get comments for idea
- `POST /api/ideas/{id}/comments` - Add comment
- `DELETE /api/comments/{id}` - Delete comment
- `POST /api/comments/{id}/reactions` - Add emoji reaction
- `DELETE /api/comments/{id}/reactions/{emoji}` - Remove reaction

### Surveys
- `GET /api/surveys` - List surveys
- `GET /api/surveys/active` - Get active surveys
- `POST /api/surveys` - Create survey
- `POST /api/surveys/{id}/vote` - Vote on survey
- `DELETE /api/surveys/{id}` - Delete survey

### Dashboard
- `GET /api/dashboard/statistics` - Get dashboard statistics
- `GET /api/dashboard/top-ideas` - Get top 3 ideas of the week

### Notifications
- `GET /api/notifications` - Get user notifications
- `GET /api/notifications/unread-count` - Get unread count
- `PUT /api/notifications/{id}/read` - Mark as read
- `PUT /api/notifications/read-all` - Mark all as read

### Users
- `GET /api/users/me` - Get current user
- `PUT /api/users/me` - Update profile
- `GET /api/users/me/likes/remaining` - Get remaining weekly likes
- `GET /api/users` - List all users (admin only)
- `PUT /api/users/{id}/role` - Update user role (admin only)
- `PUT /api/users/{id}/status` - Activate/deactivate user (admin only)

### Export (Admin/PM Only)
- `GET /api/export/ideas/csv` - Export ideas to CSV
- `GET /api/export/statistics/csv` - Export statistics to CSV
- `GET /api/export/statistics/pdf` - Export statistics to PDF
- `GET /api/export/users/csv` - Export users to CSV (admin only)

### Audit Logs (Admin Only)
- `GET /api/audit-logs` - Get audit logs

## Development

### Frontend Development
```bash
cd frontend
npm run dev       # Start dev server
npm run build     # Build for production
npm run preview   # Preview production build
npm run lint      # Run ESLint
```

### Backend Development
```bash
cd backend
mvn clean package           # Build WAR file
mvn clean compile           # Compile only
asadmin redeploy ideaboard  # Hot redeploy (if already deployed)
```

## Gamification System

### XP Rewards
- Submit idea: +50 XP
- Receive like: +10 XP
- Post comment: +5 XP
- Idea completed: +100 XP

### Level Thresholds
- Level 1: 0 XP (Newcomer)
- Level 2: 100 XP (Contributor)
- Level 3: 300 XP (Innovator)
- Level 4: 600 XP (Expert)
- Level 5: 1000 XP (Master)
- Level 6: 1500 XP (Legend)

### Badges
- **First Idea** - Submit your first idea
- **Popular** - Get 10 likes on a single idea
- **Commentator** - Post 50 comments
- **Supporter** - Use all 3 likes for 4 weeks in a row
- **Contributor of the Month** - Most ideas in a month (automated)

## Project Structure

```
gfos/
├── backend/
│   ├── src/main/java/com/gfos/ideaboard/
│   │   ├── config/           # CORS, Jackson, ApplicationConfig
│   │   ├── entity/           # JPA entities
│   │   ├── service/          # Business logic
│   │   ├── resource/         # REST endpoints
│   │   ├── security/         # JWT, filters, password utils
│   │   ├── dto/              # Data Transfer Objects
│   │   ├── exception/        # Exception handling
│   │   └── util/             # Utilities
│   ├── src/main/resources/
│   │   └── META-INF/
│   │       └── persistence.xml
│   ├── src/main/webapp/
│   │   └── WEB-INF/
│   │       ├── web.xml
│   │       └── glassfish-web.xml
│   └── pom.xml
├── frontend/
│   ├── src/
│   │   ├── components/       # Reusable components
│   │   ├── pages/            # Page components
│   │   ├── services/         # API services
│   │   ├── context/          # React contexts
│   │   ├── types/            # TypeScript types
│   │   └── utils/            # Utility functions
│   ├── public/
│   ├── package.json
│   ├── vite.config.ts
│   ├── tailwind.config.js
│   └── tsconfig.json
└── database/
    └── init.sql              # Database schema and seed data
```

## Troubleshooting

### Database Connection Issues
```bash
# Check if PostgreSQL is running
pg_isready

# Test connection
psql -U ideaboard_user -d ideaboard -h localhost
```

### GlassFish Issues
```bash
# View logs
tail -f C:\glassfish7\glassfish\domains\domain1\logs\server.log

# Restart domain
asadmin stop-domain
asadmin start-domain

# List applications
asadmin list-applications

# Undeploy
asadmin undeploy ideaboard
```

### Frontend Build Issues
```bash
# Clear node modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Clear Vite cache
rm -rf .vite
```

### CORS Issues
The backend is configured to allow CORS from `http://localhost:5173`. If you change the frontend port, update `CorsFilter.java`.

## Development Best Practices

### ⚠️ Important: Preventing Common Issues

To avoid issues like authentication failures, database errors, and deployment problems:

1. **Always validate after database changes:**
   ```bash
   cd backend
   mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"
   ```

2. **Run tests before committing:**
   ```bash
   mvn test
   ```

3. **Use the verification script regularly:**
   ```powershell
   .\verify-system.ps1
   ```

4. **Check logs when troubleshooting:**
   ```bash
   tail -f glassfish7/glassfish/domains/domain1/logs/server.log
   ```

### Development Guide

**📖 Read the full [DEVELOPMENT-GUIDE.md](DEVELOPMENT-GUIDE.md)** for comprehensive information on:

- Database management and validation
- Testing strategies and integration tests
- Development workflow best practices
- Error handling and logging
- Troubleshooting common issues
- CI/CD recommendations

**Key utilities available:**

- `ValidateDatabase` - Verify database integrity and authentication
- `PasswordHashGenerator` - Generate correct BCrypt password hashes
- `FixPasswordHashes` - Fix incorrect password hashes in database
- `AuthenticationIntegrationTest` - Test authentication system

**Before each deployment, ensure:**
- ✅ All tests pass: `mvn test`
- ✅ Database validation passes: `mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"`
- ✅ System verification passes: `.\verify-system.ps1`
- ✅ Manual smoke test (login, create idea, etc.)

## License

Proprietary - GFOS Innovation Award 2026

## Support

For issues or questions, contact the development team.
