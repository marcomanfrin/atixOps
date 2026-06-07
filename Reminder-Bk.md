Ecco il riepilogo dei file creati/modificati:

Nuovi:

backup/backup.sh — dump PostgreSQL + tar MinIO, verifica, rotazione 7g+4s, logging
backup/restore.sh — restore interattivo (scelta backup, DB/MinIO/entrambi, con conferma)
backup/install-cron.sh — setup cron alle 03:00, crea directory, verifica permessi
Modificati:

.gitignore — aggiunto backup/logs/
README.md — aggiunta sezione Backup & Restore
Per attivare sul server:


sudo mkdir -p /backups/atixops
sudo chown $(whoami) /backups/atixops
./backup/install-cron.sh
Lo script è già predisposto per aggiungere cloud sync in futuro (sezione rclone commentata in backup.sh).