# GFOS Digital Idea Board - Dokumentation

Willkommen zur offiziellen Dokumentation des **GFOS Digital Idea Board** (Ideenbrett) - einer Innovationsmanagement-Plattform fur den GFOS Innovation Award 2026.

---

## Was ist das Ideenbrett?

Das Ideenbrett ist eine webbasierte Plattform, die es Mitarbeitern ermoglicht, innovative Ideen einzureichen, zu diskutieren und gemeinsam weiterzuentwickeln. Die Anwendung bietet:

- Ideenverwaltung mit Kategorien und Fortschrittsverfolgung
- Kommentare und Reaktionen
- Direkt- und Gruppennachrichten
- Umfragen
- Gamification mit Erfahrungspunkten und Abzeichen
- Und vieles mehr!

---

## Dokumentationsubersicht

| Dokument | Beschreibung | Zielgruppe |
|----------|--------------|------------|
| [Installationsanleitung](INSTALLATION.md) | Anleitung zur Installation und Konfiguration | Administratoren, Entwickler |
| [Benutzerhandbuch](BENUTZERHANDBUCH.md) | Vollstandige Anleitung zur Nutzung der Anwendung | Alle Benutzer |
| [Architektur](ARCHITEKTUR.md) | Technische Beschreibung der Anwendungsarchitektur | Entwickler |

---

## Schnellstart

**Voraussetzung:** Docker Desktop muss installiert und gestartet sein.

```bash
# 1. Umgebungsdatei kopieren
copy .env.example .env

# 2. Alle Dienste starten
docker compose up --build
```

Nach 2-3 Minuten erscheint die Meldung `Application deployed successfully!`. Offnen Sie dann:

**http://localhost:3000**

Weitere Details finden Sie in der [Installationsanleitung](INSTALLATION.md).

---

## Testbenutzer

| Benutzername | Kennwort | Rolle |
|--------------|----------|-------|
| admin | admin123 | Administrator |
| manager | manager123 | Projektleiter |
| user | user123 | Mitarbeiter |

---

## Technologie-Ubersicht

| Komponente | Technologie |
|------------|-------------|
| Vorderseite | React 18, TypeScript, Tailwind CSS |
| Ruckseite | Java 17, Jakarta EE 10, Jersey |
| Datenbank | PostgreSQL 15 |
| Server | GlassFish 7 |
| Bereitstellung | Docker, Docker Compose |

---

## Kontakt und Unterstutzung

Bei Fragen oder Problemen wenden Sie sich bitte an das Entwicklungsteam.

---

*Dokumentation erstellt fur den GFOS Innovation Award 2026*
