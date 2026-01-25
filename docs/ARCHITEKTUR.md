# Architektur-Dokumentation

Diese Dokumentation beschreibt die technische Architektur des GFOS Digital Idea Board. Sie richtet sich an Entwickler und technische Mitarbeiter, die das System verstehen, erweitern oder warten mochten.

---

## Inhaltsverzeichnis

1. [Technologie-Ubersicht](#technologie-ubersicht)
2. [Technologie-Begrundungen](#technologie-begrundungen)
3. [Systemarchitektur](#systemarchitektur)
4. [Projektstruktur](#projektstruktur)
5. [Vorderseiten-Architektur](#vorderseiten-architektur)
6. [Ruckseiten-Architektur](#ruckseiten-architektur)
7. [Datenbankschema](#datenbankschema)
8. [Entwurfsmuster](#entwurfsmuster)
9. [Datenfluss](#datenfluss)
10. [Sicherheitskonzept](#sicherheitskonzept)
11. [Fehlerbehandlung](#fehlerbehandlung)
12. [Containerisierung](#containerisierung)

---

## Technologie-Ubersicht

### Technologie-Stapel

| Schicht | Technologien |
|---------|--------------|
| **Vorderseite** | React 18, TypeScript 5, Vite 5, Tailwind CSS 3, Axios |
| **Ruckseite** | Java 17, Jakarta EE 10, Jersey 3.1, EclipseLink JPA 4 |
| **Datenbank** | PostgreSQL 15 |
| **Server** | GlassFish 7 |
| **Authentifizierung** | JWT (jjwt), BCrypt |
| **Bereitstellung** | Docker, Docker Compose, Nginx |

### Versionen

**Vorderseite:**
| Paket | Version |
|-------|---------|
| React | 18.2.0 |
| TypeScript | 5.3.3 |
| Vite | 5.0.10 |
| Tailwind CSS | 3.4.0 |
| Axios | 1.6.2 |
| React Router | 6.21.1 |
| Recharts | 2.10.3 |
| React Hot Toast | 2.4.1 |
| React Dropzone | 14.2.3 |
| Headless UI | 1.7.17 |
| Heroicons | 2.1.1 |
| date-fns | 3.2.0 |

**Ruckseite:**
| Bibliothek | Version |
|------------|---------|
| Jakarta EE API | 10.0.0 |
| Jersey (JAX-RS) | 3.1.3 |
| EclipseLink JPA | 4.0.2 |
| PostgreSQL-Treiber | 42.7.1 |
| jjwt | 0.12.3 |
| BCrypt | 0.10.2 |
| iText (PDF) | 8.0.2 |
| Jackson | 2.16.1 |
| SLF4J | 2.0.9 |
| JUnit 5 | 5.10.1 |
| Mockito | 5.8.0 |

---

## Technologie-Begrundungen

### Warum TypeScript?

**Problem:** JavaScript ist dynamisch typisiert, was zu Laufzeitfehlern fuhrt, die erst spat erkannt werden.

**Losung:** TypeScript bietet statische Typisierung.

**Vorteile:**
- **Typsicherheit:** Fehler werden bereits beim Kompilieren erkannt, nicht erst zur Laufzeit
- **Bessere IDE-Unterstutzung:** Autovervollstandigung, Refactoring und Navigation funktionieren zuverlassiger
- **Dokumentation durch Typen:** Der Code dokumentiert sich selbst durch Typannotationen
- **Einfachere Wartung:** Bei grossen Projekten sind Anderungen sicherer durchzufuhren
- **Industriestandard:** Weit verbreitet und gut dokumentiert

**Beispiel:**
```typescript
// Ohne TypeScript: Fehler erst zur Laufzeit
function berechneSumme(a, b) {
    return a + b;
}
berechneSumme("5", 3); // Ergebnis: "53" statt 8

// Mit TypeScript: Fehler beim Kompilieren
function berechneSumme(a: number, b: number): number {
    return a + b;
}
berechneSumme("5", 3); // Kompilierfehler!
```

### Warum React?

**Problem:** Komplexe Benutzeroberflachen sind mit reinem JavaScript schwer zu warten.

**Losung:** React bietet eine komponentenbasierte Architektur.

**Vorteile:**
- **Komponentenbasiert:** Wiederverwendbare, gekapselte UI-Bausteine
- **Virtuelles DOM:** Effiziente Aktualisierung der Oberflache
- **Einweg-Datenfluss:** Vorhersagbares Verhalten und einfacheres Debugging
- **Grosse Gemeinschaft:** Umfangreiches Okosystem an Bibliotheken
- **Bewahrt:** Von Meta entwickelt und in grossen Anwendungen erprobt
- **Flexible Integration:** Kann mit beliebigen Ruckseiten-Technologien verwendet werden

### Warum Vite?

**Problem:** Herkommliche Build-Werkzeuge wie Webpack sind langsam in der Entwicklung.

**Losung:** Vite nutzt native ES-Module fur schnelle Entwicklung.

**Vorteile:**
- **Schneller Start:** Entwicklungsserver startet in Millisekunden
- **Sofortige Aktualisierung:** Anderungen werden sofort im Browser sichtbar
- **Modernes Build-System:** Optimierte Produktionsbuendel
- **Einfache Konfiguration:** Weniger Boilerplate als Webpack
- **TypeScript-Unterstutzung:** Eingebaut, keine zusatzliche Konfiguration notig

### Warum Tailwind CSS?

**Problem:** Herkommliches CSS fuhrt zu grossen, schwer wartbaren Stylesheets.

**Losung:** Tailwind bietet einen Utility-First-Ansatz.

**Vorteile:**
- **Utility-First:** Kleine, zusammensetzbare Klassen direkt im HTML
- **Konsistentes Design:** Vordefinierte Farbpaletten und Abstande
- **Kleine Produktionsbuendel:** Unbenutztes CSS wird automatisch entfernt
- **Responsive Design:** Einfache Anpassung fur verschiedene Bildschirmgrossen
- **Dunkelmodus:** Eingebaute Unterstutzung fur helles und dunkles Design

**Beispiel:**
```html
<!-- Ohne Tailwind: Separate CSS-Datei notig -->
<button class="primary-button">Klicken</button>

<!-- Mit Tailwind: Styling direkt im HTML -->
<button class="bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded">
    Klicken
</button>
```

### Warum Java 17?

**Problem:** Moderne Anwendungen benotigen eine stabile, leistungsfahige Sprache.

**Losung:** Java 17 ist eine LTS-Version (Langzeitunterstutzung).

**Vorteile:**
- **Langzeitunterstutzung:** Sicherheitsupdates bis mindestens 2029
- **Leistung:** Verbesserte Garbage Collection und JIT-Compiler
- **Moderne Funktionen:** Records, Pattern Matching, versiegelte Klassen
- **Stabilitat:** Jahrzehntelang erprobt in Unternehmensanwendungen
- **Grosse Gemeinschaft:** Umfangreiches Okosystem und gute Dokumentation
- **Plattformunabhangigkeit:** Lauft auf jedem System mit JVM

### Warum Jakarta EE 10?

**Problem:** Unternehmensanwendungen benotigen standardisierte Losungen.

**Losung:** Jakarta EE definiert Industriestandards fur Unternehmensanwendungen.

**Vorteile:**
- **Industriestandard:** Von der Eclipse Foundation verwaltet
- **Bewahrt:** Millionen von Anwendungen weltweit
- **Umfassend:** REST, Persistenz, Sicherheit, Transaktionen aus einer Hand
- **Portabilitat:** Code lauft auf verschiedenen Servern (GlassFish, Payara, WildFly)
- **Zukunftssicher:** Aktive Weiterentwicklung durch die Gemeinschaft

### Warum GlassFish 7?

**Problem:** Jakarta-EE-Anwendungen benotigen einen Anwendungsserver.

**Losung:** GlassFish ist die Referenzimplementierung fur Jakarta EE.

**Vorteile:**
- **Referenzimplementierung:** Garantierte Kompatibilitat mit Jakarta EE 10
- **Kostenlos und quelloffen:** Keine Lizenzkosten
- **Vollstandig:** Alle Jakarta-EE-Spezifikationen enthalten
- **Administrationskonsole:** Grafische Verwaltungsoberflache
- **Produktionsreif:** Fur mittlere bis grosse Anwendungen geeignet

### Warum PostgreSQL?

**Problem:** Daten mussen zuverlassig und effizient gespeichert werden.

**Losung:** PostgreSQL ist eine ausgereifte relationale Datenbank.

**Vorteile:**
- **Zuverlassigkeit:** ACID-konform, keine Datenverluste
- **Leistung:** Effiziente Abfrageverarbeitung und Indizierung
- **Erweiterbar:** JSON, Volltextsuche, geometrische Typen
- **Kostenlos und quelloffen:** Keine Lizenzkosten
- **Standardkonform:** SQL:2016-kompatibel
- **Skalierbar:** Von kleinen Projekten bis zu grossen Unternehmen

### Warum Docker?

**Problem:** "Es funktioniert auf meinem Rechner" - Umgebungsunterschiede verursachen Probleme.

**Losung:** Docker verpackt Anwendungen mit allen Abhangigkeiten.

**Vorteile:**
- **Einheitliche Umgebung:** Entwicklung und Produktion sind identisch
- **Einfache Bereitstellung:** Ein Befehl startet die gesamte Anwendung
- **Isolierung:** Jeder Dienst lauft in seinem eigenen Container
- **Portabilitat:** Lauft auf Windows, Linux und macOS
- **Skalierbarkeit:** Container konnen einfach vervielfaltigt werden
- **Versionierung:** Verschiedene Versionen konnen parallel existieren

### Warum JWT?

**Problem:** Sitzungsbasierte Authentifizierung skaliert schlecht.

**Losung:** JWT (JSON Web Token) ermoglicht zustandslose Authentifizierung.

**Vorteile:**
- **Zustandslos:** Keine Sitzungsspeicherung auf dem Server notig
- **Skalierbar:** Anfragen konnen an beliebige Server geleitet werden
- **Sicher:** Kryptografisch signiert, falschungssicher
- **Selbstbeschreibend:** Enthalt Benutzerinformationen und Berechtigungen
- **Standardisiert:** RFC 7519, weit verbreitet

---

## Systemarchitektur

Das System folgt einer **Drei-Schichten-Architektur**:

```
+------------------+     +------------------+     +------------------+
|                  |     |                  |     |                  |
|   Vorderseite    |---->|    Ruckseite     |---->|    Datenbank     |
|   (React/TS)     |<----|    (Java/EE)     |<----|   (PostgreSQL)   |
|                  |     |                  |     |                  |
+------------------+     +------------------+     +------------------+
     Port 3000              Port 8080              Port 5432
       Nginx                GlassFish             PostgreSQL
```

### Kommunikation

1. **Vorderseite -> Ruckseite:** HTTP/REST uber Axios
2. **Ruckseite -> Datenbank:** JDBC/JPA uber EclipseLink
3. **Authentifizierung:** JWT-Token im Authorization-Header

### Container-Architektur

```
+-------------------------------------------------------------------+
|                       Docker-Netzwerk                              |
|                                                                    |
|  +----------------+  +------------------+  +-------------------+   |
|  |   vorderseite  |  |    ruckseite     |  |     datenbank     |   |
|  |     (nginx)    |  |   (glassfish)    |  |   (postgresql)    |   |
|  |                |  |                  |  |                   |   |
|  |  Port: 3000    |  |  Port: 8080      |  |  Port: 5432       |   |
|  |                |  |  Port: 4848      |  |                   |   |
|  +----------------+  +------------------+  +-------------------+   |
|                                                                    |
+-------------------------------------------------------------------+
```

---

## Projektstruktur

```
GFOS-/
├── frontend/                           # Vorderseite
│   ├── src/
│   │   ├── main.tsx                    # Anwendungseinstieg
│   │   ├── App.tsx                     # Routenkonfiguration
│   │   ├── index.css                   # Globale Stile
│   │   ├── pages/                      # Seitenkomponenten (10)
│   │   ├── components/                 # Wiederverwendbare Komponenten
│   │   ├── context/                    # React-Kontexte
│   │   ├── services/                   # API-Dienste
│   │   └── types/                      # TypeScript-Typen
│   ├── package.json
│   └── vite.config.ts
│
├── backend/                            # Ruckseite
│   ├── src/main/java/com/gfos/ideaboard/
│   │   ├── config/                     # Anwendungskonfiguration
│   │   ├── resource/                   # REST-Endpunkte (12)
│   │   ├── service/                    # Geschaftslogik (14)
│   │   ├── entity/                     # JPA-Entitaten (24)
│   │   ├── dto/                        # Datenubertragungsobjekte (19)
│   │   ├── security/                   # Sicherheit (JWT)
│   │   ├── exception/                  # Ausnahmebehandlung
│   │   └── util/                       # Hilfswerkzeuge
│   └── pom.xml
│
├── database/
│   └── init.sql                        # Datenbankschema
│
├── docker/
│   ├── frontend/
│   │   ├── Dockerfile
│   │   └── nginx.conf
│   ├── backend/
│   │   ├── Dockerfile
│   │   └── setup-glassfish.sh
│   └── database/
│       ├── Dockerfile
│       └── init-user.sh
│
├── docs/                               # Dokumentation
├── docker-compose.yml
├── docker-compose.dev.yml
└── .env.example
```

---

## Vorderseiten-Architektur

### Seiten (Pages)

Alle Seiten befinden sich in `frontend/src/pages/`:

| Datei | Pfad | Beschreibung |
|-------|------|--------------|
| `LoginPage.tsx` | `/login` | Anmeldeformular |
| `RegisterPage.tsx` | `/register` | Registrierungsformular |
| `DashboardPage.tsx` | `/dashboard` | Ubersichtsbrett mit Statistiken |
| `IdeasPage.tsx` | `/ideas` | Ideenliste mit Filter und Suche |
| `CreateIdeaPage.tsx` | `/ideas/new`, `/ideas/:id/edit` | Idee erstellen/bearbeiten |
| `IdeaDetailPage.tsx` | `/ideas/:id` | Ideendetails mit Kommentaren |
| `SurveysPage.tsx` | `/surveys` | Umfragenliste und -erstellung |
| `MessagesPage.tsx` | `/messages` | Nachrichten-Oberflache |
| `ProfilePage.tsx` | `/profile` | Benutzerprofil |
| `AdminPage.tsx` | `/admin/*` | Administratorbereich |

### Komponenten

Wiederverwendbare Komponenten in `frontend/src/components/`:

| Komponente | Zweck |
|------------|-------|
| `Layout.tsx` | Hauptlayout mit Navigation |
| `NotificationDropdown.tsx` | Benachrichtigungsanzeige |

### Kontexte (Context)

React-Kontexte fur globalen Zustand in `frontend/src/context/`:

| Kontext | Zweck | Bereitgestellte Werte |
|---------|-------|----------------------|
| `AuthContext.tsx` | Authentifizierung | `user`, `login`, `logout`, `isAuthenticated` |
| `ThemeContext.tsx` | Dunkelmodus | `theme`, `toggleTheme` |

**AuthContext-Funktionsweise:**
```typescript
// Bereitgestellte Werte
interface AuthContextType {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (username: string, password: string) => Promise<void>;
  register: (data: RegisterData) => Promise<void>;
  logout: () => void;
}

// Verwendung in Komponenten
const { user, isAuthenticated, login, logout } = useAuth();
```

### Dienste (Services)

API-Dienste in `frontend/src/services/`:

| Dienst | Beschreibung | Wichtige Funktionen |
|--------|--------------|---------------------|
| `api.ts` | Axios-Instanz mit Abfangern | Token-Injektion, Fehlerbehandlung, Token-Aktualisierung |
| `authService.ts` | Authentifizierung | `login`, `register`, `logout`, `refreshToken` |
| `ideaService.ts` | Ideenverwaltung | `getIdeas`, `createIdea`, `updateIdea`, `deleteIdea` |
| `commentService.ts` | Kommentare | `getComments`, `createComment`, `addReaction` |
| `messageService.ts` | Nachrichten | `getConversations`, `sendMessage` |
| `groupService.ts` | Gruppen | `getGroup`, `joinGroup`, `leaveGroup` |
| `surveyService.ts` | Umfragen | `getSurveys`, `createSurvey`, `vote` |
| `userService.ts` | Benutzer | `getUsers`, `updateUser`, `changePassword` |
| `dashboardService.ts` | Ubersicht | `getStatistics`, `getLeaderboard` |
| `exportService.ts` | Export | `exportIdeaToPdf` |
| `fileService.ts` | Dateien | `uploadFile`, `downloadFile` |

**API-Dienst-Aufbau:**
```typescript
// frontend/src/services/api.ts
import axios from 'axios';

const api = axios.create({
  baseURL: '/api',
  headers: { 'Content-Type': 'application/json' }
});

// Anfrage-Abfanger: Token hinzufugen
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('accessToken');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Antwort-Abfanger: Token-Aktualisierung bei 401
api.interceptors.response.use(
  (response) => response,
  async (error) => {
    if (error.response?.status === 401) {
      // Token-Aktualisierung versuchen
      const refreshToken = localStorage.getItem('refreshToken');
      // ... Aktualisierungslogik
    }
    return Promise.reject(error);
  }
);
```

### Typen (Types)

TypeScript-Schnittstellen in `frontend/src/types/index.ts`:

**Kern-Entitaten:**
```typescript
interface User {
  id: number;
  username: string;
  email: string;
  role: UserRole;
  xpPoints: number;
  level: number;
  badges: UserBadge[];
}

interface Idea {
  id: number;
  title: string;
  description: string;
  category: string;
  status: IdeaStatus;
  progressPercentage: number;
  author: User;
  likeCount: number;
  commentCount: number;
  tags: string[];
  createdAt: string;
}

interface Comment {
  id: number;
  ideaId: number;
  author: User;
  content: string;
  reactions: CommentReaction[];
  createdAt: string;
}
```

**Aufzahlungstypen:**
```typescript
type UserRole = 'EMPLOYEE' | 'PROJECT_MANAGER' | 'ADMIN';
type IdeaStatus = 'CONCEPT' | 'IN_PROGRESS' | 'COMPLETED';
type NotificationType = 'LIKE' | 'COMMENT' | 'REACTION' | 'STATUS_CHANGE' |
                        'BADGE_EARNED' | 'LEVEL_UP' | 'MENTION' | 'MESSAGE';
```

**Seitenumbruch:**
```typescript
interface Page<T> {
  content: T[];
  totalElements: number;
  totalPages: number;
  size: number;
  number: number;
}

interface PageRequest {
  page: number;
  size: number;
  sort?: string;
}
```

---

## Ruckseiten-Architektur

### REST-Schnittstellen (Resources)

Alle REST-Endpunkte in `backend/src/main/java/com/gfos/ideaboard/resource/`:

| Ressource | Basispfad | Beschreibung |
|-----------|-----------|--------------|
| `AuthResource` | `/api/auth` | Anmeldung, Registrierung, Token-Aktualisierung |
| `UserResource` | `/api/users` | Benutzerverwaltung, Profil |
| `IdeaResource` | `/api/ideas` | Ideenverwaltung, Kommentare, Dateien |
| `CommentResource` | `/api/comments` | Kommentar-Reaktionen |
| `SurveyResource` | `/api/surveys` | Umfragen und Abstimmungen |
| `MessageResource` | `/api/messages` | Direktnachrichten |
| `GroupResource` | `/api/groups` | Gruppenmanagement, Gruppennachrichten |
| `NotificationResource` | `/api/notifications` | Benachrichtigungen |
| `DashboardResource` | `/api/dashboard` | Statistiken |
| `AuditResource` | `/api/audit` | Prufprotokolle |
| `ExportResource` | `/api/export` | PDF-Export |
| `HealthResource` | `/api/health` | Gesundheitsprufung |

**Endpunkt-Beispiel:**
```java
@Path("/ideas")
@Produces(MediaType.APPLICATION_JSON)
@Consumes(MediaType.APPLICATION_JSON)
public class IdeaResource {

    @Inject
    private IdeaService ideaService;

    @GET
    @Secured({UserRole.EMPLOYEE, UserRole.PROJECT_MANAGER, UserRole.ADMIN})
    public Response getIdeas(
            @QueryParam("page") @DefaultValue("0") int page,
            @QueryParam("size") @DefaultValue("10") int size,
            @QueryParam("category") String category,
            @QueryParam("status") String status,
            @QueryParam("search") String search) {

        Page<IdeaDTO> ideas = ideaService.getIdeas(page, size, category, status, search);
        return Response.ok(ideas).build();
    }

    @POST
    @Secured({UserRole.EMPLOYEE, UserRole.PROJECT_MANAGER, UserRole.ADMIN})
    public Response createIdea(CreateIdeaRequest request, @Context ContainerRequestContext ctx) {
        Long userId = (Long) ctx.getProperty("userId");
        IdeaDTO idea = ideaService.createIdea(request, userId);
        return Response.status(Status.CREATED).entity(idea).build();
    }
}
```

### Dienste (Services)

Geschaftslogik in `backend/src/main/java/com/gfos/ideaboard/service/`:

| Dienst | Beschreibung |
|--------|--------------|
| `AuthService` | Authentifizierung, Kennwortprufung |
| `UserService` | Benutzerverwaltung, Rollenprufung |
| `IdeaService` | Ideenlogik, Filterung, Suche |
| `CommentService` | Kommentare und Reaktionen |
| `LikeService` | Gefallt-mir mit Wochenlimit |
| `SurveyService` | Umfragelogik, Abstimmungen |
| `MessageService` | Direktnachrichten, Unterhaltungen |
| `GroupService` | Gruppenmanagement, Mitgliedschaft |
| `ChecklistService` | Checklistenverwaltung, Fortschritt |
| `FileService` | Datei-Upload und -Download |
| `GamificationService` | Erfahrungspunkte, Stufen, Abzeichen |
| `NotificationService` | Benachrichtigungserstellung |
| `AuditService` | Aktionsprotokollierung |
| `ExportService` | PDF-Erstellung mit iText |

**Dienst-Beispiel:**
```java
@ApplicationScoped
public class IdeaService {

    @PersistenceContext(unitName = "IdeaBoardPU")
    private EntityManager em;

    @Inject
    private GroupService groupService;

    @Inject
    private GamificationService gamificationService;

    @Inject
    private AuditService auditService;

    @Transactional
    public IdeaDTO createIdea(CreateIdeaRequest request, Long userId) {
        User author = em.find(User.class, userId);

        Idea idea = new Idea();
        idea.setTitle(request.getTitle());
        idea.setDescription(request.getDescription());
        idea.setCategory(request.getCategory());
        idea.setStatus(IdeaStatus.CONCEPT);
        idea.setAuthor(author);

        em.persist(idea);

        // Gruppe automatisch erstellen
        groupService.createGroupForIdea(idea);

        // Erfahrungspunkte vergeben
        gamificationService.awardXpForIdea(author, 50);

        // Aktion protokollieren
        auditService.log(userId, AuditAction.CREATE, "Idea", idea.getId());

        return IdeaDTO.fromEntity(idea);
    }
}
```

### Entitaten (Entities)

JPA-Entitaten in `backend/src/main/java/com/gfos/ideaboard/entity/`:

**Benutzer und Authentifizierung:**
| Entitat | Beschreibung |
|---------|--------------|
| `User` | Benutzer mit Rolle, EP, Stufe |

**Ideen:**
| Entitat | Beschreibung |
|---------|--------------|
| `Idea` | Idee mit Kategorie, Status, Fortschritt |
| `Comment` | Kommentar zu einer Idee |
| `CommentReaction` | Emoji-Reaktion auf Kommentar |
| `Like` | Gefallt-mir-Markierung |
| `ChecklistItem` | Checklisteneintrag |
| `FileAttachment` | Dateianhang |

**Gamification:**
| Entitat | Beschreibung |
|---------|--------------|
| `Badge` | Abzeichen-Definition |
| `UserBadge` | Verliehenes Abzeichen |

**Umfragen:**
| Entitat | Beschreibung |
|---------|--------------|
| `Survey` | Umfrage |
| `SurveyOption` | Antwortoption |
| `SurveyVote` | Abgegebene Stimme |

**Nachrichten:**
| Entitat | Beschreibung |
|---------|--------------|
| `Message` | Direktnachricht |
| `IdeaGroup` | Diskussionsgruppe |
| `GroupMember` | Gruppenmitgliedschaft |
| `GroupMessage` | Gruppennachricht |
| `GroupMessageRead` | Lesestatus |

**System:**
| Entitat | Beschreibung |
|---------|--------------|
| `Notification` | Benachrichtigung |
| `AuditLog` | Prufprotokoll |

**Entitats-Beispiel:**
```java
@Entity
@Table(name = "ideas")
@NamedQuery(name = "Idea.findByCategory",
            query = "SELECT i FROM Idea i WHERE i.category = :category ORDER BY i.createdAt DESC")
public class Idea {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private String title;

    @Column(columnDefinition = "TEXT")
    private String description;

    @Column(nullable = false)
    private String category;

    @Enumerated(EnumType.STRING)
    private IdeaStatus status = IdeaStatus.CONCEPT;

    private int progressPercentage = 0;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "author_id", nullable = false)
    private User author;

    @Column(name = "like_count")
    private int likeCount = 0;

    @ElementCollection
    @CollectionTable(name = "idea_tags", joinColumns = @JoinColumn(name = "idea_id"))
    @Column(name = "tag")
    private List<String> tags = new ArrayList<>();

    @OneToMany(mappedBy = "idea", cascade = CascadeType.ALL, orphanRemoval = true)
    private List<ChecklistItem> checklistItems = new ArrayList<>();

    @Column(name = "created_at")
    private LocalDateTime createdAt = LocalDateTime.now();

    // Getter und Setter...
}
```

### DTOs (Data Transfer Objects)

Datenubertragungsobjekte in `backend/src/main/java/com/gfos/ideaboard/dto/`:

| DTO | Zweck |
|-----|-------|
| `AuthRequest` | Anmeldedaten |
| `AuthResponse` | Token-Antwort |
| `RegisterRequest` | Registrierungsdaten |
| `UserDTO` | Benutzer ohne sensitive Daten |
| `IdeaDTO` | Ideendaten mit Autor |
| `CreateIdeaRequest` | Ideenerstellung |
| `CommentDTO` | Kommentar mit Reaktionen |
| `MessageDTO` | Nachricht |
| `SurveyDTO` | Umfrage mit Optionen |
| `NotificationDTO` | Benachrichtigung |
| `DashboardDTO` | Statistiken |
| `PageDTO<T>` | Seitenumbruch |

**DTO-Beispiel:**
```java
public class IdeaDTO {
    private Long id;
    private String title;
    private String description;
    private String category;
    private IdeaStatus status;
    private int progressPercentage;
    private UserDTO author;
    private int likeCount;
    private int commentCount;
    private List<String> tags;
    private boolean isLikedByCurrentUser;
    private LocalDateTime createdAt;

    public static IdeaDTO fromEntity(Idea idea, boolean isLiked) {
        IdeaDTO dto = new IdeaDTO();
        dto.setId(idea.getId());
        dto.setTitle(idea.getTitle());
        dto.setDescription(idea.getDescription());
        dto.setCategory(idea.getCategory());
        dto.setStatus(idea.getStatus());
        dto.setProgressPercentage(idea.getProgressPercentage());
        dto.setAuthor(UserDTO.fromEntity(idea.getAuthor()));
        dto.setLikeCount(idea.getLikeCount());
        dto.setTags(idea.getTags());
        dto.setLikedByCurrentUser(isLiked);
        dto.setCreatedAt(idea.getCreatedAt());
        return dto;
    }
}
```

### Sicherheit (Security)

Sicherheitskomponenten in `backend/src/main/java/com/gfos/ideaboard/security/`:

| Klasse | Zweck |
|--------|-------|
| `JwtUtil` | Token-Erstellung und -Validierung |
| `JwtFilter` | Anfrage-Filter fur Token-Prufung |
| `PasswordUtil` | BCrypt-Kennwort-Hashing |
| `@Secured` | Annotation fur Rollenprufung |

**JWT-Konfiguration:**
```java
public class JwtUtil {
    private static final String SECRET_KEY = "..."; // In Produktion: Umgebungsvariable
    private static final long ACCESS_TOKEN_VALIDITY = 24 * 60 * 60 * 1000;  // 24 Stunden
    private static final long REFRESH_TOKEN_VALIDITY = 7 * 24 * 60 * 60 * 1000; // 7 Tage

    public String generateAccessToken(User user) {
        return Jwts.builder()
                .setSubject(String.valueOf(user.getId()))
                .claim("username", user.getUsername())
                .claim("role", user.getRole().name())
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + ACCESS_TOKEN_VALIDITY))
                .signWith(SignatureAlgorithm.HS256, SECRET_KEY)
                .compact();
    }
}
```

---

## Datenbankschema

### Entitats-Beziehungen

```
User (1) ────────< (N) Idea
User (1) ────────< (N) Like
User (1) ────────< (N) Comment
User (1) ────────< (N) UserBadge
Badge (1) ────────< (N) UserBadge

Idea (1) ────────< (N) Like
Idea (1) ────────< (N) Comment
Idea (1) ────────< (N) ChecklistItem
Idea (1) ────────< (N) FileAttachment
Idea (1) ────────< (1) IdeaGroup

IdeaGroup (1) ────────< (N) GroupMember
IdeaGroup (1) ────────< (N) GroupMessage
GroupMessage (N) ────────< (N) GroupMessageRead

Comment (1) ────────< (N) CommentReaction

Survey (1) ────────< (N) SurveyOption
Survey (1) ────────< (N) SurveyVote
SurveyOption (1) ────────< (N) SurveyVote

Message (N) >──────── (1) User (Sender)
Message (N) >──────── (1) User (Empfanger)
```

### Wichtige Tabellen

**users:**
```sql
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(20) NOT NULL DEFAULT 'EMPLOYEE',
    xp_points INTEGER DEFAULT 0,
    level INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    last_login TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

**ideas:**
```sql
CREATE TABLE ideas (
    id SERIAL PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(50) NOT NULL,
    status VARCHAR(20) DEFAULT 'CONCEPT',
    progress_percentage INTEGER DEFAULT 0,
    author_id INTEGER NOT NULL REFERENCES users(id),
    like_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX idx_ideas_author ON ideas(author_id);
CREATE INDEX idx_ideas_category ON ideas(category);
CREATE INDEX idx_ideas_status ON ideas(status);
CREATE INDEX idx_ideas_created_at ON ideas(created_at);
```

---

## Entwurfsmuster

### Architekturmuster

**Schichtenarchitektur:**
- Prasentationsschicht: React-Komponenten
- API-Schicht: JAX-RS-Ressourcen
- Geschaftslogikschicht: Dienste
- Datenzugriffsschicht: JPA/EntityManager

**Ressourcen-Muster (JAX-RS):**
- Ressourcen bilden HTTP-Methoden auf Geschaftsoperationen ab
- Zustandslose Anfrageverarbeitung
- Abhangigkeitsinjektion uber @Inject

### Verhaltensmuster

**Beobachter-Muster (Benachrichtigungen):**
```java
// Bei Ideen-Erstellung
ideaService.createIdea(request, userId);
// -> Loost aus: gamificationService.awardXp()
// -> Loost aus: notificationService.notify()
// -> Loost aus: auditService.log()
```

**Strategie-Muster (Abzeichenprufung):**
```java
public interface BadgeChecker {
    boolean check(User user);
}

// Verschiedene Implementierungen
class FirstIdeaChecker implements BadgeChecker { ... }
class PopularIdeaChecker implements BadgeChecker { ... }
```

**Dekorierer-Muster (Axios-Abfanger):**
```typescript
// Anfrage-Abfanger: Token hinzufugen
api.interceptors.request.use(config => {
    config.headers.Authorization = `Bearer ${token}`;
    return config;
});

// Antwort-Abfanger: Fehlerbehandlung
api.interceptors.response.use(
    response => response,
    error => handleError(error)
);
```

### Weitere Muster

**Repository-Muster:** EntityManager kapselt Datenbankzugriff
**DTO-Muster:** Trennung von Entitaten und API-Vertragen
**Singleton-Muster:** @ApplicationScoped Dienste

---

## Datenfluss

### Idee erstellen (Beispiel)

```
1. Benutzer fullt Formular aus (CreateIdeaPage.tsx)
                ↓
2. ideaService.createIdea(data) aufgerufen
                ↓
3. Axios POST /api/ideas mit JWT-Token
                ↓
4. JwtFilter pruft Token, extrahiert userId
                ↓
5. IdeaResource.createIdea() empfangt Anfrage
                ↓
6. @Secured pruft Benutzerrolle
                ↓
7. IdeaService.createIdea() ausgefuhrt:
   - Idee in Datenbank speichern
   - Gruppe fur Idee erstellen
   - 50 EP an Autor vergeben
   - Aktion protokollieren
                ↓
8. IdeaDTO als JSON-Antwort
                ↓
9. React aktualisiert UI, zeigt Erfolgsmeldung
```

### Authentifizierungsfluss

```
1. Benutzer gibt Anmeldedaten ein
                ↓
2. POST /api/auth/login
                ↓
3. AuthService pruft Kennwort (BCrypt)
                ↓
4. JwtUtil erstellt Access- und Refresh-Token
                ↓
5. Token werden in localStorage gespeichert
                ↓
6. AuthContext aktualisiert (user, isAuthenticated)
                ↓
7. Zukunftige Anfragen: Token im Authorization-Header
                ↓
8. Bei 401: Automatische Token-Aktualisierung mit Refresh-Token
```

---

## Sicherheitskonzept

### Authentifizierung

| Aspekt | Implementierung |
|--------|-----------------|
| Kennwort-Speicherung | BCrypt-Hash (Kostenfaktor 10) |
| Token-Typ | JWT (JSON Web Token) |
| Signatur | HMAC-SHA256 |
| Access-Token-Gultigkeit | 24 Stunden |
| Refresh-Token-Gultigkeit | 7 Tage |

### Autorisierung

**Rollenbasierte Zugriffskontrolle:**
```java
@Secured({UserRole.ADMIN})
public Response deleteIdea(@PathParam("id") Long id) { ... }

@Secured({UserRole.EMPLOYEE, UserRole.PROJECT_MANAGER, UserRole.ADMIN})
public Response getIdeas() { ... }
```

**Rollenberechtigungen:**
| Aktion | Mitarbeiter | Projektleiter | Administrator |
|--------|-------------|---------------|---------------|
| Idee erstellen | Ja | Ja | Ja |
| Eigene Idee bearbeiten | Ja | Ja | Ja |
| Fremde Idee bearbeiten | Nein | Nein | Ja |
| Idee loschen | Nein | Nein | Ja |
| Status andern | Eigene | Alle | Alle |
| Benutzer verwalten | Nein | Nein | Ja |
| Prufprotokolle einsehen | Nein | Nein | Ja |

### Eingabevalidierung

```java
// JPA-Validierung
@Column(nullable = false)
@Size(min = 3, max = 200)
private String title;

@Email
private String email;

// Manuelle Validierung in Ressourcen
if (request.getTitle() == null || request.getTitle().isBlank()) {
    throw ApiException.badRequest("Titel ist erforderlich");
}
```

### Weitere Massnahmen

- **CORS-Filter:** Konfiguriert fur erlaubte Ursprunge
- **Parameterisierte Abfragen:** JPQL verhindert SQL-Injektion
- **Wochentliches Like-Limit:** Verhindert Spam
- **Prufprotokollierung:** Alle Aktionen werden protokolliert

---

## Fehlerbehandlung

### Zentralisierte Ausnahmebehandlung

```java
// Benutzerdefinierte Ausnahme
public class ApiException extends RuntimeException {
    private final int status;
    private final String message;

    public static ApiException badRequest(String message) {
        return new ApiException(400, message);
    }

    public static ApiException notFound(String message) {
        return new ApiException(404, message);
    }

    public static ApiException forbidden(String message) {
        return new ApiException(403, message);
    }
}

// Globaler Ausnahme-Handler
@Provider
public class GlobalExceptionHandler implements ExceptionMapper<Throwable> {

    @Override
    public Response toResponse(Throwable exception) {
        if (exception instanceof ApiException) {
            ApiException e = (ApiException) exception;
            return Response.status(e.getStatus())
                    .entity(new ErrorResponse(e.getStatus(), e.getMessage()))
                    .build();
        }

        // Unbekannte Fehler
        return Response.status(500)
                .entity(new ErrorResponse(500, "Interner Serverfehler"))
                .build();
    }
}
```

### Fehlerformat

```json
{
    "status": 400,
    "error": "Bad Request",
    "message": "Titel ist erforderlich",
    "timestamp": "2026-01-25T10:30:00"
}
```

### Vorderseiten-Fehlerbehandlung

```typescript
// Zentralisierte Fehlerbehandlung in api.ts
api.interceptors.response.use(
    response => response,
    error => {
        const message = error.response?.data?.message || 'Ein Fehler ist aufgetreten';
        toast.error(message);
        return Promise.reject(error);
    }
);
```

---

## Containerisierung

### Mehrstufige Builds

**Ruckseite:**
```dockerfile
# Stufe 1: Build
FROM maven:3.9-eclipse-temurin-17 AS build
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

# Stufe 2: Laufzeit
FROM eclipse-temurin:17-jdk-jammy
# GlassFish Installation...
COPY --from=build /target/ideaboard.war /glassfish/domains/domain1/autodeploy/
```

**Vorderseite:**
```dockerfile
# Stufe 1: Build
FROM node:20-alpine AS build
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

# Stufe 2: Produktion
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
```

### Gesundheitsprufungen

```yaml
# docker-compose.yml
services:
  backend:
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/ideaboard/api/health"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 180s

  db:
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5
```

### Netzwerk und Volumes

```yaml
networks:
  ideaboard-network:
    driver: bridge

volumes:
  pgdata:  # Persistente Datenbank-Daten
```

---

## Weitere Ressourcen

- [React-Dokumentation](https://react.dev/)
- [TypeScript-Handbuch](https://www.typescriptlang.org/docs/)
- [Jakarta EE Tutorial](https://jakarta.ee/learn/)
- [Docker-Dokumentation](https://docs.docker.com/)
- [PostgreSQL-Dokumentation](https://www.postgresql.org/docs/)

---

*Zurck zur [Dokumentationsubersicht](README.md)*
