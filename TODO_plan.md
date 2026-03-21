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

### 14. Stile card lavoro e ticket nella dashboard (bianche con bordino)
- **Riferimento visivo:** `card_style.png` nella root del repo
- **File:** `AtixFrontEnd/src/pages/Dashboard.tsx`
  - Lines 238-283 (card lavori recenti): cambiare `bg-muted/30 hover:bg-muted/50` → `bg-white border border-border hover:bg-muted/10`
  - Lines 286-322 (card ticket recenti): stesso cambio di stile
- **File (opzionale):** `AtixFrontEnd/src/index.css`
  - Verificare che `--card` e `--border` diano il risultato desiderato (attualmente `--card: 0 0% 98%`, `--border: 0 0% 83%`)
- **Risultato atteso:** card bianche con bordo sottile grigio chiaro, angoli arrotondati, come da screenshot di riferimento

---

## Fase 3 — Backend logic changes

### 15. expectedOfficeHours / expectedPlantHours → float
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

### 16. Admin può editare WorkReport e WorkReportEntry
- **File:** `AtixBackEnd/.../controllers/WorkReportsController.java`
  - POST entries (line 35): aggiungere `hasAnyRole('ADMIN', 'OWNER')` in OR con `isTechnician`
  - PATCH entries (line 43): aggiungere `hasAnyRole('ADMIN', 'OWNER')` in OR con `isTechnician`
- **File:** `AtixBackEnd/.../services/WorkReportService.java`
  - Gestire il caso in cui l'utente non è TechnicianUser (admin che edita)
  - Il campo technician potrebbe dover essere specificato nel request o restare null

---

## Fase 4 — Ricerca lavori full-text backend

### 17. Ricerca lavori lato backend
- **Backend:**
  - `WorkSpecification.java`: creare metodo `searchByKeyword(String keyword)` che cerca con `LIKE %keyword%` case-insensitive in: `name`, `atixClient.companyName`, `finalClient.companyName`, `plant.name`, combinati con OR
  - `WorksController.java`: aggiungere parametro `search` all'endpoint GET `/works`
  - `WorkService.java`: integrare la nuova specification nel filtro
- **Frontend:**
  - `WorksPage.tsx`: sostituire la ricerca client-side (lines 209-234) con parametro `search` inviato all'API
  - Aggiungere debounce (300ms) sull'input di ricerca

---

## Fase 5 — Bug fixes

### 18. Bug: "Aggiungi riferimento cantiere" con ALTRO causa errore 409
- **Sintomo:** Selezionando "ALTRO" come riferimento, il nuovo riferimento viene creato (201) ma l'associazione al lavoro fallisce con 409 "Conflitto di dati"
- **Causa root:** Il riferimento viene creato e poi immediatamente associato al lavoro. Tuttavia, il flusso nel frontend (`WorkDetailPage.tsx` lines 502-599) prima crea il riferimento, poi chiama `add-reference`. Se il riferimento era già stato selezionato/associato in un tentativo precedente, la unique constraint `uk_work_worksite_reference` su `(work_id, worksite_reference_id)` in `WorksiteReferenceAssignment.java` (lines 9-16) viene violata → `DataIntegrityViolationException` → 409
- **Backend:**
  - `AtixBackEnd/.../entities/WorksiteReferenceAssignment.java` (lines 9-16): la unique constraint è su `(work_id, worksite_reference_id)` senza considerare il `role`
  - `AtixBackEnd/.../services/WorkService.java` (lines 439-454): il check `existsByWorkAndWorksiteReference()` (line 447) verifica solo se la coppia (work, reference) esiste, ma non gestisce il caso in cui l'utente ri-seleziona lo stesso riferimento con un ruolo diverso
  - `AtixBackEnd/.../repositories/WorksiteReferenceAssignmentRepository.java` (line 30): query di esistenza senza filtro sul ruolo
- **Fix proposto (opzione A — preferita):** nel `WorkService.addWorksiteReference()`, se la coppia (work, reference) esiste già, aggiornare il ruolo invece di lanciare errore (upsert)
- **Fix proposto (opzione B):** aggiungere `role` alla unique constraint: `columnNames = {"work_id", "worksite_reference_id", "role"}` — permette lo stesso riferimento con ruoli diversi sullo stesso lavoro
- **Frontend:**
  - `AtixFrontEnd/src/pages/WorkDetailPage.tsx` (lines 502-599): valutare se il flusso "crea + associa" debba essere atomico o se servono controlli aggiuntivi per evitare doppia associazione

---

## Riepilogo

| Fase | Items | Effort | Rischio |
|------|-------|--------|---------|
| 1 — Quick wins | #1-6 | Basso | Basso |
| 2 — UI/UX | #7-14 | Medio | Basso |
| 3 — Backend logic | #15-16 | Medio | Medio (migration DB) |
| 4 — Ricerca backend | #17 | Alto | Medio |
| 5 — Bug fixes | #18 | Medio | Basso |

**Totale: 18 items in 5 fasi**
