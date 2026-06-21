import mysql.connector

# Hardcoded for the final assessment validation to bypass Windows environment variable issues
src_config = {
    'host': '127.0.0.1',
    'user': 'root',
    'password': 'root',
    'database': 'petclinic' 
}

tgt_config = {
    # The ACTUAL Azure Host URL
    'host': 'tgt-petclinic-mysql-18632.mysql.database.azure.com',
    'user': 'adminuser',
    'password': 'super_secure_password',
    'database': 'petclinic'
}

def count_rows(config, table):
    try:
        conn = mysql.connector.connect(**config)
        cursor = conn.cursor()
        cursor.execute(f"SELECT COUNT(*) FROM {table}")
        count = cursor.fetchone()[0]
        conn.close()
        return count
    except Exception as e:
        return f"Error: {e}"

tables = ['vets', 'owners', 'pets', 'visits']

print("==================================================")
print("Database Reconciliation Report")
print("==================================================")

for table in tables:
    src_count = count_rows(src_config, table)
    tgt_count = count_rows(tgt_config, table)
    
    match_status = "✅ PASS" if src_count == tgt_count else "❌ FAIL"
    
    print(f"Table: {table.ljust(10)} | Source Rows: {str(src_count).ljust(5)} | Target Rows: {str(tgt_count).ljust(5)} | Status: {match_status}")
print("==================================================")