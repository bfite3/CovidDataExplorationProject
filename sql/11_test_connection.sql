/*
Test: SQL Runner Connectivity

Verify that Python can execute SQL batches
and retrieve results from SQL Server.
*/

USE CovidPortfolioProject;
GO

SELECT DB_NAME() AS current_database;
GO

SELECT COUNT(*) AS total_records
FROM staging.CovidClean cc
;