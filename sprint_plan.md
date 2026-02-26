# Sprint Plan

Data: 2026-02-26

---

## Bug Fix (alta priorità)

| # | Task | Componente |
|---|------|------------|
| B1 | Un utente di tipo `ADMINISTRATION` non riesce a marcare un lavoro come fatturato | Backend / Frontend |
| B2 | Rimuovere dalla sidebar il tasto `worksite reference` | Frontend |
| B3 | Elimina work report entry non funziona | Backend / Frontend |

---

## Testi / i18n

| # | Task | Note |
|---|------|------|
| T1 | `elettricista` → `impiantista elettrico` | locales it/ + en/ |
| T2 | `idraulico` → `impiantista idraulico` | locales it/ + en/ |
| T3 | `frase psw` → `System Passphrase` | locales it/ + en/ |
| T4 | `nome` → `nome lavoro` (filtri pagina Works) | locales it/ + en/ + componente filtri |

---

## Feature

| # | Task | Componente | Priorità |
|---|------|------------|----------|
| F1 | Pagina `works`: ordinare dal più recente al meno recente (per data creazione) | Backend + Frontend | Alta |
| F2 | Pagina `clients`: ordinare in ordine alfabetico | Backend + Frontend | Alta |
| F3 | Card `work` in pagina `works`: aggiungere cliente atix dopo numero ordine (ordine: n. ordine → cliente atix → impianto → tecnico → data avviamento) | Frontend | Alta |
| F4 | Pagina `works`: riordinare schede con ordine aperti → chiusi → non assegnati | Frontend | Alta |
| F5 | Utente `TECHNICIAN`: permesso di eliminare un lavoro | Backend + Frontend | Media |
| F6 | `WorksiteReferenceRole`: aggiungere valori `manutentore` e `altro` | Backend + Frontend | Media |
| F7 | Rendere `numero offerta` in un work NULLABLE | Backend (DB migration) | Media |
| F8 | Work report entry: consentire numero ore = 0 | Backend (validazione) | Media |
| F9 | Dashboard per `TECHNICIAN`: mostrare solo i lavori assegnati all'utente loggato | Backend + Frontend | Alta |

---

## Riepilogo

| Categoria | Totale task |
|-----------|-------------|
| Bug Fix   | 3 |
| Testi     | 4 |
| Feature   | 9 |
| **Totale**| **16** |

---

## Note

- I bug fix vanno risolti prima delle feature.
- Le modifiche ai testi (T1–T4) sono indipendenti e possono essere fatte in parallelo.
- F7 richiede una migration del database — verificare impatto su dati esistenti.
- F9 richiede un filtro lato backend nelle query dei lavori basato sul `currentUser`.
