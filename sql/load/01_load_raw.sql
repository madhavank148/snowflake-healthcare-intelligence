-- ============================================================================
-- 01_load_raw.sql
-- Loads the local sample FHIR Bundle JSON files into RAW.BUNDLE_RAW.
--
-- All 111 files under resources/sample_synthetic_data_fhir_r4/ are FHIR
-- Bundles (resourceType = "Bundle"): 109 per-patient clinical bundles plus
-- two reference bundles (hospitalInformation... -> Organization/Location,
-- practitionerInformation... -> Practitioner/PractitionerRole). All of them
-- load the same way here; FOUNDATION has tables for all 24 resource types
-- found in the sample data (20 clinical + these 4 reference/directory types).
--
-- Run this PUT from SnowSQL or the Snowflake VS Code extension with local
-- filesystem access. PUT does not resolve relative paths and cannot read files
-- from a Snowsight browser worksheet.
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;
USE SCHEMA RAW;

-- Upload local files to the internal stage. The file:// URI must be absolute.
PUT 'file:///Users/madhavan/vs_code_workspace/snowflake-healthcare-intelligence/resources/sample_synthetic_data_fhir_r4/*.json'
    @RAW.FHIR_STAGE
    AUTO_COMPRESS=TRUE
    OVERWRITE=TRUE;

-- Each staged file is a single JSON object (one Bundle) -> load as one VARIANT row per file.
COPY INTO RAW.BUNDLE_RAW (SOURCE_FILE_NAME, TRACKING_ID, BUNDLE_JSON)
FROM (
    SELECT
        METADATA$FILENAME,
        UUID_STRING(),
        $1
    FROM @RAW.FHIR_STAGE
)
FILE_FORMAT = (FORMAT_NAME = RAW.JSON_FORMAT)
ON_ERROR = ABORT_STATEMENT;
