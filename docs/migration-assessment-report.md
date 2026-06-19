# Database Migration Assessment Report
**Prepared by:** Amit Ajit Rao, Database Migration Architect
**Date:** {{Current_Date}}
**Target Workload:** eShopOnWeb (.NET / SQL Server)

## 1. Executive Summary
This document outlines the migration strategy for transitioning the on-premises eShopOnWeb database infrastructure to Azure. Based on the Data Migration Assistant (DMA) assessment, the recommended target is **Azure SQL Database**, leveraging a replatforming approach to reduce operational overhead while maintaining high availability.

## 2. Discovery & Inventory Summary
* **Total Databases:** 2 (CatalogDb, Identity)
* **Total Tables:** 15
* **Total Data Volume:** < 1 GB (Sample Data)
* **Unsupported Features:** None detected blocking Azure SQL Database migration.
* **Network Flow:** The application tier communicates over TCP 1433 directly to the data tier.

## 3. Target Selection Matrix
| Capability | Azure SQL Database | Azure SQL Managed Instance | SQL Server on VM |
| :--- | :--- | :--- | :--- |
| **PaaS Benefits** | High (Fully Managed) | High (Fully Managed) | Low (IaaS) |
| **Compatibility** | Moderate (Replatform) | High (Lift & Shift) | Perfect |
| **VNet Integration** | Yes (Private Link) | Yes (Native VNet) | Yes |
| **Decision** | **Selected** | Rejected (Overkill for schema) | Rejected |

## 4. Migration Strategy
* **Approach:** Offline Migration using `SqlPackage.exe` (BACPAC export/import).
* **Downtime Window:** Estimated 1-2 hours for final data sync and application cutover.
* **Cutover Mechanism:** DNS switch at the App Service level pointing to the new Azure SQL DB endpoint. Secrets will be securely retrieved via Azure Key Vault.