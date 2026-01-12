# CLAUDE.md

Diese Datei enthält Richtlinien für Claude Code (claude.ai/code) bei der Arbeit mit Code in diesem Repository.

## Projektübersicht

GFOS Digital Ideen-Board ist eine Innovationsmanagemntplattform, die für den GFOS Innovation Award 2026 entwickelt wurde. Es ist eine vollständige Web-Anwendung mit Jakarta EE Backend und React TypeScript Frontend, die Gamifikation, Umfragen und umfassende Ideenverwaltung implementiert.

## Architektur

### Technologie-Stack

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

### Wichtigste Architektur-Muster

**Backend-Struktur** (`backend/src/main/java/com/gfos/ideaboard/`)
- `resource/` - JAX-RS REST Endpunkte (z.B. IdeaResource, AuthResource)
- `service/` - Geschäftslogik-Schicht (z.B. IdeaService, AuthService)
- `entity/` - JPA Entities (User, Idea, Comment, etc.)
- `dto/` - Datenübertragungsobjekte für API-Antworten
- `security/` - JWT Verwaltung (JwtFilter, JwtUtil, @Secured Annotation)
- `config/` - Anwendungskonfiguration, CORS Filter, Jackson Konfiguration
- `exception/` - Globale Exception-Behandlung

**Frontend-Struktur** (`frontend/src/`)
- `pages/` - Komponenten auf Seitenebene (DashboardPage, IdeasPage, etc.)
- `components/` - Wiederverwendbare UI-Komponenten (Layout, NotificationDropdown)
- `services/` - API-Client-Services (ideaService, authService, etc.)
- `context/` - React Kontexte für globalen Zustand (AuthContext, ThemeContext)
- `types/` - TypeScript Typ-Definitionen (geteilt über das Frontend)

**Authentifizierungsablauf**
1. Login gibt sowohl Access Token (1 Tag Gültigkeit) als auch Refresh Token (7 Tage) zurück
2. Frontend speichert Tokens in localStorage (`ideaboard_token`, `ideaboard_refresh_token`)
3. Axios Interceptor fügt `Authorization: Bearer <token>` zu allen Anfragen hinzu
4. Bei 401 Antwort ruft Interceptor automatisch `/api/auth/refresh` mit Refresh Token auf
5. Backend verwendet `@Secured` Annotation + `JwtFilter` zum Schutz der Endpunkte
6. JwtFilter extrahiert userId, username, role aus Token und speichert in Request Context
7. Resources verwenden `@Context ContainerRequestContext` für Zugriff auf authentifizierte Benutzerinformationen

**Datenbankzugriffsmuster**
- JPA Persistenzeinheit mit dem Namen "IdeaBoardPU" konfiguriert in `persistence.xml`
- JDBC Ressource: `jdbc/ideaboard` (muss in GlassFish konfiguriert werden)
- Services verwenden `@PersistenceContext` für EntityManager Injection
- EclipseLink führt automatische Schema-Verwaltung mit "create-or-extend-tables" durch

**API Design**
- Basis-URL: `/api` (in ApplicationConfig und web.xml zugeordnet)
- RESTful Endpunkte folgen dem Muster: `/api/{resource}/{id}?{filters}`
- Alle Antworten/Anfragen verwenden JSON (Jersey + Jackson)
- CORS für alle Ursprünge aktiviert über CorsFilter mit @PreMatching Priorität

## Entwicklungsbefehle

### Backend-Entwicklung

```bash
# Erstellen und verpacken
cd backend
mvn clean package              # Erstellt ideaboard.war in target/

# Nur kompilieren (schneller zum Überprüfen der Kompilierung)
mvn clean compile

# Tests während des Builds auslassen
mvn clean package -DskipTests

# Bereitstellung in GlassFish (erfordert JDBC Verbindungspool Setup)
asadmin deploy target/ideaboard.war

# Erneute Bereitstellung nach Code-Änderungen
asadmin redeploy --force --name ideaboard target/ideaboard.war

# ODER verwende bereitgestellte Batch-Datei (Windows)
C:\GGFF\redeploy.bat           # Setzt JAVA_HOME und stellt erneut bereit

# GlassFish starten
asadmin start-domain           # Standard domain1 auf Port 8080
# ODER verwende Batch-Skript
C:\GGFF\start-backend.bat      # Setzt JAVA_HOME und startet domain

# Bereitstellung überprüfen
asadmin list-applications

# Logs anzeigen
tail -f C:\glassfish-7.1.0\glassfish7\glassfish\domains\domain1\logs\server.log
```

### Frontend-Entwicklung

```bash
cd frontend

# Abhängigkeiten installieren
npm install

# Dev-Server starten (http://localhost:3000)
npm run dev

# Für die Produktion erstellen
npm run build                  # Ausgabe zu dist/

# Production Build Vorschau
npm run preview

# TypeScript linting
npm run lint

# Type Check ohne Datei-Emission (schnell)
npx tsc --noEmit
```

### Datenbank-Setup

```bash
# Datenbank und Benutzer erstellen
psql -U postgres -c "CREATE DATABASE ideaboard;"
psql -U postgres -c "CREATE USER ideaboard_user WITH ENCRYPTED PASSWORD 'your_password';"
psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE ideaboard TO ideaboard_user;"

# Schema und Seed-Daten initialisieren
psql -U postgres -d ideaboard -f database/init.sql

# Auf Datenbank zugreifen
PGPASSWORD=your_password psql -U ideaboard_user -d ideaboard
```

### GlassFish JDBC Konfiguration

```bash
# Verbindungspool erstellen
asadmin create-jdbc-connection-pool \
  --restype javax.sql.DataSource \
  --datasourceclassname org.postgresql.ds.PGSimpleDataSource \
  --property user=ideaboard_user:password=your_password:serverName=localhost:portNumber=5432:databaseName=ideaboard \
  IdeaBoardPool

# JDBC Ressource erstellen (muss mit persistence.xml jta-data-source übereinstimmen)
asadmin create-jdbc-resource --connectionpoolid IdeaBoardPool jdbc/ideaboard

# Verbindung testen
asadmin ping-connection-pool IdeaBoardPool
```

## Wichtige Implementierungsdetails

### JWT Token Verwaltung
- Access Tokens werden NICHT als Refresh Tokens akzeptiert (überprüft in JwtFilter)
- Refresh Tokens werden NUR am `/api/auth/refresh` Endpunkt akzeptiert
- Token Validierung erfolgt in JwtFilter für alle `@Secured` Endpunkte
- Benutzerkontext in Request Properties gespeichert: `userId`, `username`, `role`

### Rollenbasierte Zugriffskontrolle
- Drei Rollen: `EMPLOYEE`, `PROJECT_MANAGER`, `ADMIN`
- Resources überprüfen Rollen über `ContainerRequestContext.getSecurityContext().isUserInRole()`
- Nur Admin Endpunkte: Audit Logs, Benutzerverwaltung, Ideen-Löschung
- PM + Admin: Export Funktionalität

### Wöchentliches Like-System
- Benutzer erhalten 3 Likes pro Woche (setzt sich Sonntag 00:00 Uhr zurück)
- Nachverfolgung in `Like` Entity mit `createdAt` Zeitstempel
- LikeService berechnet verbleibende Likes basierend auf aktueller Woche
- Unlike verringert wöchentliche Zählung (erlaubt Neuverteilung)

### Gamifikationssystem
- XP Belohnungen: Idee einreichen (+50), Like erhalten (+10), Kommentar (+5), Idee abgeschlossen (+100)
- Levelschwellen: 0, 100, 300, 600, 1000, 1500 XP
- GamificationService verwaltet XP Vergabe und Abzeichen-Zuweisung
- Abzeichen Kriterien werden in GamificationService evaluiert

### Datei-Upload Beschränkungen
- Max Dateigröße: 10MB
- Unterstützte Typen: Bilder (PNG, JPG, JPEG, GIF), PDFs, Dokumente (DOC, DOCX)
- Dateien in FileAttachment Entity mit Metadaten gespeichert
- FileService verwaltet Validierung und Speicherung

### Demo-Modus Unterstützung
- Frontend hat Demo-Modus unter `/demo-mode.html`
- Setzt `ideaboard_demo_mode=true` in localStorage
- AuthContext überspringt API Token Verifikation im Demo-Modus
- Ermöglicht UI-Tests ohne Backend

## Häufige Workflows

### Einen neuen API Endpunkt hinzufügen

1. Erstelle Methode in der entsprechenden Service Klasse (Geschäftslogik)
2. Füge Endpunkt in der entsprechenden Resource Klasse mit `@Path`, `@GET/@POST/@PUT/@DELETE` hinzu
3. Füge `@Secured` Annotation hinzu, wenn Authentifizierung erforderlich ist
4. Verwende `@Context ContainerRequestContext` für Zugriff auf Benutzerinformationen
5. Gebe DTO Objekte zurück (nicht Entities direkt)
6. Füge entsprechende Methode in Frontend-Service Datei hinzu (z.B. `ideaService.ts`)
7. Aktualisiere TypeScript Typen in `frontend/src/types/index.ts` falls nötig

### Änderung des Datenbankschemas

1. Aktualisiere JPA Entity in `backend/src/main/java/com/gfos/ideaboard/entity/`
2. Füge Entity Klasse zu `persistence.xml` hinzu, wenn neue Entity
3. Aktualisiere `database/init.sql` für saubere Installationen
4. EclipseLink wird Schema bei nächster Bereitstellung automatisch aktualisieren (create-or-extend-tables Modus)
5. Für manuelle Schema Änderungen, Datenbank direkt oder via init.sql aktualisieren

### Eine neue Seite/Route hinzufügen

1. Erstelle Page Komponente in `frontend/src/pages/`
2. Füge Route in `frontend/src/App.tsx` hinzu
3. Füge Navigationslink in `frontend/src/components/Layout.tsx` hinzu, falls nötig
4. Erstelle entsprechende Service Methoden in `frontend/src/services/` für API Aufrufe
5. Verwende `useAuth()` Hook für aktuellen Benutzerkontext
6. Geschützte Routes sollten `user.role` überprüfen und bedingt rendern

## Debugging Tipps

**Backend Fehler**
- GlassFish Logs überprüfen: `glassfish7/glassfish/domains/domain1/logs/server.log`
- SQL Logging aktivieren: Setze `eclipselink.logging.level.sql` zu `FINE` in persistence.xml
- JWT Fehler: Token könnte abgelaufen oder malformed sein (Gültigkeit in JwtUtil überprüfen)
- 401 Fehler: Überprüfe, ob Endpunkt `@Secured` hat und Token gültig ist

**Frontend Fehler**
- Browser Konsole und Network Tab für API Antworten überprüfen
- Token Refresh Fehler: localStorage löschen und erneut anmelden
- CORS Fehler: CorsFilter Konfiguration im Backend überprüfen
- TypeScript Fehler: `npx tsc --noEmit` für detaillierte Typ-Überprüfung ausführen

**Datenbankverbindungsprobleme**
- Überprüfe, dass PostgreSQL läuft: `pg_isready`
- JDBC Pool testen: `asadmin ping-connection-pool IdeaBoardPool`
- Überprüfe, dass Anmeldeinformationen mit persistence.xml Konfiguration übereinstimmen
- Stelle sicher, dass Datenbank `ideaboard` existiert und Benutzer Berechtigungen hat

## Standard Test Anmeldeinformationen

Nach Ausführung von `database/init.sql`:
- Admin: `admin` / `admin123`
- Employee: `john.doe` / `password123`
- Project Manager: `jane.smith` / `password123`

## Sicherheitsaspekte

- Passwörter mit BCrypt (12 Runden) gehashed via `PasswordUtil.hashPassword()`
- JWT Secret Key in `JwtUtil` gespeichert (sollte in Produktion externalisiert werden)
- Refresh Tokens in Datenbank gespeichert für Revokation
- SQL Injection verhindert via JPA parametrisierte Abfragen
- XSS gemindert durch automatisches Escaping von React
- CSRF nicht benötigt (zustandslose JWT Authentifizierung)

## Konfigurationsdateien

- `backend/pom.xml` - Maven Abhängigkeiten und Build Konfiguration
- `backend/src/main/resources/META-INF/persistence.xml` - JPA Konfiguration
- `backend/src/main/webapp/WEB-INF/web.xml` - Servlet Zuordnung, Fehlerseiten
- `frontend/package.json` - npm Skripte und Abhängigkeiten
- `frontend/vite.config.ts` - Vite Dev Server (Port 3000, Proxies /api zum Backend)
- `frontend/tailwind.config.js` - Tailwind CSS Anpassung
- `frontend/tsconfig.json` - TypeScript Compiler Optionen
