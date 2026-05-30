#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# AtixOps Restore Script
# Ripristina backup PostgreSQL e/o MinIO da backup giornalieri o settimanali
# =============================================================================

BACKUP_ROOT="/backups/atixops"
DAILY_DIR="$BACKUP_ROOT/daily"
WEEKLY_DIR="$BACKUP_ROOT/weekly"

PG_CONTAINER="atix-postgres"
PG_USER="${PG_USERNAME:-postgres}"
PG_DB="${PG_DB_NAME:-atix_backend}"
MINIO_VOLUME="minio_data"

# --- Funzioni -----------------------------------------------------------------
list_backups() {
    echo ""
    echo "=== Backup disponibili ==="
    echo ""

    local index=1
    BACKUP_LIST=()

    for dir in "$DAILY_DIR" "$WEEKLY_DIR"; do
        local type
        [[ "$dir" == "$DAILY_DIR" ]] && type="daily" || type="weekly"

        for pg_file in "$dir"/*_postgres.sql.gz; do
            [[ -f "$pg_file" ]] || continue
            local date
            date=$(basename "$pg_file" | sed 's/_postgres\.sql\.gz//')
            local minio_file="$dir/${date}_minio.tar.gz"
            local has_minio="no"
            [[ -f "$minio_file" ]] && has_minio="si"

            local pg_size
            pg_size=$(ls -lh "$pg_file" | awk '{print $5}')
            local minio_size="-"
            [[ "$has_minio" == "si" ]] && minio_size=$(ls -lh "$minio_file" | awk '{print $5}')

            echo "  [$index] $date ($type) - DB: $pg_size | MinIO: $minio_size"
            BACKUP_LIST+=("$dir|$date")
            index=$((index + 1))
        done
    done

    if [[ ${#BACKUP_LIST[@]} -eq 0 ]]; then
        echo "  Nessun backup trovato."
        exit 0
    fi

    echo ""
}

restore_postgres() {
    local dir="$1"
    local date="$2"
    local file="$dir/${date}_postgres.sql.gz"

    if [[ ! -f "$file" ]]; then
        echo "ERRORE: File non trovato: $file"
        return 1
    fi

    echo "Ripristino PostgreSQL da: $file"
    echo "ATTENZIONE: Il database '$PG_DB' verrà ricreato. Tutti i dati attuali saranno persi."
    read -rp "Confermi? (si/no): " confirm
    if [[ "$confirm" != "si" ]]; then
        echo "Annullato."
        return 0
    fi

    echo "Chiudo connessioni attive al database..."
    docker exec "$PG_CONTAINER" psql -U "$PG_USER" -d postgres -c \
        "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$PG_DB' AND pid <> pg_backend_pid();" \
        > /dev/null 2>&1 || true

    echo "Ricreo il database..."
    docker exec "$PG_CONTAINER" dropdb -U "$PG_USER" --if-exists "$PG_DB"
    docker exec "$PG_CONTAINER" createdb -U "$PG_USER" "$PG_DB"

    echo "Importo il dump..."
    gunzip -c "$file" | docker exec -i "$PG_CONTAINER" psql -U "$PG_USER" "$PG_DB" > /dev/null

    echo "PostgreSQL ripristinato con successo."
}

restore_minio() {
    local dir="$1"
    local date="$2"
    local file="$dir/${date}_minio.tar.gz"

    if [[ ! -f "$file" ]]; then
        echo "ERRORE: File non trovato: $file"
        return 1
    fi

    echo "Ripristino MinIO da: $file"
    echo "ATTENZIONE: Tutti i file in MinIO verranno sovrascritti."
    read -rp "Confermi? (si/no): " confirm
    if [[ "$confirm" != "si" ]]; then
        echo "Annullato."
        return 0
    fi

    echo "Ripristino volume MinIO..."
    docker run --rm \
        -v "${MINIO_VOLUME}:/data" \
        -v "$dir:/backup:ro" \
        alpine sh -c "rm -rf /data/* && tar xzf /backup/${date}_minio.tar.gz -C /"

    echo "MinIO ripristinato con successo."
    echo "NOTA: Riavvia il container MinIO per applicare le modifiche:"
    echo "  docker restart atix-minio"
}

# --- Main ---------------------------------------------------------------------
echo "==========================================="
echo "  AtixOps - Restore Backup"
echo "==========================================="

list_backups

read -rp "Seleziona il backup da ripristinare [1-${#BACKUP_LIST[@]}]: " selection

if [[ "$selection" -lt 1 ]] || [[ "$selection" -gt ${#BACKUP_LIST[@]} ]]; then
    echo "Selezione non valida."
    exit 1
fi

IFS='|' read -r selected_dir selected_date <<< "${BACKUP_LIST[$((selection - 1))]}"

echo ""
echo "Backup selezionato: $selected_date ($(basename "$selected_dir"))"
echo ""
echo "Cosa vuoi ripristinare?"
echo "  [1] Solo PostgreSQL (database)"
echo "  [2] Solo MinIO (file/allegati)"
echo "  [3] Entrambi"
echo ""
read -rp "Scelta [1-3]: " choice

case "$choice" in
    1)
        restore_postgres "$selected_dir" "$selected_date"
        ;;
    2)
        restore_minio "$selected_dir" "$selected_date"
        ;;
    3)
        restore_postgres "$selected_dir" "$selected_date"
        echo ""
        restore_minio "$selected_dir" "$selected_date"
        ;;
    *)
        echo "Scelta non valida."
        exit 1
        ;;
esac

echo ""
echo "Operazione completata."
