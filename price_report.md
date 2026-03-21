# Report di Valutazione - Piattaforma AtixOps

**Data:** 21 Marzo 2026
**Versione:** 1.0

---

## 1. Panoramica del Prodotto

AtixOps è una piattaforma gestionale completa per la gestione di interventi tecnici, ticketing e reportistica operativa. Il sistema è composto da un backend enterprise-grade e un frontend moderno e responsive, con supporto multilingua (IT/EN).

---

## 2. Stack Tecnologico

| Componente | Tecnologia |
|------------|-----------|
| Backend | Java 21, Spring Boot 4.0.0, PostgreSQL |
| Frontend | React 18, TypeScript, Vite, Tailwind CSS |
| Autenticazione | JWT con RBAC (3 ruoli, 3 tipi utente) |
| API | REST (67 endpoint) + GraphQL |
| Storage file | Cloudinary + MinIO (S3-compatible) |
| Email transazionali | Mailgun |
| Monitoraggio errori | Sentry |
| Deploy | Docker (multi-stage, production-ready) |
| Internazionalizzazione | i18next (Italiano + Inglese, 805 chiavi) |

---

## 3. Dimensione e Complessità del Software

### Backend
| Elemento | Quantità |
|----------|----------|
| Entità JPA | 16 |
| Controller REST | 13 |
| Endpoint HTTP | 67 |
| Servizi business | 13 |
| DTO (request/response) | 42 |
| Specifiche JPA (filtri dinamici) | 3 |
| Integrazioni esterne | 4 |
| Resolver GraphQL | 1 |
| File Java totali | ~80+ |

### Frontend
| Elemento | Quantità |
|----------|----------|
| Pagine applicative | 17 |
| Componenti UI (shadcn + custom) | 60 |
| Hook API (React Query) | 11 |
| File di traduzione | 30 (15 namespace × 2 lingue) |
| Linee di codice TypeScript | ~15.000 |
| Dipendenze npm | 43 produzione + 12 sviluppo |

### Funzionalità Principali
- Dashboard con grafici e KPI in tempo reale
- Gestione completa ordini di lavoro con macchina a stati (SCHEDULED → IN_PROGRESS → CLOSED → INVOICED)
- Sistema di ticketing integrato con sincronizzazione automatica degli stati
- Gestione clienti, impianti, referenti di cantiere
- Assegnazione tecnici agli interventi
- Reportistica dettagliata per singolo intervento
- Sistema allegati polimorfico (file su qualsiasi entità)
- Log di accesso e audit trail
- Gestione profilo utente con avatar
- Interfaccia responsive (mobile-first)
- Tema chiaro/scuro
- Controllo accessi basato su ruolo e tipo utente

---

## 4. Stima delle Ore di Sviluppo

### Backend (~320 ore)
| Attività | Ore |
|----------|-----|
| Modellazione entità e schema DB (16 entità, 15 relazioni) | 40 |
| Controller + Servizi (67 endpoint, logica business) | 120 |
| Sicurezza (JWT, RBAC, filtri, configurazione) | 30 |
| Integrazioni esterne (Cloudinary, MinIO, Mailgun, Sentry) | 40 |
| Macchina a stati workflow + sincronizzazione ticket | 20 |
| DTO, validazione, eccezioni custom | 25 |
| Specifiche JPA per filtri dinamici | 15 |
| GraphQL (schema + resolver dashboard) | 10 |
| Configurazione Docker e deploy | 15 |
| Documentazione API + collection Postman | 15 |

### Frontend (~430 ore)
| Attività | Ore |
|----------|-----|
| 17 pagine applicative (da semplice a molto complessa) | 200 |
| Setup componenti UI + personalizzazioni | 40 |
| Hook API + integrazione React Query | 30 |
| Autenticazione, routing, protezione rotte | 20 |
| Internazionalizzazione (805 chiavi × 2 lingue) | 40 |
| Styling, responsive design, tema chiaro/scuro | 40 |
| Grafici e data visualization | 15 |
| Gestione allegati e upload file | 20 |
| Form complessi + validazione (Zod + React Hook Form) | 25 |

### Altro (~70 ore)
| Attività | Ore |
|----------|-----|
| Architettura e progettazione | 40 |
| DevOps, CI/CD, configurazione ambienti | 15 |
| Documentazione tecnica | 15 |

### **Totale stimato: ~820 ore di sviluppo**

---

## 5. Proposta Economica

### A) Valore del Software Sviluppato

| Voce | Dettaglio | Importo |
|------|-----------|---------|
| Sviluppo software | 820 ore × €55/ora (tariffa media sviluppatore mid-senior) | €45.100 |
| **Valore sviluppo** | | **€45.100** |

> *Nota: tariffe di mercato per sviluppo custom full-stack in Italia variano da €40-60/ora (freelance mid-senior) a €80-120/ora (agenzia/consulenza). Il valore a tariffa agenzia sarebbe €65.600 - €98.400.*

### B) Messa in Servizio (Setup e Deployment)

| Voce | Dettaglio | Importo |
|------|-----------|---------|
| Provisioning server (VPS/Cloud) | Setup infrastruttura, Docker, reverse proxy, SSL | €800 |
| Configurazione database PostgreSQL | Setup, backup automatici, tuning | €400 |
| Configurazione servizi esterni | Cloudinary, MinIO, Mailgun, Sentry, dominio | €500 |
| Migrazione dati iniziale | Import dati esistenti (se applicabile) | €300 - €1.500 |
| Configurazione DNS e certificati SSL | Dominio + HTTPS | €200 |
| Test di integrazione e collaudo | Verifica end-to-end in ambiente produzione | €600 |
| Formazione utenti | Sessione formativa (2-4 ore) | €300 |
| **Totale messa in servizio** | | **€3.100 - €4.300** |

### C) Costi Infrastruttura Ricorrenti (stima mensile)

| Voce | Importo/mese |
|------|-------------|
| Server VPS (4 vCPU, 8GB RAM) | €25 - €50 |
| Database PostgreSQL managed (opzionale) | €15 - €30 |
| Cloudinary (piano free/base) | €0 - €50 |
| MinIO (self-hosted su stesso server) | incluso |
| Mailgun (transazionale) | €0 - €35 |
| Sentry (piano free/team) | €0 - €26 |
| Dominio + SSL | €1 - €3 |
| **Totale infrastruttura** | **€40 - €195/mese** |

### D) Manutenzione e Supporto (opzionale)

| Piano | Include | Importo/mese |
|-------|---------|-------------|
| Base | Bug fix, aggiornamenti sicurezza, monitoring | €200/mese |
| Standard | Base + supporto email, piccoli miglioramenti (4h/mese) | €400/mese |
| Premium | Standard + supporto prioritario, evolutive (8h/mese) | €700/mese |

---

## 6. Riepilogo Opzioni di Vendita

### Opzione 1 — Licenza + Messa in Servizio (consigliata)

| Voce | Importo |
|------|---------|
| Licenza software | €12.000 |
| Messa in servizio | €3.500 |
| Formazione | inclusa |
| **Totale una tantum** | **€15.500** |
| Manutenzione base (annuale) | €2.400/anno |

### Opzione 2 — Pacchetto Completo Chiavi in Mano

| Voce | Importo |
|------|---------|
| Licenza software | €12.000 |
| Messa in servizio | €3.500 |
| Infrastruttura primo anno | inclusa |
| Manutenzione standard primo anno | inclusa |
| Formazione | inclusa |
| **Totale primo anno** | **€20.000** |
| Rinnovo annuale (infra + manutenzione) | €5.500/anno |

### Opzione 3 — SaaS (canone mensile)

| Voce | Importo |
|------|---------|
| Setup iniziale | €2.000 |
| Canone mensile (tutto incluso) | €350/mese |
| **Costo primo anno** | **€6.200** |
| **Costo anni successivi** | **€4.200/anno** |

> *Il modello SaaS è interessante per il cliente (costo d'ingresso basso) e per il fornitore (ricavo ricorrente). Non include personalizzazioni.*

---

## 7. Note

- I prezzi **non includono IVA** (22%)
- Personalizzazioni aggiuntive vengono quotate separatamente a €55/ora
- Il software è venduto in licenza d'uso, non in cessione del codice sorgente (salvo diverso accordo)
- La stima del valore di sviluppo (€45.100) rappresenta il costo di ricostruzione, non il prezzo di vendita — il prezzo di vendita riflette il valore per il cliente, il mercato di riferimento e il modello commerciale scelto
- I costi infrastrutturali possono variare in base al provider scelto e al volume di utilizzo

---

*Report generato il 21/03/2026*
