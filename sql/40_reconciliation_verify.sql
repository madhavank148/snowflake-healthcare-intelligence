-- ============================================================================
-- 40_reconciliation_verify.sql
-- Read-only verification queries across every layer. Run after a load to
-- eyeball that data actually landed, and reused as-is by the Reconciliation
-- Agent (Poc.html) as its query surface for pipeline-health questions
-- ("did every message get fully split?", "is anything mismatched?").
-- No DDL/DML here -- SELECT only.
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;

-- ---------------------------------------------------------------------------
-- 1. Platform health at a glance: row counts across every table, every layer.
-- ---------------------------------------------------------------------------
SELECT 'RAW.BUNDLE_RAW' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM RAW.BUNDLE_RAW
UNION ALL
SELECT 'FOUNDATION.PATIENT' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.PATIENT
UNION ALL
SELECT 'FOUNDATION.ENCOUNTER' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.ENCOUNTER
UNION ALL
SELECT 'FOUNDATION.CONDITION' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.CONDITION
UNION ALL
SELECT 'FOUNDATION.OBSERVATION' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.OBSERVATION
UNION ALL
SELECT 'FOUNDATION.PROCEDURE' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.PROCEDURE
UNION ALL
SELECT 'FOUNDATION.CLAIM' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.CLAIM
UNION ALL
SELECT 'FOUNDATION.EXPLANATION_OF_BENEFIT' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.EXPLANATION_OF_BENEFIT
UNION ALL
SELECT 'FOUNDATION.DIAGNOSTIC_REPORT' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.DIAGNOSTIC_REPORT
UNION ALL
SELECT 'FOUNDATION.DOCUMENT_REFERENCE' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.DOCUMENT_REFERENCE
UNION ALL
SELECT 'FOUNDATION.IMMUNIZATION' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.IMMUNIZATION
UNION ALL
SELECT 'FOUNDATION.MEDICATION_REQUEST' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.MEDICATION_REQUEST
UNION ALL
SELECT 'FOUNDATION.MEDICATION' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.MEDICATION
UNION ALL
SELECT 'FOUNDATION.MEDICATION_ADMINISTRATION' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.MEDICATION_ADMINISTRATION
UNION ALL
SELECT 'FOUNDATION.CARE_TEAM' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.CARE_TEAM
UNION ALL
SELECT 'FOUNDATION.CARE_PLAN' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.CARE_PLAN
UNION ALL
SELECT 'FOUNDATION.SUPPLY_DELIVERY' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.SUPPLY_DELIVERY
UNION ALL
SELECT 'FOUNDATION.PROVENANCE' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.PROVENANCE
UNION ALL
SELECT 'FOUNDATION.ALLERGY_INTOLERANCE' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.ALLERGY_INTOLERANCE
UNION ALL
SELECT 'FOUNDATION.DEVICE' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.DEVICE
UNION ALL
SELECT 'FOUNDATION.IMAGING_STUDY' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.IMAGING_STUDY
UNION ALL
SELECT 'FOUNDATION.ORGANIZATION' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.ORGANIZATION
UNION ALL
SELECT 'FOUNDATION.LOCATION' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.LOCATION
UNION ALL
SELECT 'FOUNDATION.PRACTITIONER' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.PRACTITIONER
UNION ALL
SELECT 'FOUNDATION.PRACTITIONER_ROLE' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM FOUNDATION.PRACTITIONER_ROLE
UNION ALL
SELECT 'RECONCILIATION.LOAD_SUMMARY' AS TABLE_NAME, COUNT(*) AS ROW_COUNT FROM RECONCILIATION.LOAD_SUMMARY
ORDER BY TABLE_NAME;

-- ---------------------------------------------------------------------------
-- 2. Raw bundle sample -- confirm the whole Bundle JSON landed untouched.
-- ---------------------------------------------------------------------------
SELECT TRACKING_ID, SOURCE_FILE_NAME, RAW_LOAD_TS, BUNDLE_JSON
FROM RAW.BUNDLE_RAW
LIMIT 10;

-- ---------------------------------------------------------------------------
-- 3. Foundation sample -- spot check one resource type split out correctly.
-- ---------------------------------------------------------------------------
SELECT *
FROM FOUNDATION.PATIENT
LIMIT 10;

-- ---------------------------------------------------------------------------
-- 4. Full reconciliation summary -- every bundle x resourceType comparison.
-- ---------------------------------------------------------------------------
SELECT *
FROM RECONCILIATION.LOAD_SUMMARY
ORDER BY SOURCE_FILE_NAME, RESOURCE_TYPE;

-- ---------------------------------------------------------------------------
-- 5. Mismatches only -- the actionable query: entries that didn't fully make
--    it from RAW into FOUNDATION. Empty result = clean load.
-- ---------------------------------------------------------------------------
SELECT *
FROM RECONCILIATION.LOAD_SUMMARY
WHERE STATUS = 'MISMATCH'
ORDER BY SOURCE_FILE_NAME, RESOURCE_TYPE;

-- ---------------------------------------------------------------------------
-- 6. Coverage check -- resourceTypes seen in RAW with no FOUNDATION table yet.
--    Empty result = every resourceType in the sample data is now tracked.
-- ---------------------------------------------------------------------------
SELECT RESOURCE_TYPE, COUNT(DISTINCT TRACKING_ID) AS BUNDLES_SEEN_IN, SUM(RAW_ENTRY_COUNT) AS TOTAL_RAW_ENTRIES
FROM RECONCILIATION.LOAD_SUMMARY
WHERE STATUS = 'NOT_TRACKED'
GROUP BY RESOURCE_TYPE
ORDER BY RESOURCE_TYPE;

-- ---------------------------------------------------------------------------
-- 7. Per-bundle drill-down -- pass in a TRACKING_ID (from RAW.BUNDLE_RAW or
--    RECONCILIATION.LOAD_SUMMARY) to see every resourceType's match status
--    for that one file. Swap the literal for the id you're investigating.
-- ---------------------------------------------------------------------------
-- SELECT *
-- FROM RECONCILIATION.LOAD_SUMMARY
-- WHERE TRACKING_ID = '<paste TRACKING_ID here>'
-- ORDER BY RESOURCE_TYPE;
