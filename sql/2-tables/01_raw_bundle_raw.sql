-- ============================================================================
-- 01_raw_bundle_raw.sql
-- RAW schema: landing table for whole FHIR Bundles + the stage/file format
-- used to load the sample JSON files into it.
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;
USE SCHEMA RAW;

CREATE FILE FORMAT IF NOT EXISTS RAW.JSON_FORMAT
    TYPE = JSON
    STRIP_OUTER_ARRAY = FALSE;

CREATE STAGE IF NOT EXISTS RAW.FHIR_STAGE
    FILE_FORMAT = RAW.JSON_FORMAT
    COMMENT = 'Internal stage for PUT-ing local FHIR Bundle JSON files before COPY INTO RAW.BUNDLE_RAW';

-- One row per loaded Bundle file. Untouched, whole-bundle JSON.
CREATE TABLE IF NOT EXISTS RAW.BUNDLE_RAW (
    TRACKING_ID     VARCHAR       DEFAULT UUID_STRING(),   -- unique id for this load, referenced by FOUNDATION.BUNDLE_TRACK_ID_REF
    SOURCE_FILE_NAME VARCHAR,
    RAW_LOAD_TS      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    BUNDLE_JSON      VARIANT
);
