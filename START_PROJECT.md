# How to Start the Project

## 1. Database (PostgreSQL)

**Option A: Using pgAdmin (recommended for Windows)**
1. Open pgAdmin
2. Right-click "Databases" → Create → Database → Name: `ideaboard`
3. Right-click `ideaboard` → Query Tool
4. File → Open → select `GFOS-/database/init.sql` → Execute (F5)
5. In the same Query Tool, run these commands to create test user:
   ```sql
   CREATE USER ideaboard_user WITH PASSWORD 'ideaboard123';
   GRANT ALL PRIVILEGES ON DATABASE ideaboard TO ideaboard_user;
   GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ideaboard_user;
   GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ideaboard_user;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO ideaboard_user;
   ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO ideaboard_user;
   ```

**Option B: Using command line (CMD or PowerShell)**

**Step 1:** Find your PostgreSQL installation folder (usually `C:\Program Files\PostgreSQL\15\bin` or `16\bin`)

**Step 2:** Open CMD or PowerShell and run these commands one by one:

```cmd
:: Navigate to PostgreSQL bin folder (adjust version number 15/16/17/18 to match yours)
cd "C:\Program Files\PostgreSQL\18\bin"

:: Create the database (enter your postgres password when prompted)
psql -U postgres -c "CREATE DATABASE ideaboard;"

:: Load the schema and seed data (adjust path to your project location)
psql -U postgres -d ideaboard -f "C:\GGFF\GFOS-\database\init.sql"
```

**Step 3:** Create database user for tests:
```cmd
:: Create the test user (required for mvn test and mvn package)
psql -U postgres -d ideaboard -c "CREATE USER ideaboard_user WITH PASSWORD 'ideaboard123';"

:: Grant all privileges on database
psql -U postgres -d ideaboard -c "GRANT ALL PRIVILEGES ON DATABASE ideaboard TO ideaboard_user;"

:: Grant permissions on all existing tables
psql -U postgres -d ideaboard -c "GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO ideaboard_user;"

:: Grant permissions on sequences (for auto-increment IDs)
psql -U postgres -d ideaboard -c "GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO ideaboard_user;"

:: Grant default privileges for future tables
psql -U postgres -d ideaboard -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON TABLES TO ideaboard_user;"
psql -U postgres -d ideaboard -c "ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL PRIVILEGES ON SEQUENCES TO ideaboard_user;"
```

**Step 4:** Verify it worked:
```cmd
psql -U postgres -d ideaboard -c "\dt"
```
You should see a list of ~20 tables.

**Seed data includes:**
- 4 users: `admin` (password: `admin123`), `jsmith`, `mwilson`, `tjohnson` (password: `password123`)
- 10 badges, 5 sample ideas, comments, surveys, and messages

---

## 2. Backend (GlassFish)

### Start GlassFish
```cmd
:: Start GlassFish server
C:\glassfish-7.1.0\glassfish7\bin\asadmin start-domain domain1

:: Check if running
C:\glassfish-7.1.0\glassfish7\bin\asadmin list-domains
```

You should see `domain1 running` in the output.

### GlassFish JDBC Setup (One-time configuration)
1. Open GlassFish Admin Console: `http://localhost:4848`
2. Create JDBC Connection Pool:
   - Resources → JDBC → Connection Pools → New
   - Pool Name: `ideaboardPool`
   - Resource Type: `javax.sql.DataSource`
   - Database Driver Vendor: `PostgreSQL`
   - Click Next, then add these properties:
     - `URL`: `jdbc:postgresql://localhost:5432/ideaboard`
     - `User`: `postgres`
     - `Password`: `yourpassword` (your PostgreSQL password)
   - Click Finish
   - Click `ideaboardPool` → Ping (to verify connection works)

3. Create JDBC Resource:
   - Resources → JDBC → JDBC Resources → New
   - JNDI Name: `jdbc/ideaboard`
   - Pool Name: `ideaboardPool`
   - Click OK

### Build & Deploy Backend
```cmd
:: Navigate to backend folder
cd C:\GGFF\GFOS-\backend

:: Build the WAR file (compiles code and runs tests)
mvn clean package

:: Deploy to GlassFish autodeploy folder
copy target\ideaboard.war C:\glassfish-7.1.0\glassfish7\glassfish\domains\domain1\autodeploy\
```

**Verify deployment:**
- Check for `ideaboard.war_deployed` file in autodeploy folder (created automatically by GlassFish)
- Or visit: `http://localhost:8080/ideaboard/api` (should show a response)

**GlassFish Management Commands:**
```cmd
:: Stop GlassFish
C:\glassfish-7.1.0\glassfish7\bin\asadmin stop-domain domain1

:: Restart GlassFish
C:\glassfish-7.1.0\glassfish7\bin\asadmin restart-domain domain1

:: List deployed applications
C:\glassfish-7.1.0\glassfish7\bin\asadmin list-applications
```

Backend runs at: `http://localhost:8080/ideaboard/api`

---

## 3. Frontend (React/Vite)

```cmd
:: Navigate to frontend folder
cd C:\GGFF\GFOS-\frontend

:: Install dependencies (first time only)
npm install

:: Start dev server
npm run dev
```

Frontend runs at: `http://localhost:3000`

The Vite proxy automatically routes `/api` calls to the GlassFish backend at `http://localhost:8080/ideaboard`.

---

## Quick Start Order

### First-time Setup
1. **PostgreSQL**: Create database `ideaboard` and run `init.sql`
2. **Database User**: Create `ideaboard_user` with permissions (required for tests)
3. **GlassFish**: Configure JDBC connection pool and resource (one-time)
4. **Backend**: Build WAR file with `mvn clean package`
5. **Backend**: Copy WAR to GlassFish autodeploy folder
6. **Frontend**: Run `npm install` in frontend folder

### Daily Development Workflow
1. **Start PostgreSQL** (if not already running)
2. **Start GlassFish**: `C:\glassfish-7.1.0\glassfish7\bin\asadmin start-domain domain1`
3. **Start Frontend**: `cd C:\GGFF\GFOS-\frontend && npm run dev`
4. **Access App**: Open `http://localhost:3000` and login with `admin` / `admin123`

### After Code Changes
- **Backend changes**: Run `mvn clean package`, then copy new WAR to autodeploy folder
- **Frontend changes**: Vite hot-reload will update automatically

### Common URLs
- Frontend: `http://localhost:3000`
- Backend API: `http://localhost:8080/ideaboard/api`
- GlassFish Admin: `http://localhost:4848`
- PostgreSQL: `localhost:5432` (database: `ideaboard`)

---

## Troubleshooting

### Build fails with "keine Berechtigung für Tabelle users"
- Run the database user creation commands in Section 1, Step 3
- The user `ideaboard_user` needs permissions to run integration tests

### WAR file copy fails: "Das System kann den angegebenen Pfad nicht finden"
- Verify GlassFish path: `C:\glassfish-7.1.0\glassfish7\`
- Adjust version number if you have a different GlassFish version

### Backend not accessible at localhost:8080
- Check if GlassFish is running: `C:\glassfish-7.1.0\glassfish7\bin\asadmin list-domains`
- Check deployed apps: `C:\glassfish-7.1.0\glassfish7\bin\asadmin list-applications`
- Look for `ideaboard.war_deployed` marker file in autodeploy folder

### Frontend can't connect to backend
- Verify backend is running: `http://localhost:8080/ideaboard/api`
- Check GlassFish JDBC configuration is correct
- Verify PostgreSQL is running and database exists

### Database connection errors
- Verify PostgreSQL is running (check Services or pg_ctl status)
- Test connection: `psql -U postgres -d ideaboard -c "SELECT 1;"`
- Check JDBC pool in GlassFish admin console (Resources → JDBC → Connection Pools → ideaboardPool → Ping)
