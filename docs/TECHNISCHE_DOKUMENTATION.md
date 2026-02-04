# Technische Dokumentation
## GFOS Digital Idea Board (Ideenbrett)

**Version:** 1.0.0
**Datum:** Januar 2026
**Projekt:** GFOS Innovationspreis 2026

---

## Inhaltsverzeichnis

1. [Einleitung](#1-einleitung)
2. [Technologieübersicht](#2-technologieübersicht)
3. [Systemarchitektur](#3-systemarchitektur)
4. [Backend-Architektur](#4-backend-architektur)
5. [Frontend-Architektur](#5-frontend-architektur)
6. [Sicherheitsarchitektur](#6-sicherheitsarchitektur)
7. [Gamification-System](#7-gamification-system)
8. [Deployment und Infrastruktur](#8-deployment-und-infrastruktur)
9. [Zusammenfassung](#9-zusammenfassung)

---

## 1. Einleitung

### 1.1 Projektübersicht

Das **GFOS Digital Idea Board** ist eine webbasierte Innovationsmanagement-Plattform, die im Rahmen des GFOS Innovationspreises 2026 entwickelt wurde. Die Anwendung ermöglicht es Mitarbeitern, innovative Ideen einzureichen, gemeinsam zu diskutieren und kollaborativ weiterzuentwickeln.

### 1.2 Kernfunktionen

Die Plattform bietet folgende Hauptfunktionen:

- **Ideenmanagement**: Einreichen, Bearbeiten und Verwalten von Innovationsideen
- **Kollaboration**: Kommentare, Diskussionsgruppen und Direktnachrichten
- **Gamification**: XP-Punkte, Level und Badges zur Motivation
- **Umfragen**: Erstellen und Durchführen von Abstimmungen
- **Benachrichtigungen**: Echtzeit-Benachrichtigungen über Aktivitäten
- **Administration**: Benutzerverwaltung und Audit-Logging

### 1.3 Zielgruppe

Die Anwendung richtet sich an alle Mitarbeiter eines Unternehmens, unabhängig von ihrer technischen Expertise. Durch ein intuitives Design und Gamification-Elemente wird die aktive Teilnahme am Innovationsprozess gefördert.

---

## 2. Technologieübersicht

### 2.1 Technologie-Stack im Überblick

```
┌─────────────────────────────────────────────────────────────┐
│                      PRÄSENTATIONSSCHICHT                    │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  React 18  │  TypeScript  │  Tailwind CSS  │  Vite     │ │
│  └─────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                        API-SCHICHT                           │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Jakarta EE 10  │  JAX-RS (Jersey)  │  JWT-Auth        │ │
│  └─────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                    GESCHÄFTSLOGIK-SCHICHT                    │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  Java 17  │  CDI  │  Service-Layer  │  GlassFish 7     │ │
│  └─────────────────────────────────────────────────────────┘ │
├─────────────────────────────────────────────────────────────┤
│                     DATENPERSISTENZ-SCHICHT                  │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  JPA (EclipseLink)  │  PostgreSQL 15  │  Named Queries │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 2.2 Backend-Technologien

| Technologie | Version | Verwendungszweck |
|-------------|---------|------------------|
| Java | 17 LTS | Programmiersprache |
| Jakarta EE | 10.0.0 | Enterprise-Standard |
| Jersey (JAX-RS) | 3.1.3 | REST-API-Framework |
| EclipseLink JPA | 4.0.2 | Object-Relational Mapping |
| PostgreSQL | 15 | Relationale Datenbank |
| GlassFish | 7.0.11 | Application Server |
| jjwt | 0.12.3 | JWT-Token-Verwaltung |
| BCrypt | 0.10.2 | Passwort-Hashing |
| iText | 8.0.2 | PDF-Export |

**Warum diese Technologien?**

- **Java 17 LTS**: Als Long-Term-Support-Version bietet Java 17 Stabilität und moderne Sprachfeatures wie Records und Pattern Matching. Die breite Unterstützung in der Enterprise-Welt garantiert langfristige Wartbarkeit.

- **Jakarta EE 10**: Der Industriestandard für Enterprise-Java-Anwendungen. Die Migration von javax.* auf jakarta.* Namespaces stellt Zukunftssicherheit sicher. Jakarta EE bietet ein bewährtes Ökosystem mit standardisierten APIs.

- **GlassFish 7**: Als Referenzimplementierung für Jakarta EE 10 bietet GlassFish vollständige Spezifikationsunterstützung, eine integrierte Admin-Konsole und ist Open Source.

- **PostgreSQL 15**: Eine ausgereifte, zuverlässige Open-Source-Datenbank mit exzellenter Performance, ACID-Konformität und umfangreichen Funktionen für komplexe Abfragen.

- **EclipseLink**: Nahtlose Integration mit GlassFish und vollständige JPA-Spezifikationsunterstützung. Die Named-Query-Funktionalität ermöglicht optimierte, vorkompilierte Datenbankabfragen.

### 2.3 Frontend-Technologien

| Technologie | Version | Verwendungszweck |
|-------------|---------|------------------|
| React | 18.2.0 | UI-Komponentenbibliothek |
| TypeScript | 5.3.3 | Statische Typisierung |
| Vite | 5.0.10 | Build-Tool |
| Tailwind CSS | 3.4.0 | Utility-First CSS |
| Axios | 1.6.2 | HTTP-Client |
| React Router | 6.21.1 | Client-seitiges Routing |
| Recharts | 2.10.3 | Datenvisualisierung |
| Headless UI | 1.7.17 | Barrierefreie UI-Komponenten |

**Warum diese Technologien?**

- **React 18**: Die führende UI-Bibliothek mit einer riesigen Community, exzellenter Dokumentation und einem ausgereiften Ökosystem. React 18 bietet Concurrent Features für bessere Performance und Benutzererfahrung.

- **TypeScript**: Statische Typisierung fängt Fehler bereits zur Compile-Zeit ab. Dies verbessert die Code-Qualität, erleichtert das Refactoring und bietet bessere IDE-Unterstützung. Die Typdefinitionen dienen gleichzeitig als Dokumentation.

- **Vite**: Im Vergleich zu Webpack bietet Vite deutlich schnellere Entwicklungszyklen durch native ES-Module und blitzschnelles Hot Module Replacement (HMR). Dies beschleunigt die Entwicklung erheblich.

- **Tailwind CSS**: Der Utility-First-Ansatz ermöglicht schnelles Prototyping und konsistentes Design ohne separates CSS. Die geringe Bundle-Größe durch PurgeCSS optimiert die Ladezeit.

### 2.4 Infrastruktur

| Technologie | Verwendungszweck |
|-------------|------------------|
| Docker | Container-Runtime |
| Docker Compose | Multi-Container-Orchestrierung |
| Nginx | Reverse Proxy für Frontend |

**Warum Containerisierung?**

Docker stellt sicher, dass die Anwendung in jeder Umgebung identisch läuft – vom Entwickler-Laptop bis zur Produktionsumgebung. Dies eliminiert das klassische "Es funktioniert auf meinem Rechner"-Problem und ermöglicht einfaches Deployment.

---

## 3. Systemarchitektur

### 3.1 Drei-Schichten-Architektur

Die Anwendung folgt einer klassischen Drei-Schichten-Architektur (Three-Tier Architecture), die eine klare Trennung der Verantwortlichkeiten gewährleistet.

```
                    ┌─────────────────────────────────────┐
                    │           BENUTZER                   │
                    │      (Browser/Mobile)                │
                    └──────────────┬──────────────────────┘
                                   │
                                   ▼
┌──────────────────────────────────────────────────────────────────────┐
│                     PRÄSENTATIONSSCHICHT                              │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                    React Frontend (Port 3000)                   │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────────┐   │  │
│  │  │  Pages   │  │ Services │  │ Context  │  │  Components  │   │  │
│  │  └──────────┘  └──────────┘  └──────────┘  └──────────────┘   │  │
│  └────────────────────────────────────────────────────────────────┘  │
│                              Nginx                                    │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │ HTTP/REST
                                   ▼
┌──────────────────────────────────────────────────────────────────────┐
│                        API-SCHICHT                                    │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │               GlassFish Server (Port 8080)                      │  │
│  │  ┌──────────────┐  ┌────────────────┐  ┌──────────────────┐   │  │
│  │  │  Resources   │  │  JWT-Filter    │  │  CORS-Filter     │   │  │
│  │  │  (REST API)  │  │  (Security)    │  │  (Cross-Origin)  │   │  │
│  │  └──────────────┘  └────────────────┘  └──────────────────┘   │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │
                                   ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    GESCHÄFTSLOGIK-SCHICHT                             │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                     Service Layer                               │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │  │
│  │  │ AuthService │  │ IdeaService │  │ GamificationService │    │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘    │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │  │
│  │  │ UserService │  │GroupService │  │ NotificationService │    │  │
│  │  └─────────────┘  └─────────────┘  └─────────────────────┘    │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────┬───────────────────────────────────┘
                                   │ JPA
                                   ▼
┌──────────────────────────────────────────────────────────────────────┐
│                    DATENPERSISTENZ-SCHICHT                            │
│  ┌────────────────────────────────────────────────────────────────┐  │
│  │                  PostgreSQL (Port 5432)                         │  │
│  │  ┌─────────┐  ┌─────────┐  ┌─────────┐  ┌─────────────────┐   │  │
│  │  │  users  │  │  ideas  │  │ surveys │  │  notifications  │   │  │
│  │  └─────────┘  └─────────┘  └─────────┘  └─────────────────┘   │  │
│  └────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────────┘
```

### 3.2 Begründung der Architektur

**Warum Drei-Schichten-Architektur?**

1. **Klare Verantwortlichkeiten**: Jede Schicht hat eine definierte Aufgabe. Die Präsentationsschicht kümmert sich um die Benutzeroberfläche, die Geschäftslogik-Schicht um die Anwendungslogik und die Datenschicht um die Persistenz.

2. **Unabhängige Skalierung**: Jede Schicht kann unabhängig skaliert werden. Bei hoher Last kann beispielsweise nur die API-Schicht horizontal skaliert werden.

3. **Austauschbarkeit**: Technologien können in einzelnen Schichten ausgetauscht werden, ohne die anderen zu beeinflussen. Das Frontend könnte theoretisch durch eine Mobile-App ersetzt werden.

4. **Testbarkeit**: Die klare Trennung ermöglicht isolierte Unit-Tests für jede Schicht.

5. **Team-Organisation**: Verschiedene Teams können parallel an unterschiedlichen Schichten arbeiten.

### 3.3 Kommunikationsfluss

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   Browser   │────▶│   Nginx     │────▶│  GlassFish  │────▶│ PostgreSQL  │
│             │◀────│   (Proxy)   │◀────│  (Backend)  │◀────│             │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │                    │
      │    HTTP/HTTPS     │    HTTP REST      │       JDBC         │
      └───────────────────┴───────────────────┴────────────────────┘

Datenformat: JSON (API) / SQL (Datenbank)
Authentifizierung: JWT Bearer Token
```

---

## 4. Backend-Architektur

### 4.1 Paketstruktur

```
com.gfos.ideaboard/
├── config/          # Anwendungskonfiguration (3 Dateien)
├── dto/             # Data Transfer Objects (23 Dateien)
├── entity/          # JPA-Entitäten (18 Klassen + 6 Enums = 24 Dateien)
├── exception/       # Fehlerbehandlung (2 Dateien)
├── resource/        # REST-API-Endpunkte (12 Dateien)
├── security/        # JWT & Authentifizierung (4 Dateien)
├── service/         # Geschäftslogik (14 Dateien)
└── util/            # Hilfsfunktionen (3 Dateien)
```

### 4.2 Entity-Schicht (JPA-Entitäten)

Die Entity-Schicht bildet das Datenmodell der Anwendung ab. Insgesamt wurden **19 Entity-Klassen** und **5 Enum-Typen** (24 Dateien) definiert, die über JPA (Java Persistence API) mit der PostgreSQL-Datenbank verbunden sind.

#### Kernentitäten und ihre Beziehungen

```
                              ┌──────────────┐
                              │     User     │
                              │──────────────│
                              │ - username   │
                              │ - email      │
                              │ - role       │
                              │ - xpPoints   │
                              │ - level      │
                              └──────┬───────┘
                                     │
          ┌──────────────────────────┼──────────────────────────┐
          │                          │                          │
          ▼                          ▼                          ▼
   ┌──────────────┐          ┌──────────────┐          ┌──────────────┐
   │     Idea     │          │    Survey    │          │   Message    │
   │──────────────│          │──────────────│          │──────────────│
   │ - title      │          │ - question   │          │ - content    │
   │ - description│          │ - options    │          │ - isRead     │
   │ - status     │          │ - votes      │          │ - createdAt  │
   │ - progress   │          └──────────────┘          └──────────────┘
   └──────┬───────┘
          │
   ┌──────┴──────┬──────────────┬──────────────┐
   │             │              │              │
   ▼             ▼              ▼              ▼
┌─────────┐ ┌─────────┐  ┌───────────┐  ┌─────────────┐
│ Comment │ │  Like   │  │ IdeaGroup │  │ Checklist   │
│─────────│ │─────────│  │───────────│  │─────────────│
│ content │ │ userId  │  │ members   │  │ title       │
│reactions│ │ ideaId  │  │ messages  │  │ isCompleted │
└─────────┘ └─────────┘  └───────────┘  └─────────────┘
```

#### Übersicht aller Entity-Klassen (19)

| Entität | Beschreibung | Wichtige Felder |
|---------|--------------|-----------------|
| **User** | Benutzerkonten mit Rollen und Gamification | username, email, role, xpPoints, level |
| **Idea** | Innovationsideen mit Status-Tracking | title, description, status, progressPercentage, tags |
| **Comment** | Kommentare zu Ideen | content, authorId, ideaId, reactionCount |
| **CommentReaction** | Emoji-Reaktionen auf Kommentare | emoji, userId, commentId |
| **Like** | Gefällt-mir-Markierungen | userId, ideaId, createdAt |
| **FileAttachment** | Dateianhänge für Ideen | filename, mimeType, fileSize, filePath |
| **IdeaGroup** | Diskussionsgruppen pro Idee | name, description, createdBy |
| **GroupMember** | Gruppenmitgliedschaften | role (CREATOR, MEMBER), joinedAt |
| **GroupMessage** | Nachrichten in Gruppen | content, senderId, createdAt |
| **GroupMessageRead** | Lesestatus von Nachrichten | messageId, userId, readAt |
| **Message** | Direktnachrichten zwischen Benutzern | sender, recipient, content, isRead |
| **Survey** | Umfragen/Abstimmungen | question, isAnonymous, allowMultipleVotes, expiresAt |
| **SurveyOption** | Umfrageoptionen | optionText, voteCount, displayOrder |
| **SurveyVote** | Benutzerabstimmungen | surveyId, optionId, userId |
| **Badge** | Achievement-Abzeichen | name, displayName, description, xpReward |
| **UserBadge** | Verdiente Abzeichen | userId, badgeId, earnedAt |
| **Notification** | Systembenachrichtigungen | type, title, message, isRead, link |
| **ChecklistItem** | To-Do-Einträge für Ideen | title, isCompleted, ordinalPosition |
| **AuditLog** | Aktivitätsprotokoll | action, entityType, entityId, oldValue, newValue |

#### Enum-Typen (5)

| Enum | Werte | Verwendung |
|------|-------|------------|
| **UserRole** | EMPLOYEE, PROJECT_MANAGER, ADMIN | Benutzerrollen |
| **IdeaStatus** | CONCEPT, IN_PROGRESS, COMPLETED | Ideen-Lebenszyklus |
| **NotificationType** | LIKE, COMMENT, REACTION, STATUS_CHANGE, BADGE_EARNED, LEVEL_UP, MENTION, MESSAGE | Benachrichtigungsarten |
| **GroupMemberRole** | CREATOR, MEMBER | Gruppenrollen |
| **AuditAction** | CREATE, UPDATE, DELETE, STATUS_CHANGE, LOGIN, LOGOUT | Audit-Aktionen |

#### Design-Entscheidungen

**VARCHAR statt PostgreSQL ENUMs**: Wir verwenden VARCHAR-Spalten anstelle von PostgreSQL-nativen ENUM-Typen. Dies bietet bessere JPA-Kompatibilität und ermöglicht einfachere Datenbankmigrationen, da ENUMs in PostgreSQL schwer zu ändern sind.

**Named Queries**: Häufig verwendete Abfragen werden als @NamedQuery definiert. Dies ermöglicht Vorkompilierung und Optimierung durch den Persistence-Provider.

```java
@NamedQuery(name = "Idea.findByCategory",
            query = "SELECT i FROM Idea i WHERE i.category = :category")
@NamedQuery(name = "Idea.findTopByLikes",
            query = "SELECT i FROM Idea i ORDER BY i.likeCount DESC")
```

**Cascade-Löschung**: Beim Löschen einer Idee werden automatisch alle zugehörigen Kommentare, Likes und Anhänge gelöscht. Dies stellt die referentielle Integrität sicher.

### 4.3 DTO-Schicht (Data Transfer Objects)

Die DTO-Schicht (20 Klassen) trennt die interne Datenrepräsentation von der API. Dies bietet mehrere Vorteile:

| DTO | Zweck |
|-----|-------|
| **AuthRequest/AuthResponse** | Login-Anfrage und -Antwort mit Token |
| **RegisterRequest** | Registrierungsdaten mit Validierung |
| **UserDTO** | Benutzerprofil ohne sensible Daten |
| **IdeaDTO** | Idee mit Autor, Tags, Anhängen, Likes |
| **CommentDTO** | Kommentar mit Reaktionen |
| **SurveyDTO** | Umfrage mit Optionen und Abstimmungsstatus |
| **NotificationDTO** | Benachrichtigung mit Typ und Link |
| **IdeaGroupDTO** | Gruppe mit Mitgliedern und letzter Nachricht |
| **GroupMessageDTO** | Gruppennachricht mit Sender |
| **MessageDTO** | Direktnachricht zwischen Benutzern |
| **ConversationDTO** | Konversationsübersicht mit ungelesenen |
| **BadgeDTO/UserBadgeDTO** | Badge-Informationen |
| **FileAttachmentDTO** | Datei-Metadaten |
| **ChecklistItemDTO** | To-Do-Einträge |
| **ChecklistToggleResponse** | Antwort für Checklist-Toggle-Operationen |
| **GroupMemberDTO** | Gruppenmitglied-Informationen |
| **SendMessageRequest** | Anfrage zum Senden von Nachrichten |
| **AuditLogDTO** | Audit-Protokolleintrag |

**Warum DTOs?**

1. **API-Stabilität**: Änderungen an Entities brechen nicht die API
2. **Sicherheit**: Sensible Felder (z.B. passwordHash) werden nicht exponiert
3. **Flexibilität**: DTOs können berechnete Felder enthalten (z.B. isLikedByCurrentUser)
4. **Validierung**: Input-DTOs können @NotNull, @Size etc. nutzen

### 4.4 Service-Schicht (Geschäftslogik)

Die Service-Schicht (14 Klassen) kapselt die gesamte Geschäftslogik und trennt sie von der API-Schicht. Jeder Service wird mittels CDI (Contexts and Dependency Injection) verwaltet.

#### Übersicht der Services

| Service | Verantwortlichkeit |
|---------|-------------------|
| **AuthService** | Authentifizierung, Registrierung, Token-Verwaltung |
| **UserService** | Benutzerverwaltung, Profil-Updates, Leaderboard |
| **IdeaService** | Ideen-CRUD, Filterung, Status-Management |
| **CommentService** | Kommentare erstellen/löschen, Reaktionen |
| **LikeService** | Like-Verwaltung, wöchentliches Limit |
| **GamificationService** | XP-Vergabe, Level-Berechnung, Badges |
| **GroupService** | Gruppen-Verwaltung, Mitgliedschaften |
| **MessageService** | Direktnachrichten zwischen Benutzern |
| **SurveyService** | Umfragen erstellen, Abstimmungen |
| **NotificationService** | Benachrichtigungen erstellen und senden |
| **ChecklistService** | Checklisten-Verwaltung, Fortschrittsberechnung |
| **FileService** | Datei-Upload und -Verwaltung |
| **ExportService** | PDF/CSV-Export |
| **AuditService** | Aktivitätsprotokollierung |

#### Wichtige Service-Funktionen

**IdeaService** (376 Zeilen):
- Komplexe Filterung nach Kategorie, Status, Autor und Suchbegriff
- Paginierung für große Datenmengen
- Automatische Erstellung einer Diskussionsgruppe bei neuen Ideen
- XP-Vergabe bei Ideen-Erstellung und -Abschluss

**GamificationService**:
- XP-Konstanten: Idee einreichen (+50 XP), Like erhalten (+10 XP), Kommentar (+5 XP), Idee abgeschlossen (+100 XP)
- Level-Schwellenwerte: [0, 100, 300, 600, 1000, 1500, 2500, 4000, 6000, 10000]
- Automatische Badge-Prüfung bei XP-Änderungen

**Warum Service-Layer-Pattern?**

1. **Testbarkeit**: Services können mit Mock-Objekten isoliert getestet werden
2. **Wiederverwendbarkeit**: Geschäftslogik kann von mehreren Endpunkten genutzt werden
3. **Transaktionsmanagement**: @Transactional auf Service-Methoden
4. **Kapselung**: Änderungen an der Logik beeinflussen nicht die API-Schicht

### 4.5 REST-API-Schicht (Resources)

Die Resource-Klassen (12 Klassen mit 79 Endpunkten) definieren die REST-API-Endpunkte der Anwendung.

#### API-Struktur

| Resource | Basis-Pfad | Endpunkte | Beschreibung |
|----------|------------|-----------|--------------|
| AuthResource | `/api/auth` | 4 | Login, Registrierung, Token-Refresh, Logout |
| UserResource | `/api/users` | 12 | Benutzerverwaltung, Profile, Badges, Leaderboard |
| IdeaResource | `/api/ideas` | 20 | Ideen-CRUD, Kommentare, Likes, Dateien, Checklisten |
| CommentResource | `/api/comments` | 3 | Kommentar-Löschung, Emoji-Reaktionen |
| GroupResource | `/api/groups` | 12 | Diskussionsgruppen, Mitgliedschaften, Nachrichten |
| MessageResource | `/api/messages` | 7 | Direktnachrichten, Konversationen |
| SurveyResource | `/api/surveys` | 6 | Umfragen erstellen, abstimmen |
| NotificationResource | `/api/notifications` | 4 | Benachrichtigungen verwalten |
| DashboardResource | `/api/dashboard` | 4 | Statistiken, Top-Ideen, Aktivität |
| AuditResource | `/api/audit-logs` | 2 | Audit-Logs abrufen (Admin) |
| ExportResource | `/api/export` | 4 | CSV/PDF-Export von Daten |
| HealthResource | `/api/health` | 1 | Docker Health-Check |
| | **Gesamt** | **79** | |

#### Vollständige Endpunkt-Übersicht (79 Endpunkte)

**IdeaResource** (`/api/ideas`) - 20 Endpunkte:
```
GET    /ideas                     - Ideen mit Filterung/Paginierung
GET    /ideas/{id}                - Einzelne Idee abrufen
POST   /ideas                     - Neue Idee erstellen
PUT    /ideas/{id}                - Idee aktualisieren
PUT    /ideas/{id}/status         - Status und Fortschritt ändern
DELETE /ideas/{id}                - Idee löschen (Admin)
POST   /ideas/{id}/like           - Idee liken
DELETE /ideas/{id}/like           - Like entfernen
GET    /ideas/{id}/comments       - Kommentare abrufen
POST   /ideas/{id}/comments       - Kommentar hinzufügen
GET    /ideas/categories          - Kategorien abrufen
GET    /ideas/tags/popular        - Beliebte Tags
POST   /ideas/{id}/files          - Datei hochladen
GET    /ideas/{id}/files/{fileId} - Datei herunterladen
DELETE /ideas/{id}/files/{fileId} - Datei löschen
GET    /ideas/{id}/checklist      - Checkliste abrufen
POST   /ideas/{id}/checklist      - Checklist-Item erstellen
PATCH  /ideas/{id}/checklist/{itemId}/toggle - Item abhaken
PUT    /ideas/{id}/checklist/{itemId}        - Item bearbeiten
DELETE /ideas/{id}/checklist/{itemId}        - Item löschen
```

**UserResource** (`/api/users`) - 12 Endpunkte:
```
GET    /users/me                  - Eigenes Profil
PUT    /users/me                  - Profil aktualisieren
PUT    /users/me/password         - Passwort ändern
GET    /users/me/likes/remaining  - Verbleibende Likes (Woche)
GET    /users/me/badges           - Eigene Badges
GET    /users/{id}/badges         - Benutzer-Badges
GET    /users/badges              - Alle verfügbaren Badges
GET    /users/leaderboard         - Rangliste
GET    /users                     - Alle Benutzer (Admin)
GET    /users/{id}                - Benutzer abrufen (Admin)
PUT    /users/{id}/role           - Rolle ändern (Admin)
PUT    /users/{id}/status         - Status ändern (Admin)
```

**GroupResource** (`/api/groups`) - 12 Endpunkte:
```
GET    /groups                    - Eigene Gruppen
GET    /groups/{id}               - Gruppe abrufen
GET    /groups/idea/{ideaId}      - Gruppe einer Idee
POST   /groups/{id}/join          - Gruppe beitreten
POST   /groups/idea/{ideaId}/join - Gruppe via Idee beitreten
DELETE /groups/{id}/leave         - Gruppe verlassen
GET    /groups/{id}/messages      - Nachrichten abrufen
POST   /groups/{id}/messages      - Nachricht senden
PUT    /groups/{id}/messages/read - Alle als gelesen markieren
GET    /groups/{id}/membership    - Mitgliedschaft prüfen
GET    /groups/idea/{ideaId}/membership - Mitgliedschaft via Idee
GET    /groups/unread-count       - Ungelesene Nachrichten
```

**Weitere Resources** (39 Endpunkte in 9 Klassen):
- **AuthResource**: Login, Register, Refresh, Logout (4)
- **CommentResource**: Delete, Reactions (3)
- **MessageResource**: Send, Conversations, Read-Status (7)
- **SurveyResource**: CRUD, Vote (6)
- **NotificationResource**: List, Unread, Mark Read (4)
- **DashboardResource**: Statistics, Top Ideas, Activity (4)
- **AuditResource**: Logs abrufen (2)
- **ExportResource**: CSV/PDF-Export (4)
- **HealthResource**: Health Check (1)

#### Design-Prinzipien

- **RESTful**: Ressourcenorientierte URLs mit Standard-HTTP-Verben
- **Konsistente Antworten**: Einheitliches JSON-Format mit Status und Zeitstempel
- **Paginierung**: Alle Listen-Endpunkte unterstützen Paginierung
- **Fehlerbehandlung**: Zentralisierte Exception-Mapper für konsistente Fehlermeldungen

---

## 5. Frontend-Architektur

### 5.1 Projektstruktur

```
frontend/src/
├── components/      # Wiederverwendbare UI-Komponenten
│   ├── Layout.tsx              # Haupt-Layout mit Navigation
│   └── NotificationDropdown.tsx # Benachrichtigungs-Dropdown
├── context/         # React Context Provider
│   ├── AuthContext.tsx         # Authentifizierungszustand
│   └── ThemeContext.tsx        # Theme-Verwaltung (Hell/Dunkel)
├── pages/           # Seiten-Komponenten (10 Dateien)
│   ├── LoginPage.tsx
│   ├── RegisterPage.tsx
│   ├── DashboardPage.tsx
│   ├── IdeasPage.tsx
│   ├── IdeaDetailPage.tsx
│   ├── CreateIdeaPage.tsx
│   ├── SurveysPage.tsx
│   ├── MessagesPage.tsx
│   ├── ProfilePage.tsx
│   └── AdminPage.tsx
├── services/        # API-Client-Services (9 Dateien)
│   ├── api.ts                  # Axios-Instanz mit Interceptors
│   ├── authService.ts
│   ├── ideaService.ts
│   ├── userService.ts
│   ├── groupService.ts
│   ├── messageService.ts
│   ├── surveyService.ts
│   ├── dashboardService.ts
│   └── exportService.ts
├── types/           # TypeScript-Typdefinitionen
│   └── index.ts
├── App.tsx          # Haupt-Routing-Komponente
├── main.tsx         # React-Einstiegspunkt
└── index.css        # Globale Styles (Tailwind)
```

### 5.2 Komponenten-Architektur

```
                        ┌─────────────────────────────────┐
                        │           main.tsx              │
                        │  (React Root + Providers)       │
                        └───────────────┬─────────────────┘
                                        │
                        ┌───────────────┴─────────────────┐
                        │                                 │
                ┌───────▼────────┐              ┌────────▼────────┐
                │  AuthProvider  │              │  ThemeProvider  │
                │  (Kontext)     │              │  (Kontext)      │
                └───────┬────────┘              └────────┬────────┘
                        │                                │
                        └───────────────┬────────────────┘
                                        │
                        ┌───────────────▼─────────────────┐
                        │           App.tsx               │
                        │      (React Router)             │
                        └───────────────┬─────────────────┘
                                        │
                        ┌───────────────▼─────────────────┐
                        │          Layout.tsx             │
                        │  (Navigation + Sidebar)         │
                        └───────────────┬─────────────────┘
                                        │
        ┌───────────────┬───────────────┼───────────────┬───────────────┐
        │               │               │               │               │
  ┌─────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐  ┌───────▼─────┐
  │ Dashboard │  │   Ideas   │  │ Messages  │  │  Surveys  │  │   Profile   │
  │   Page    │  │   Page    │  │   Page    │  │   Page    │  │    Page     │
  └───────────┘  └───────────┘  └───────────┘  └───────────┘  └─────────────┘
```

### 5.3 State Management

**Warum React Context statt Redux?**

Für diese Anwendung wurde bewusst React Context anstelle von Redux gewählt:

1. **Einfachheit**: Die Anwendung hat überschaubare globale Zustandsanforderungen (Authentifizierung, Theme)
2. **Geringere Komplexität**: Kein zusätzliches Boilerplate für Actions, Reducers, Store
3. **Native React-Lösung**: Context ist in React eingebaut und erfordert keine zusätzliche Abhängigkeit
4. **Performance**: Für unseren Anwendungsfall ausreichend, da die meisten Zustandsänderungen lokal sind

#### AuthContext

```typescript
interface AuthContextType {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (credentials: LoginRequest) => Promise<void>;
  register: (data: RegisterRequest) => Promise<void>;
  logout: () => void;
  updateUser: (user: User) => void;
}
```

Der AuthContext verwaltet:
- Aktuellen Benutzerzustand
- JWT-Token (gespeichert in localStorage)
- Authentifizierungsstatus
- Login/Logout-Funktionen

### 5.4 API-Service-Schicht

Jeder Service kapselt die API-Kommunikation für einen bestimmten Bereich:

```
┌──────────────────────────────────────────────────────────────────┐
│                         api.ts (Basis)                            │
│  ┌────────────────────────────────────────────────────────────┐  │
│  │  Axios-Instanz mit:                                         │  │
│  │  - Base URL Konfiguration                                   │  │
│  │  - Request Interceptor (JWT-Token hinzufügen)               │  │
│  │  - Response Interceptor (Token-Refresh bei 401)             │  │
│  └────────────────────────────────────────────────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                                  │
     ┌────────────────────────────┼────────────────────────────┐
     │                            │                            │
┌────▼────┐    ┌────────▼────────┐    ┌────────▼────────┐
│authSvc  │    │   ideaService   │    │   userService   │
├─────────┤    ├─────────────────┤    ├─────────────────┤
│login()  │    │getAllIdeas()    │    │getUser()        │
│register()│   │createIdea()     │    │updateUser()     │
│logout() │    │updateIdea()     │    │getLeaderboard() │
└─────────┘    └─────────────────┘    └─────────────────┘
```

### 5.5 Datenfluss

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Benutzer-  │────▶│    React    │────▶│   Service   │────▶│  Backend    │
│  Interaktion│     │  Component  │     │   (Axios)   │     │    API      │
└─────────────┘     └──────┬──────┘     └─────────────┘     └─────────────┘
                           │
                           ▼
                    ┌─────────────┐
                    │   Context   │
                    │  (Zustand)  │
                    └─────────────┘

Beispiel: Idee erstellen
1. Benutzer füllt Formular aus und klickt "Erstellen"
2. CreateIdeaPage ruft ideaService.createIdea() auf
3. ideaService sendet POST-Request an /api/ideas
4. Backend erstellt Idee und gibt IdeaDTO zurück
5. Component navigiert zur Ideen-Übersicht
```

---

## 6. Sicherheitsarchitektur

### 6.1 Authentifizierungsfluss

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        JWT-AUTHENTIFIZIERUNGSFLUSS                       │
└─────────────────────────────────────────────────────────────────────────┘

    FRONTEND                         BACKEND                    DATENBANK
        │                               │                           │
        │  1. POST /auth/login          │                           │
        │   {username, password}        │                           │
        │─────────────────────────────▶ │                           │
        │                               │  2. Benutzer suchen       │
        │                               │──────────────────────────▶│
        │                               │                           │
        │                               │  3. Benutzer + Hash       │
        │                               │◀──────────────────────────│
        │                               │                           │
        │                               │  4. Passwort verifizieren │
        │                               │     (BCrypt)              │
        │                               │                           │
        │  5. AuthResponse              │                           │
        │   {token, refreshToken, user} │                           │
        │◀───────────────────────────── │                           │
        │                               │                           │
        │  6. Token in localStorage     │                           │
        │     speichern                 │                           │
        │                               │                           │
        │  7. GET /api/ideas            │                           │
        │   Header: Bearer {token}      │                           │
        │─────────────────────────────▶ │                           │
        │                               │                           │
        │                               │  8. JwtFilter prüft Token │
        │                               │                           │
        │  9. Daten oder 401 Fehler     │                           │
        │◀───────────────────────────── │                           │
```

### 6.2 JWT-Token-Konfiguration

| Parameter | Wert | Begründung |
|-----------|------|------------|
| Algorithmus | HS256 | Symmetrisch, performant, ausreichend sicher |
| Access Token Gültigkeit | 24 Stunden | Balance zwischen Sicherheit und Benutzerfreundlichkeit |
| Refresh Token Gültigkeit | 7 Tage | Ermöglicht längere Sessions ohne erneute Anmeldung |
| Claims | userId, username, role, email | Minimale Daten für Autorisierung |

**Warum JWT statt Session-basiert?**

1. **Zustandslosigkeit**: Server muss keine Sessions speichern, was die Skalierung vereinfacht
2. **Cross-Origin-Kompatibilität**: Tokens funktionieren über verschiedene Domains hinweg
3. **Mobile-Unterstützung**: Standard für moderne API-Authentifizierung
4. **Selbstbeschreibend**: Token enthält alle nötigen Benutzerinformationen

### 6.3 Rollenbasierte Zugriffskontrolle (RBAC)

```
┌─────────────────────────────────────────────────────────────────────────┐
│                         BENUTZERROLLEN                                   │
├───────────────┬─────────────────────────────────────────────────────────┤
│   EMPLOYEE    │  Ideen erstellen, kommentieren, liken (max 3/Woche)     │
│               │  An Umfragen teilnehmen, Nachrichten senden              │
├───────────────┼─────────────────────────────────────────────────────────┤
│PROJECT_MANAGER│  Alle EMPLOYEE-Rechte                                    │
│               │  + Ideen-Status ändern, Fortschritt aktualisieren        │
├───────────────┼─────────────────────────────────────────────────────────┤
│     ADMIN     │  Alle PROJECT_MANAGER-Rechte                             │
│               │  + Benutzer verwalten, Ideen löschen, Audit-Logs sehen   │
└───────────────┴─────────────────────────────────────────────────────────┘
```

Die Zugriffskontrolle wird über die @Secured-Annotation implementiert:

```java
@Secured({"PROJECT_MANAGER", "ADMIN"})
public Response updateIdeaStatus(Long id, IdeaStatus status) { ... }
```

### 6.4 Sicherheitsfilter

**JwtFilter**: Prüft jeden Request auf gültigen JWT-Token und setzt den SecurityContext.

**CorsFilter**: Ermöglicht Cross-Origin-Requests vom Frontend (Port 3000) zum Backend (Port 8080). Wird mit @PreMatching vor dem JwtFilter ausgeführt, um OPTIONS-Preflight-Requests zu behandeln.

---

## 7. Gamification-System

### 7.1 Konzept

Das Gamification-System fördert die aktive Teilnahme durch spielerische Elemente:

```
┌─────────────────────────────────────────────────────────────────────────┐
│                      GAMIFICATION-ELEMENTE                               │
├──────────────────┬──────────────────────────────────────────────────────┤
│    XP-PUNKTE     │  Erfahrungspunkte für Aktivitäten                    │
├──────────────────┼──────────────────────────────────────────────────────┤
│      LEVEL       │  10 Stufen basierend auf XP-Schwellenwerten          │
├──────────────────┼──────────────────────────────────────────────────────┤
│     BADGES       │  Abzeichen für besondere Leistungen                  │
├──────────────────┼──────────────────────────────────────────────────────┤
│   LEADERBOARD    │  Rangliste der aktivsten Benutzer                    │
└──────────────────┴──────────────────────────────────────────────────────┘
```

### 7.2 XP-Vergabe

| Aktion | XP-Punkte |
|--------|-----------|
| Idee einreichen | +50 XP |
| Idee abgeschlossen | +100 XP |
| Like erhalten | +10 XP |
| Kommentar schreiben | +5 XP |

### 7.3 Level-System

```
Level 1:    0 XP   │████░░░░░░░░░░░░░░░░│   0%
Level 2:  100 XP   │████████░░░░░░░░░░░░│  10%
Level 3:  300 XP   │████████████░░░░░░░░│  30%
Level 4:  600 XP   │████████████████░░░░│  60%
Level 5: 1000 XP   │████████████████████│ 100%
...
Level 10: 10000 XP (Maximum)
```

### 7.4 Badge-System

| Badge | Kriterium | XP-Bonus |
|-------|-----------|----------|
| First Idea | Erste Idee eingereicht | +25 XP |
| Popular | 10+ Likes auf eine Idee | +50 XP |
| Commentator | 50+ Kommentare verfasst | +75 XP |

**Warum Gamification?**

- **Motivation**: Spielerische Anreize steigern die Beteiligung
- **Sichtbarkeit**: Leaderboard fördert gesunden Wettbewerb
- **Anerkennung**: Badges würdigen besondere Beiträge
- **Engagement**: Regelmäßige XP-Vergabe hält Benutzer aktiv

---

## 8. Deployment und Infrastruktur

### 8.1 Container-Architektur

```
┌─────────────────────────────────────────────────────────────────────────┐
│                        DOCKER COMPOSE                                    │
├─────────────────────────────────────────────────────────────────────────┤
│                                                                          │
│  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐     │
│  │    frontend     │    │     backend     │    │    database     │     │
│  │    (Nginx)      │    │   (GlassFish)   │    │  (PostgreSQL)   │     │
│  │   Port: 3000    │───▶│   Port: 8080    │───▶│   Port: 5432    │     │
│  └─────────────────┘    └─────────────────┘    └─────────────────┘     │
│                                                        │                │
│                                               ┌────────▼────────┐      │
│                                               │    pgdata       │      │
│                                               │   (Volume)      │      │
│                                               └─────────────────┘      │
│                                                                          │
│  Network: ideaboard-network (Bridge)                                    │
└─────────────────────────────────────────────────────────────────────────┘
```

### 8.2 Container-Konfiguration

| Service | Image | Ports | Abhängigkeiten |
|---------|-------|-------|----------------|
| database | PostgreSQL 15 | 5432 | - |
| backend | GlassFish 7 + Java 17 | 8080, 4848 | database (healthy) |
| frontend | Nginx + React Build | 3000 | backend (healthy) |

### 8.3 Health-Checks

Jeder Container hat definierte Gesundheitsprüfungen:

- **Database**: `pg_isready` Befehl
- **Backend**: HTTP GET auf `/api/health`
- **Frontend**: HTTP GET auf Nginx

Die Container starten erst, wenn ihre Abhängigkeiten gesund sind.

### 8.4 Deployment-Workflow

```bash
# 1. Umgebungsvariablen konfigurieren
copy .env.example .env

# 2. Container bauen und starten
docker compose up --build

# 3. Anwendung aufrufen
# Frontend: http://localhost:3000
# Backend API: http://localhost:8080/ideaboard/api
# GlassFish Admin: http://localhost:4848
```

**Warum Docker?**

1. **Konsistenz**: Identische Umgebung auf allen Systemen
2. **Isolation**: Jeder Service läuft in eigenem Container
3. **Einfaches Deployment**: Ein Befehl startet die gesamte Anwendung
4. **Skalierbarkeit**: Container können bei Bedarf repliziert werden

---

## 9. Zusammenfassung

### 9.1 Architektur-Highlights

Das GFOS Digital Idea Board ist eine moderne, vollständige Enterprise-Webanwendung mit folgenden Kernmerkmalen:

- **Drei-Schichten-Architektur** mit klarer Trennung von Präsentation, Logik und Persistenz
- **RESTful API** mit 12 Resource-Klassen und umfassender Dokumentation
- **JWT-basierte Sicherheit** mit Dual-Token-System und rollenbasierter Zugriffskontrolle
- **Gamification-Integration** als zentrales Element zur Benutzerengagement
- **Containerisierte Infrastruktur** für einfaches Deployment

### 9.2 Designprinzipien

Bei der Entwicklung wurden folgende Prinzipien verfolgt:

| Prinzip | Umsetzung |
|---------|-----------|
| **Separation of Concerns** | Klare Trennung in Schichten und Module |
| **DRY (Don't Repeat Yourself)** | Wiederverwendbare Services und Komponenten |
| **KISS (Keep It Simple)** | React Context statt überladener State-Management |
| **Security by Design** | JWT, CORS, Passwort-Hashing von Anfang an |

### 9.3 Erweiterbarkeit

Die Architektur ermöglicht einfache Erweiterungen:

- Neue Entitäten können durch Hinzufügen von Entity, DTO, Service und Resource integriert werden
- Das Frontend kann durch neue Pages und Services erweitert werden
- Die API ist versionierbar durch Pfad-Präfixe
- Docker-Container können horizontal skaliert werden

### 9.4 Wartbarkeit

Die Wartbarkeit wird durch folgende Maßnahmen sichergestellt:

- **TypeScript** fängt Fehler zur Compile-Zeit ab
- **Einheitliche Code-Struktur** erleichtert die Orientierung
- **Umfassende Typdefinitionen** dienen als Dokumentation
- **Audit-Logging** ermöglicht Nachverfolgung von Änderungen

### 9.5 Codestatistik

| Bereich | Anzahl |
|---------|--------|
| **Backend** | |
| Java-Dateien (gesamt) | 82 |
| Entity-Klassen | 19 |
| Enum-Typen | 5 |
| Service-Klassen | 14 |
| REST-Resources | 12 |
| DTO-Klassen | 20 |
| API-Endpunkte | 79 |
| **Frontend** | |
| TypeScript-Dateien | 26 |
| React-Seiten | 10 |
| API-Services | 9 |
| Context-Provider | 2 |
| UI-Komponenten | 2 |
| **Infrastruktur** | |
| Docker-Container | 3 |
| Datenbank-Tabellen | 20 |

---

**Erstellt für den GFOS Innovationspreis 2026**

*Diese Dokumentation beschreibt die technische Architektur des GFOS Digital Idea Board. Bei Fragen zur Implementierung oder Erweiterung wenden Sie sich bitte an das Entwicklungsteam.*
