@echo off
setlocal EnableDelayedExpansion

:: ============================================
:: GFOS Digital Ideen-Board - Startskript
:: ============================================

:: Konfiguration - PASSEN SIE DIESE PFADE FÜR IHR SYSTEM AN
set "JAVA_HOME=C:\Program Files\Eclipse Adoptium\jdk-17.0.17.10-hotspot"
set "MAVEN_HOME=C:\apache-maven-3.9.12"
set "GLASSFISH_HOME=C:\glassfish-7.1.0\glassfish7"
set "POSTGRES_BIN=C:\Program Files\PostgreSQL\18\bin"

:: Datenbankkonfiguration
set "DB_NAME=ideaboard"
set "DB_USER=ideaboard_user"
set "DB_PASSWORD=ideaboard123"
set "DB_HOST=localhost"
set "DB_PORT=5432"
set "PG_ADMIN_USER=postgres"
set "PG_ADMIN_PASSWORD=17918270"

:: Projektpfade
set "PROJECT_ROOT=C:\GGFF\GFOS-"
set "BACKEND_PATH=%PROJECT_ROOT%\backend"
set "FRONTEND_PATH=%PROJECT_ROOT%\frontend"
set "DATABASE_PATH=%PROJECT_ROOT%\database"

:: Ports
set "GLASSFISH_PORT=8080"
set "FRONTEND_PORT=3000"

:: Farben
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "CYAN=[96m"
set "WHITE=[97m"
set "RESET=[0m"

:: Argumente analysieren
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

:: Vollständiger Start
if "%SKIP_CHECKS%"=="0" call :check_all_dependencies
if %ERRORLEVEL% neq 0 (
    echo.
    echo %RED%[ERROR] Fehlende Abhängigkeiten. Bitte installieren Sie diese und versuchen Sie es erneut.%RESET%
    echo %YELLOW%Führen Sie --skip-checks aus, um die Verifikation zu überspringen.%RESET%
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
echo %GREEN% Backend bereit!%RESET%
echo %GREEN%========================================%RESET%
echo.
echo %GREEN%[OK]%RESET% Backend API: http://localhost:%GLASSFISH_PORT%/ideaboard/api
goto :eof

:frontend_only
call :start_frontend
goto :eof

:: ============================================
:: ABHÄNGIGKEITSPRÜFUNGEN
:: ============================================

:check_all_dependencies
echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Überprüfe Abhängigkeiten%RESET%
echo %CYAN%========================================%RESET%

set "ALL_OK=1"

:: Java überprüfen
echo %WHITE%[INFO]%RESET% Überprüfe Java-Installation...
if exist "%JAVA_HOME%\bin\java.exe" (
    "%JAVA_HOME%\bin\java.exe" -version 2>&1 | findstr /C:"17" >nul
    if !ERRORLEVEL! equ 0 (
        echo %GREEN%[OK]%RESET% Java 17 gefunden unter: %JAVA_HOME%
    ) else (
        echo %RED%[ERROR]%RESET% Java gefunden, aber nicht Version 17
        set "ALL_OK=0"
    )
) else (
    echo %RED%[ERROR]%RESET% Java 17 NICHT GEFUNDEN!
    echo.
    echo %YELLOW%    Bitte installieren Sie Java 17 ^(JDK^):%RESET%
    echo     1. Laden Sie Eclipse Temurin JDK 17 herunter: https://adoptium.net/
    echo     2. Führen Sie das Installationsprogramm aus
    echo     3. Aktualisieren Sie JAVA_HOME in diesem Skript
    echo.
    set "ALL_OK=0"
)

:: Maven überprüfen
echo %WHITE%[INFO]%RESET% Überprüfe Maven-Installation...
if exist "%MAVEN_HOME%\bin\mvn.cmd" (
    echo %GREEN%[OK]%RESET% Maven gefunden unter: %MAVEN_HOME%
) else (
    where mvn >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo %GREEN%[OK]%RESET% Maven in PATH gefunden
    ) else (
        echo %RED%[ERROR]%RESET% Maven NICHT GEFUNDEN!
        echo.
        echo %YELLOW%    Bitte installieren Sie Apache Maven 3.8+:%RESET%
        echo     1. Herunterladen von: https://maven.apache.org/download.cgi
        echo     2. Extrahieren nach C:\apache-maven-3.9.x
        echo     3. Aktualisieren Sie MAVEN_HOME in diesem Skript
        echo.
        set "ALL_OK=0"
    )
)

:: Node.js überprüfen
echo %WHITE%[INFO]%RESET% Überprüfe Node.js-Installation...
where node >nul 2>&1
if %ERRORLEVEL% equ 0 (
    for /f "tokens=*" %%i in ('node -v') do set "NODE_VER=%%i"
    echo %GREEN%[OK]%RESET% Node.js !NODE_VER! gefunden
) else (
    echo %RED%[ERROR]%RESET% Node.js NICHT GEFUNDEN!
    echo.
    echo %YELLOW%    Bitte installieren Sie Node.js 18+:%RESET%
    echo     1. Herunterladen von: https://nodejs.org/
    echo     2. Führen Sie das Installationsprogramm aus ^(LTS-Version empfohlen^)
    echo     3. Starten Sie dieses Terminal neu
    echo.
    set "ALL_OK=0"
)

:: PostgreSQL überprüfen
echo %WHITE%[INFO]%RESET% Überprüfe PostgreSQL-Installation...
if exist "%POSTGRES_BIN%\psql.exe" (
    echo %GREEN%[OK]%RESET% PostgreSQL gefunden unter: %POSTGRES_BIN%
) else (
    where psql >nul 2>&1
    if !ERRORLEVEL! equ 0 (
        echo %GREEN%[OK]%RESET% PostgreSQL in PATH gefunden
    ) else (
        echo %RED%[ERROR]%RESET% PostgreSQL NICHT GEFUNDEN!
        echo.
        echo %YELLOW%    Bitte installieren Sie PostgreSQL 15+:%RESET%
        echo     1. Herunterladen von: https://www.postgresql.org/download/windows/
        echo     2. Führen Sie das Installationsprogramm aus
        echo     3. Aktualisieren Sie POSTGRES_BIN in diesem Skript
        echo.
        set "ALL_OK=0"
    )
)

:: GlassFish überprüfen
echo %WHITE%[INFO]%RESET% Überprüfe GlassFish-Installation...
if exist "%GLASSFISH_HOME%\bin\asadmin.bat" (
    echo %GREEN%[OK]%RESET% GlassFish gefunden unter: %GLASSFISH_HOME%
) else (
    echo %RED%[ERROR]%RESET% GlassFish 7 NICHT GEFUNDEN!
    echo.
    echo %YELLOW%    Bitte installieren Sie GlassFish 7:%RESET%
    echo     1. Herunterladen von: https://glassfish.org/download
    echo     2. Extrahieren nach C:\glassfish-7.1.0
    echo     3. Aktualisieren Sie GLASSFISH_HOME in diesem Skript
    echo.
    set "ALL_OK=0"
)

if "%ALL_OK%"=="1" (
    echo.
    echo %GREEN%[OK]%RESET% Alle Abhängigkeiten sind installiert!
    exit /b 0
) else (
    exit /b 1
)

:: ============================================
:: DATENBANKEINRICHTUNG
:: ============================================

:setup_database
echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Richte Datenbank ein%RESET%
echo %CYAN%========================================%RESET%

set "PGPASSWORD=%PG_ADMIN_PASSWORD%"

:: Überprüfen Sie, ob PostgreSQL läuft
echo %WHITE%[INFO]%RESET% Überprüfe, ob PostgreSQL läuft...
"%POSTGRES_BIN%\psql.exe" -U %PG_ADMIN_USER% -h %DB_HOST% -p %DB_PORT% -c "SELECT 1" >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo %RED%[ERROR]%RESET% PostgreSQL läuft nicht oder Anmeldedaten sind falsch!
    echo %YELLOW%Bitte starten Sie den PostgreSQL-Dienst und überprüfen Sie die Anmeldedaten.%RESET%
    exit /b 1
)
echo %GREEN%[OK]%RESET% PostgreSQL läuft

:: Überprüfen Sie, ob die Datenbank existiert
echo %WHITE%[INFO]%RESET% Überprüfe, ob die Datenbank '%DB_NAME%' existiert...
for /f "tokens=*" %%i in ('"%POSTGRES_BIN%\psql.exe" -U %PG_ADMIN_USER% -h %DB_HOST% -p %DB_PORT% -t -c "SELECT 1 FROM pg_database WHERE datname='%DB_NAME%'" 2^>nul') do set "DB_EXISTS=%%i"

if "!DB_EXISTS!"=="         1" (
    echo %GREEN%[OK]%RESET% Datenbank '%DB_NAME%' existiert
) else (
    echo %WHITE%[INFO]%RESET% Erstelle Datenbank '%DB_NAME%'...

    :: Benutzer erstellen
    "%POSTGRES_BIN%\psql.exe" -U %PG_ADMIN_USER% -h %DB_HOST% -p %DB_PORT% -c "DO $$ BEGIN IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '%DB_USER%') THEN CREATE USER %DB_USER% WITH ENCRYPTED PASSWORD '%DB_PASSWORD%'; END IF; END $$;" >nul 2>&1

    :: Datenbank erstellen
    "%POSTGRES_BIN%\psql.exe" -U %PG_ADMIN_USER% -h %DB_HOST% -p %DB_PORT% -c "CREATE DATABASE %DB_NAME% OWNER %DB_USER%;" >nul 2>&1

    if !ERRORLEVEL! equ 0 (
        echo %GREEN%[OK]%RESET% Datenbank erfolgreich erstellt

        :: Berechtigungen gewähren
        "%POSTGRES_BIN%\psql.exe" -U %PG_ADMIN_USER% -h %DB_HOST% -p %DB_PORT% -c "GRANT ALL PRIVILEGES ON DATABASE %DB_NAME% TO %DB_USER%;" >nul 2>&1

        :: Mit Seed-Daten initialisieren
        if exist "%DATABASE_PATH%\init.sql" (
            echo %WHITE%[INFO]%RESET% Führe Datenbank-Initialisierungsskript aus...
            set "PGPASSWORD=%DB_PASSWORD%"
            "%POSTGRES_BIN%\psql.exe" -U %DB_USER% -h %DB_HOST% -p %DB_PORT% -d %DB_NAME% -f "%DATABASE_PATH%\init.sql" >nul 2>&1
            echo %GREEN%[OK]%RESET% Datenbank mit Seed-Daten initialisiert
        )
    ) else (
        echo %RED%[ERROR]%RESET% Fehler beim Erstellen der Datenbank
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
echo %CYAN% Starte GlassFish Server%RESET%
echo %CYAN%========================================%RESET%

:: Überprüfe, ob bereits läuft
netstat -an | findstr ":%GLASSFISH_PORT% " | findstr "LISTENING" >nul 2>&1
if %ERRORLEVEL% equ 0 (
    echo %GREEN%[OK]%RESET% GlassFish läuft bereits auf Port %GLASSFISH_PORT%
    exit /b 0
)

echo %WHITE%[INFO]%RESET% Starte GlassFish Domain...
"%GLASSFISH_HOME%\bin\asadmin.bat" start-domain >nul 2>&1

:: Warten auf Start
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
echo %GREEN%[OK]%RESET% GlassFish erfolgreich auf Port %GLASSFISH_PORT% gestartet
exit /b 0

:glassfish_timeout
echo.
echo %RED%[ERROR]%RESET% GlassFish konnte nicht innerhalb des Timeouts gestartet werden
exit /b 1

:setup_jdbc
echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Konfiguriere JDBC Verbindungspool%RESET%
echo %CYAN%========================================%RESET%

:: Überprüfe, ob Pool existiert
echo %WHITE%[INFO]%RESET% Überprüfe JDBC Verbindungspool...
"%GLASSFISH_HOME%\bin\asadmin.bat" list-jdbc-connection-pools 2>nul | findstr "IdeaBoardPool" >nul
if %ERRORLEVEL% equ 0 (
    echo %GREEN%[OK]%RESET% JDBC Pool 'IdeaBoardPool' existiert bereits
) else (
    echo %WHITE%[INFO]%RESET% Erstelle JDBC Verbindungspool...
    "%GLASSFISH_HOME%\bin\asadmin.bat" create-jdbc-connection-pool --restype javax.sql.DataSource --datasourceclassname org.postgresql.ds.PGSimpleDataSource --property user=%DB_USER%:password=%DB_PASSWORD%:serverName=%DB_HOST%:portNumber=%DB_PORT%:databaseName=%DB_NAME% IdeaBoardPool >nul 2>&1
    echo %GREEN%[OK]%RESET% JDBC Pool erstellt
)

:: Überprüfe, ob Ressource existiert
echo %WHITE%[INFO]%RESET% Überprüfe JDBC Ressource...
"%GLASSFISH_HOME%\bin\asadmin.bat" list-jdbc-resources 2>nul | findstr "jdbc/ideaboard" >nul
if %ERRORLEVEL% equ 0 (
    echo %GREEN%[OK]%RESET% JDBC Ressource 'jdbc/ideaboard' existiert bereits
) else (
    echo %WHITE%[INFO]%RESET% Erstelle JDBC Ressource...
    "%GLASSFISH_HOME%\bin\asadmin.bat" create-jdbc-resource --connectionpoolid IdeaBoardPool jdbc/ideaboard >nul 2>&1
    echo %GREEN%[OK]%RESET% JDBC Ressource erstellt
)

:: Teste Verbindung
echo %WHITE%[INFO]%RESET% Teste Datenbankverbindung...
"%GLASSFISH_HOME%\bin\asadmin.bat" ping-connection-pool IdeaBoardPool 2>&1 | findstr "successfully" >nul
if %ERRORLEVEL% equ 0 (
    echo %GREEN%[OK]%RESET% Datenbankverbindungstest bestanden
) else (
    echo %YELLOW%[WARNING]%RESET% Datenbankverbindungstest fehlgeschlagen - überprüfen Sie die Konfiguration
)

exit /b 0

:: ============================================
:: ERSTELLEN UND BEREITSTELLUNG
:: ============================================

:build_backend
echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Backend erstellen%RESET%
echo %CYAN%========================================%RESET%

if exist "%MAVEN_HOME%\bin\mvn.cmd" (
    set "MVN=%MAVEN_HOME%\bin\mvn.cmd"
) else (
    set "MVN=mvn"
)

echo %WHITE%[INFO]%RESET% Erstelle WAR-Datei mit Maven...
pushd "%BACKEND_PATH%"
"%MVN%" clean package -DskipTests -q
set "BUILD_RESULT=%ERRORLEVEL%"
popd

if %BUILD_RESULT% equ 0 (
    if exist "%BACKEND_PATH%\target\ideaboard.war" (
        echo %GREEN%[OK]%RESET% Backend erfolgreich erstellt: target\ideaboard.war
        exit /b 0
    )
)
echo %RED%[ERROR]%RESET% Backend-Build fehlgeschlagen!
exit /b 1

:deploy_backend
echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Stellen Sie Backend in GlassFish bereit%RESET%
echo %CYAN%========================================%RESET%

if not exist "%BACKEND_PATH%\target\ideaboard.war" (
    echo %RED%[ERROR]%RESET% WAR-Datei nicht gefunden!
    exit /b 1
)

echo %WHITE%[INFO]%RESET% Stelle Anwendung bereit...
"%GLASSFISH_HOME%\bin\asadmin.bat" redeploy --force --name ideaboard "%BACKEND_PATH%\target\ideaboard.war" >nul 2>&1

echo %GREEN%[OK]%RESET% Backend bereitgestellt!
echo %WHITE%[INFO]%RESET% API verfügbar unter: http://localhost:%GLASSFISH_PORT%/ideaboard/api
exit /b 0

:: ============================================
:: FRONTEND
:: ============================================

:start_frontend
echo.
echo %CYAN%========================================%RESET%
echo %CYAN% Starten Sie Frontend Dev Server%RESET%
echo %CYAN%========================================%RESET%

:: Überprüfen/Abhängigkeiten installieren
if not exist "%FRONTEND_PATH%\node_modules" (
    echo %WHITE%[INFO]%RESET% Installiere npm Abhängigkeiten...
    pushd "%FRONTEND_PATH%"
    npm install >nul 2>&1
    popd
    echo %GREEN%[OK]%RESET% Abhängigkeiten installiert
) else (
    echo %GREEN%[OK]%RESET% Frontend Abhängigkeiten bereits installiert
)

echo %WHITE%[INFO]%RESET% Starten Sie Vite Dev Server auf Port %FRONTEND_PORT%...
start "GFOS Frontend" cmd /k "cd /d %FRONTEND_PATH% && npm run dev"

timeout /t 3 /nobreak >nul
echo %GREEN%[OK]%RESET% Frontend startet in neuem Fenster...
echo %WHITE%[INFO]%RESET% Frontend ist verfügbar unter: http://localhost:%FRONTEND_PORT%

exit /b 0

:: ============================================
:: ABSCHLIESSINFORMATIONEN
:: ============================================

:show_final_info
echo.
echo %GREEN%========================================%RESET%
echo %GREEN% Alle Dienste gestartet!%RESET%
echo %GREEN%========================================%RESET%
echo.
echo   %WHITE%Anwendungs-URLs:%RESET%
echo   -----------------
echo   %GREEN%[OK]%RESET% Frontend:    http://localhost:%FRONTEND_PORT%
echo   %GREEN%[OK]%RESET% Backend API: http://localhost:%GLASSFISH_PORT%/ideaboard/api
echo   %GREEN%[OK]%RESET% GlassFish:   http://localhost:4848 (Admin Konsole)
echo.
echo   %WHITE%Standard Anmeldedaten:%RESET%
echo   --------------------------
echo   %CYAN%Admin:    admin / admin123%RESET%
echo   %CYAN%Employee: john.doe / password123%RESET%
echo   %CYAN%Manager:  jane.smith / password123%RESET%
echo.
echo %WHITE%[INFO]%RESET% Drücken Sie Strg+C, um den Frontend-Server zu stoppen
echo.
pause
goto :eof

:error_exit
echo.
echo %RED%[ERROR] Startup fehlgeschlagen. Überprüfen Sie die obigen Fehler.%RESET%
pause
exit /b 1

:show_help
echo.
echo GFOS Digital Ideen-Board - Startskript
echo =========================================
echo.
echo Verwendung: start-project.bat [Optionen]
echo.
echo Optionen:
echo   --skip-checks, -s    Überspringe Abhängigkeitsprüfungen (schnellerer Start)
echo   --skip-build, -b     Überspringe Maven Build (verwende bestehendes WAR)
echo   --frontend, -f       Starten Sie nur den Frontend Dev Server
echo   --backend            Starten Sie nur PostgreSQL und GlassFish
echo   --help, -h           Diese Hilfemeldung anzeigen
echo.
echo Anforderungen:
echo   - Java 17 (JDK)
echo   - Apache Maven 3.8+
echo   - Node.js 18+ mit npm
echo   - PostgreSQL 15+
echo   - GlassFish 7
echo.
echo Konfiguration:
echo   Bearbeiten Sie den Konfigurationsabschnitt oben in diesem Skript
echo   um Ihre Installationspfade zu matchen.
echo.
echo Beispiele:
echo   start-project.bat                  Vollständiger Start mit allen Überprüfungen
echo   start-project.bat --skip-checks    Überspringe Abhängigkeitsverifikation
echo   start-project.bat --frontend       Starten Sie nur Frontend
echo.
pause
goto :eof
