-- ============================================================================
-- 04_reconciliation.sql
-- RECONCILIATION schema: tracks, per loaded bundle and resource type, how many
-- entries existed in RAW vs. how many rows actually landed in FOUNDATION.
-- Skeleton only for now -- populated by a future reconciliation step/agent.
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;
USE SCHEMA RECONCILIATION;

CREATE TABLE IF NOT EXISTS RECONCILIATION.LOAD_SUMMARY (
    TRACKING_ID           VARCHAR,   -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME       VARCHAR,
    RESOURCE_TYPE          VARCHAR,
    RAW_ENTRY_COUNT         NUMBER,   -- entries of this resourceType found in RAW.BUNDLE_RAW.BUNDLE_JSON:entry
    FOUNDATION_LOADED_COUNT NUMBER,   -- rows landed in the matching FOUNDATION table
    LOAD_TS                 TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    STATUS                  VARCHAR   -- e.g. MATCHED / MISMATCH, set by the reconciliation check
);
