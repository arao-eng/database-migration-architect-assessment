import pyodbc
import os

# Define connections
SRC_CONN_STR = os.getenv('ONPREM_DB_CONN')
TGT_CONN_STR = os.getenv('AZURE_SQL_CONN')

def get_row_counts(connection_string):
    counts = {}
    conn = pyodbc.connect(connection_string)
    cursor = conn.cursor()
    # Query to safely get row counts for all user tables
    query = """
        SELECT t.name, p.rows
        FROM sys.tables t
        INNER JOIN sys.partitions p ON t.object_id = p.object_id
        WHERE p.index_id IN (0,1) AND t.is_ms_shipped = 0;
    """
    cursor.execute(query)
    for row in cursor.fetchall():
        counts[row.name] = row.rows
    conn.close()
    return counts

def validate_migration():
    print("Starting Post-Migration Data Reconciliation...")
    source_counts = get_row_counts(SRC_CONN_STR)
    target_counts = get_row_counts(TGT_CONN_STR)

    mismatches = 0
    for table, src_count in source_counts.items():
        tgt_count = target_counts.get(table, 0)
        if src_count == tgt_count:
            print(f"[PASS] Table: {table} | Rows: {src_count}")
        else:
            print(f"[FAIL] Table: {table} | Source: {src_count} | Target: {tgt_count}")
            mismatches += 1

    if mismatches == 0:
        print("\nSUCCESS: All row counts match exactly. Ready for application cutover.")
    else:
        print(f"\nWARNING: {mismatches} table(s) failed validation. DO NOT CUTOVER.")

if __name__ == "__main__":
    validate_migration()