# AtixOps — Backup & Restore

Sistema di backup automatico per PostgreSQL e MinIO, con rotazione giornaliera e settimanale.

---

## Come funziona

### `backup.sh` — il cuore del sistema

Eseguito ogni notte alle **03:00** dal cron, fa queste cose in sequenza:

1. **Dump PostgreSQL** — esegue `pg_dump` dentro il container `atix-postgres` e salva il risultato compresso (`gzip`) in `/backups/atixops/daily/YYYY-MM-DD_postgres.sql.gz`
2. **Backup MinIO** — monta il volume Docker `minio_data` in sola lettura e lo archivia in `/backups/atixops/daily/YYYY-MM-DD_minio.tar.gz`
3. **Verifica** — controlla che ogni file generato esista e non sia vuoto; in caso contrario incrementa il contatore errori e lo registra nel log
4. **Rotazione giornaliera** — cancella i file `.gz` più vecchi di **7 giorni** dalla cartella `daily/`
5. **Promozione settimanale** — ogni **domenica** copia i file del giorno in `weekly/`
6. **Rotazione settimanale** — cancella i file `.gz` più vecchi di **28 giorni** da `weekly/`

Tutto viene scritto in `/backups/atixops/logs/backup.log`.

### Struttura directory

```
/backups/atixops/
├── daily/          # ultimi 7 giorni
│   ├── 2025-05-30_postgres.sql.gz
│   └── 2025-05-30_minio.tar.gz
├── weekly/         # ultimi 4 domeniche
│   ├── 2025-05-25_postgres.sql.gz
│   └── 2025-05-25_minio.tar.gz
└── logs/
    ├── backup.log  # log backup.sh
    └── cron.log    # stdout/stderr del cron
```

### `install-cron.sh` — attivazione sul server

Crea le directory, imposta i permessi su `backup.sh` e registra il cron job:

```
0 3 * * *  /path/to/backup/backup.sh >> /backups/atixops/logs/cron.log 2>&1
```

Se il cron job esiste già lo sostituisce senza duplicati.

### `restore.sh` — ripristino interattivo

Script guidato che:
1. Elenca tutti i backup disponibili (daily + weekly) con data, tipo e dimensione
2. Chiede quale backup ripristinare
3. Chiede cosa ripristinare: solo DB, solo MinIO, o entrambi
4. Richiede una conferma esplicita (`si`) prima di sovrascrivere qualsiasi dato

Il ripristino PostgreSQL chiude le connessioni attive, ricrea il database da zero e importa il dump. Il ripristino MinIO svuota il volume e lo riespande dall'archivio, poi suggerisce di riavviare il container.

---

## Requisiti

- Docker installato e in esecuzione
- Container PostgreSQL chiamato `atix-postgres`
- Volume Docker MinIO chiamato `minio_data`
- Variabili d'ambiente `PG_USERNAME` e `PG_DB_NAME` (oppure i default: `postgres` / `atix_backend`)

---

## Attivazione sul server (prima volta)

```bash
# 1. Crea la directory root con i permessi giusti
sudo mkdir -p /backups/atixops
sudo chown $(whoami) /backups/atixops

# 2. Installa il cron job (una sola volta)
./backup/install-cron.sh

# 3. Verifica che il cron sia attivo
crontab -l
```

## Test manuale

```bash
# Esegui un backup subito (senza aspettare le 03:00)
./backup/backup.sh

# Controlla il log
tail -f /backups/atixops/logs/backup.log
```

## Ripristino

```bash
./backup/restore.sh
# Segui il menu interattivo
```

---

## Cloud sync (opzionale)

In `backup.sh` è presente una sezione commentata per sincronizzare `/backups/atixops/` su un remote via [rclone](https://rclone.org). Per abilitarla:

1. Installa e configura rclone: `rclone config`
2. In `backup.sh` imposta `RCLONE_REMOTE="nomeremote:bucket"` e decommenta le righe `rclone_sync`.
