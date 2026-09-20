-- ============================================================================
-- 06a_access_flattened.sql
-- Flattened ACCESS views: extract scalar values from VARIANT/JSON columns
-- so that Semantic Views have clean, typed columns to define dimensions
-- and metrics against.
--
-- These views sit alongside the existing ACCESS.*_VIEW objects (05_access.sql)
-- and are the sole source for the Semantic Views in 06b_semantic_views.sql.
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;
USE SCHEMA ACCESS;

-- ---------------------------------------------------------------------------
-- 1. VW_VISITS
--    Grain: one row per encounter, enriched with patient, org, location,
--    and practitioner details.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW ACCESS.VW_VISITS AS
SELECT
    -- Patient
    p.RESOURCE_ID                                              AS PATIENT_ID,
    p.FHIR_NAME[0]:given[0]::VARCHAR || ' ' ||
        p.FHIR_NAME[0]:family::VARCHAR                        AS PATIENT_NAME,
    p.FHIR_GENDER::VARCHAR                                    AS PATIENT_GENDER,
    p.FHIR_BIRTHDATE::DATE                                    AS PATIENT_BIRTH_DATE,

    -- Encounter
    e.RESOURCE_ID                                              AS ENCOUNTER_ID,
    e.FHIR_STATUS::VARCHAR                                    AS ENCOUNTER_STATUS,
    e.FHIR_CLASS:code::VARCHAR                                AS ENCOUNTER_CLASS,
    e.FHIR_TYPE[0]:coding[0]:display::VARCHAR                 AS ENCOUNTER_TYPE,
    e.FHIR_TYPE[0]:coding[0]:code::VARCHAR                    AS ENCOUNTER_TYPE_CODE,
    e.FHIR_PERIOD:start::TIMESTAMP_NTZ                        AS ENCOUNTER_START,
    e.FHIR_PERIOD:"end"::TIMESTAMP_NTZ                        AS ENCOUNTER_END,
    DATEDIFF('minute',
             e.FHIR_PERIOD:start::TIMESTAMP_NTZ,
             e.FHIR_PERIOD:"end"::TIMESTAMP_NTZ)              AS LENGTH_OF_STAY_MINUTES,
    e.FHIR_REASONCODE[0]:coding[0]:display::VARCHAR           AS ENCOUNTER_REASON,

    -- Organization (service provider)
    org.RESOURCE_ID                                            AS ORGANIZATION_ID,
    org.FHIR_NAME::VARCHAR                                    AS ORGANIZATION_NAME,

    -- Location
    loc.RESOURCE_ID                                            AS LOCATION_ID,
    loc.FHIR_NAME::VARCHAR                                    AS LOCATION_NAME,
    loc.FHIR_ADDRESS:city::VARCHAR                            AS LOCATION_CITY,
    loc.FHIR_ADDRESS:state::VARCHAR                           AS LOCATION_STATE,

    -- Practitioner
    prac.RESOURCE_ID                                           AS PRACTITIONER_ID,
    prac.FHIR_NAME[0]:given[0]::VARCHAR || ' ' ||
        prac.FHIR_NAME[0]:family::VARCHAR                     AS PRACTITIONER_NAME

FROM FOUNDATION.ENCOUNTER e
JOIN FOUNDATION.PATIENT p
    ON e.FHIR_SUBJECT:reference::VARCHAR = 'Patient/' || p.RESOURCE_ID
LEFT JOIN FOUNDATION.ORGANIZATION org
    ON SPLIT_PART(e.FHIR_SERVICEPROVIDER:reference::VARCHAR, '|', -1)
       = org.FHIR_IDENTIFIER[0]:value::VARCHAR
LEFT JOIN FOUNDATION.LOCATION loc
    ON SPLIT_PART(e.FHIR_LOCATION[0]:location:reference::VARCHAR, '|', -1)
       = loc.FHIR_IDENTIFIER[0]:value::VARCHAR
LEFT JOIN FOUNDATION.PRACTITIONER prac
    ON SPLIT_PART(e.FHIR_PARTICIPANT[0]:individual:reference::VARCHAR, '|', -1)
       = prac.FHIR_IDENTIFIER[0]:value::VARCHAR;


-- ---------------------------------------------------------------------------
-- 2. VW_DIAGNOSES
--    Grain: one row per condition (diagnosis), enriched with patient and
--    linked encounter.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW ACCESS.VW_DIAGNOSES AS
SELECT
    -- Patient
    p.RESOURCE_ID                                              AS PATIENT_ID,
    p.FHIR_NAME[0]:given[0]::VARCHAR || ' ' ||
        p.FHIR_NAME[0]:family::VARCHAR                        AS PATIENT_NAME,

    -- Condition / Diagnosis
    c.RESOURCE_ID                                              AS CONDITION_ID,
    c.FHIR_CODE:coding[0]:code::VARCHAR                       AS ICD_CODE,
    c.FHIR_CODE:coding[0]:display::VARCHAR                    AS DIAGNOSIS_DISPLAY,
    c.FHIR_CODE:coding[0]:system::VARCHAR                     AS CODE_SYSTEM,
    c.FHIR_CLINICALSTATUS:coding[0]:code::VARCHAR             AS CLINICAL_STATUS,
    c.FHIR_VERIFICATIONSTATUS:coding[0]:code::VARCHAR         AS VERIFICATION_STATUS,
    c.FHIR_CATEGORY[0]:coding[0]:code::VARCHAR                AS DIAGNOSIS_CATEGORY,
    c.FHIR_ONSETDATETIME::TIMESTAMP_NTZ                       AS ONSET_DATE,
    c.FHIR_ABATEMENTDATETIME::TIMESTAMP_NTZ                   AS ABATEMENT_DATE,
    c.FHIR_RECORDEDDATE::DATE                                 AS RECORDED_DATE,

    -- Linked encounter
    SPLIT_PART(c.FHIR_ENCOUNTER:reference::VARCHAR, '/', -1)  AS ENCOUNTER_ID

FROM FOUNDATION.PATIENT p
JOIN FOUNDATION.CONDITION c
    ON c.FHIR_SUBJECT:reference::VARCHAR = 'Patient/' || p.RESOURCE_ID;


-- ---------------------------------------------------------------------------
-- 3. VW_MEDICATIONS
--    Grain: one row per medication request (prescription).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW ACCESS.VW_MEDICATIONS AS
SELECT
    -- Patient
    p.RESOURCE_ID                                              AS PATIENT_ID,
    p.FHIR_NAME[0]:given[0]::VARCHAR || ' ' ||
        p.FHIR_NAME[0]:family::VARCHAR                        AS PATIENT_NAME,

    -- MedicationRequest
    m.RESOURCE_ID                                              AS MEDICATION_REQUEST_ID,
    m.FHIR_MEDICATIONCODEABLECONCEPT:coding[0]:code::VARCHAR  AS MEDICATION_CODE,
    m.FHIR_MEDICATIONCODEABLECONCEPT:coding[0]:display::VARCHAR AS MEDICATION_NAME,
    m.FHIR_STATUS::VARCHAR                                    AS MEDICATION_STATUS,
    m.FHIR_INTENT::VARCHAR                                    AS MEDICATION_INTENT,
    m.FHIR_AUTHOREDON::DATE                                   AS AUTHORED_DATE,
    m.FHIR_REASONCODE[0]:coding[0]:display::VARCHAR           AS MEDICATION_REASON,
    m.FHIR_DOSAGEINSTRUCTION[0]:text::VARCHAR                 AS DOSAGE_INSTRUCTION,

    -- Linked encounter
    SPLIT_PART(m.FHIR_ENCOUNTER:reference::VARCHAR, '/', -1)  AS ENCOUNTER_ID

FROM FOUNDATION.PATIENT p
JOIN FOUNDATION.MEDICATION_REQUEST m
    ON m.FHIR_SUBJECT:reference::VARCHAR = 'Patient/' || p.RESOURCE_ID;


-- ---------------------------------------------------------------------------
-- 4. VW_CLAIMS
--    Grain: one row per claim, with patient and financial details.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW ACCESS.VW_CLAIMS AS
SELECT
    -- Patient
    p.RESOURCE_ID                                              AS PATIENT_ID,
    p.FHIR_NAME[0]:given[0]::VARCHAR || ' ' ||
        p.FHIR_NAME[0]:family::VARCHAR                        AS PATIENT_NAME,

    -- Claim
    cl.RESOURCE_ID                                             AS CLAIM_ID,
    cl.FHIR_STATUS::VARCHAR                                   AS CLAIM_STATUS,
    cl.FHIR_TYPE:coding[0]:code::VARCHAR                      AS CLAIM_TYPE,
    cl.FHIR_USE::VARCHAR                                      AS CLAIM_USE,
    cl.FHIR_BILLABLEPERIOD:start::DATE                        AS BILLABLE_START,
    cl.FHIR_BILLABLEPERIOD:"end"::DATE                        AS BILLABLE_END,
    cl.FHIR_TOTAL:value::NUMBER(18,2)                         AS TOTAL_CLAIM_AMOUNT,
    cl.FHIR_TOTAL:currency::VARCHAR                           AS CLAIM_CURRENCY,
    cl.FHIR_CREATED::DATE                                     AS CLAIM_CREATED_DATE,

    -- Linked encounter (via first item's encounter reference if available)
    SPLIT_PART(cl.FHIR_ITEM[0]:encounter[0]:reference::VARCHAR, '/', -1)
                                                               AS ENCOUNTER_ID

FROM FOUNDATION.PATIENT p
JOIN FOUNDATION.CLAIM cl
    ON cl.FHIR_PATIENT:reference::VARCHAR = 'Patient/' || p.RESOURCE_ID;


-- ---------------------------------------------------------------------------
-- 5. VW_OBSERVATIONS
--    Grain: one row per observation (lab result / vital sign).
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW ACCESS.VW_OBSERVATIONS AS
SELECT
    -- Patient
    p.RESOURCE_ID                                              AS PATIENT_ID,
    p.FHIR_NAME[0]:given[0]::VARCHAR || ' ' ||
        p.FHIR_NAME[0]:family::VARCHAR                        AS PATIENT_NAME,

    -- Observation
    o.RESOURCE_ID                                              AS OBSERVATION_ID,
    o.FHIR_CODE:coding[0]:code::VARCHAR                       AS OBSERVATION_CODE,
    o.FHIR_CODE:coding[0]:display::VARCHAR                    AS OBSERVATION_DISPLAY,
    o.FHIR_CATEGORY[0]:coding[0]:code::VARCHAR                AS OBSERVATION_CATEGORY,
    o.FHIR_STATUS::VARCHAR                                    AS OBSERVATION_STATUS,
    o.FHIR_EFFECTIVEDATETIME::TIMESTAMP_NTZ                   AS EFFECTIVE_DATE,
    o.FHIR_VALUEQUANTITY:value::NUMBER(18,4)                  AS VALUE_QUANTITY,
    o.FHIR_VALUEQUANTITY:unit::VARCHAR                        AS VALUE_UNIT,
    o.FHIR_VALUECODEABLECONCEPT:coding[0]:display::VARCHAR    AS VALUE_CODEABLE_DISPLAY,
    o.FHIR_VALUESTRING::VARCHAR                               AS VALUE_STRING,

    -- Linked encounter
    SPLIT_PART(o.FHIR_ENCOUNTER:reference::VARCHAR, '/', -1)  AS ENCOUNTER_ID

FROM FOUNDATION.PATIENT p
JOIN FOUNDATION.OBSERVATION o
    ON o.FHIR_SUBJECT:reference::VARCHAR = 'Patient/' || p.RESOURCE_ID;


-- ---------------------------------------------------------------------------
-- 6. VW_PROCEDURES
--    Grain: one row per procedure performed on a patient.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW ACCESS.VW_PROCEDURES AS
SELECT
    -- Patient
    p.RESOURCE_ID                                              AS PATIENT_ID,
    p.FHIR_NAME[0]:given[0]::VARCHAR || ' ' ||
        p.FHIR_NAME[0]:family::VARCHAR                        AS PATIENT_NAME,

    -- Procedure
    r.RESOURCE_ID                                              AS PROCEDURE_ID,
    r.FHIR_CODE:coding[0]:code::VARCHAR                       AS PROCEDURE_CODE,
    r.FHIR_CODE:coding[0]:display::VARCHAR                    AS PROCEDURE_DISPLAY,
    r.FHIR_STATUS::VARCHAR                                    AS PROCEDURE_STATUS,
    r.FHIR_PERFORMEDPERIOD:start::TIMESTAMP_NTZ               AS PERFORMED_START,
    r.FHIR_PERFORMEDPERIOD:"end"::TIMESTAMP_NTZ               AS PERFORMED_END,
    r.FHIR_REASONCODE[0]:coding[0]:display::VARCHAR           AS PROCEDURE_REASON,

    -- Linked encounter
    SPLIT_PART(r.FHIR_ENCOUNTER:reference::VARCHAR, '/', -1)  AS ENCOUNTER_ID

FROM FOUNDATION.PATIENT p
JOIN FOUNDATION.PROCEDURE r
    ON r.FHIR_SUBJECT:reference::VARCHAR = 'Patient/' || p.RESOURCE_ID;


-- ---------------------------------------------------------------------------
-- 7. VW_RECONCILIATION
--    Grain: one row per resource-type per loaded bundle.
--    Source is already scalar -- this view just provides a clean name in
--    the ACCESS schema.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE VIEW ACCESS.VW_RECONCILIATION AS
SELECT
    TRACKING_ID,
    SOURCE_FILE_NAME,
    RESOURCE_TYPE,
    RAW_ENTRY_COUNT,
    FOUNDATION_LOADED_COUNT,
    LOAD_TS,
    STATUS,
    (RAW_ENTRY_COUNT - FOUNDATION_LOADED_COUNT) AS MISMATCH_COUNT
FROM RECONCILIATION.LOAD_SUMMARY;
