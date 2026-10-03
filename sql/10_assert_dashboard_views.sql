/*
Project: COVID-19 Global Data Analysis
Script: 10_assert_dashboard_views.sql

Purpose:
Automatically validate Tableau-ready SQL views
and raise errors when data integrity checks fail.
*/

USE CovidPortfolioProject;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    /*
    Assertion 1: Historical View Record Counts

    Verify that the daily and vaccination views
    contain matching country/date observations.
    */

    IF (
        SELECT COUNT(*)
        FROM dbo.vw_CovidCountryDaily vcd
    ) <> (
        SELECT COUNT(*)
        FROM dbo.vw_CovidVaccinationTrends vvt
    )
    BEGIN
        THROW 50012,
            'FAIL: Historical dashboard view row counts differ.',
            1;
    END;

    PRINT 'PASS: Historical dashboard view row counts match.';

    /*
    Assertion 2: Latest Country Uniqueness

    Verify that each country appears only once
    in the latest-country dashboard view.
    */

    IF EXISTS (
        SELECT vcl.iso_code
        FROM dbo.vw_CovidCountryLatest vcl
        GROUP BY vcl.iso_code
        HAVING COUNT(*) > 1
    )
    BEGIN
        THROW 50013,
            'FAIL: Duplicate countries in latest dashboard view.',
            1;
    END;

    PRINT 'PASS: Latest-country records are unique.';


END TRY

BEGIN CATCH
    PRINT ERROR_MESSAGE();
    THROW;
END CATCH;