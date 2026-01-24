# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a full-stack application for managing technical work operations and ticketing:
- **Backend**: `/AtixBackEnd` - Spring Boot 4.0.0, Java 21, PostgreSQL
- **Frontend**: `/atixfrontend` - React 18, TypeScript, Vite, shadcn-ui

## Build & Run Commands

### Backend (AtixBackEnd)
```bash
cd AtixBackEnd
./mvnw spring-boot:run          # Development (http://localhost:3001/api)
./mvnw clean package            # Production build
./mvnw test                     # Run tests
```

### Frontend (atixfrontend)
```bash
cd atixfrontend
npm install                     # Install dependencies
npm run dev                     # Development (http://localhost:8080)
npm run build                   # Production build
npm run lint                    # ESLint
```

## Architecture

### Backend Structure
```
AtixBackEnd/src/main/java/marcomanfrin/atixbackend/
├── controllers/      # REST endpoints
├── DTO/              # Request/response objects (organized by feature)
├── entities/         # JPA entities (User uses SINGLE_TABLE inheritance)
├── enums/            # UserRole, UserType, TicketStatus, WorkStatus
├── repositories/     # Spring Data JPA
├── resolvers/        # GraphQL resolvers
├── security/         # JWT auth, filters, configs
├── services/         # Business logic
├── specifications/   # JPA Specifications for dynamic filtering
└── tools/            # Cloudinary, Mailgun utilities
```

### Frontend Structure
```
atixfrontend/src/
├── components/ui/    # shadcn-ui components
├── contexts/         # React Context providers
├── hooks/api/        # API integration hooks (React Query)
├── pages/            # Page components
├── locales/          # i18n (en/, it/)
└── types/            # TypeScript definitions
```

### Key Patterns
- **Authentication**: JWT tokens, role-based access (USER, ADMIN, OWNER)
- **User types**: TECHNICIAN, ADMINISTRATION, SELLER (affects permissions)
- **API**: REST + GraphQL (GraphiQL at `/api/graphiql` in dev)
- **State**: React Query for server state, Context for client state
- **Filtering**: JPA Specifications for complex queries
- **i18n**: English and Italian with automatic language detection

## Database

12 entities with relationships:
- **User hierarchy**: SINGLE_TABLE inheritance for TechnicianUser, AdministrativeUser, SellerUser
- **Work orders**: Link to clients (atixClient + finalClient), plants, technicians, tickets
- **Attachments**: Polymorphic via AttachmentLink (can attach to Work, Plant, Ticket, Report)

Default admin on first launch: `admin@atixbackend.com` / `Admin123!`

## Environment

Backend requires `env.properties` in AtixBackEnd root:
```properties
PG_DB_NAME, PG_USERNAME, PG_PASSWORD    # PostgreSQL
CLOUDINARY_NAME, CLOUDINARY_KEY, CLOUDINARY_SECRET
MAILGUN_DOMAIN, MAILGUN_API_KEY, MAILGUN_SENDER
JWT_SECRET                               # Min 256 bits
CORS_ALLOWED_ORIGINS
```

## API Reference

- **Postman Collection**: `AtixBackEnd/AtixBackEnd API.postman_collection.json`
- **API Documentation**: `AtixBackEnd/API_DOCUMENTATION.md`
- **Entity Relationships**: `AtixBackEnd/src/relationship.md`

## Work Order Workflow (Planned)

Status transitions: SCHEDULED → IN_PROGRESS → CLOSED → INVOICED

Ticket auto-sync:
- Work IN_PROGRESS → Ticket IN_PROGRESS
- Work CLOSED → Ticket RESOLVED
- Work INVOICED → Ticket CLOSED

See `AtixBackEnd/CLAUDE.md` for detailed implementation plan.
