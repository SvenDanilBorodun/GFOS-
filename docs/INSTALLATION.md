# Installationsanleitung

Diese Anleitung beschreibt, wie Sie das GFOS Digital Idea Board auf Ihrem System installieren und starten konnen.

---

## Inhaltsverzeichnis

1. [Voraussetzungen](#voraussetzungen)
2. [Schnellstart mit Docker](#schnellstart-mit-docker)
3. [Umgebungsvariablen konfigurieren](#umgebungsvariablen-konfigurieren)
4. [Entwicklungsmodus](#entwicklungsmodus)
5. [Lokale Entwicklung ohne Docker](#lokale-entwicklung-ohne-docker)
6. [Testbenutzer](#testbenutzer)
7. [Wichtige Befehle](#wichtige-befehle)
8. [Fehlerbehebung](#fehlerbehebung)
9. [Ports und Dienste](#ports-und-dienste)

---

## Voraussetzungen

### Erforderlich

| Software | Version | Zweck |
|----------|---------|-------|
| **Docker Desktop** | 4.0 oder hoher | Container-Verwaltung |
| **Git** | 2.0 oder hoher | Versionskontrolle |

### Optional (fur lokale Entwicklung ohne Docker)

| Software | Version | Zweck |
|----------|---------|-------|
| **Node.js** | 20.x LTS | Vorderseiten-Entwicklung |
| **Maven** | 3.9.x | Ruckseiten-Build |
| **Java JDK** | 17 | Java-Entwicklung |
| **PostgreSQL** | 15+ | Lokale Datenbank |

### Docker Desktop installieren

1. Laden Sie Docker Desktop von der offiziellen Webseite herunter:
   - Windows: https://docs.docker.com/desktop/install/windows-install/

2. Fuhren Sie das Installationsprogramm aus und folgen Sie den Anweisungen

3. Starten Sie Docker Desktop nach der Installation

4. Uberprufen Sie die Installation im Terminal:
   ```bash
   docker --version
   docker compose version
   ```

---

## Schnellstart mit Docker

### Schritt 1: Repository klonen

```bash
git clone <repository-url>
cd GFOS-
```

### Schritt 2: Umgebungsdatei erstellen

Kopieren Sie die Beispiel-Umgebungsdatei:

```bash
# Windows (Eingabeaufforderung)
copy .env.example .env

# Windows (PowerShell) oder Linux/Mac
cp .env.example .env
```

### Schritt 3: Container starten

Starten Sie alle Dienste mit einem Befehl:

```bash
docker compose up --build
```

**Was passiert jetzt?**
1. Docker ladt die benotigten Basis-Images herunter (beim ersten Start)
2. Die Datenbank wird initialisiert
3. Die Ruckseite wird kompiliert und auf GlassFish bereitgestellt
4. Die Vorderseite wird gebaut und uber Nginx bereitgestellt

**Hinweis:** Der erste Start kann 5-10 Minuten dauern, da alle Abhangigkeiten heruntergeladen werden mussen.

### Schritt 4: Auf Bereitschaft warten

Beobachten Sie die Protokollausgabe. Die Anwendung ist bereit, wenn Sie diese Meldung sehen:

```
Application deployed successfully!
```

### Schritt 5: Anwendung offnen

Offnen Sie Ihren Browser und navigieren Sie zu:

**http://localhost:3000**

![Screenshot: Anmeldeseite]
*Platzhalter fur Screenshot der Anmeldeseite*

---

## Umgebungsvariablen konfigurieren

Die Datei `.env` enthalt alle konfigurierbaren Parameter:

```bash
# Datenbank-Konfiguration
DB_NAME=ideaboard          # Name der Datenbank
DB_USER=postgres           # Datenbank-Benutzer
DB_PASSWORD=postgres       # Datenbank-Kennwort
DB_PORT=5432               # Datenbank-Port

# Server-Konfiguration
BACKEND_PORT=8080          # Ruckseiten-Port
GLASSFISH_ADMIN_PORT=4848  # GlassFish-Admin-Port
FRONTEND_PORT=3000         # Vorderseiten-Port
```

### Parameter-Beschreibung

| Variable | Standardwert | Beschreibung |
|----------|--------------|--------------|
| `DB_NAME` | ideaboard | Name der PostgreSQL-Datenbank |
| `DB_USER` | postgres | Benutzername fur die Datenbankverbindung |
| `DB_PASSWORD` | postgres | Kennwort fur die Datenbankverbindung |
| `DB_PORT` | 5432 | Port, auf dem PostgreSQL lauscht |
| `BACKEND_PORT` | 8080 | Port fur die REST-Schnittstelle |
| `GLASSFISH_ADMIN_PORT` | 4848 | Port fur die GlassFish-Administrationskonsole |
| `FRONTEND_PORT` | 3000 | Port fur die Web-Oberflache |

**Wichtig:** Nach Anderungen an der `.env`-Datei mussen die Container neu gestartet werden:

```bash
docker compose down
docker compose up --build
```

---

## Entwicklungsmodus

Der Entwicklungsmodus aktiviert die automatische Aktualisierung (Hot-Reload) fur die Vorderseite. Anderungen am Quellcode werden sofort im Browser sichtbar.

### Entwicklungsmodus starten

```bash
docker compose -f docker-compose.yml -f docker-compose.dev.yml up --build
```

### Unterschiede zum Produktionsmodus

| Aspekt | Produktionsmodus | Entwicklungsmodus |
|--------|------------------|-------------------|
| Vorderseite | Statische Dateien uber Nginx | Vite-Entwicklungsserver |
| Aktualisierung | Manueller Neustart erforderlich | Automatisch bei Anderungen |
| Protokollierung | Standard | Ausfuhrlich (FINE) |
| Leistung | Optimiert | Nicht optimiert |

---

## Lokale Entwicklung ohne Docker

Falls Sie ohne Docker entwickeln mochten, konnen Sie die Dienste einzeln starten.

### Datenbank einrichten

1. Installieren Sie PostgreSQL 15 oder hoher
2. Erstellen Sie eine Datenbank:
   ```sql
   CREATE DATABASE ideaboard;
   CREATE USER ideaboard_user WITH PASSWORD 'ideaboard123';
   GRANT ALL PRIVILEGES ON DATABASE ideaboard TO ideaboard_user;
   ```
3. Fuhren Sie das Initialisierungsskript aus:
   ```bash
   psql -U postgres -d ideaboard -f database/init.sql
   ```

### Ruckseite starten

```bash
cd backend
mvn clean compile           # Kompilieren
mvn test                    # Tests ausfuhren (optional)
mvn clean package           # WAR-Datei erstellen
```

Die WAR-Datei (`ideaboard.war`) muss dann auf einem GlassFish-Server bereitgestellt werden.

### Vorderseite starten

```bash
cd frontend
npm install                 # Abhangigkeiten installieren
npm run dev                 # Entwicklungsserver starten
```

Die Vorderseite ist dann unter **http://localhost:3000** erreichbar.

**Hinweis:** Die Vorderseite leitet API-Anfragen automatisch an `http://localhost:8080/ideaboard` weiter.

---

## Testbenutzer

Nach der Installation sind folgende Testbenutzer verfugbar:

| Benutzername | Kennwort | Rolle | Berechtigungen |
|--------------|----------|-------|----------------|
| **admin** | admin123 | Administrator | Voller Zugriff, Benutzerverwaltung, Systemeinstellungen |
| **manager** | manager123 | Projektleiter | Ideen verwalten, Status andern, Berichte erstellen |
| **user** | user123 | Mitarbeiter | Ideen einreichen, kommentieren, abstimmen |

### Benutzerrollen erklart

**Mitarbeiter (EMPLOYEE)**
- Kann eigene Ideen erstellen und bearbeiten
- Kann andere Ideen kommentieren und bewerten
- Kann an Umfragen teilnehmen
- Kann Nachrichten senden und empfangen

**Projektleiter (PROJECT_MANAGER)**
- Alle Mitarbeiter-Rechte
- Kann Ideen-Status andern
- Kann abgeschlossene Ideen wiedereroffnen
- Kann Berichte erstellen

**Administrator (ADMIN)**
- Alle Projektleiter-Rechte
- Kann Benutzer verwalten (erstellen, bearbeiten, loschen)
- Kann Systemeinstellungen andern
- Kann Pruprotokolle einsehen

---

## Wichtige Befehle

### Container verwalten

```bash
# Alle Container starten (Vordergrund)
docker compose up --build

# Alle Container starten (Hintergrund)
docker compose up -d --build

# Protokolle anzeigen (alle Dienste)
docker compose logs -f

# Protokolle eines Dienstes anzeigen
docker compose logs -f backend
docker compose logs -f frontend
docker compose logs -f db

# Container stoppen
docker compose down

# Container stoppen und Daten loschen
docker compose down -v
```

### Container-Status prufen

```bash
# Laufende Container anzeigen
docker compose ps

# Ressourcenverbrauch anzeigen
docker stats
```

### Neustart nach Anderungen

```bash
# Einzelnen Dienst neu starten
docker compose restart backend

# Alle Dienste neu bauen und starten
docker compose down
docker compose up --build
```

### Vollstandiger Reset

Falls Probleme auftreten, konnen Sie alles zurucksetzen:

```bash
# Container stoppen und alle Daten loschen
docker compose down -v

# Ungenutzte Docker-Ressourcen bereinigen
docker system prune -a

# Neu starten
docker compose up --build
```

**Warnung:** Der Befehl `docker compose down -v` loscht alle Datenbankdaten unwiderruflich!

---

## Fehlerbehebung

### Problem: Container starten nicht

**Symptom:** `docker compose up` zeigt Fehler an

**Losungen:**
1. Uberprufen Sie, ob Docker Desktop lauft
2. Prufen Sie, ob die Ports bereits belegt sind:
   ```bash
   netstat -an | findstr "3000 8080 5432"
   ```
3. Andern Sie die Ports in der `.env`-Datei

### Problem: Datenbank-Verbindungsfehler

**Symptom:** Ruckseite zeigt Verbindungsfehler zur Datenbank

**Losungen:**
1. Warten Sie langer - die Datenbank braucht Zeit zum Starten
2. Prufen Sie die Datenbank-Protokolle:
   ```bash
   docker compose logs db
   ```
3. Starten Sie die Container neu:
   ```bash
   docker compose restart
   ```

### Problem: Vorderseite zeigt Netzwerkfehler

**Symptom:** Browser zeigt "Netzwerkfehler" oder "Verbindung abgelehnt"

**Losungen:**
1. Warten Sie, bis die Ruckseite vollstandig gestartet ist
2. Prufen Sie die Ruckseiten-Protokolle:
   ```bash
   docker compose logs backend
   ```
3. Testen Sie die Gesundheitsprufung:
   ```bash
   curl http://localhost:8080/ideaboard/api/health
   ```

### Problem: Speicherplatz-Fehler

**Symptom:** Docker zeigt "no space left on device"

**Losung:**
```bash
# Ungenutzte Docker-Ressourcen loschen
docker system prune -a

# Ungenutzte Volumes loschen
docker volume prune
```

### Problem: Langsamer erster Start

**Symptom:** Erster Start dauert sehr lange

**Erklarung:** Beim ersten Start mussen alle Abhangigkeiten heruntergeladen werden:
- Maven-Abhangigkeiten (~200 MB)
- npm-Pakete (~300 MB)
- Docker-Images (~1 GB)

**Losung:** Warten Sie geduldig. Folgestarts sind deutlich schneller.

### Protokolle einsehen

Fur detaillierte Fehleranalyse:

```bash
# Alle Protokolle (letzte 100 Zeilen)
docker compose logs --tail=100

# Protokolle mit Zeitstempel
docker compose logs -t

# Protokolle in Datei speichern
docker compose logs > protokoll.txt
```

---

## Ports und Dienste

### Standard-Ports

| Dienst | Port | Beschreibung |
|--------|------|--------------|
| **Vorderseite** | 3000 | Web-Oberflache (Nginx) |
| **Ruckseite** | 8080 | REST-Schnittstelle (GlassFish) |
| **GlassFish-Admin** | 4848 | Administrationskonsole |
| **Datenbank** | 5432 | PostgreSQL |

### Wichtige URLs

| Dienst | URL |
|--------|-----|
| Web-Oberflache | http://localhost:3000 |
| REST-Schnittstelle | http://localhost:8080/ideaboard/api |
| Gesundheitsprufung | http://localhost:8080/ideaboard/api/health |
| GlassFish-Admin | http://localhost:4848 |

### Container-Namen

| Dienst | Container-Name |
|--------|----------------|
| Vorderseite | ideaboard-frontend |
| Ruckseite | ideaboard-backend |
| Datenbank | ideaboard-db |

---

## Nachste Schritte

Nach erfolgreicher Installation:

1. Melden Sie sich mit einem Testbenutzer an
2. Erkunden Sie die Oberflache
3. Lesen Sie das [Benutzerhandbuch](BENUTZERHANDBUCH.md) fur eine vollstandige Anleitung

Bei technischen Fragen zur Architektur lesen Sie die [Architektur-Dokumentation](ARCHITEKTUR.md).

---

*Zurck zur [Dokumentationsubersicht](README.md)*
