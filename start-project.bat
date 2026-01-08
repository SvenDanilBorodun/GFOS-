@echo off
setlocal EnableDelayedExpansion

:: ============================================
:: GFOS Digital Idea Board - Startup Script
:: ============================================

:: Configuration - ADJUST THESE PATHS FOR YOUR SYSTEM
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot"
set "MAVEN_HOME=C:\apache-maven-3.9.12"
set "GLASSFISH_HOME=C:\glassfish-7.1.0\glassfish7"
set "POSTGRES_BIN=C:\Program Files\PostgreSQL\18\bin"

:: Database Configuration
set "DB_NAME=ideaboard"
set "DB_USER=ideaboard_user"
set "DB_PASSWORD=ideaboard123"
set "DB_HOST=localhost"
set "DB_PORT=5432"
set "PG_ADMIN_USER=postgres"
set "PG_ADMIN_PASSWORD=17918270"

:: Project Paths
set "PROJECT_ROOT=C:\GGFF\GFOS-"
set "BACKEND_PATH=%PROJECT_ROOT%\backend"
set "FRONTEND_PATH=%PROJECT_ROOT%\frontend"
set "DATABASE_PATH=%PROJECT_ROOT%\database"

:: Ports
set "GLASSFISH_PORT=8080"
set "FRONTEND_PORT=3000"

:: Colors
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "CYAN=[96m"
set "WHITE=[97m"
set "RESET=[0m"

:: Parse arguments
set "SKIP_CHECKS=0"
set "SKIP_BUILD=0"
set "FRONTEND_ONLY=0"
set "BACKEND_ONLY=0"

:parse_args
if "%~1"=="" goto :start
if /I "%~1"=="--skip-checks" set "SKIP_CHECKS=1"
if /I "%~1"=="-s" set "SKIP_CHECKS=1"
if /I "%~1"=="--skip-build" set "SKIP_BUILD=1"
if /I "%~1"=="-b" set "SKIP_BUILD=1"
if /I "%~1"=="--frontend" set "FRONTEND_ONLY=1"
if /I "%~1"=="-f" set "FRONTEND_ONLY=1"
if /I "%~1"=="--backend" set "BACKEND_ONLY=1"
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
shift
goto :parse_args

:start
cls
echo.
echo %CYAN%  ____  _____ ___  ____    ___    _            ____                      _ %RESET%
echo %CYAN% / ___|  ___/ _ \/ ___|  ^|_ _^|__^| ^| ___  __ _^| __ ^)  ___   __ _ _ __ __^| ^|%RESET%
echo %CYAN%^| ^|  _^| ^|_ ^| ^| ^| \___ \   ^| ^|/ _` ^|/ _ \/ _` ^|  _ \ / _ \ / _` ^| '__/ _` ^|%RESET%
echo %CYAN%^| ^|_^| ^|  _^|^| ^|_^| ^|___^) ^|  ^| ^| ^(_^| ^|  __/ ^(_^| ^| ^|_^) ^| ^(_^) ^| ^(_^| ^| ^| ^| ^(_^| ^|%RESET%
echo %CYAN% \____^|_^|   \___/____/  ^|___\__,_^|\___^|\__,_^|____/ \___/ \__,_^|_^|  \__,_^|%RESET%
echo.
echo                     %WHITE%Digital Innovation Platform%RESET%
echo.

if "%FRONTEND_ONLY%"=="1" goto :frontend_only
if "%BACKEND_ONLY%"=="1" goto :backend_only

:: Full startup
if "%SKIP_CHECKS%"=="0" call :check_all_dependencies
if %ERRORLEVEL% neq 0 (
    echo.
    echo %RED%[ERROR] Missing dependencies. Please install them and try again.%RESET%
    echo %YELLOW%Run with --skip-checks to bypass verification.%RESET%
    pause
    exit /b 1
)

call :setup_database
if %ERRORLEVEL% neq 0 goto :error_exit

call :start_glassfish
if %ERRORLEVEL% neq 0 goto :error_exit

call :setup_jdbc
if %ERRORLEVEL% neq 0 goto :error_exit

if "%SKIP_BUILD%"=="0" (
    call :build_backend
    if %ERRORLEVEL% neq 0 goto :error_exit
)

call :deploy_backend
if %ERRORLEVEL% neq 0 goto :error_exit

call :start_frontend

goto :show_final_info

:backend_only
if "%SKIP_CHECKS%"=="0" call :check_all_dependencies
call :setup_database
call :start_glassfish
call :setup_jdbc
if "%SKIP_BUILD%"=="0" call :build_backend
call :deploy_backend
echo.
echo %GREEN%========================================%RESET%
echo %GREEN% Backend Ready!%RESET%
echo %GREEN%========================================%RESET%
echo.
echo %GREEN%[OK]%RESET% Backend API: http://localhost:%GLASSFISH_PORT%/ideaboard/api
goto :eof

:frontend_only
call :start_frontend
goto :eof

:: ============================================
:: DEPENDENCY CHECKS
:: ============================================

:check_all_dependencies
echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Checking Dependencies%RESET%
echo %CYAN%========================================%RESET%

set "ALL_OK=1"

:: Check Java
echo %WHITE%[INFO]%RESET% Checking Java installation...
if exist "%JAVA_HOME%\bin\java.exe" (
    "%JAVA_HOME%\bin\java.exe" -version 2>&1 | findstr /C:"17" >nul
    if !ERRORLEVEL! equ 0 (
        echo %GREEN%[OK]%RESET% Java 17 found at: %JAVA_HOME%
    ) else (
        echo %RED%[ERROR]%RESET% Java found but not version 17
        set "ALL_OK=0"
    )
) else (
    echo %RED%[ERROR]%RESET% Java 17 NOT FOUND!
    echo.
    echo %YELLOW%    Please install Java 17 ^(JDK^):%RESET%
    echo     1. Download Eclipse Temurin JDK 17 from: https://adoptium.net/
    echo     2. Run the installer
    echo     3. Update JAVA_HOME in this script
    echo.
    set "ALL_OK=0"
)

:: Check Maven
echo %WHITE%[INFO]%RESET% Checking Maven installation...
if exist "%MAVEN_HOME%\bin\mvn.cmd" (
    echo %GREEN%[OK]%RESET% Maven found at: %MAVEN_HOME%
) else (
    where mvn >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo %GREEN%[OK]%RESET% Maven found in PATH
    ) else (
        echo %RED%[ERROR]%RESET% Maven NOT FOUND!
        echo.
        echo %YELLOW%    Please install Apache Maven 3.8+:%RESET%
        echo     1. Download from: https://maven.apache.org/download.cgi
        echo     2. Extract to C:\apache-maven-3.9.x
        echo     3. Update MAVEN_HOME in this script
        echo.
        set "ALL_OK=0"
    )
)

:: Check Node.js
echo %WHITE%[INFO]%RESET% Checking Node.js installation...
where node >nul 2>&1
if %ERRORLEVEL% equ 0 (
    for /f "tokens=*" %%i in ('node -v') do set "NODE_VER=%%i"
    echo %GREEN%[OK]%RESET% Node.js !NODE_VER! found
) else (
    echo %RED%[ERROR]%RESET% Node.js NOT FOUND!
    echo.
    echo %YELLOW%    Please install Node.js 18+:%RESET%
    echo     1. Download from: https://nodejs.org/
    echo     2. Run the installer ^(LTS version recommended^)
    echo     3. Restart this terminal
    echo.
    set "ALL_OK=0"
)

:: Check PostgreSQL
echo %WHITE%[INFO]%RESET% Checking PostgreSQL installation...
if exist "%POSTGRES_BIN%\psql.exe" (
    echo %GREEN%[OK]%RESET% PostgreSQL found at: %POSTGRES_BIN%
) else (
    where psql >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo %GREEN%[OK]%RESET% PostgreSQL found in PATH
    ) else (
        echo %RED%[ERROR]%RESET% PostgreSQL NOT FOUND!
        echo.
        echo %YELLOW%    Please install PostgreSQL 15+:%RESET%
        echo     1. Download from: https://www.postgresql.org/download/windows/
        echo     2. Run the installer
        echo     3. Update POSTGRES_BIN in this script
        echo.
        set "ALL_OK=0"
    )
)

:: Check GlassFish
echo %WHITE%[INFO]%RESET% Checking GlassFish installation...
if exist "%GLASSFISH_HOME%\bin\asadmin.bat" (
    echo %GREEN%[OK]%RESET% GlassFish found at: %GLASSFISH_HOME%
) else (
    echo %RED%[ERROR]%RESET% GlassFish 7 NOT FOUND!
    echo.
    echo %YELLOW%    Please install GlassFish 7:%RESET%
    echo     1. Download from: https://glassfish.org/download
    echo     2. Extract to C:\glassfish-7.1.0
    echo     3. Update GLASSFISH_HOME in this script
    echo.
    set "ALL_OK=0"
)

if "%ALL_OK%"=="1" (
    echo.
    echo %GREEN%[OK]%RESET% All dependencies are installed!
    exit /b 0
) else (
    exit /b 1
)

:: ============================================
:: DATABASE SETUP
:: ============================================

:setup_database
echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Setting Up Database%RESET%
echo %CYAN%========================================%RESET%

set "PGPASSWORD=%PG_ADMIN_PASSWORD%"

:: Check if PostgreSQL is running
echo %WHITE%[INFO]%RESET% Checking if PostgreSQL is running...
"%POSTGRES_BIN%\psql.exe" -U %PG_ADMIN_USER% -h %DB_HOST% -p %DB_PORT% -c "SELECT 1" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %RED%[ERROR]%RESET% PostgreSQL is not running or credentials are incorrect!
    echo %YELLOW%Please start PostgreSQL service and check credentials.%RESET%
    exit /b 1
)
echo %GREEN%[OK]%RESET% PostgreSQL is running

:: Check if database exists
echo %WHITE%[INFO]%RESET% Checking if database '%DB_NAME%' exists...
for /f "tokens=*" %%i in ('"%POSTGRES_BIN%\psql.exe" -U %PG_ADMIN_USER% -h %DB_HOST% -p %DB_PORT% -t -c "SELECT 1 FROM pg_database WHERE datname='%DB_NAME%'" 2^>nul') do set "DB_EXISTS=%%i"

if "!DB_EXISTS!"=="         1" (
    echo %GREEN%[OK]%RESET% Database '%DB_NAME%' exists
) else (
    echo %WHITE%[INFO]%RESET% Creating database '%DB_NAME%'...

    :: Create user
    "%POSTGRES_BIN%\psql.exe" -U %PG_ADMIN_USER% -h %DB_HOST% -p %DB_PORT% -c "DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '%DB_USER%') THEN CREATE USER %DB_USER% WITH ENCRYPTED PASSWORD '%DB_PASSWORD%'; END IF; END $$;" >nul 2>&1

    :: Create database
    "%POSTGRES_BIN%\psql.exe" -U %PG_ADMIN_USER% -h %DB_HOST% -p %DB_PORT% -c "CREATE DATABASE %DB_NAME% OWNER %DB_USER%;" >nul 2>&1

    if !ERRORLEVEL! equ 0 (
        echo %GREEN%[OK]%RESET% Database created successfully

        :: Grant privileges
        "%POSTGRES_BIN%\psql.exe" -U %PG_ADMIN_USER% -h %DB_HOST% -p %DB_PORT% -c "GRANT ALL PRIVILEGES ON DATABASE %DB_NAME% TO %DB_USER%;" >nul 2>&1

        :: Initialize with seed data
        if exist "%DATABASE_PATH%\init.sql" (
            echo %WHITE%[INFO]%RESET% Running database initialization script...
            set "PGPASSWORD=%DB_PASSWORD%"
            "%POSTGRES_BIN%\psql.exe" -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -f "%DATABASE_PATH%\init.sql" >nul 2>&1
            echo %GREEN%[OK]%RESET% Database initialized with seed data
        )
    ) else (
        echo %RED%[ERROR]%RESET% Failed to create database
        exit /b 1
    )
)

exit /b 0

:: ============================================
:: GLASSFISH
:: ============================================

:start_glassfish
echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Starting GlassFish Server%RESET%
echo %CYAN%========================================%RESET%

:: Check if already running
netstat -an | findstr ":%GLASSFISH_PORT% " | findstr "LISTENING" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo %GREEN%[OK]%RESET% GlassFish is already running on port %GLASSFISH_PORT%
    exit /b 0
)

echo %WHITE%[INFO]%RESET% Starting GlassFish domain...
"%GLASSFISH_HOME%\bin\asadmin.bat" start-domain >nul 2>&1

:: Wait for startup
set "ATTEMPTS=0"
:wait_glassfish
if %ATTEMPTS% geq 30 goto :glassfish_timeout
netstat -an | findstr ":%GLASSFISH_PORT% " | findstr "LISTENING" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    timeout /t 2 /nobreak >nul
    set /a ATTEMPTS+=1
    echo | set /p=.
    goto :wait_glassfish
)
echo.
echo %GREEN%[OK]%RESET% GlassFish started successfully on port %GLASSFISH_PORT%
exit /b 0

:glassfish_timeout
echo.
echo %RED%[ERROR]%RESET% GlassFish failed to start within timeout
exit /b 1

:setup_jdbc
echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Configuring JDBC Connection Pool%RESET%
echo %CYAN%========================================%RESET%

:: Check if pool exists
echo %WHITE%[INFO]%RESET% Checking JDBC connection pool...
"%GLASSFISH_HOME%\bin\asadmin.bat" list-jdbc-connection-pools 2>nul | findstr "IdeaBoardPool" >nul
if %ERRORLEVEL% equ 0 (
    echo %GREEN%[OK]%RESET% JDBC pool 'IdeaBoardPool' already exists
) else (
    echo %WHITE%[INFO]%RESET% Creating JDBC connection pool...
    "%GLASSFISH_HOME%\bin\asadmin.bat" create-jdbc-connection-pool --restype javax.sql.DataSource --datasourceclassname org.postgresql.ds.PGSimpleDataSource --property user=%DB_USER%:password=%DB_PASSWORD%:serverName=%DB_HOST%:portNumber=%DB_PORT%:databaseName=%DB_NAME% IdeaBoardPool >nul 2>&1
    echo %GREEN%[OK]%RESET% JDBC pool created
)

:: Check if resource exists
echo %WHITE%[INFO]%RESET% Checking JDBC resource...
"%GLASSFISH_HOME%\bin\asadmin.bat" list-jdbc-resources 2>nul | findstr "jdbc/ideaboard" >nul
if %ERRORLEVEL% equ 0 (
    echo %GREEN%[OK]%RESET% JDBC resource 'jdbc/ideaboard' already exists
) else (
    echo %WHITE%[INFO]%RESET% Creating JDBC resource...
    "%GLASSFISH_HOME%\bin\asadmin.bat" create-jdbc-resource --connectionpoolid IdeaBoardPool jdbc/ideaboard >nul 2>&1
    echo %GREEN%[OK]%RESET% JDBC resource created
)

:: Test connection
echo %WHITE%[INFO]%RESET% Testing database connection...
"%GLASSFISH_HOME%\bin\asadmin.bat" ping-connection-pool IdeaBoardPool 2>&1 | findstr "successfully" >nul
if %ERRORLEVEL% equ 0 (
    echo %GREEN%[OK]%RESET% Database connection test passed
) else (
    echo %YELLOW%[WARNING]%RESET% Database connection test failed - check configuration
)

exit /b 0

:: ============================================
:: BUILD AND DEPLOY
:: ============================================

:build_backend
echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Building Backend%RESET%
echo %CYAN%========================================%RESET%

if exist "%MAVEN_HOME%\bin\mvn.cmd" (
    set "MVN=%MAVEN_HOME%\bin\mvn.cmd"
) else (
    set "MVN=mvn"
)

echo %WHITE%[INFO]%RESET% Building WAR file with Maven...
pushd "%BACKEND_PATH%"
"%MVN%" clean package -DskipTests -q
set "BUILD_RESULT=%ERRORLEVEL%"
popd

if %BUILD_RESULT% equ 0 (
    if exist "%BACKEND_PATH%\target\ideaboard.war" (
        echo %GREEN%[OK]%RESET% Backend built successfully: target\ideaboard.war
        exit /b 0
    )
)
echo %RED%[ERROR]%RESET% Backend build failed!
exit /b 1

:deploy_backend
echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Deploying Backend to GlassFish%RESET%
echo %CYAN%========================================%RESET%

if not exist "%BACKEND_PATH%\target\ideaboard.war" (
    echo %RED%[ERROR]%RESET% WAR file not found!
    exit /b 1
)

echo %WHITE%[INFO]%RESET% Deploying application...
"%GLASSFISH_HOME%\bin\asadmin.bat" redeploy --force --name ideaboard "%BACKEND_PATH%\target\ideaboard.war" >nul 2>&1

echo %GREEN%[OK]%RESET% Backend deployed!
echo %WHITE%[INFO]%RESET% API available at: http://localhost:%GLASSFISH_PORT%/ideaboard/api
exit /b 0

:: ============================================
:: FRONTEND
:: ============================================

:start_frontend
echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Starting Frontend Dev Server%RESET%
echo %CYAN%========================================%RESET%

:: Check/install dependencies
if not exist "%FRONTEND_PATH%\node_modules" (
    echo %WHITE%[INFO]%RESET% Installing npm dependencies...
    pushd "%FRONTEND_PATH%"
    npm install >nul 2>&1
    popd
    echo %GREEN%[OK]%RESET% Dependencies installed
) else (
    echo %GREEN%[OK]%RESET% Frontend dependencies already installed
)

echo %WHITE%[INFO]%RESET% Starting Vite dev server on port %FRONTEND_PORT%...
start "GFOS Frontend" cmd /k "cd /d %FRONTEND_PATH% && npm run dev"

timeout /t 3 /nobreak >nul
echo %GREEN%[OK]%RESET% Frontend starting in new window...
echo %WHITE%[INFO]%RESET% Frontend will be available at: http://localhost:%FRONTEND_PORT%

exit /b 0

:: ============================================
:: FINAL INFO
:: ============================================

:show_final_info
echo.
echo %GREEN%========================================%RESET%
echo %GREEN% All Services Started!%RESET%
echo %GREEN%========================================%RESET%
echo.
echo   %WHITE%Application URLs:%RESET%
echo   -----------------
echo   %GREEN%[OK]%RESET% Frontend:    http://localhost:%FRONTEND_PORT%
echo   %GREEN%[OK]%RESET% Backend API: http://localhost:%GLASSFISH_PORT%/ideaboard/api
echo   %GREEN%[OK]%RESET% GlassFish:   http://localhost:4848 (Admin Console)
echo.
echo   %WHITE%Default Login Credentials:%RESET%
echo   --------------------------
echo   %CYAN%Admin:    admin / admin123%RESET%
echo   %CYAN%Employee: john.doe / password123%RESET%
echo   %CYAN%Manager:  jane.smith / password123%RESET%
echo.
echo %WHITE%[INFO]%RESET% Press Ctrl+C to stop the frontend server
echo.
pause
goto :eof

:error_exit
echo.
echo %RED%[ERROR] Startup failed. Check the errors above.%RESET%
pause
exit /b 1

:show_help
echo.
echo GFOS Digital Idea Board - Startup Script
echo =========================================
echo.
echo Usage: start-project.bat [options]
echo.
echo Options:
echo   --skip-checks, -s    Skip dependency checks (faster startup)
echo   --skip-build, -b     Skip Maven build (use existing WAR)
echo   --frontend, -f       Start only the frontend dev server
echo   --backend            Start only PostgreSQL and GlassFish
echo   --help, -h           Show this help message
echo.
echo Requirements:
echo   - Java 17 (JDK)
echo   - Apache Maven 3.8+
echo   - Node.js 18+ with npm
echo   - PostgreSQL 15+
echo   - GlassFish 7
echo.
echo Configuration:
echo   Edit the configuration section at the top of this script
echo   to match your installation paths.
echo.
echo Examples:
echo   start-project.bat                  Full startup with all checks
echo   start-project.bat --skip-checks    Skip dependency verification
echo   start-project.bat --frontend       Start only frontend
echo.
pause
goto :eof
