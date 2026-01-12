@echo off
setlocal EnableDelayedExpansion

:: ============================================
:: GFOS Digital Ideen-Board - Stoppskript
:: ============================================

:: Konfiguration
set "GLASSFISH_HOME=C:\glassfish-7.1.0\glassfish7"
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot"

:: Farben
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "CYAN=[96m"
set "WHITE=[97m"
set "RESET=[0m"

echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Stoppe GFOS Ideen-Board Services%RESET%
echo %CYAN%========================================%RESET%
echo.

:: Stoppe Frontend (Node.js Prozesse auf Port 3000)
echo %WHITE%[INFO]%RESET% Stoppe Frontend Dev Server...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":3000" ^| findstr "LISTENING"') do (
    taskkill /PID %%a /F >nul 2>&1
)
echo %GREEN%[OK]%RESET% Frontend gestoppt

:: Stoppe GlassFish
echo %WHITE%[INFO]%RESET% Stoppe GlassFish Server...
if exist "%GLASSFISH_HOME%\bin\asadmin.bat" (
    "%GLASSFISH_HOME%\bin\asadmin.bat" stop-domain >nul 2>&1
    echo %GREEN%[OK]%RESET% GlassFish gestoppt
) else (
    echo %YELLOW%[WARNING]%RESET% GlassFish nicht am konfigurierten Pfad gefunden
)

echo.
echo %GREEN%[OK]%RESET% Alle Services gestoppt!
echo.
echo %WHITE%Hinweis:%RESET% PostgreSQL Service wird nicht gestoppt (wird von Windows Services verwaltet)
echo.
pause
