# Sprint Report 2

**Data**: 2026-02-27

---

## Bug Fix 1 — Frontend: selettore ruolo WorksiteReference incompleto

### Causa
In `WorkDetailPage.tsx` il tipo del `useState` era `'PLUMBER' | 'ELECTRICIAN'`
e il `<SelectContent>` conteneva solo i corrispondenti due `<SelectItem>`,
escludendo `MAINTENANCE` e `OTHER` già supportati dal backend e dalle traduzioni.

### Modifiche
**`AtixFrontEnd/src/pages/WorkDetailPage.tsx`**
- Aggiunto `WorksiteReferenceRole` all'import da `@/types` (riga 18)
- Tipo del `useState<WorksiteReferenceRole>` (riga 153)
- Aggiunti `<SelectItem value="MAINTENANCE">` e `<SelectItem value="OTHER">`
  nel selettore (righe 1414-1415)

### Risultato
Il dropdown mostra ora tutti e 4 i ruoli: Idraulico, Elettricista,
Manutentore, Altro.

---

## Bug Fix 2 — Backend: 500 → 403 per utenti non-tecnici su work report entry

### Causa
Gli endpoint `POST /work-reports/entries` e `PATCH /work-reports/entries/{id}`
non avevano l'annotazione `@PreAuthorize` (era presente come commento TODO).
Senza quel guard, la request arrivava al service dove `(TechnicianUser) currentUser`
lanciava una `ClassCastException` per utenti non-tecnici → HTTP 500.

Il metodo `SecurityService.isTechnician()` era già implementato correttamente.

### Modifiche
**`AtixBackEnd/.../controllers/WorkReportsController.java`**
- Riga 35: aggiunto `@PreAuthorize("@securityService.isTechnician(authentication)")`
  su `POST /entries`
- Riga 43: stessa annotazione su `PATCH /entries/{id}`

### Risultato
Un utente non-tecnico che tenta di creare o aggiornare una work report entry
riceve ora HTTP 403 Forbidden prima che la request raggiunga il service.

---

## File modificati

| File | Tipo modifica |
|------|---------------|
| `AtixFrontEnd/src/pages/WorkDetailPage.tsx` | Bug fix frontend |
| `AtixBackEnd/.../controllers/WorkReportsController.java` | Bug fix backend |

## Todo svuotato

Entrambi i task del `todo.md` sono stati risolti.
