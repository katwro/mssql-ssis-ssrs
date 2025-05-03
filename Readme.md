📖 Overview

The Debt Management project is a debt collection system built using Microsoft SQL Server, SSIS, and SSRS.It manages client debts, generates repayment schedules, tracks debt status history, and provides interactive reporting. The system also incorporates monitoring tools such as Query Store and Extended Events for performance analysis and diagnostics.


📦 Requirements 

1. Microsoft SQL Server 2019+ (with SSIS and SSRS components)

2. SQL Server Management Studio (SSMS)

3. Visual Studio 2022 with:
   1. SQL Server Data Tools (SSDT)
   2. Microsoft Reporting Services Projects extension
   3. SQL Server Integration Services Projects extension


🗄️ Database Tables

* Clients — Client information.

* Debts — Debt records per client.

* DebtStatusHistory — Status change log per debt

* InstallmentPayments — Stores records of individual installment payments

* Payments — Contains overall payment records

* PaymentSchedules — Repayment schedule per debt

* Stg_Debts — Staging table for imported debts

* Stg_Clients — Staging table for imported clients

⚙️ Stored Procedures

* AddNewClient — Adds a new client to the system. Automatically generates a unique sequential `ClientNumber` in the format `CUST00001`.

* AddNewDebt — Adds a new debt and generates a repayment schedule with status tracking. Automatically generates the next sequential `DebtNumber` for the client based on their existing debts.

* CheckOverdueDebts – Assigns the "Overdue" status to debts with past due payments and the "Upcoming" status to debts approaching their due date. It also records each status change in the DebtStatusHistory table.

* RegisterPayment - Registers a new payment and allocates the payment amount across the installments in the repayment schedule.


🔄 SSIS Packages

Import_data.dtsx — ETL package:

* Truncate Stg_Client

* Load from clients.csv

* Merge

* Truncate Stg_Debts

* Load from debts.csv

* Execute AddNewDebt for each record via Data Flow + OLE DB Command

📊 SSRS Reports

* DebtsStatus.rdl - Displays a list of all debts filtered by the selected status.

* DebtStatusHistory.rdl - Shows the full status change history for each debt.

* DebtDashboard.rdl — Presents a dashboard with a pie chart showing the percentage distribution of active debts by status and a line chart illustrating the number of new debts added each month.

* OverduePaymentsReport.rdl - Lists all overdue payments with their due dates and amounts.

* RegistredDebts.rdl - Provides an overview of all registered debts.


📈 Monitoring & Diagnostics

Query Store:

Enabled via EnableQueryStore.sql

Configured to capture query performance for FinRecover database

Extended Events:

Session TrackLongQueries created via TrackLongQueries.sql

Captures queries longer than 5 seconds to C:\XELogs\TrackLongQueries.xel


📥 Installation Steps

1. Install SQL Server 2019+ with SSIS and SSRS features.

2. Install Visual Studio 2022 + SQL Server Data Tools.

3. Add Microsoft Reporting Services Projects extension via VS installer (Modify → Individual Components).

4. Add SQL Server Integration Services Projects (SSIS) extension via Visual Studio Marketplace or installer (Modify → Individual Components).

5. Deploy database objects via create_database_tables.sql and Stored Procedures.

6. Execute EnableQueryStore.sql.

7. Create Extended Events session via TrackLongQueries.sql.

8. Deploy Import_data.dtsx SSIS package using Visual Studio.

9. Deploy .rdl reports to SSRS or preview locally via Visual Studio.

10. Test with sample clients.csv, debts.csv and review data via reports and Query Store.


📑 Notes

* Ensure SSRS permissions for local preview or upload

* Update Extended Events file path if different drive/location

* Schedule SSIS package via SQL Server Agent or run manually

