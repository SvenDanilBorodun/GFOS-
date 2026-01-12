# GFOS Digital Ideen-Board - System Verifikationsskript
# Führen Sie dieses Skript aus, um zu überprüfen, dass alle Systeme funktionieren

param(
    [switch]$Quick,
    [switch]$Help
)

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

function Write-Info($text) {
    Write-Host "[INFO] $text" -ForegroundColor White
}

function Show-Help {
    Write-Host @"

GFOS Digital Ideen-Board - System Verifikation
==============================================

Dieses Skript überprüft, dass alle Komponenten korrekt funktionieren.

Verwendung: .\verify-system.ps1 [Optionen]

Optionen:
  -Quick    Führe nur schnelle Überprüfungen aus (überspringe vollständige Tests)
  -Help     Diese Hilfemeldung anzeigen

Was dieses Skript überprüft:
  ✓ PostgreSQL Datenbankverbindung
  ✓ Benutzer-Authentifizierung und Passwort-Hashes
  ✓ Datenbank-Schema und Seed-Datenintegrität
  ✓ GlassFish Server Status
  ✓ Backend API Erreichbarkeit
  ✓ Frontend Konnektivität
  ✓ Integrationstests

Beispiele:
  .\verify-system.ps1           # Vollständige Verifikation
  .\verify-system.ps1 -Quick    # Nur schnelle Überprüfungen

"@
}

if ($Help) {
    Show-Help
    exit 0
}

$CONFIG = @{
    JAVA_HOME = "C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot"
    MAVEN_HOME = "C:\apache-maven-3.9.12"
    BACKEND_PATH = "C:\GGFF\GFOS-\backend"
    GLASSFISH_PORT = 8080
    FRONTEND_PORT = 3000
    DB_PORT = 5432
}

$allPassed = $true

Write-Host ""
Write-Host "  ___      ___   ___  ___ ___ _____   _____ ___ ___ _____ " -ForegroundColor Magenta
Write-Host " / __|_  _/ __| | __| __| _ \___  \ |_   _| __/ __|_   _|" -ForegroundColor Magenta
Write-Host " \__ \ || \__ \ | _||  _|   / /  /    | | | _|\__ \ | |  " -ForegroundColor Magenta
Write-Host " |___/\_, |___/ |___|_| |_|_\ /_|     |_| |___|___/ |_|  " -ForegroundColor Magenta
Write-Host "      |__/                                                " -ForegroundColor Magenta
Write-Host ""
Write-Host "                System Verifikationswerkzeug" -ForegroundColor White
Write-Host ""

# Überprüfung 1: PostgreSQL
Write-Header "1. PostgreSQL Datenbank"
$psqlPath = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
$env:PGPASSWORD = "ideaboard123"

try {
    $result = & $psqlPath -U ideaboard_user -h localhost -p $CONFIG.DB_PORT -d ideaboard -c "SELECT COUNT(*) FROM users;" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Datenbankverbindung erfolgreich"
        $userCount = ($result | Select-String -Pattern "\d+" | Select-Object -First 1).Matches[0].Value
        Write-Info "Gefunden $userCount Benutzer in Datenbank"
    } else {
        Write-Error "Datenbankverbindung fehlgeschlagen"
        $allPassed = $false
    }
} catch {
    Write-Error "PostgreSQL Fehler: $_"
    $allPassed = $false
}

# Überprüfung 2: GlassFish Server
Write-Header "2. GlassFish Server"
$glassFishRunning = Get-NetTCPConnection -LocalPort $CONFIG.GLASSFISH_PORT -ErrorAction SilentlyContinue
if ($glassFishRunning) {
    Write-Success "GlassFish läuft auf Port $($CONFIG.GLASSFISH_PORT)"
} else {
    Write-Error "GlassFish läuft NICHT auf Port $($CONFIG.GLASSFISH_PORT)"
    $allPassed = $false
}

# Überprüfung 3: Backend API
Write-Header "3. Backend API"
try {
    # Teste mit Anmeldeversuchen, was ein öffentlicher Endpunkt ist
    $testBody = @{
        username = "admin"
        password = "admin123"
    } | ConvertTo-Json

    $response = Invoke-RestMethod -Uri "http://localhost:$($CONFIG.GLASSFISH_PORT)/ideaboard/api/auth/login" `
        -Method POST `
        -ContentType "application/json" `
        -Body $testBody `
        -TimeoutSec 5 `
        -ErrorAction Stop

    if ($response.token) {
        Write-Success "Backend API ist erreichbar und antwortet"
    } else {
        Write-Error "Backend API gab unerwartete Antwort zurück"
        $allPassed = $false
    }
} catch {
    Write-Error "Backend API ist nicht erreichbar: $_"
    $allPassed = $false
}

# Überprüfung 4: Frontend
Write-Header "4. Frontend Server"
$frontendRunning = Get-NetTCPConnection -LocalPort $CONFIG.FRONTEND_PORT -ErrorAction SilentlyContinue
if ($frontendRunning) {
    Write-Success "Frontend läuft auf Port $($CONFIG.FRONTEND_PORT)"
} else {
    Write-Error "Frontend läuft NICHT auf Port $($CONFIG.FRONTEND_PORT)"
    $allPassed = $false
}

# Check 5: Database Validation (unless -Quick)
if (-not $Quick) {
    Write-Header "5. Database Validation"
    Write-Info "Running database validation utility..."

    $env:JAVA_HOME = $CONFIG.JAVA_HOME
    Push-Location $CONFIG.BACKEND_PATH

    $validationResult = & "$($CONFIG.MAVEN_HOME)\bin\mvn.cmd" exec:java `
        -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase" `
        -Dexec.cleanupDaemonThreads=false -q 2>&1

    Pop-Location

    if ($validationResult -match "ALL VALIDATION CHECKS PASSED") {
        Write-Success "Database validation passed"
    } else {
        Write-Error "Database validation failed"
        Write-Host $validationResult -ForegroundColor Yellow
        $allPassed = $false
    }
}

# Check 6: Test User Logins
Write-Header "6. Test User Accounts"
Write-Info "Testing all default user accounts..."

$testUsers = @(
    @{username="admin"; password="admin123"; role="Admin"},
    @{username="jsmith"; password="password123"; role="Employee"},
    @{username="mwilson"; password="password123"; role="Project Manager"}
)

$loginsFailed = 0
foreach ($testUser in $testUsers) {
    try {
        $body = @{
            username = $testUser.username
            password = $testUser.password
        } | ConvertTo-Json

        $loginResponse = Invoke-RestMethod -Uri "http://localhost:$($CONFIG.GLASSFISH_PORT)/ideaboard/api/auth/login" `
            -Method POST `
            -ContentType "application/json" `
            -Body $body `
            -ErrorAction Stop

        if ($loginResponse.token) {
            Write-Success "$($testUser.username) ($($testUser.role)) - login successful"
        } else {
            Write-Error "$($testUser.username) - login failed (no token)"
            $loginsFailed++
        }
    } catch {
        Write-Error "$($testUser.username) - login failed: $_"
        $loginsFailed++
    }
}

if ($loginsFailed -gt 0) {
    $allPassed = $false
}

# Check 7: Integration Tests (unless -Quick)
if (-not $Quick) {
    Write-Header "7. Integration Tests"
    Write-Info "Running integration tests..."

    $env:JAVA_HOME = $CONFIG.JAVA_HOME
    Push-Location $CONFIG.BACKEND_PATH

    $testResult = & "$($CONFIG.MAVEN_HOME)\bin\mvn.cmd" test `
        -Dtest=AuthenticationIntegrationTest -q 2>&1

    Pop-Location

    if ($testResult -match "BUILD SUCCESS") {
        Write-Success "All integration tests passed"
    } else {
        Write-Error "Integration tests failed"
        Write-Host $testResult -ForegroundColor Yellow
        $allPassed = $false
    }
}

# Zusammenfassung
Write-Header "VERIFIKATIONS-ZUSAMMENFASSUNG"

if ($allPassed) {
    Write-Host ""
    Write-Success "ALLE ÜBERPRÜFUNGEN BESTANDEN!"
    Write-Host ""
    Write-Host "  Ihr System ist einsatzbereit:" -ForegroundColor White
    Write-Host "  - Frontend:    http://localhost:$($CONFIG.FRONTEND_PORT)" -ForegroundColor Cyan
    Write-Host "  - Backend API: http://localhost:$($CONFIG.GLASSFISH_PORT)/ideaboard/api" -ForegroundColor Cyan
    Write-Host "  - Admin-Anmeldung: admin / admin123" -ForegroundColor Cyan
    Write-Host ""
    exit 0
} else {
    Write-Host ""
    Write-Error "EINIGE ÜBERPRÜFUNGEN FEHLGESCHLAGEN!"
    Write-Host ""
    Write-Host "  Bitte überprüfen Sie die obigen Fehler und:" -ForegroundColor Yellow
    Write-Host "  1. Überprüfen Sie, dass alle Services laufen" -ForegroundColor Yellow
    Write-Host "  2. Führen Sie .\start-project.ps1 aus, um fehlende Services zu starten" -ForegroundColor Yellow
    Write-Host "  3. Überprüfen Sie DEVELOPMENT-GUIDE.md für Fehlerbehebung" -ForegroundColor Yellow
    Write-Host "  4. Führen Sie .\verify-system.ps1 erneut aus, nachdem Sie Probleme behoben haben" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
