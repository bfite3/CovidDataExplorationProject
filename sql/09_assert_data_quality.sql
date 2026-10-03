/*
Project: COVID-19 Global Data Analysis
Script: 09_assert_data_quality.sql

Purpose:
Automatically validate data integrity following
the COVID-19 ingestion and transformation pipeline.

Sources:
- staging.CovidClean
- dbo.CovidDeaths
- dbo.CovidVaccinations

Notes:
- This script is read-only.
- Failed assertions generate SQL Server errors.
- Execute after creating the analytical tables.
*/

USE CovidPortfolioProject;
GO

SET NOCOUNT ON;
SET XACT_ABORT ON;

BEGIN TRY

    /*
    Assertion 1: Cleaned Dataset Is Not Empty

    Verify that the cleaning process produced records.
    */

    IF NOT EXISTS (
        SELECT TOP (1) 1
        FROM staging.CovidClean cc
    )
    BEGIN
        THROW 50001,
            'FAIL: The cleaned staging table is empty.',
            1;
    END;

    PRINT 'PASS: Cleaned staging table contains records.';


    /*
    Assertion 2: Cleaned Dataset Has Unique Keys

    Verify that each ISO code and reporting date
    combination identifies exactly one record.
    */

    IF EXISTS (
        SELECT cc.iso_code
        ,cc.[date]
        FROM staging.CovidClean cc
        GROUP BY cc.iso_code
        ,cc.[date]
        HAVING COUNT(*) > 1
    )
    BEGIN
        THROW 50002,
            'FAIL: Duplicate ISO code/date keys detected.',
            1;
    END;

    PRINT 'PASS: Cleaned staging keys are unique.';


    /*
    Assertion 3: Analytical Table Record Counts

    Verify that both analytical tables contain
    the expected number of cleaned records.
    */

    IF (
        SELECT COUNT(*)
        FROM staging.CovidClean cc
    ) <> (
        SELECT COUNT(*)
        FROM dbo.CovidDeaths cd
    )
    OR (
        SELECT COUNT(*)
        FROM staging.CovidClean cc
    ) <> (
        SELECT COUNT(*)
        FROM dbo.CovidVaccinations cv
    )
    BEGIN
        THROW 50003,
            'FAIL: Analytical table record counts do not match.',
            1;
    END;

    PRINT 'PASS: Analytical table record counts match.';

    /*
    Assertion 4: Required Identifiers

    Verify that all analytical records contain
    the identifiers required for reliable joins.
    */

    IF EXISTS (
        SELECT 1
        FROM dbo.CovidDeaths cd
        WHERE cd.iso_code IS NULL
        OR cd.location IS NULL
        OR cd.[date] IS NULL
    )
    OR EXISTS (
        SELECT 1
        FROM dbo.CovidVaccinations cv
        WHERE cv.iso_code IS NULL
        OR cv.location IS NULL
        OR cv.[date] IS NULL
    )
    BEGIN
        THROW 50004,
            'FAIL: Missing analytical table identifiers.',
            1;
    END;

    PRINT 'PASS: Required analytical identifiers are populated.';


    /*
    Assertion 5: Analytical Key Uniqueness

    Verify that each ISO code and reporting date
    combination occurs only once in each table.
    */

    IF EXISTS (
        SELECT cd.iso_code
        ,cd.[date]
        FROM dbo.CovidDeaths cd
        GROUP BY cd.iso_code
        ,cd.[date]
        HAVING COUNT(*) > 1
    )
    OR EXISTS (
        SELECT cv.iso_code
        ,cv.[date]
        FROM dbo.CovidVaccinations cv
        GROUP BY cv.iso_code
        ,cv.[date]
        HAVING COUNT(*) > 1
    )
    BEGIN
        THROW 50005,
            'FAIL: Duplicate analytical table keys detected.',
            1;
    END;

    PRINT 'PASS: Analytical table keys are unique.';


    /*
    Assertion 6A: Cleaned Records Exist in CovidDeaths

    Verify that every cleaned country/date key
    exists in the deaths analytical table.
    */

    IF EXISTS (
        SELECT cc.iso_code
        ,cc.[date]
        FROM staging.CovidClean cc

        EXCEPT

        SELECT cd.iso_code
        ,cd.[date]
        FROM dbo.CovidDeaths cd
    )
    BEGIN
        THROW 50006,
            'FAIL: Cleaned keys are missing from CovidDeaths.',
            1;
    END;

    PRINT 'PASS: All cleaned keys exist in CovidDeaths.';


    /*
    Assertion 6B: No Unexpected CovidDeaths Records

    Verify that the deaths table contains no
    country/date keys absent from cleaned staging.
    */

    IF EXISTS (
        SELECT cd.iso_code
        ,cd.[date]
        FROM dbo.CovidDeaths cd

        EXCEPT

        SELECT cc.iso_code
        ,cc.[date]
        FROM staging.CovidClean cc
    )
    BEGIN
        THROW 50007,
            'FAIL: Unexpected country/date keys in CovidDeaths.',
            1;
    END;

    PRINT 'PASS: CovidDeaths contains no unexpected keys.';


    /*
    Assertion 6C: Cleaned Records Exist in CovidVaccinations

    Verify that every cleaned country/date key
    exists in the vaccinations analytical table.
    */

    IF EXISTS (
        SELECT cc.iso_code
        ,cc.[date]
        FROM staging.CovidClean cc

        EXCEPT

        SELECT cv.iso_code
        ,cv.[date]
        FROM dbo.CovidVaccinations cv
    )
    BEGIN
        THROW 50008,
            'FAIL: Cleaned keys are missing from CovidVaccinations.',
            1;
    END;

    PRINT 'PASS: All cleaned keys exist in CovidVaccinations.';


    /*
    Assertion 6D: No Unexpected CovidVaccinations Records

    Verify that the vaccinations table contains no
    country/date keys absent from cleaned staging.
    */

    IF EXISTS (
        SELECT cv.iso_code
        ,cv.[date]
        FROM dbo.CovidVaccinations cv

        EXCEPT

        SELECT cc.iso_code
        ,cc.[date]
        FROM staging.CovidClean cc
    )
    BEGIN
        THROW 50009,
            'FAIL: Unexpected country/date keys in CovidVaccinations.',
            1;
    END;

    PRINT 'PASS: CovidVaccinations contains no unexpected keys.';


    /*
    Assertion 7: Case and Mortality Data Integrity

    Verify that analytical case, death, and population
    measurements match the cleaned staging dataset.
    */

    IF EXISTS (
        SELECT cc.iso_code
        ,cc.[date]
        ,cc.population
        ,cc.total_cases
        ,cc.new_cases
        ,cc.total_deaths
        ,cc.new_deaths
        FROM staging.CovidClean cc

        EXCEPT

        SELECT cd.iso_code
        ,cd.[date]
        ,cd.population
        ,cd.total_cases
        ,cd.new_cases
        ,cd.total_deaths
        ,cd.new_deaths
        FROM dbo.CovidDeaths cd
    )
    BEGIN
        THROW 50010,
            'FAIL: Case or mortality measurements differ from staging.',
            1;
    END;

    PRINT 'PASS: Case and mortality measurements match.';

    /*
    Assertion 8: Vaccination Data Integrity

    Verify that analytical vaccination measurements
    match the cleaned staging dataset.
    */

    IF EXISTS (
        SELECT cc.iso_code
        ,cc.[date]
        ,cc.new_vaccinations
        ,cc.total_vaccinations
        FROM staging.CovidClean cc

        EXCEPT

        SELECT cv.iso_code
        ,cv.[date]
        ,cv.new_vaccinations
        ,cv.total_vaccinations
        FROM dbo.CovidVaccinations cv
    )
    BEGIN
        THROW 50011,
            'FAIL: Vaccination measurements differ from staging.',
            1;
    END;

    PRINT 'PASS: Vaccination measurements match.';

END TRY

BEGIN CATCH

    PRINT ERROR_MESSAGE();
    THROW;

END CATCH;