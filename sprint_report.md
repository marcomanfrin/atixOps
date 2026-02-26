# Sprint Report

**Data**: 2026-02-26
**Branch**: `dev`
**Commit base**: `c1c5c98` (errori tradotti)

---

## Riepilogo esecutivo

Sprint completato con **16 task** risolti: 3 bug fix, 4 aggiornamenti testi/i18n, 9 feature.
Nessun errore introdotto nei file modificati (verificato via diagnostici IDE).
La feature F5 era già presente dal commit precedente (`d4176a7`) e non ha richiesto intervento.

---

## Bug Fix

### B1 — Utente ADMINISTRATION non riesce a marcare un lavoro come fatturato

**Problema**
L'endpoint `PATCH /works/{id}/invoice` era protetto con `@PreAuthorize("hasAnyRole('ADMIN', 'OWNER')")`.
Gli utenti di tipo `ADMINISTRATION` con ruolo `USER` ricevevano un 403 Forbidden anche se semanticamente autorizzati a fatturare.

**Causa**
Il sistema distingue *ruolo* (`USER`, `ADMIN`, `OWNER`) da *tipo utente* (`TECHNICIAN`, `ADMINISTRATION`, `SELLER`).
Un utente `ADMINISTRATION` con ruolo `USER` non soddisfaceva il controllo basato solo sul ruolo.

**Fix**
```java
// WorksController.java
@PreAuthorize("hasAnyRole('ADMIN', 'OWNER') or @securityService.isAdministrative(authentication)")
```
Il metodo `isAdministrative()` è già presente in `SecurityService` e controlla il tipo via `instanceof AdministrativeUser`.

**File modificati**
- `AtixBackEnd/.../controllers/WorksController.java`

---

### B2 — Rimuovere il tasto "Worksite Reference" dalla sidebar

**Problema**
Il link "Riferimenti cantiere" era visibile nella sidebar per tutti gli utenti, ma la sezione non è destinata all'uso corrente.

**Fix**
Rimossa la voce `worksiteReferences` dall'array `managementItems` in `AppSidebar.tsx`.
Rimosso anche l'import `Wrench` da `lucide-react` che era usato esclusivamente da quella voce.

**File modificati**
- `AtixFrontEnd/.../components/layout/AppSidebar.tsx`

---

### B3 — Elimina work report entry non funziona

**Problema**
L'endpoint `DELETE /work-reports/entries/{id}` era protetto con `@PreAuthorize("hasRole('OWNER')")`.
Qualsiasi utente con ruolo `ADMIN` o di tipo `ADMINISTRATION` riceveva un 403 Forbidden al tentativo di eliminazione.

**Fix**
```java
// WorkReportsController.java
@PreAuthorize("hasAnyRole('ADMIN', 'OWNER') or @securityService.isAdministrative(authentication)")
```

**File modificati**
- `AtixBackEnd/.../controllers/WorkReportsController.java`

---

## Testi / i18n

### T1 — elettricista → impiantista elettrico

| Lingua | Chiave | Prima | Dopo |
|--------|--------|-------|------|
| IT | `roles.ELECTRICIAN` | Elettricista | Impiantista elettrico |
| EN | `roles.ELECTRICIAN` | Electrician | Electrical Installer |

**File modificati**
- `AtixFrontEnd/.../locales/it/worksite-references.json`
- `AtixFrontEnd/.../locales/en/worksite-references.json`

---

### T2 — idraulico → impiantista idraulico

| Lingua | Chiave | Prima | Dopo |
|--------|--------|-------|------|
| IT | `roles.PLUMBER` | Idraulico | Impiantista idraulico |
| EN | `roles.PLUMBER` | Plumber | Hydraulic Installer |

**File modificati**
- `AtixFrontEnd/.../locales/it/worksite-references.json`
- `AtixFrontEnd/.../locales/en/worksite-references.json`

---

### T3 — frase psw → System Passphrase

La dicitura "Frase PSW" compariva in più punti dell'interfaccia (scheda impianto e scheda lavoro).
Uniformata a "System Passphrase" in tutte le occorrenze e in entrambe le lingue.

| File | Chiavi aggiornate |
|------|-------------------|
| `it/plants.json` | `details.pswPhrase`, `form.pswPhraseLabel` |
| `en/plants.json` | `details.pswPhrase`, `form.pswPhraseLabel` |
| `it/works.json` | `addPlant.pswPhraseLabel` |
| `en/works.json` | `addPlant.pswPhraseLabel` |

---

### T4 — nome → nome lavoro (filtri pagina Works)

Il filtro testuale nella pagina Works era etichettato genericamente "Nome".
Rinominato in "Nome lavoro" (IT) / "Work Name" (EN) per chiarire che il filtro si riferisce al nome del lavoro e non al nome del cliente o dell'impianto.

| Lingua | Chiave | Prima | Dopo |
|--------|--------|-------|------|
| IT | `filters.name` | Nome | Nome lavoro |
| EN | `filters.name` | Name | Work Name |

**File modificati**
- `AtixFrontEnd/.../locales/it/works.json`
- `AtixFrontEnd/.../locales/en/works.json`

---

## Feature

### F1 — Ordinamento lavori dal più recente al meno recente

**Implementazione**
Aggiunto il parametro `sort: 'createdAt,desc'` ai `listParams` nella pagina Works.
Spring Data JPA riceve il parametro tramite `Pageable` e ordina la query sul campo `created_at` della tabella `works`.
Il campo `createdAt` è già presente nell'entità `Work` con `@PrePersist` e `updatable = false`.

```typescript
// WorksPage.tsx — listParams
sort: 'createdAt,desc',
```

**Note**
- Il campo `createdAt` non è incluso nel `WorkSummaryResponse` (non serve lato frontend) ma è presente nel DB, quindi l'ordinamento funziona a livello di query.
- I `countParams` (size=1) non sono stati modificati perché il count è indipendente dall'ordinamento.

**File modificati**
- `AtixFrontEnd/.../pages/WorksPage.tsx`

---

### F2 — Ordinamento clienti in ordine alfabetico

**Implementazione**
Aggiunto `&sort=name,asc` alla URL della chiamata `clientsApi.getAll()` in `api.ts`.
L'ordinamento avviene lato backend tramite `Pageable`, senza modifiche al backend.

```typescript
// api.ts
getAll: (page = 0, size = 20) =>
  apiRequest<any>(`/clients?page=${page}&size=${size}&sort=name,asc`),
```

**Impatto**: si applica a tutte le pagine che usano `useClients()` (ClientsPage, filtri in WorksPage, CreateWorkPage, ecc.).

**File modificati**
- `AtixFrontEnd/.../lib/api.ts`

---

### F3 — Aggiungere cliente ATIX alla card lavoro

**Problema**
Il `WorkSummaryResponse` (usato dalla lista lavori) includeva solo `finalClient` ma non `atixClient`.
La funzione `getClientNames()` nel frontend tentava di leggere `work.atixClient?.name` ma il campo era sempre `undefined` per i lavori in lista.

**Implementazione**

*Backend*: aggiunto `ClientResponse atixClient` al record `WorkSummaryResponse` e popolato nel metodo `toWorkSummaryResponse()` in `WorkService`.

```java
// WorkSummaryResponse.java
ClientResponse atixClient,   // aggiunto prima di finalClient
ClientResponse finalClient,

// WorkService.java — toWorkSummaryResponse
work.getAtixClient() != null ? toClientResponse(work.getAtixClient()) : null,
```

*Frontend*: nessuna modifica necessaria — `getClientNames()` già leggeva `work.atixClient?.name` e lo includeva nella riga informativa della card.

L'ordine risultante nella card è: **numero ordine → cliente (atix/finale) → impianto → tecnico → data avviamento**.

**File modificati**
- `AtixBackEnd/.../DTO/works/WorkSummaryResponse.java`
- `AtixBackEnd/.../services/WorkService.java`

---

### F4 — Riordinare le schede nella pagina Works

**Specifica**: aperti → chiusi → non assegnati (precedente: non assegnati → aperti → chiusi).

**Implementazione**
- Cambiato `activeTab` default da `'scheduled'` a `'open'`
- Riordinato l'array `TabsTrigger` nella `TabsList`
- Riordinato l'array `TabsContent` (per coerenza con la struttura del DOM)

```tsx
// WorksPage.tsx
const [activeTab, setActiveTab] = useState('open');

<TabsList>
  <TabsTrigger value="open">...</TabsTrigger>
  <TabsTrigger value="closed">...</TabsTrigger>
  <TabsTrigger value="scheduled">...</TabsTrigger>
</TabsList>
```

**File modificati**
- `AtixFrontEnd/.../pages/WorksPage.tsx`

---

### F5 — Permesso eliminazione lavoro per TECHNICIAN *(già implementata)*

Presente dal commit `d4176a7` ("tecnici possono eliminare un lavoro").

- Backend: `@PreAuthorize("hasRole('OWNER') or @securityService.isTechnician(authentication)")` su `DELETE /works/{id}`
- Frontend: `const canDelete = isOwner() || currentUser?.type === 'TECHNICIAN'`

Nessuna modifica necessaria in questo sprint.

---

### F6 — Aggiungere MANUTENTORE e ALTRO a WorksiteReferenceRole

**Implementazione**

*Backend*: aggiunti `MAINTENANCE` e `OTHER` all'enum `WorksiteReferenceRole`.

```java
// WorksiteReferenceRole.java
public enum WorksiteReferenceRole {
    PLUMBER, ELECTRICIAN, MAINTENANCE, OTHER
}
```

*Frontend*: aggiornato il tipo TypeScript.

```typescript
// types/index.ts
export type WorksiteReferenceRole = 'PLUMBER' | 'ELECTRICIAN' | 'MAINTENANCE' | 'OTHER';
```

*Locale*: aggiunto `MAINTENANCE` ai file di traduzione (la voce `OTHER` era già presente come placeholder).

| Lingua | MAINTENANCE |
|--------|-------------|
| IT | Manutentore |
| EN | Maintenance |

**File modificati**
- `AtixBackEnd/.../enums/WorksiteReferenceRole.java`
- `AtixFrontEnd/.../types/index.ts`
- `AtixFrontEnd/.../locales/it/worksite-references.json`
- `AtixFrontEnd/.../locales/en/worksite-references.json`

---

### F7 — Rendere "numero offerta" nullable

**Implementazione**

*Entità*: cambiato constraint DB da `nullable = false` a `nullable = true`.
Con `ddl-auto = update`, il vincolo `NOT NULL` sulla colonna `bid_number` verrà rimosso al prossimo avvio dell'applicazione.

```java
// Work.java
@Column(nullable = true)
private String bidNumber;
```

*DTO*: rimosso `@NotBlank` da `WorkRequest`.

```java
// WorkRequest.java — prima
@NotBlank(message = "Bid number is required")
String bidNumber,

// dopo
String bidNumber,  // opzionale
```

`WorkUpdateRequest` non aveva `@NotBlank` su `bidNumber`, quindi non ha richiesto modifiche.

**Nota**: il frontend `CreateWorkPage.tsx` mostra già il campo come opzionale nella UI — nessuna modifica necessaria.

**File modificati**
- `AtixBackEnd/.../entities/Work.java`
- `AtixBackEnd/.../DTO/works/WorkRequest.java`

---

### F8 — Consentire numero ore = 0 in work report entry

**Problema**
La validazione `@DecimalMin(value = "0.0", inclusive = false)` impediva di salvare una entry con `hours = 0`.
Esisteva lo stesso vincolo anche nel DTO di aggiornamento.

**Fix**
```java
// WorkReportEntryRequest.java e WorkReportEntryUpdateRequest.java
@DecimalMin(value = "0.0", inclusive = true, message = "Hours must be 0 or greater")
BigDecimal hours,
```

**File modificati**
- `AtixBackEnd/.../DTO/workReports/WorkReportEntryRequest.java`
- `AtixBackEnd/.../DTO/workReports/WorkReportEntryUpdateRequest.java`

---

### F9 — Dashboard: TECHNICIAN vede solo i propri lavori

**Specifica**: quando un utente di tipo `TECHNICIAN` accede alla dashboard, la sezione "Lavori recenti" deve mostrare solo i lavori a cui è assegnato.

**Implementazione**

*`useWorks.ts`*: il hook ora accetta `null` come valore di `params` per disabilitare la query (utile per fetch condizionali senza violare le regole degli hook React).

```typescript
export function useWorks(params?: Record<string, any> | null) {
  return useQuery<PaginatedResponse<Work>>({
    ...
    enabled: params !== null,
  });
}
```

*`Dashboard.tsx`*: quando l'utente loggato è di tipo `TECHNICIAN`, viene effettuata una seconda chiamata a `useWorks` con `technicianId` dell'utente corrente. Il risultato sostituisce `data.recentWorks` nella sezione "Lavori recenti".

```typescript
const isTechnician = currentUser?.type === 'TECHNICIAN';

const { data: technicianWorksData } = useWorks(
  isTechnician && currentUser?.id
    ? { technicianId: currentUser.id, page: 0, size: 5, sort: 'createdAt,desc' }
    : null
);

const recentWorksToShow = isTechnician && technicianWorksData?.content
  ? technicianWorksData.content
  : data?.recentWorks ?? [];
```

**Scope**
- Filtrati: i lavori nella sezione "Lavori recenti"
- Non filtrati: grafici a torta (distribuzione per stato) — rimangono overview globale di sistema

**File modificati**
- `AtixFrontEnd/.../hooks/api/useWorks.ts`
- `AtixFrontEnd/.../pages/Dashboard.tsx`

---

## File modificati — elenco completo

### Backend (`AtixBackEnd`)
| File | Motivo |
|------|--------|
| `controllers/WorksController.java` | B1, F3 (comment) |
| `controllers/WorkReportsController.java` | B3 |
| `DTO/works/WorkSummaryResponse.java` | F3 |
| `DTO/works/WorkRequest.java` | F7 |
| `DTO/workReports/WorkReportEntryRequest.java` | F8 |
| `DTO/workReports/WorkReportEntryUpdateRequest.java` | F8 |
| `entities/Work.java` | F7 |
| `enums/WorksiteReferenceRole.java` | F6 |
| `services/WorkService.java` | F3 |

### Frontend (`AtixFrontEnd`)
| File | Motivo |
|------|--------|
| `components/layout/AppSidebar.tsx` | B2 |
| `hooks/api/useWorks.ts` | F9 |
| `lib/api.ts` | F2 |
| `pages/Dashboard.tsx` | F9 |
| `pages/WorksPage.tsx` | F1, F3 (comment), F4 |
| `types/index.ts` | F6 |
| `locales/it/worksite-references.json` | T1, T2, F6 |
| `locales/en/worksite-references.json` | T1, T2, F6 |
| `locales/it/plants.json` | T3 |
| `locales/en/plants.json` | T3 |
| `locales/it/works.json` | T3, T4 |
| `locales/en/works.json` | T3, T4 |

---

## Dipendenze e rischi

| Rischio | Dettaglio | Mitigazione |
|---------|-----------|-------------|
| **F7 — migrazione DB** | Rimozione vincolo `NOT NULL` su `bid_number` avviene automaticamente con `ddl-auto=update` al prossimo avvio | Nessun dato esistente viene perso; il cambio è retrocompatibile |
| **F3 — campo aggiunto al DTO** | `WorkSummaryResponse` ha un campo in più; client che deserializzano questo DTO potrebbero ignorarlo (JSON è tollerante per i campi extra) | Nessun impatto sui client esistenti |
| **F6 — nuovo valore enum** | `MAINTENANCE` e `OTHER` sono nuovi valori in un enum JPA. Dati esistenti con questi valori non ci sono (enum era PLUMBER/ELECTRICIAN). | Aggiunta sicura |
| **F9 — doppia chiamata API in Dashboard** | Per i TECHNICIAN la dashboard fa una chiamata extra a `/works?technicianId=...`. Overhead minimo (5 record, già paginati). | Accettabile |
