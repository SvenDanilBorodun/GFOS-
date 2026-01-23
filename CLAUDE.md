# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

GFOS Digital Idea Board (Ideenbrett) - Innovation management platform for GFOS Innovation Award 2026. Full-stack web application with a React/TypeScript frontend and Java/Jakarta EE backend.

**Language:** German (UI text, comments, error messages)

## Build & Development Commands

### Frontend (C:\GGFF\GFOS-\frontend)
```bash
npm run dev        # Start dev server (port 3000, proxies /api to localhost:8080/ideaboard)
npm run build      # TypeScript check + Vite build
npm run lint       # ESLint with zero-warning policy (--max-warnings 0)
npm run preview    # Preview production build
```

### Backend (C:\GGFF\GFOS-\backend)
```bash
mvn clean compile           # Compile
mvn test                    # Run JUnit tests
mvn clean package           # Build ideaboard.war for GlassFish deployment
```

## Architecture

```
GFOS-/
├── frontend/           # React 18 + TypeScript + Vite + Tailwind CSS
│   └── src/
│       ├── pages/      # 10 route pages (Dashboard, Ideas, Surveys, Messages, Admin, etc.)
│       ├── components/ # Reusable UI components
│       ├── context/    # AuthContext, ThemeContext (React Context API)
│       ├── services/   # API service modules (axios-based)
│       └── types/      # TypeScript interfaces for all API contracts
├── backend/            # Java 17 + Jakarta EE 10 + Jersey (JAX-RS) + EclipseLink JPA
│   └── src/main/java/com/gfos/ideaboard/
│       ├── resource/   # REST endpoints (11 JAX-RS @Path resources)
│       ├── service/    # Business logic services (14 @ApplicationScoped services)
│       ├── entity/     # JPA entities (24 entities)
│       ├── dto/        # Data Transfer Objects (19 DTOs)
│       └── security/   # JWT auth (JwtUtil, JwtFilter, @Secured annotation)
└── database/           # PostgreSQL init scripts (init.sql)
```

## Key Patterns

- **Authentication:** JWT tokens stored in localStorage, Bearer token in Authorization header, automatic refresh on 401
- **User Roles:** EMPLOYEE, PROJECT_MANAGER, ADMIN (role-based access via @Secured annotation)
- **Frontend State:** React Context API (AuthContext for user session, ThemeContext for dark mode)
- **API Base Path:** Backend serves `/api/*`, frontend dev server proxies to `http://localhost:8080/ideaboard`
- **Database:** PostgreSQL with JPA DDL generation (create-or-extend-tables)

## Tech Stack Summary

| Layer | Stack |
|-------|-------|
| Frontend | React 18, TypeScript 5, Vite 5, Tailwind CSS 3, Axios |
| Backend | Java 17, Jakarta EE 10, Jersey 3.1, EclipseLink JPA 4 |
| Database | PostgreSQL 15+ |
| Auth | JWT (jjwt), BCrypt password hashing |
| Deploy | GlassFish application server (WAR deployment) |
