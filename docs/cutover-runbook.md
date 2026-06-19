# Migration Cutover Runbook
**Owner:** Amit Ajit Rao, Technical Director / Solution Architect
**Environment:** Production

## 1. Pre-Cutover (T-minus 2 Hours)
* [ ] **Verify Target Infrastructure:** Confirm Azure SQL DB and App Service are online via Bicep deployment logs.
* [ ] **Check Secrets:** Ensure App Service has successful `GET` access to Key Vault for the new database credentials.
* [ ] **Communicate:** Notify stakeholders that the maintenance window is opening.

## 2. Application Freeze & Final Sync (Downtime Starts)
* [ ] **Stop Traffic:** Route local NGINX/ingress traffic to a static "Maintenance" page. Stop the on-premises `.NET` application services.
* [ ] **Final Delta Sync:** If using replication/CDC, ensure the final transactions are flushed to Azure SQL DB. If offline, execute final `BACPAC` export/import.
* [ ] **Data Validation:** Execute `validation/reconciliation.py`. [cite_start]**GATE:** Do not proceed unless script returns `SUCCESS`[cite: 32, 98].

## 3. Application Cutover
* [ ] **Deploy Cloud App:** Trigger the GitHub Actions deployment pipeline to spin up the containerized app pointing to Azure SQL DB.
* [cite_start][ ] **Smoke Testing:** Run `smoke_test.sh` to verify application health, login functionality, and successful read/write transactions[cite: 62].

## 4. Rollback Triggers
* **Condition A:** `reconciliation.py` fails to validate row counts or checksums within 30 minutes of the downtime window.
* **Condition B:** Application smoke tests fail to establish a connection to Azure SQL DB due to VNet/firewall misconfigurations.
* **Rollback Action:** Repoint ingress reverse proxy back to the on-premises .NET application. Bring on-premises SQL Server fully online. Abort cloud cutover.

## 5. Hypercare
* [cite_start][ ] Monitor Azure App Insights and SQL Query Store for 48 hours to establish the post-migration performance baseline[cite: 69].