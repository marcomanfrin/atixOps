# AtixOps

Full-stack application for managing technical work operations, ticketing, and client relationships.

## Tech Stack

- **Backend**: Spring Boot 4.0.0, Java 21, PostgreSQL, GraphQL
- **Frontend**: React 18, TypeScript, Vite, shadcn/ui, TailwindCSS
- **Storage**: Cloudinary (images), MinIO (files)
- **Email**: Mailgun
- **Monitoring**: Sentry
- **Auth**: JWT with role-based access control

## Project Structure

```
AtixOps/
├── AtixBackEnd/       # Spring Boot REST + GraphQL API
├── AtixFrontEnd/      # React SPA
└── CLAUDE.md          # AI assistant instructions
```

## Getting Started

### Prerequisites

- Java 21
- Node.js 18+
- PostgreSQL

### Backend

```bash
cd AtixBackEnd
# Configure env.properties (see AtixBackEnd/env.properties.example)
./mvnw spring-boot:run    # http://localhost:3001/api
```

### Frontend

```bash
cd AtixFrontEnd
npm install
npm run dev               # http://localhost:8080
```

## Key Features

- Work order management with status workflow (SCHEDULED -> IN_PROGRESS -> CLOSED -> INVOICED)
- Ticketing system with automatic status sync
- Role-based access: USER, ADMIN, OWNER
- User types: TECHNICIAN, ADMINISTRATION, SELLER
- Client and plant management
- File attachments (polymorphic)
- i18n support (English, Italian)
- REST API + GraphQL (GraphiQL available in dev at `/api/graphiql`)

## Environment Variables

The backend requires an `env.properties` file in `AtixBackEnd/`:

| Variable | Description |
|---|---|
| `PG_DB_NAME`, `PG_USERNAME`, `PG_PASSWORD` | PostgreSQL connection |
| `CLOUDINARY_NAME`, `CLOUDINARY_KEY`, `CLOUDINARY_SECRET` | Image storage |
| `MAILGUN_DOMAIN`, `MAILGUN_API_KEY`, `MAILGUN_SENDER` | Email service |
| `JWT_SECRET` | JWT signing key (min 256 bits) |
| `CORS_ALLOWED_ORIGINS` | Allowed CORS origins |

## Backup & Restore

I dati dell'app (PostgreSQL + MinIO) vengono backuppati automaticamente ogni notte alle 03:00.

### Setup (una sola volta sul server)

```bash
sudo mkdir -p /backups/atixops
sudo chown $(whoami) /backups/atixops
./backup/install-cron.sh
```

### Comandi utili

```bash
./backup/backup.sh       # Backup manuale
./backup/restore.sh      # Restore interattivo
crontab -l               # Verifica cron attivo
```

### Struttura backup

- `/backups/atixops/daily/` — ultimi 7 giorni
- `/backups/atixops/weekly/` — ultime 4 domeniche
- `/backups/atixops/logs/backup.log` — log operazioni

## API Documentation

- Postman collection: `AtixBackEnd/AtixBackEnd API.postman_collection.json`
- API docs: `AtixBackEnd/API_DOCUMENTATION.md`
- Entity relationships: `AtixBackEnd/src/relationship.md`
