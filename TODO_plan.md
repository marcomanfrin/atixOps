# Piano di Implementazione TODO

## Fase 1 — Quick wins (modifiche isolate, basso rischio)

### 1. Restart policy Docker
- **File:** `docker-compose.yml`
- Aggiungere `restart: unless-stopped` a tutti i 6 servizi (postgres, minio, backend, frontend, nginx, certbot)

### 2. Ordinamento work_report_entry per data (più vecchia → più recente)
- **Approccio più semplice:** aggiungere `@OrderBy("date ASC")` sulla collection `entries` in `WorkReport.java` (line 31)
  ```java
  @OneToMany(mappedBy = "report", cascade = CascadeType.ALL, orphanRemoval = true)
  @OrderBy("date ASC")
  private List<WorkReportEntry> entries = new ArrayList<>();
  ```
- **Stato attuale:** nessun ordinamento a nessun livello (repository, service, frontend). Le entries vengono mostrate nell'ordine di inserimento nel DB
- **File coinvolti:**
  - `AtixBackEnd/.../entities/WorkReport.java` (line 31) — unico file da modificare
- **Alternativa:** ordinamento nel repository con query JPQL `ORDER BY e.date DESC` in `WorkReportEntryRepository.java` (line 17-18)

### 3. Ordinamento plants per data (più recente → meno recente)
- **File:** `AtixFrontEnd/src/pages/PlantsPage.tsx` (line 35)
- Aggiungere sort di default `createdAt,desc` nella chiamata API
- Verificare che il backend supporti il sort parameter nel `PlantsController`

### 4. Rimuovere campo NAS-SubDirectory dal frontend
- **File:** `AtixFrontEnd/src/pages/CreateWorkPage.tsx` — rimuovere input (lines 312-320)
- **File:** `AtixFrontEnd/src/pages/WorkDetailPage.tsx` — rimuovere campo edit (lines 988-995) e view (lines 1067-1073)
- Backend: nessuna modifica, campo mantenuto inalterato

### 5. Conferma prima di eliminare un file allegato
- **File:** `AtixFrontEnd/src/components/AttachmentManager.tsx` (lines 248-260)
- Wrappare il bottone delete in un `AlertDialog` (come già fatto per work deletion in `WorkDetailPage.tsx`)

### 6. Bottoni allegati riposizionati
- **File:** `AtixFrontEnd/src/components/AttachmentManager.tsx` (lines 236-260)
- Spostare delete in alto a sinistra e download in alto a destra con positioning assoluto

---

## Fase 2 — UI/UX improvements (solo frontend)

### 7. Codice lavoro più visibile nelle card
- **File:** `AtixFrontEnd/src/pages/WorksPage.tsx` (lines 719-720)
- Modificare il Badge del work index: font più grande, colore accent (es. `bg-primary text-primary-foreground text-sm font-bold`)

### 8. Tab "TUTTI/ALL" nella pagina works
- **File:** `AtixFrontEnd/src/pages/WorksPage.tsx`
- Aggiungere tab "all" prima degli altri 3 che non filtra per status
- Aggiungere query count senza filtro status
- **File:** `AtixFrontEnd/src/locales/en/works.json` e `it/works.json` — aggiungere label tradotto

### 9. PDF preview più larga su desktop (90% schermo)
- **File:** `AtixFrontEnd/src/components/AttachmentManager.tsx` (line 286)
- Cambiare `max-w-4xl` → `max-w-[90vw]` nel `DialogContent`

### 10. PDF preview scrollabile su smartphone
- **File:** `AtixFrontEnd/src/components/AttachmentManager.tsx`
- Aggiungere `overflow-auto` e `-webkit-overflow-scrolling: touch` al container dell'`<object>` PDF
- Valutare sostituzione con iframe per migliore compatibilità mobile

### 11. Dashboard card responsive (max 95% su smartphone)
- **File:** `AtixFrontEnd/src/pages/Dashboard.tsx` (line 236)
- Aggiungere `max-w-[95vw] mx-auto` o classe responsive per smartphone

### 12. Versioni nella sidebar
- **Approccio:** file statico `versions.json` nella root del frontend, modificabile a mano ad ogni release
  - Esempio: `{ "frontend": "1.0.0", "backend": "1.0.0" }`
  - Importato direttamente nel componente sidebar con `import versions from '@/../../versions.json'` o copiato in `public/`
- **Frontend:**
  - `AtixFrontEnd/src/components/layout/AppSidebar.tsx` — aggiungere nel `SidebarFooter` (prima della sezione utente, line 142) un blocco con le due versioni:
    ```tsx
    <div className="flex items-center justify-between px-3">
      <span className="text-xs text-muted-foreground">FE v{versions.frontend}</span>
      <span className="text-xs text-muted-foreground">BE v{versions.backend}</span>
    </div>
    ```
  - Nessun endpoint backend necessario — le versioni vengono aggiornate manualmente nel file statico ad ogni deploy

### 13. Limite dimensione file upload visibile nella UI
- **Backend:** verificare/configurare `spring.servlet.multipart.max-file-size` in `application.properties`
- **Frontend:** `AtixFrontEnd/src/components/AttachmentManager.tsx`
  - Aggiungere validazione dimensione prima dell'upload
  - Mostrare il limite nella UI (es. "Max 10MB per file")

---

## Fase 3 — Backend logic changes

### 14. expectedOfficeHours / expectedPlantHours → float
- **Backend:**
  - `Work.java` (lines 86-88): `int` → `double`, aggiornare getter/setter
  - `WorkRequest.java`, `WorkUpdateRequest.java`: `Integer` → `Double`
  - `WorkDetailResponse.java`: `Integer` → `Double`
  - `WorkService.java`: aggiornare cast e valori default
- **Database:** colonna PostgreSQL `int4` → `float8` (migration o ddl-auto)
- **Frontend:**
  - `types/index.ts`: già `number`, nessun cambio necessario
  - `validations.ts`: già `z.number()`, nessun cambio necessario
  - `CreateWorkPage.tsx` e `WorkDetailPage.tsx`: aggiungere `step="0.5"` agli input number

### 15. Admin può editare WorkReport e WorkReportEntry
- **File:** `AtixBackEnd/.../controllers/WorkReportsController.java`
  - POST entries (line 35): aggiungere `hasAnyRole('ADMIN', 'OWNER')` in OR con `isTechnician`
  - PATCH entries (line 43): aggiungere `hasAnyRole('ADMIN', 'OWNER')` in OR con `isTechnician`
- **File:** `AtixBackEnd/.../services/WorkReportService.java`
  - Gestire il caso in cui l'utente non è TechnicianUser (admin che edita)
  - Il campo technician potrebbe dover essere specificato nel request o restare null

---

## Fase 4 — Ricerca lavori full-text backend

### 16. Ricerca lavori lato backend
- **Backend:**
  - `WorkSpecification.java`: creare metodo `searchByKeyword(String keyword)` che cerca con `LIKE %keyword%` case-insensitive in: `name`, `atixClient.companyName`, `finalClient.companyName`, `plant.name`, combinati con OR
  - `WorksController.java`: aggiungere parametro `search` all'endpoint GET `/works`
  - `WorkService.java`: integrare la nuova specification nel filtro
- **Frontend:**
  - `WorksPage.tsx`: sostituire la ricerca client-side (lines 209-234) con parametro `search` inviato all'API
  - Aggiungere debounce (300ms) sull'input di ricerca

---

## Riepilogo

| Fase | Items | Effort | Rischio |
|------|-------|--------|---------|
| 1 — Quick wins | #1-6 | Basso | Basso |
| 2 — UI/UX | #7-13 | Medio | Basso |
| 3 — Backend logic | #14-15 | Medio | Medio (migration DB) |
| 4 — Ricerca backend | #16 | Alto | Medio |

**Totale: 16 items in 4 fasi**
