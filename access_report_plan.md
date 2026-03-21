# Access Report - Piano di Implementazione

## Obiettivo

Implementare un sistema di logging degli accessi al sistema, con report visibile esclusivamente agli utenti con ruolo OWNER.

---

## Backend

### 1. Entità `AccessLog`

**File**: `AtixBackEnd/src/main/java/marcomanfrin/atixbackend/entities/AccessLog.java`

```java
@Entity
@Table(name = "access_logs")
public class AccessLog {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "user_id")
    private User user;               // null se login fallito con email inesistente

    private String email;            // sempre presente, anche se l'utente non esiste
    private LocalDateTime timestamp;
    private String ipAddress;
    private String userAgent;
    private boolean success;
    private String failureReason;    // "INVALID_PASSWORD", "USER_NOT_FOUND", etc.
}
```

### 2. Repository

**File**: `AccessLogRepository.java`

```java
public interface AccessLogRepository extends JpaRepository<AccessLog, UUID> {
    Page<AccessLog> findAll(Specification<AccessLog> spec, Pageable pageable);
}
```

### 3. Specification per filtri dinamici

**File**: `AccessLogSpecification.java`

Filtri supportati:
- `userId` — accessi di un utente specifico
- `from` / `to` — intervallo temporale
- `success` — solo successi o fallimenti
- `email` — ricerca per email (utile per tentativi falliti)

### 4. Modifica AuthService

**File**: `AuthService.java`

Nel metodo `login()`, aggiungere il salvataggio dell'AccessLog:
- Iniettare `HttpServletRequest` per estrarre IP e User-Agent
- Salvare un record **sia per login riusciti che falliti**
- Catturare il motivo del fallimento (utente non trovato, password errata)

```java
// Pseudo-codice
public LoginResponseDTO login(LoginDTO loginDTO, HttpServletRequest request) {
    String ip = extractIpAddress(request);
    String userAgent = request.getHeader("User-Agent");

    try {
        User user = userRepository.findByEmail(loginDTO.email())
            .orElseThrow(() -> {
                saveAccessLog(null, loginDTO.email(), ip, userAgent, false, "USER_NOT_FOUND");
                return new NotFoundException("User not found");
            });

        if (!passwordEncoder.matches(loginDTO.password(), user.getPasswordHash())) {
            saveAccessLog(user, loginDTO.email(), ip, userAgent, false, "INVALID_PASSWORD");
            throw new UnauthorizedException("Invalid credentials");
        }

        saveAccessLog(user, loginDTO.email(), ip, userAgent, true, null);
        // ... generazione token e risposta
    }
}
```

### 5. AccessLogService

**File**: `AccessLogService.java`

- `saveAccessLog(...)` — salvataggio del log
- `getAccessLogs(filtri, pageable)` — lettura paginata con Specification

### 6. DTO

**File**: `DTO/accessLog/AccessLogResponseDTO.java`

```java
public record AccessLogResponseDTO(
    UUID id,
    UUID userId,
    String userFullName,
    String email,
    LocalDateTime timestamp,
    String ipAddress,
    String userAgent,
    boolean success,
    String failureReason
) {}
```

### 7. Controller

**File**: `AccessLogController.java`

```java
@RestController
@RequestMapping("/api/access-logs")
public class AccessLogController {

    @GetMapping
    @PreAuthorize("hasRole('OWNER')")
    public Page<AccessLogResponseDTO> getAccessLogs(
        @RequestParam(required = false) UUID userId,
        @RequestParam(required = false) LocalDateTime from,
        @RequestParam(required = false) LocalDateTime to,
        @RequestParam(required = false) Boolean success,
        @RequestParam(required = false) String email,
        @RequestParam(defaultValue = "0") int page,
        @RequestParam(defaultValue = "50") int size,
        @RequestParam(defaultValue = "timestamp,desc") String sort
    ) { ... }
}
```

---

## Frontend

### 8. Tipi TypeScript

**File**: `types/index.ts`

```typescript
export interface AccessLog {
  id: string;
  userId: string | null;
  userFullName: string | null;
  email: string;
  timestamp: string;
  ipAddress: string;
  userAgent: string;
  success: boolean;
  failureReason: string | null;
}
```

### 9. Hook API

**File**: `hooks/api/useAccessLogs.ts`

- `useAccessLogs(filters, pagination)` — query paginata con React Query

### 10. Pagina Access Logs

**File**: `pages/AccessLogsPage.tsx`

Componenti:
- Tabella paginata con colonne: Data/Ora, Utente, Email, IP, Esito, Motivo fallimento
- Filtri: intervallo date, utente (select), esito (successo/fallimento)
- Badge colorato per esito (verde = successo, rosso = fallimento)
- Ordinamento per timestamp (default: più recenti prima)

### 11. Sidebar

**File**: `components/layout/AppSidebar.tsx`

Aggiungere voce nel menu management:

```typescript
{
  title: t('sidebar.accessLogs'),
  url: '/access-logs',
  icon: ShieldCheck,        // da lucide-react
  ownerOnly: true
}
```

Filtro: `!item.ownerOnly || isOwner()`

### 12. Routing

**File**: `App.tsx`

Aggiungere route: `<Route path="/access-logs" element={<AccessLogsPage />} />`

### 13. Traduzioni i18n

**EN** (`locales/en/`):
```json
{
  "accessLogs": {
    "title": "Access Logs",
    "timestamp": "Date/Time",
    "user": "User",
    "email": "Email",
    "ipAddress": "IP Address",
    "success": "Success",
    "failure": "Failure",
    "failureReason": "Reason",
    "filterByUser": "Filter by user",
    "filterByDate": "Filter by date",
    "filterByOutcome": "Filter by outcome"
  }
}
```

**IT** (`locales/it/`): equivalente in italiano.

---

## Considerazioni

### Privacy / GDPR
- L'indirizzo IP è un dato personale ai sensi del GDPR
- Valutare se mostrare IP completo o offuscato (es. `192.168.1.xxx`)
- Informare gli utenti nella privacy policy che gli accessi vengono tracciati

### Retention dei dati
- Implementare un job schedulato (es. `@Scheduled`) per eliminare log più vecchi di 90 giorni
- In alternativa, rendere il periodo configurabile via `env.properties`

### Ordine di implementazione
1. Entità + Repository + Specification
2. Modifica AuthService + AccessLogService
3. Controller + DTO
4. Frontend: tipi + hook + pagina
5. Sidebar + routing + i18n
6. (Opzionale) Job di retention
