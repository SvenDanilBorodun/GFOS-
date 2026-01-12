# GFOS Digital Ideen-Board - Entwicklungshandbuch

## Verhinderung häufiger Probleme - Best Practices

Dieses Handbuch beschreibt Best Practices zur Vermeidung von Problemen wie Passwort-Hash Nichtübereinstimmungen und zur Gewährleistung zuverlässiger Entwicklung und Bereitstellung.

---

## Inhaltsverzeichnis

1. [Datenbankverwaltung](#datenbankverwaltung)
2. [Test-Strategie](#test-strategie)
3. [Entwicklungsworkflow](#entwicklungsworkflow)
4. [Validierung und Integritätsprüfungen](#validierung-und-integritätsprüfungen)
5. [Fehlerbehandlung und Protokollierung](#fehlerbehandlung-und-protokollierung)
6. [Kontinuierliche Integration](#kontinuierliche-integration)
7. [Fehlerbehebung](#fehlerbehebung)

---

## 1. Datenbankverwaltung

### Seed-Daten immer validieren

**Problem**: Das Datenbank-Initialisierungsskript hatte fehlerhafte BCrypt-Passwort-Hashes.

**Lösung**:
```bash
# Nach der Datenbankinitialisierung IMMER Validierung ausführen
cd backend
mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"
```

Dieses Utility testet:
- ✓ Benutzeranmeldedaten funktionieren korrekt
- ✓ Passwort-Hashes verifizieren mit BCrypt
- ✓ Alle Tabellen haben Seed-Daten
- ✓ Datenintegrität Beschränkungen werden erfüllt

### Passwort-Hashes generieren

**Niemals** Passwort-Hashes hardcodieren. Immer die PasswordUtil der Anwendung verwenden:

```bash
# Korrekte BCrypt Hashes generieren
cd backend
mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.PasswordHashGenerator"
```

### Datenbank zurücksetzen Prozedur

Wenn Sie die Datenbank zurücksetzen müssen:

1. Datenbank löschen und neu erstellen:
   ```sql
   DROP DATABASE IF EXISTS ideaboard;
   CREATE DATABASE ideaboard OWNER ideaboard_user;
   ```

2. Initialisierungsskript ausführen:
   ```bash
   psql -U ideaboard_user -h localhost -d ideaboard -f database/init.sql
   ```

3. **IMMER validieren** nach der Initialisierung:
   ```bash
   cd backend
   mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"
   ```

---

## 2. Test-Strategie

### Integrationstests

Integrationstests verifizieren, dass das gesamte System korrekt zusammenarbeitet.

**Authentifizierungstests ausführen:**
```bash
cd backend
mvn test -Dtest=AuthenticationIntegrationTest
```

**Standort**: `backend/src/test/java/com/gfos/ideaboard/integration/`

Diese Tests verifizieren:
- ✓ Datenbankverbindung funktioniert
- ✓ Benutzerkonten existieren
- ✓ Passwort-Verifikation funktioniert
- ✓ BCrypt Hashes sind korrekt
- ✓ Ungültige Passwörter werden abgelehnt

### Test-Checkliste vor der Bereitstellung

- [ ] Datenbank-Validierung ausführen: `mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"`
- [ ] Integrationstests ausführen: `mvn test`
- [ ] Anmeldung via API testen: `curl -X POST http://localhost:8080/ideaboard/api/auth/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}'`
- [ ] Frontend Anmeldung bei http://localhost:3000 testen
- [ ] GlassFish Logs auf Fehler überprüfen

---

## 3. Entwicklungsworkflow

### Vor dem Commit von Code

1. **Testen Sie Ihre Änderungen**
   ```bash
   mvn clean test
   ```

2. **Validieren Sie die Datenbank, wenn Sie Schema oder Seed-Daten geändert haben**
   ```bash
   mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"
   ```

3. **Überprüfen Sie Fehler in den Logs**
   - Backend: `glassfish7/glassfish/domains/domain1/logs/server.log`
   - Frontend: Browser Konsole und Terminal

4. **Testen Sie den vollständigen Benutzerablauf**
   - Anmeldung
   - Ideen erstellen/ansehen
   - Berechtigungen nach Rolle testen

### Code Review Checkliste

- [ ] Werden Passwort-Hashes mit PasswordUtil generiert?
- [ ] Gibt es Tests für neue Features?
- [ ] Wird Fehlerprotokollierung für Fehlerfälle hinzugefügt?
- [ ] Sind Konfigurationswerte externalisiert (nicht hardcodiert)?
- [ ] Behandelt der Code Grenzfälle und Validierung?

---

## 4. Validierung und Integritätsprüfungen

### Automatisierte Validierungswerkzeuge

| Werkzeug | Zweck | Wann ausführen |
|------|---------|-------------|
| `ValidateDatabase` | Seed-Daten Datenbank verifizieren | Nach DB Init, vor Bereitstellung |
| `PasswordHashGenerator` | BCrypt Hashes generieren | Beim Hinzufügen neuer Test-Benutzer |
| `AuthenticationIntegrationTest` | Anmeldesystem testen | Vor jeder Bereitstellung |

### Anwendungs-Integritätsprüfung

Fügen Sie dies zu Ihrer Bereitstellungs-Checkliste hinzu:

```bash
# 1. Datenbankverbindung überprüfen
psql -U ideaboard_user -h localhost -d ideaboard -c "SELECT COUNT(*) FROM users;"

# 2. GlassFish läuft überprüfen
curl http://localhost:8080/ideaboard/api/ideas

# 3. Frontend kann sich mit Backend verbinden überprüfen
curl http://localhost:3000

# 4. Authentifizierung verifizieren
curl -X POST http://localhost:8080/ideaboard/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

---

## 5. Fehlerbehandlung und Protokollierung

### Best Practices für Protokollierung

Die Anwendung enthält jetzt umfangreiche Protokollierung:

**Authentifizierungsereignisse werden protokolliert:**
- `INFO`: Erfolgreiche Anmeldungen
- `WARN`: Fehlgeschlagene Anmeldeversuche
- `DEBUG`: Details zu Anmeldeversuchen

**Logs auf Probleme überprüfen:**
```bash
# GlassFish Server Log
tail -f "C:/glassfish-7.1.0/glassfish7/glassfish/domains/domain1/logs/server.log"
```

### Häufige Fehlermuster

| Fehler | Ursache | Lösung |
|-------|-------|----------|
| "Invalid username or password" | Falsche Anmeldeinformationen ODER schlechter Passwort-Hash | Führen Sie ValidateDatabase aus, überprüfen Sie init.sql Hashes |
| "Account is deactivated" | Benutzer is_active=false | Überprüfen Sie Datenbank: `SELECT * FROM users WHERE username='...'` |
| 401 Unauthorized | Token abgelaufen oder ungültig | localStorage löschen, erneut anmelden |
| Database connection failed | PostgreSQL läuft nicht | PostgreSQL Service starten |
| JDBC pool error | Falsche Datenbankdaten | Überprüfen Sie GlassFish JDBC Konfiguration |

### Debugging von Authentifizierungsproblemen

```bash
# 1. Benutzer existiert überprüfen
psql -U ideaboard_user -d ideaboard -c "SELECT username, is_active FROM users WHERE username='admin';"

# 2. Passwort-Hash manuell testen
cd backend
mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.PasswordHashGenerator"

# 3. GlassFish Logs auf detaillierten Fehler überprüfen
grep -i "auth" glassfish7/glassfish/domains/domain1/logs/server.log

# 4. Validierung ausführen
mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"
```

---

## 6. Kontinuierliche Integration

### Empfohlene CI/CD Pipeline

```yaml
# Beispiel GitHub Actions / GitLab CI Pipeline

stages:
  - build
  - test
  - validate
  - deploy

build:
  script:
    - mvn clean package -DskipTests

test:
  script:
    - mvn test

validate_database:
  script:
    - psql -f database/init.sql
    - mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"

integration_tests:
  script:
    - mvn test -Dtest=AuthenticationIntegrationTest

deploy:
  script:
    - ./start-project.ps1
    - # Smoke Tests ausführen
```

### Pre-Commit Hooks

Erstelle `.git/hooks/pre-commit`:
```bash
#!/bin/bash
echo "Starte Pre-Commit Überprüfungen..."

# Führe Tests aus
mvn test || {
    echo "Tests fehlgeschlagen! Commit abgebrochen."
    exit 1
}

echo "Alle Überprüfungen bestanden!"
```

---

## 7. Fehlerbehebung

### Schnelle Diagnose-Befehle

```bash
# Überprüfen Sie, dass alle Services laufen
netstat -an | findstr "8080 3000 5432"

# Datenbank-Benutzeranzahl
psql -U ideaboard_user -d ideaboard -c "SELECT COUNT(*) FROM users;"

# Admin-Anmeldungs-API testen
curl -X POST http://localhost:8080/ideaboard/api/auth/login \
  -H "Content-Type: application/json" \
  -d "{\"username\":\"admin\",\"password\":\"admin123\"}"

# GlassFish Bereitstellungsstatus überprüfen
asadmin list-applications
```

### Häufige Probleme und Lösungen

#### Problem: "Kann nicht mit admin/admin123 anmelden"

**Diagnose:**
```bash
cd backend
mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"
```

**Lösungen:**
1. Wenn Validierung fehlschlägt, sind Passwort-Hashes falsch:
   ```bash
   mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.FixPasswordHashes"
   ```

2. Wenn Benutzer nicht existiert, Datenbank neu initialisieren:
   ```bash
   psql -U ideaboard_user -d ideaboard -f database/init.sql
   ```

#### Problem: "Tests bestanden, aber Anmeldung schlägt fehl"

**Überprüfen Sie, dass Frontend das richtige Backend trifft:**
```javascript
// frontend/vite.config.ts
proxy: {
  '/api': {
    target: 'http://localhost:8080/ideaboard',  // ← Muss Backend URL entsprechen
    changeOrigin: true,
  },
}
```

**API Endpunkt verifizieren:**
```bash
# Sollte JWT Token zurückgeben
curl -X POST http://localhost:8080/ideaboard/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

#### Problem: "Datenbank-Validierung schlägt fehl"

1. Überprüfen Sie, dass PostgreSQL läuft
2. Verifizieren Sie Datenbankzugangsangaben in Validierungsskript
3. Stellen Sie sicher, dass Datenbank initialisiert wurde: `psql -f database/init.sql`
4. Überprüfen Sie Datenbankberechtigungen: `GRANT ALL ON DATABASE ideaboard TO ideaboard_user;`

---

## Zusammenfassung: Präventions-Checkliste

✅ **Vor dem Programmieren:**
- Rufen Sie den neuesten Code ab
- Führen Sie `start-project.ps1` aus, um die Umgebung zu verifizieren

✅ **Während der Entwicklung:**
- Schreiben Sie Tests für neue Features
- Fügen Sie Protokollierung für Fehlerfälle hinzu
- Verwenden Sie Validierungswerkzeuge für Datenbankänderungen

✅ **Vor dem Commit:**
- Führen Sie `mvn test` aus
- Führen Sie `ValidateDatabase` aus, wenn die Datenbank geändert wurde
- Testen Sie manuell im Browser
- Überprüfen Sie auf Fehler in Logs

✅ **Vor der Bereitstellung:**
- Alle Tests bestehen
- Datenbank-Validierung bestanden
- API Tests bestanden (curl Befehle)
- Frontend verbindet sich erfolgreich
- Dokumentation aktualisiert

✅ **Nach der Bereitstellung:**
- Führen Sie Smoke Tests aus
- Überwachen Sie Logs auf Fehler
- Überprüfen Sie, dass Benutzer anmelden kann
- Überprüfen Sie, dass alle kritischen Features funktionieren

---

## Schnellreferenz

```bash
# Anwendung starten
.\start-project.ps1

# Datenbank validieren
cd backend && mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.ValidateDatabase"

# Tests ausführen
cd backend && mvn test

# Passwort-Hashes reparieren
cd backend && mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.FixPasswordHashes"

# Passwort-Hashes generieren
cd backend && mvn exec:java -Dexec.mainClass="com.gfos.ideaboard.util.PasswordHashGenerator"

# Anmeldungs-API testen
curl -X POST http://localhost:8080/ideaboard/api/auth/login -H "Content-Type: application/json" -d '{"username":"admin","password":"admin123"}'

# Logs anzeigen
tail -f glassfish7/glassfish/domains/domain1/logs/server.log
```

---

## Hilfe anfordern

Wenn Sie auf Probleme stoßen:

1. Überprüfen Sie den Abschnitt Fehlerbehebung in diesem Handbuch
2. Führen Sie `ValidateDatabase` aus, um das Problem zu identifizieren
3. Überprüfen Sie GlassFish Logs für detaillierte Fehler
4. Überprüfen Sie die Test-Ergebnisse: `mvn test`
5. Überprüfen Sie, dass die Konfiguration diesem Handbuch entspricht

**Denken Sie daran**: Die meisten Probleme können durch regelmäßige Ausführung von Validierungswerkzeugen nach Änderungen verhindert werden!
