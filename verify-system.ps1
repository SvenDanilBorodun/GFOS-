# GFOS Digital Idea Board - System Verification Script
# Run this script to verify all systems are functioning correctly

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

GFOS Digital Idea Board - System Verification
==============================================

This script verifies that all components are working correctly.

Usage: .\verify-system.ps1 [options]

Options:
  -Quick    Run quick checks only (skip full tests)
  -Help     Show this help message

What this script checks:
  ✓ PostgreSQL database connectivity
  ✓ User authentication and password hashes
  ✓ Database schema and seed data integrity
  ✓ GlassFish server status
  ✓ Backend API accessibility
  ✓ Frontend connectivity
  ✓ Integration tests

Examples:
  .\verify-system.ps1           # Full verification
  .\verify-system.ps1 -Quick    # Quick checks only

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
Write-Host "                System Verification Tool" -ForegroundColor White
Write-Host ""

# Check 1: PostgreSQL
Write-Header "1. PostgreSQL Database"
$psqlPath = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
$env:PGPASSWORD = "ideaboard123"

try {
    $result = & $psqlPath -U ideaboard_user -h localhost -p $CONFIG.DB_PORT -d ideaboard -c "SELECT COUNT(*) FROM users;" 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "Database connection successful"
        $userCount = ($result | Select-String -Pattern "\d+" | Select-Object -First 1).Matches[0].Value
        Write-Info "Found $userCount users in database"
    } else {
        Write-Error "Database connection failed"
        $allPassed = $false
    }
} catch {
    Write-Error "PostgreSQL error: $_"
    $allPassed = $false
}

# Check 2: GlassFish Server
Write-Header "2. GlassFish Server"
$glassFishRunning = Get-NetTCPConnection -LocalPort $CONFIG.GLASSFISH_PORT -ErrorAction SilentlyContinue
if ($glassFishRunning) {
    Write-Success "GlassFish is running on port $($CONFIG.GLASSFISH_PORT)"
} else {
    Write-Error "GlassFish is NOT running on port $($CONFIG.GLASSFISH_PORT)"
    $allPassed = $false
}

# Check 3: Backend API
Write-Header "3. Backend API"
try {
    # Test with a login attempt which is a public endpoint
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
        Write-Success "Backend API is accessible and responding"
    } else {
        Write-Error "Backend API returned unexpected response"
        $allPassed = $false
    }
} catch {
    Write-Error "Backend API is not accessible: $_"
    $allPassed = $false
}

# Check 4: Frontend
Write-Header "4. Frontend Server"
$frontendRunning = Get-NetTCPConnection -LocalPort $CONFIG.FRONTEND_PORT -ErrorAction SilentlyContinue
if ($frontendRunning) {
    Write-Success "Frontend is running on port $($CONFIG.FRONTEND_PORT)"
} else {
    Write-Error "Frontend is NOT running on port $($CONFIG.FRONTEND_PORT)"
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

# Summary
Write-Header "VERIFICATION SUMMARY"

if ($allPassed) {
    Write-Host ""
    Write-Success "ALL CHECKS PASSED!"
    Write-Host ""
    Write-Host "  Your system is ready to use:" -ForegroundColor White
    Write-Host "  - Frontend:    http://localhost:$($CONFIG.FRONTEND_PORT)" -ForegroundColor Cyan
    Write-Host "  - Backend API: http://localhost:$($CONFIG.GLASSFISH_PORT)/ideaboard/api" -ForegroundColor Cyan
    Write-Host "  - Admin Login: admin / admin123" -ForegroundColor Cyan
    Write-Host ""
    exit 0
} else {
    Write-Host ""
    Write-Error "SOME CHECKS FAILED!"
    Write-Host ""
    Write-Host "  Please review the errors above and:" -ForegroundColor Yellow
    Write-Host "  1. Check that all services are running" -ForegroundColor Yellow
    Write-Host "  2. Run .\start-project.ps1 to start missing services" -ForegroundColor Yellow
    Write-Host "  3. Review DEVELOPMENT-GUIDE.md for troubleshooting" -ForegroundColor Yellow
    Write-Host "  4. Run .\verify-system.ps1 again after fixing issues" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}
