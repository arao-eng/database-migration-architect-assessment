#!/bin/bash
# Strict mode: Exit immediately on error, undefined variables, or pipe failures
set -euo pipefail

# Define source parameters
SRC_MYSQL_USER="${SRC_MYSQL_USER:-root}"
SRC_MYSQL_PASSWORD="${SRC_MYSQL_PASSWORD:-root}"

# Define target parameters 
TGT_MYSQL_HOST="${TGT_MYSQL_HOST:-your-flexible-server.mysql.database.azure.com}"
TGT_MYSQL_PORT="${TGT_MYSQL_PORT:-3306}"
TGT_MYSQL_USER="${TGT_MYSQL_USER:-adminuser}"
TGT_MYSQL_PASSWORD="${TGT_MYSQL_PASSWORD:-super_secure_password}"

DB_NAME="petclinic"
DUMP_FILE="migration/mysql/petclinic_dump.sql"

echo "============================================================"
echo "Starting Database Export using On-Premises Docker Container"
echo "============================================================"

# Ensure the output directory exists
mkdir -p "$(dirname "$DUMP_FILE")"

# Dynamically grab the running MySQL container ID
MYSQL_CONTAINER=$(docker-compose -f docker-compose.onprem.yml ps -q mysql)

# Execute mysqldump INSIDE the container, but save the file LOCALLY
docker exec -i "$MYSQL_CONTAINER" mysqldump \
  --user="$SRC_MYSQL_USER" \
  --password="$SRC_MYSQL_PASSWORD" \
  --single-transaction \
  --routines \
  --triggers \
  --events \
  --databases "$DB_NAME" > "$DUMP_FILE"

echo "Export complete. Dump successfully saved to $DUMP_FILE."
echo ""
echo "============================================================"
echo "Starting Target Import to Azure DB for MySQL: $TGT_MYSQL_HOST"
echo "============================================================"

echo "Executing LIVE import to Azure DB..."
docker exec -i "$MYSQL_CONTAINER" mysql \
   --host="$TGT_MYSQL_HOST" \
   --port="$TGT_MYSQL_PORT" \
   --user="$TGT_MYSQL_USER" \
   --password="$TGT_MYSQL_PASSWORD" petclinic < "$DUMP_FILE"

echo "Migration script completed successfully."