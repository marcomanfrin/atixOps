#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# AtixOps Backup Script
# Esegue backup di PostgreSQL e MinIO con rotazione giornaliera/settimanale
# =============================================================================

# --- Configurazione -----------------------------------------------------------
BACKUP_ROOT="/backups/atixops"
DAILY_DIR="$BACKUP_ROOT/daily"
WEEKLY_DIR="$BACKUP_ROOT/weekly"
LOG_DIR="$BACKUP_ROOT/logs"
LOG_FILE="$LOG_DIR/backup.log"

# Container e credenziali (match docker-compose.yml defaults)
PG_CONTAINER="atix-postgres"
PG_USER="${PG_USERNAME:-postgres}"
PG_DB="${PG_DB_NAME:-atix_backend}"

MINIO_VOLUME="minio_data"

# Retention
DAILY_RETENTION_DAYS=7
WEEKLY_RETENTION_DAYS=28

# Data corrente
DATE=$(date +%Y-%m-%d)
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")

# --- Cloud sync (decommentare per abilitare) ----------------------------------
# RCLONE_REMOTE="myremote:atixops-backups"
# rclone_sync() {
#     rclone sync "$BACKUP_ROOT" "$RCLONE_REMOTE" --log-file="$LOG_FILE" --log-level INFO
# }

# --- Funzioni -----------------------------------------------------------------
log() {
    echo "[$TIMESTAMP] $1" >> "$LOG_FILE"
}

log_error() {
    echo "[$TIMESTAMP] ERROR: $1" >> "$LOG_FILE"
}

check_file() {
    local file="$1"
    if [[ ! -f "$file" ]] || [[ ! -s "$file" ]]; then
        log_error "File mancante o vuoto: $file"
        return 1
    fi
    local size
    size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
    log "OK: $file ($size bytes)"
    return 0
}

cleanup_old() {
    local dir="$1"
    local days="$2"
    local count
    count=$(find "$dir" -name "*.gz" -mtime +"$days" | wc -l)
    if [[ "$count" -gt 0 ]]; then
        find "$dir" -name "*.gz" -mtime +"$days" -delete
        log "Rimossi $count file più vecchi di $days giorni da $dir"
    fi
}

# --- Setup directory ----------------------------------------------------------
mkdir -p "$DAILY_DIR" "$WEEKLY_DIR" "$LOG_DIR"

# --- Inizio backup ------------------------------------------------------------
log "========== Inizio backup =========="

ERRORS=0

# 1. Backup PostgreSQL
log "Dump PostgreSQL..."
if docker exec "$PG_CONTAINER" pg_dump -U "$PG_USER" "$PG_DB" | gzip > "$DAILY_DIR/${DATE}_postgres.sql.gz"; then
    check_file "$DAILY_DIR/${DATE}_postgres.sql.gz" || ERRORS=$((ERRORS + 1))
else
    log_error "pg_dump fallito"
    ERRORS=$((ERRORS + 1))
fi

# 2. Backup MinIO
log "Backup MinIO volume..."
if docker run --rm \
    -v "${MINIO_VOLUME}:/data:ro" \
    -v "$DAILY_DIR:/backup" \
    alpine tar czf "/backup/${DATE}_minio.tar.gz" -C / data; then
    check_file "$DAILY_DIR/${DATE}_minio.tar.gz" || ERRORS=$((ERRORS + 1))
else
    log_error "Backup MinIO fallito"
    ERRORS=$((ERRORS + 1))
fi

# 3. Rotazione giornaliera
log "Rotazione backup giornalieri (retention: $DAILY_RETENTION_DAYS giorni)..."
cleanup_old "$DAILY_DIR" "$DAILY_RETENTION_DAYS"

# 4. Promozione settimanale (domenica = day 0)
DAY_OF_WEEK=$(date +%u)
if [[ "$DAY_OF_WEEK" -eq 7 ]]; then
    log "Domenica: promozione backup a settimanale..."
    for f in "$DAILY_DIR/${DATE}"_*.gz; do
        if [[ -f "$f" ]]; then
            cp "$f" "$WEEKLY_DIR/"
            log "Copiato $(basename "$f") in weekly/"
        fi
    done
fi

# 5. Rotazione settimanale
log "Rotazione backup settimanali (retention: $WEEKLY_RETENTION_DAYS giorni)..."
cleanup_old "$WEEKLY_DIR" "$WEEKLY_RETENTION_DAYS"

# 6. Cloud sync (decommentare per abilitare)
# log "Sync su cloud..."
# rclone_sync

# --- Riepilogo ----------------------------------------------------------------
if [[ "$ERRORS" -eq 0 ]]; then
    log "========== Backup completato con successo =========="
else
    log_error "========== Backup completato con $ERRORS errori =========="
    exit 1
fi
