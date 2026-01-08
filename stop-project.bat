@echo off
setlocal EnableDelayedExpansion

:: ============================================
:: GFOS Digital Idea Board - Stop Script
:: ============================================

:: Configuration
set "GLASSFISH_HOME=C:\glassfish-7.1.0\glassfish7"
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot"

:: Colors
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "CYAN=[96m"
set "WHITE=[97m"
set "RESET=[0m"

echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Stopping GFOS Idea Board Services%RESET%
echo %CYAN%========================================%RESET%
echo.

:: Stop frontend (Node.js processes on port 3000)
echo %WHITE%[INFO]%RESET% Stopping frontend dev server...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":3000" ^| findstr "LISTENING"') do (
    taskkill /PID %%a /F >nul 2>&1
)
echo %GREEN%[OK]%RESET% Frontend stopped

:: Stop GlassFish
echo %WHITE%[INFO]%RESET% Stopping GlassFish server...
if exist "%GLASSFISH_HOME%\bin\asadmin.bat" (
    "%GLASSFISH_HOME%\bin\asadmin.bat" stop-domain >nul 2>&1
    echo %GREEN%[OK]%RESET% GlassFish stopped
) else (
    echo %YELLOW%[WARNING]%RESET% GlassFish not found at configured path
)

echo.
echo %GREEN%[OK]%RESET% All services stopped!
echo.
echo %WHITE%Note:%RESET% PostgreSQL service is not stopped (managed by Windows services)
echo.
pause
