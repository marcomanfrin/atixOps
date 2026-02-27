# Sprint Plan 2

## Obiettivi

Due bug fix identificati nel todo.md.

---

## Task 1 — Frontend: aggiungere MAINTENANCE e OTHER al selettore ruolo WorksiteReference

### Problema
In `WorkDetailPage.tsx` il `useState` per `selectedRole` è tipizzato solo come
`'PLUMBER' | 'ELECTRICIAN'`, e nel JSX sono presenti solo i due `<SelectItem>`
corrispondenti. Il backend e le traduzioni supportano già tutti e 4 i valori
(`PLUMBER`, `ELECTRICIAN`, `MAINTENANCE`, `OTHER`).

### File da modificare
- `AtixFrontEnd/src/pages/WorkDetailPage.tsx`
  - Riga 153: aggiornare il tipo del `useState` a `WorksiteReferenceRole`
  - Righe 1412-1413: aggiungere `<SelectItem>` per `MAINTENANCE` e `OTHER`

### Dipendenze già presenti
- `WorksiteReferenceRole` definito in `types/index.ts`
- Traduzioni `MAINTENANCE` / `OTHER` presenti in `en/worksite-references.json`
  e `it/worksite-references.json`
- Backend enum `WorksiteReferenceRole` contiene già tutti e 4 i valori

---

## Task 2 — Backend: restituire 403 invece di 500 per utenti non-tecnici su work report entry

### Problema
Gli endpoint `POST /work-reports/entries` e `PATCH /work-reports/entries/{id}`
mancano dell'annotazione `@PreAuthorize`. Quando un utente non-tecnico chiama
questi endpoint, il service esegue un cast non sicuro `(TechnicianUser) currentUser`
che genera una `ClassCastException` → HTTP 500. Il comportamento corretto è
HTTP 403.

### File da modificare
- `AtixBackEnd/src/main/java/marcomanfrin/atixbackend/controllers/WorkReportsController.java`
  - Riga 35: sostituire il commento TODO con
    `@PreAuthorize("@securityService.isTechnician(authentication)")`
  - Riga 43: stessa cosa per l'endpoint PATCH

### Dipendenze già presenti
- `SecurityService.isTechnician()` esiste ed è correttamente implementato
- `@Component("securityService")` già registrato nel contesto Spring

---

## Stima

| Task | Effort |
|------|--------|
| Frontend selector | XS |
| Backend @PreAuthorize | XS |
