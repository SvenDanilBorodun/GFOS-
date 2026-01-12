# GFOS Digital Ideen-Board - Vollständiges Startskript
# Dieses Skript überprüft alle Abhängigkeiten und startet den gesamten Projekt-Stack

param(
    [switch]$SkipChecks,
    [switch]$SkipBuild,
    [switch]$FrontendOnly,
    [switch]$BackendOnly,
    [switch]$Help
)

# Konfiguration - PASSEN SIE DIESE PFADE FÜR IHR SYSTEM AN
$CONFIG = @{
    # Pfade (ändern Sie diese für Ihre Installation)
    JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot"
    MAVEN_HOME = "C:\apache-maven-3.9.12"
    GLASSFISH_HOME = "C:\glassfish-7.1.0\glassfish7"
    POSTGRES_BIN = "C:\Program Files\PostgreSQL\18\bin"
    NODE_PATH = $null  # Wird automatisch erkannt, wenn null

    # Datenbankkonfiguration
    DB_NAME = "ideaboard"
    DB_USER = "ideaboard_user"
    DB_PASSWORD = "ideaboard123"
    DB_HOST = "localhost"
    DB_PORT = "5432"
    POSTGRES_ADMIN_USER = "postgres"
    POSTGRES_ADMIN_PASSWORD = "17918270"  # Ändern Sie dies!

    # Projektpfade
    PROJECT_ROOT = "C:\GGFF\GFOS-"
    BACKEND_PATH = "C:\GGFF\GFOS-\backend"
    FRONTEND_PATH = "C:\GGFF\GFOS-\frontend"
    DATABASE_PATH = "C:\GGFF\GFOS-\database"

    # Server Ports
    GLASSFISH_PORT = 8080
    FRONTEND_PORT = 3000
}

# Colors for output
function Write-ColorOutput($ForegroundColor) {
    $fc = $host.UI.RawUI.ForegroundColor
    $host.UI.RawUI.ForegroundColor = $ForegroundColor
    if ($args) {
        Write-Output $args
    }
    $host.UI.RawUI.ForegroundColor = $fc
}

function Write-Header($text) {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host " $text" -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
}

function Write-Success($text) {
    Write-Host "[OK] $text" -ForegroundColor Green
}

function Write-Error($text) {
    Write-Host "[ERROR] $text" -ForegroundColor Red
}

function Write-Warning($text) {
    Write-Host "[WARNING] $text" -ForegroundColor Yellow
}

function Write-Info($text) {
    Write-Host "[INFO] $text" -ForegroundColor White
}

function Show-Help {
    Write-Host @"

GFOS Digital Ideen-Board - Startskript
=========================================

Verwendung: .\start-project.ps1 [Optionen]

Optionen:
  -SkipChecks     Überspringe Abhängigkeitsprüfungen (schnellerer Start)
  -SkipBuild      Überspringe Maven Build (verwende bestehendes WAR)
  -FrontendOnly   Starten Sie nur den Frontend Dev Server
  -BackendOnly    Starten Sie nur PostgreSQL und GlassFish
  -Help           Diese Hilfemeldung anzeigen

Anforderungen:
  - Java 17 (JDK)
  - Apache Maven 3.8+
  - Node.js 18+ mit npm
  - PostgreSQL 15+
  - GlassFish 7

Konfiguration:
  Bearbeiten Sie den `$CONFIG` Abschnitt oben in diesem Skript um Ihre Installationspfade zu matchen.

Beispiele:
  .\start-project.ps1                    # Vollständiger Start mit allen Überprüfungen
  .\start-project.ps1 -SkipChecks        # Überspringe Abhängigkeitsverifikation
  .\start-project.ps1 -FrontendOnly      # Starten Sie nur Frontend

"@
}

# Check if a command exists
function Test-CommandExists($command) {
    $oldPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Stop'
    try {
        if (Get-Command $command) { return $true }
    }
    catch { return $false }
    finally { $ErrorActionPreference = $oldPreference }
}

# Check if a TCP port is in use
function Test-PortInUse($port) {
    $connection = Get-NetTCPConnection -LocalPort $port -ErrorAction SilentlyContinue
    return $null -ne $connection
}

# ============================================
# DEPENDENCY CHECKS
# ============================================

function Test-JavaInstallation {
    Write-Info "Überprüfe Java-Installation..."

    # Überprüfe konfigurierte JAVA_HOME
    if (Test-Path "$($CONFIG.JAVA_HOME)\bin\java.exe") {
        $javaVersion = & "$($CONFIG.JAVA_HOME)\bin\java.exe" -version 2>&1 | Select-Object -First 1
        if ($javaVersion -match "17") {
            Write-Success "Java 17 gefunden unter: $($CONFIG.JAVA_HOME)"
            $env:JAVA_HOME = $CONFIG.JAVA_HOME
            return $true
        }
    }

    # Versuche System Java
    if (Test-CommandExists "java") {
        $javaVersion = & java -version 2>&1 | Select-Object -First 1
        if ($javaVersion -match "17") {
            Write-Success "Java 17 in PATH gefunden"
            return $true
        }
        Write-Warning "Java gefunden, aber nicht Version 17: $javaVersion"
    }

    Write-Error "Java 17 NICHT GEFUNDEN!"
    Write-Host @"

    Bitte installieren Sie Java 17 (JDK):
    1. Laden Sie Eclipse Temurin JDK 17 herunter: https://adoptium.net/
    2. Führen Sie das Installationsprogramm aus
    3. Aktualisieren Sie JAVA_HOME in diesem Skript um auf Ihre Installation zu zeigen

    Aktuell konfigurierter Pfad: $($CONFIG.JAVA_HOME)

"@ -ForegroundColor Yellow
    return $false
}

function Test-MavenInstallation {
    Write-Info "Checking Maven installation..."

    $mvnPath = "$($CONFIG.MAVEN_HOME)\bin\mvn.cmd"
    if (Test-Path $mvnPath) {
        $mvnVersion = & $mvnPath -version 2>&1 | Select-Object -First 1
        Write-Success "Maven found: $mvnVersion"
        return $true
    }

    # Try system Maven
    if (Test-CommandExists "mvn") {
        $mvnVersion = & mvn -version 2>&1 | Select-Object -First 1
        Write-Success "Maven found in PATH: $mvnVersion"
        return $true
    }

    Write-Error "Maven NOT FOUND!"
    Write-Host @"

    Please install Apache Maven 3.8+:
    1. Download from: https://maven.apache.org/download.cgi
    2. Extract to C:\apache-maven-3.9.x
    3. Update MAVEN_HOME in this script

    Current configured path: $($CONFIG.MAVEN_HOME)

"@ -ForegroundColor Yellow
    return $false
}

function Test-NodeInstallation {
    Write-Info "Checking Node.js installation..."

    if (Test-CommandExists "node") {
        $nodeVersion = & node -v 2>&1
        $npmVersion = & npm -v 2>&1

        # Check Node version >= 18
        $versionNumber = [int]($nodeVersion -replace 'v(\d+)\..*', '$1')
        if ($versionNumber -ge 18) {
            Write-Success "Node.js $nodeVersion found (npm $npmVersion)"
            return $true
        }
        Write-Warning "Node.js $nodeVersion found but version 18+ recommended"
        return $true
    }

    Write-Error "Node.js NOT FOUND!"
    Write-Host @"

    Please install Node.js 18+:
    1. Download from: https://nodejs.org/
    2. Run the installer (LTS version recommended)
    3. Restart this terminal after installation

"@ -ForegroundColor Yellow
    return $false
}

function Test-PostgresInstallation {
    Write-Info "Checking PostgreSQL installation..."

    $psqlPath = "$($CONFIG.POSTGRES_BIN)\psql.exe"
    if (Test-Path $psqlPath) {
        Write-Success "PostgreSQL found at: $($CONFIG.POSTGRES_BIN)"
        return $true
    }

    # Try system psql
    if (Test-CommandExists "psql") {
        Write-Success "PostgreSQL found in PATH"
        return $true
    }

    Write-Error "PostgreSQL NOT FOUND!"
    Write-Host @"

    Please install PostgreSQL 15+:
    1. Download from: https://www.postgresql.org/download/windows/
    2. Run the installer
    3. Remember the password you set for 'postgres' user
    4. Update POSTGRES_BIN and POSTGRES_ADMIN_PASSWORD in this script

    Current configured path: $($CONFIG.POSTGRES_BIN)

"@ -ForegroundColor Yellow
    return $false
}

function Test-GlassFishInstallation {
    Write-Info "Checking GlassFish installation..."

    $asadminPath = "$($CONFIG.GLASSFISH_HOME)\bin\asadmin.bat"
    if (Test-Path $asadminPath) {
        Write-Success "GlassFish found at: $($CONFIG.GLASSFISH_HOME)"
        return $true
    }

    Write-Error "GlassFish 7 NOT FOUND!"
    Write-Host @"

    Please install GlassFish 7:
    1. Download from: https://glassfish.org/download
    2. Extract to C:\glassfish-7.1.0
    3. Update GLASSFISH_HOME in this script

    Current configured path: $($CONFIG.GLASSFISH_HOME)

"@ -ForegroundColor Yellow
    return $false
}

function Test-AllDependencies {
    Write-Header "Checking Dependencies"

    $allPassed = $true

    if (-not (Test-JavaInstallation)) { $allPassed = $false }
    if (-not (Test-MavenInstallation)) { $allPassed = $false }
    if (-not (Test-NodeInstallation)) { $allPassed = $false }
    if (-not (Test-PostgresInstallation)) { $allPassed = $false }
    if (-not (Test-GlassFishInstallation)) { $allPassed = $false }

    if ($allPassed) {
        Write-Host ""
        Write-Success "All dependencies are installed!"
    }
    else {
        Write-Host ""
        Write-Error "Some dependencies are missing. Please install them and try again."
    }

    return $allPassed
}

# ============================================
# DATABASE SETUP
# ============================================

function Initialize-Database {
    Write-Header "Setting Up Database"

    $psqlPath = "$($CONFIG.POSTGRES_BIN)\psql.exe"
    $env:PGPASSWORD = $CONFIG.POSTGRES_ADMIN_PASSWORD

    # Check if PostgreSQL service is running
    Write-Info "Checking if PostgreSQL is running..."
    try {
        $result = & $psqlPath -U $CONFIG.POSTGRES_ADMIN_USER -h $CONFIG.DB_HOST -p $CONFIG.DB_PORT -c "SELECT 1" 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Error "PostgreSQL is not running or credentials are incorrect!"
            Write-Host "Please start PostgreSQL service and check credentials." -ForegroundColor Yellow
            return $false
        }
        Write-Success "PostgreSQL is running"
    }
    catch {
        Write-Error "Cannot connect to PostgreSQL: $_"
        return $false
    }

    # Check if database exists
    Write-Info "Checking if database '$($CONFIG.DB_NAME)' exists..."
    $dbExists = & $psqlPath -U $CONFIG.POSTGRES_ADMIN_USER -h $CONFIG.DB_HOST -p $CONFIG.DB_PORT -t -c "SELECT 1 FROM pg_database WHERE datname='$($CONFIG.DB_NAME)'" 2>&1

    if ($dbExists -match "1") {
        Write-Success "Database '$($CONFIG.DB_NAME)' exists"
    }
    else {
        Write-Info "Creating database '$($CONFIG.DB_NAME)'..."

        # Create user if not exists
        & $psqlPath -U $CONFIG.POSTGRES_ADMIN_USER -h $CONFIG.DB_HOST -p $CONFIG.DB_PORT -c "DO `$`$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$($CONFIG.DB_USER)') THEN CREATE USER $($CONFIG.DB_USER) WITH ENCRYPTED PASSWORD '$($CONFIG.DB_PASSWORD)'; END IF; END `$`$;" 2>&1 | Out-Null

        # Create database
        & $psqlPath -U $CONFIG.POSTGRES_ADMIN_USER -h $CONFIG.DB_HOST -p $CONFIG.DB_PORT -c "CREATE DATABASE $($CONFIG.DB_NAME) OWNER $($CONFIG.DB_USER);" 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Success "Database created successfully"

            # Grant privileges
            & $psqlPath -U $CONFIG.POSTGRES_ADMIN_USER -h $CONFIG.DB_HOST -p $CONFIG.DB_PORT -c "GRANT ALL PRIVILEGES ON DATABASE $($CONFIG.DB_NAME) TO $($CONFIG.DB_USER);" 2>&1 | Out-Null

            # Initialize with seed data
            $initSqlPath = "$($CONFIG.DATABASE_PATH)\init.sql"
            if (Test-Path $initSqlPath) {
                Write-Info "Running database initialization script..."
                $env:PGPASSWORD = $CONFIG.DB_PASSWORD
                & $psqlPath -U $CONFIG.DB_USER -h $CONFIG.DB_HOST -p $CONFIG.DB_PORT -d $CONFIG.DB_NAME -f $initSqlPath 2>&1 | Out-Null
                Write-Success "Database initialized with seed data"
            }
        }
        else {
            Write-Error "Failed to create database"
            return $false
        }
    }

    return $true
}

# ============================================
# GLASSFISH SETUP
# ============================================

function Start-GlassFishServer {
    Write-Header "Starting GlassFish Server"

    $asadminPath = "$($CONFIG.GLASSFISH_HOME)\bin\asadmin.bat"
    $env:JAVA_HOME = $CONFIG.JAVA_HOME
    $env:AS_JAVA = $CONFIG.JAVA_HOME

    # Check if GlassFish is already running
    if (Test-PortInUse $CONFIG.GLASSFISH_PORT) {
        Write-Success "GlassFish is already running on port $($CONFIG.GLASSFISH_PORT)"
        return $true
    }

    Write-Info "Starting GlassFish domain..."
    $startResult = & cmd.exe /c "set JAVA_HOME=$($CONFIG.JAVA_HOME) && $asadminPath start-domain" 2>&1

    # Wait for startup
    $attempts = 0
    $maxAttempts = 30
    while (-not (Test-PortInUse $CONFIG.GLASSFISH_PORT) -and $attempts -lt $maxAttempts) {
        Start-Sleep -Seconds 2
        $attempts++
        Write-Host "." -NoNewline
    }
    Write-Host ""

    if (Test-PortInUse $CONFIG.GLASSFISH_PORT) {
        Write-Success "GlassFish started successfully on port $($CONFIG.GLASSFISH_PORT)"
        return $true
    }
    else {
        Write-Error "GlassFish failed to start within timeout"
        Write-Host $startResult -ForegroundColor Yellow
        return $false
    }
}

function Initialize-JdbcPool {
    Write-Header "Configuring JDBC Connection Pool"

    $asadminPath = "$($CONFIG.GLASSFISH_HOME)\bin\asadmin.bat"
    $env:JAVA_HOME = $CONFIG.JAVA_HOME

    # Check if pool exists
    Write-Info "Checking JDBC connection pool..."
    $poolList = & cmd.exe /c "set JAVA_HOME=$($CONFIG.JAVA_HOME) && $asadminPath list-jdbc-connection-pools" 2>&1

    if ($poolList -match "IdeaBoardPool") {
        Write-Success "JDBC pool 'IdeaBoardPool' already exists"
    }
    else {
        Write-Info "Creating JDBC connection pool..."
        $poolCmd = "set JAVA_HOME=$($CONFIG.JAVA_HOME) && $asadminPath create-jdbc-connection-pool --restype javax.sql.DataSource --datasourceclassname org.postgresql.ds.PGSimpleDataSource --property user=$($CONFIG.DB_USER):password=$($CONFIG.DB_PASSWORD):serverName=$($CONFIG.DB_HOST):portNumber=$($CONFIG.DB_PORT):databaseName=$($CONFIG.DB_NAME) IdeaBoardPool"
        & cmd.exe /c $poolCmd 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Success "JDBC pool created"
        }
        else {
            Write-Warning "Could not create JDBC pool (may already exist)"
        }
    }

    # Check if JDBC resource exists
    Write-Info "Checking JDBC resource..."
    $resourceList = & cmd.exe /c "set JAVA_HOME=$($CONFIG.JAVA_HOME) && $asadminPath list-jdbc-resources" 2>&1

    if ($resourceList -match "jdbc/ideaboard") {
        Write-Success "JDBC resource 'jdbc/ideaboard' already exists"
    }
    else {
        Write-Info "Creating JDBC resource..."
        & cmd.exe /c "set JAVA_HOME=$($CONFIG.JAVA_HOME) && $asadminPath create-jdbc-resource --connectionpoolid IdeaBoardPool jdbc/ideaboard" 2>&1 | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Success "JDBC resource created"
        }
        else {
            Write-Warning "Could not create JDBC resource (may already exist)"
        }
    }

    # Test connection
    Write-Info "Testing database connection..."
    $pingResult = & cmd.exe /c "set JAVA_HOME=$($CONFIG.JAVA_HOME) && $asadminPath ping-connection-pool IdeaBoardPool" 2>&1

    if ($pingResult -match "successfully") {
        Write-Success "Database connection test passed"
        return $true
    }
    else {
        Write-Warning "Database connection test failed - check configuration"
        Write-Host $pingResult -ForegroundColor Yellow
        return $true  # Continue anyway, might work after deployment
    }
}

# ============================================
# BUILD AND DEPLOY
# ============================================

function Build-Backend {
    Write-Header "Building Backend"

    $mvnPath = "$($CONFIG.MAVEN_HOME)\bin\mvn.cmd"
    if (-not (Test-Path $mvnPath)) {
        $mvnPath = "mvn"  # Try system Maven
    }

    $env:JAVA_HOME = $CONFIG.JAVA_HOME

    Write-Info "Building WAR file with Maven..."
    Push-Location $CONFIG.BACKEND_PATH

    $buildResult = & $mvnPath clean package -DskipTests -q 2>&1
    $buildExitCode = $LASTEXITCODE

    Pop-Location

    if ($buildExitCode -eq 0 -and (Test-Path "$($CONFIG.BACKEND_PATH)\target\ideaboard.war")) {
        Write-Success "Backend built successfully: target\ideaboard.war"
        return $true
    }
    else {
        Write-Error "Backend build failed!"
        Write-Host $buildResult -ForegroundColor Yellow
        return $false
    }
}

function Deploy-Backend {
    Write-Header "Deploying Backend to GlassFish"

    $asadminPath = "$($CONFIG.GLASSFISH_HOME)\bin\asadmin.bat"
    $warPath = "$($CONFIG.BACKEND_PATH)\target\ideaboard.war"
    $env:JAVA_HOME = $CONFIG.JAVA_HOME

    if (-not (Test-Path $warPath)) {
        Write-Error "WAR file not found: $warPath"
        return $false
    }

    Write-Info "Deploying application..."
    $deployResult = & cmd.exe /c "set JAVA_HOME=$($CONFIG.JAVA_HOME) && $asadminPath redeploy --force --name ideaboard `"$warPath`"" 2>&1

    if ($deployResult -match "deployed successfully" -or $deployResult -match "Command redeploy executed successfully") {
        Write-Success "Backend deployed successfully!"
        Write-Info "API available at: http://localhost:$($CONFIG.GLASSFISH_PORT)/ideaboard/api"
        return $true
    }
    else {
        Write-Warning "Deployment may have issues - check GlassFish logs"
        Write-Host $deployResult -ForegroundColor Yellow
        return $true  # Continue anyway
    }
}

# ============================================
# FRONTEND
# ============================================

function Install-FrontendDependencies {
    Write-Info "Checking frontend dependencies..."

    $nodeModulesPath = "$($CONFIG.FRONTEND_PATH)\node_modules"
    if (-not (Test-Path $nodeModulesPath)) {
        Write-Info "Installing npm dependencies..."
        Push-Location $CONFIG.FRONTEND_PATH
        & npm install 2>&1 | Out-Null
        Pop-Location

        if (Test-Path $nodeModulesPath) {
            Write-Success "Dependencies installed"
        }
        else {
            Write-Error "Failed to install dependencies"
            return $false
        }
    }
    else {
        Write-Success "Frontend dependencies already installed"
    }
    return $true
}

function Start-Frontend {
    Write-Header "Starting Frontend Dev Server"

    if (-not (Install-FrontendDependencies)) {
        return $false
    }

    Write-Info "Starting Vite dev server on port $($CONFIG.FRONTEND_PORT)..."

    Push-Location $CONFIG.FRONTEND_PATH

    # Start frontend in a new window
    Start-Process -FilePath "cmd.exe" -ArgumentList "/k npm run dev" -WorkingDirectory $CONFIG.FRONTEND_PATH

    Pop-Location

    # Wait a moment for the server to start
    Start-Sleep -Seconds 3

    Write-Success "Frontend starting in new window..."
    Write-Info "Frontend will be available at: http://localhost:$($CONFIG.FRONTEND_PORT)"

    return $true
}

# ============================================
# MAIN EXECUTION
# ============================================

function Start-Project {
    Write-Host ""
    Write-Host "  ____  _____ ___  ____    ___    _            ____                      _ " -ForegroundColor Magenta
    Write-Host " / ___|  ___/ _ \/ ___|  |_ _|__| | ___  __ _| __ )  ___   __ _ _ __ __| |" -ForegroundColor Magenta
    Write-Host "| |  _| |_ | | | \___ \   | |/ _`` |/ _ \/ _`` |  _ \ / _ \ / _`` | '__/ _`` |" -ForegroundColor Magenta
    Write-Host "| |_| |  _|| |_| |___) |  | | (_| |  __/ (_| | |_) | (_) | (_| | | | (_| |" -ForegroundColor Magenta
    Write-Host " \____|_|   \___/|____/  |___\__,_|\___|\__,_|____/ \___/ \__,_|_|  \__,_|" -ForegroundColor Magenta
    Write-Host ""
    Write-Host "                    Digitale Innovationsplattform" -ForegroundColor White
    Write-Host ""

    if ($Help) {
        Show-Help
        return
    }

    # Abhängigkeitsprüfungen
    if (-not $SkipChecks) {
        if (-not (Test-AllDependencies)) {
            Write-Host ""
            Write-Error "Bitte installieren Sie die fehlenden Abhängigkeiten und versuchen Sie es erneut."
            Write-Host "Führen Sie mit -SkipChecks aus, um die Abhängigkeitsverifikation zu überspringen." -ForegroundColor Yellow
            return
        }
    }
    else {
        Write-Info "Überspringe Abhängigkeitsprüfungen..."
    }

    # Backend only mode
    if ($BackendOnly) {
        if (-not (Initialize-Database)) { return }
        if (-not (Start-GlassFishServer)) { return }
        if (-not (Initialize-JdbcPool)) { return }
        if (-not $SkipBuild) {
            if (-not (Build-Backend)) { return }
        }
        if (-not (Deploy-Backend)) { return }

        Write-Header "Backend Ready!"
        Write-Host ""
        Write-Success "Backend API: http://localhost:$($CONFIG.GLASSFISH_PORT)/ideaboard/api"
        return
    }

    # Frontend only mode
    if ($FrontendOnly) {
        Start-Frontend
        return
    }

    # Full startup
    if (-not (Initialize-Database)) { return }
    if (-not (Start-GlassFishServer)) { return }
    if (-not (Initialize-JdbcPool)) { return }

    if (-not $SkipBuild) {
        if (-not (Build-Backend)) { return }
    }

    if (-not (Deploy-Backend)) { return }

    Start-Frontend

    Write-Header "Alle Services gestartet!"
    Write-Host ""
    Write-Host "  Anwendungs-URLs:" -ForegroundColor White
    Write-Host "  -----------------" -ForegroundColor White
    Write-Success "Frontend:    http://localhost:$($CONFIG.FRONTEND_PORT)"
    Write-Success "Backend API: http://localhost:$($CONFIG.GLASSFISH_PORT)/ideaboard/api"
    Write-Success "GlassFish:   http://localhost:4848 (Admin Konsole)"
    Write-Host ""
    Write-Host "  Standard Anmeldedaten:" -ForegroundColor White
    Write-Host "  --------------------------" -ForegroundColor White
    Write-Host "  Admin:    admin / admin123" -ForegroundColor Cyan
    Write-Host "  Employee: john.doe / password123" -ForegroundColor Cyan
    Write-Host "  Manager:  jane.smith / password123" -ForegroundColor Cyan
    Write-Host ""
    Write-Info "Drücken Sie Strg+C um den Frontend-Server zu stoppen"
    Write-Host ""
}

# Führen Sie das Skript aus
Start-Project
