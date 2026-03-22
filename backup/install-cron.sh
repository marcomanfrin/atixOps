#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# AtixOps - Installazione Cron Job per Backup Automatico
# Esegui una sola volta sul server di produzione
# =============================================================================

BACKUP_ROOT="/backups/atixops"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SCRIPT="$SCRIPT_DIR/backup.sh"
CRON_SCHEDULE="0 3 * * *"  # Ogni giorno alle 03:00

# --- Controlli ----------------------------------------------------------------
if [[ ! -f "$BACKUP_SCRIPT" ]]; then
    echo "ERRORE: backup.sh non trovato in $SCRIPT_DIR"
    exit 1
fi

if ! command -v docker &> /dev/null; then
    echo "ERRORE: docker non installato"
    exit 1
fi

# --- Creazione directory ------------------------------------------------------
echo "Creazione directory backup..."
mkdir -p "$BACKUP_ROOT/daily" "$BACKUP_ROOT/weekly" "$BACKUP_ROOT/logs"
echo "  $BACKUP_ROOT/daily/"
echo "  $BACKUP_ROOT/weekly/"
echo "  $BACKUP_ROOT/logs/"

# --- Permessi -----------------------------------------------------------------
echo "Verifica permessi..."
chmod +x "$BACKUP_SCRIPT"

if [[ ! -w "$BACKUP_ROOT" ]]; then
    echo "ERRORE: Non hai permessi di scrittura su $BACKUP_ROOT"
    echo "Esegui: sudo chown \$(whoami) $BACKUP_ROOT"
    exit 1
fi

# --- Installazione cron ------------------------------------------------------
CRON_LINE="$CRON_SCHEDULE $BACKUP_SCRIPT >> $BACKUP_ROOT/logs/cron.log 2>&1"

# Verifica se il cron esiste già
if crontab -l 2>/dev/null | grep -qF "$BACKUP_SCRIPT"; then
    echo "Cron job già presente. Aggiornamento..."
    crontab -l 2>/dev/null | grep -vF "$BACKUP_SCRIPT" | { cat; echo "$CRON_LINE"; } | crontab -
else
    echo "Installazione cron job..."
    (crontab -l 2>/dev/null; echo "$CRON_LINE") | crontab -
fi

# --- Verifica -----------------------------------------------------------------
echo ""
echo "=== Installazione completata ==="
echo ""
echo "Cron job attivo:"
crontab -l | grep "$BACKUP_SCRIPT"
echo ""
echo "Il backup verrà eseguito ogni giorno alle 03:00."
echo "Backup salvati in: $BACKUP_ROOT"
echo "Log disponibili in: $BACKUP_ROOT/logs/"
echo ""
echo "Per testare manualmente: $BACKUP_SCRIPT"
