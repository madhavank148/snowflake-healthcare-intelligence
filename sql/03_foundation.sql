-- ============================================================================
-- 03_foundation.sql
-- FOUNDATION schema: one table per FHIR resource type, semi-flat.
-- Every root-level JSON field of the resource becomes its own FHIR_<FIELD>
-- VARIANT column (holding that field's JSON as-is, not flattened further).
-- Lineage columns tie every row back to the RAW bundle it came from.
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;
USE SCHEMA FOUNDATION;


-- Patient
CREATE TABLE IF NOT EXISTS FOUNDATION.PATIENT (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_IDENTIFIER           VARIANT,
    FHIR_NAME                 VARIANT,
    FHIR_GENDER               VARIANT,
    FHIR_BIRTHDATE            VARIANT,
    FHIR_ADDRESS              VARIANT,
    FHIR_TELECOM              VARIANT,
    FHIR_MARITALSTATUS        VARIANT,
    FHIR_MULTIPLEBIRTHBOOLEAN VARIANT,
    FHIR_MULTIPLEBIRTHINTEGER VARIANT,
    FHIR_COMMUNICATION        VARIANT,
    FHIR_DECEASEDDATETIME     VARIANT,
    FHIR_EXTENSION            VARIANT,
    FHIR_TEXT                 VARIANT
);

-- Encounter
CREATE TABLE IF NOT EXISTS FOUNDATION.ENCOUNTER (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_IDENTIFIER           VARIANT,
    FHIR_STATUS               VARIANT,
    FHIR_CLASS                VARIANT,
    FHIR_TYPE                 VARIANT,
    FHIR_SUBJECT              VARIANT,
    FHIR_PARTICIPANT          VARIANT,
    FHIR_PERIOD               VARIANT,
    FHIR_REASONCODE           VARIANT,
    FHIR_HOSPITALIZATION      VARIANT,
    FHIR_LOCATION             VARIANT,
    FHIR_SERVICEPROVIDER      VARIANT
);

-- Condition
CREATE TABLE IF NOT EXISTS FOUNDATION.CONDITION (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_CLINICALSTATUS       VARIANT,
    FHIR_VERIFICATIONSTATUS   VARIANT,
    FHIR_CATEGORY             VARIANT,
    FHIR_CODE                 VARIANT,
    FHIR_SUBJECT              VARIANT,
    FHIR_ENCOUNTER            VARIANT,
    FHIR_ONSETDATETIME        VARIANT,
    FHIR_ABATEMENTDATETIME    VARIANT,
    FHIR_RECORDEDDATE         VARIANT
);

-- Observation
CREATE TABLE IF NOT EXISTS FOUNDATION.OBSERVATION (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_STATUS               VARIANT,
    FHIR_CATEGORY             VARIANT,
    FHIR_CODE                 VARIANT,
    FHIR_SUBJECT              VARIANT,
    FHIR_ENCOUNTER            VARIANT,
    FHIR_EFFECTIVEDATETIME    VARIANT,
    FHIR_ISSUED               VARIANT,
    FHIR_VALUEQUANTITY        VARIANT,
    FHIR_VALUECODEABLECONCEPT VARIANT,
    FHIR_VALUESTRING          VARIANT,
    FHIR_COMPONENT            VARIANT
);

-- Procedure
CREATE TABLE IF NOT EXISTS FOUNDATION.PROCEDURE (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_STATUS               VARIANT,
    FHIR_CODE                 VARIANT,
    FHIR_SUBJECT              VARIANT,
    FHIR_ENCOUNTER            VARIANT,
    FHIR_PERFORMEDPERIOD      VARIANT,
    FHIR_REASONCODE           VARIANT,
    FHIR_REASONREFERENCE      VARIANT,
    FHIR_LOCATION             VARIANT
);

-- Claim
CREATE TABLE IF NOT EXISTS FOUNDATION.CLAIM (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_STATUS               VARIANT,
    FHIR_TYPE                 VARIANT,
    FHIR_USE                  VARIANT,
    FHIR_PATIENT              VARIANT,
    FHIR_BILLABLEPERIOD       VARIANT,
    FHIR_CREATED              VARIANT,
    FHIR_PROVIDER             VARIANT,
    FHIR_PRIORITY             VARIANT,
    FHIR_FACILITY             VARIANT,
    FHIR_PRESCRIPTION         VARIANT,
    FHIR_INSURANCE            VARIANT,
    FHIR_ITEM                 VARIANT,
    FHIR_TOTAL                VARIANT,
    FHIR_DIAGNOSIS            VARIANT,
    FHIR_PROCEDURE            VARIANT,
    FHIR_SUPPORTINGINFO       VARIANT
);

-- ExplanationOfBenefit
CREATE TABLE IF NOT EXISTS FOUNDATION.EXPLANATION_OF_BENEFIT (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_IDENTIFIER           VARIANT,
    FHIR_STATUS               VARIANT,
    FHIR_TYPE                 VARIANT,
    FHIR_USE                  VARIANT,
    FHIR_PATIENT              VARIANT,
    FHIR_BILLABLEPERIOD       VARIANT,
    FHIR_CREATED              VARIANT,
    FHIR_INSURER              VARIANT,
    FHIR_PROVIDER             VARIANT,
    FHIR_OUTCOME              VARIANT,
    FHIR_CARETEAM             VARIANT,
    FHIR_DIAGNOSIS            VARIANT,
    FHIR_INSURANCE            VARIANT,
    FHIR_ITEM                 VARIANT,
    FHIR_TOTAL                VARIANT,
    FHIR_PAYMENT              VARIANT,
    FHIR_CLAIM                VARIANT,
    FHIR_REFERRAL             VARIANT,
    FHIR_FACILITY             VARIANT,
    FHIR_CONTAINED            VARIANT
);

-- DiagnosticReport
CREATE TABLE IF NOT EXISTS FOUNDATION.DIAGNOSTIC_REPORT (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_STATUS               VARIANT,
    FHIR_CATEGORY             VARIANT,
    FHIR_CODE                 VARIANT,
    FHIR_SUBJECT              VARIANT,
    FHIR_ENCOUNTER            VARIANT,
    FHIR_EFFECTIVEDATETIME    VARIANT,
    FHIR_ISSUED               VARIANT,
    FHIR_PERFORMER            VARIANT,
    FHIR_RESULT               VARIANT,
    FHIR_PRESENTEDFORM        VARIANT
);

-- DocumentReference
CREATE TABLE IF NOT EXISTS FOUNDATION.DOCUMENT_REFERENCE (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_IDENTIFIER           VARIANT,
    FHIR_STATUS               VARIANT,
    FHIR_TYPE                 VARIANT,
    FHIR_CATEGORY             VARIANT,
    FHIR_SUBJECT              VARIANT,
    FHIR_DATE                 VARIANT,
    FHIR_AUTHOR               VARIANT,
    FHIR_CUSTODIAN            VARIANT,
    FHIR_CONTENT              VARIANT,
    FHIR_CONTEXT              VARIANT
);

-- Immunization
CREATE TABLE IF NOT EXISTS FOUNDATION.IMMUNIZATION (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_STATUS               VARIANT,
    FHIR_VACCINECODE          VARIANT,
    FHIR_PATIENT              VARIANT,
    FHIR_ENCOUNTER            VARIANT,
    FHIR_OCCURRENCEDATETIME   VARIANT,
    FHIR_PRIMARYSOURCE        VARIANT,
    FHIR_LOCATION             VARIANT
);

-- MedicationRequest
CREATE TABLE IF NOT EXISTS FOUNDATION.MEDICATION_REQUEST (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_STATUS               VARIANT,
    FHIR_INTENT               VARIANT,
    FHIR_CATEGORY             VARIANT,
    FHIR_MEDICATIONCODEABLECONCEPT VARIANT,
    FHIR_MEDICATIONREFERENCE  VARIANT,
    FHIR_SUBJECT              VARIANT,
    FHIR_ENCOUNTER            VARIANT,
    FHIR_AUTHOREDON           VARIANT,
    FHIR_REQUESTER            VARIANT,
    FHIR_REASONCODE           VARIANT,
    FHIR_REASONREFERENCE      VARIANT,
    FHIR_DOSAGEINSTRUCTION    VARIANT
);

-- Medication
CREATE TABLE IF NOT EXISTS FOUNDATION.MEDICATION (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_CODE                 VARIANT,
    FHIR_STATUS               VARIANT
);

-- MedicationAdministration
CREATE TABLE IF NOT EXISTS FOUNDATION.MEDICATION_ADMINISTRATION (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_STATUS               VARIANT,
    FHIR_MEDICATIONCODEABLECONCEPT VARIANT,
    FHIR_SUBJECT              VARIANT,
    FHIR_CONTEXT              VARIANT,
    FHIR_EFFECTIVEDATETIME    VARIANT,
    FHIR_REASONCODE           VARIANT,
    FHIR_REASONREFERENCE      VARIANT
);

-- CareTeam
CREATE TABLE IF NOT EXISTS FOUNDATION.CARE_TEAM (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_STATUS               VARIANT,
    FHIR_SUBJECT              VARIANT,
    FHIR_ENCOUNTER            VARIANT,
    FHIR_PERIOD               VARIANT,
    FHIR_PARTICIPANT          VARIANT,
    FHIR_REASONCODE           VARIANT,
    FHIR_MANAGINGORGANIZATION VARIANT
);

-- CarePlan
CREATE TABLE IF NOT EXISTS FOUNDATION.CARE_PLAN (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_STATUS               VARIANT,
    FHIR_INTENT               VARIANT,
    FHIR_CATEGORY             VARIANT,
    FHIR_SUBJECT              VARIANT,
    FHIR_ENCOUNTER            VARIANT,
    FHIR_PERIOD               VARIANT,
    FHIR_CARETEAM             VARIANT,
    FHIR_ADDRESSES            VARIANT,
    FHIR_ACTIVITY             VARIANT,
    FHIR_TEXT                 VARIANT
);

-- SupplyDelivery
CREATE TABLE IF NOT EXISTS FOUNDATION.SUPPLY_DELIVERY (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_STATUS               VARIANT,
    FHIR_PATIENT              VARIANT,
    FHIR_TYPE                 VARIANT,
    FHIR_SUPPLIEDITEM         VARIANT,
    FHIR_OCCURRENCEDATETIME   VARIANT
);

-- Provenance
CREATE TABLE IF NOT EXISTS FOUNDATION.PROVENANCE (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_TARGET               VARIANT,
    FHIR_RECORDED             VARIANT,
    FHIR_AGENT                VARIANT
);

-- AllergyIntolerance
CREATE TABLE IF NOT EXISTS FOUNDATION.ALLERGY_INTOLERANCE (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_CLINICALSTATUS       VARIANT,
    FHIR_VERIFICATIONSTATUS   VARIANT,
    FHIR_TYPE                 VARIANT,
    FHIR_CATEGORY             VARIANT,
    FHIR_CRITICALITY          VARIANT,
    FHIR_CODE                 VARIANT,
    FHIR_PATIENT              VARIANT,
    FHIR_RECORDEDDATE         VARIANT,
    FHIR_REACTION             VARIANT
);

-- Device
CREATE TABLE IF NOT EXISTS FOUNDATION.DEVICE (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_STATUS               VARIANT,
    FHIR_DISTINCTIDENTIFIER   VARIANT,
    FHIR_MANUFACTUREDATE      VARIANT,
    FHIR_EXPIRATIONDATE       VARIANT,
    FHIR_LOTNUMBER            VARIANT,
    FHIR_SERIALNUMBER         VARIANT,
    FHIR_DEVICENAME           VARIANT,
    FHIR_TYPE                 VARIANT,
    FHIR_PATIENT              VARIANT,
    FHIR_UDICARRIER           VARIANT
);

-- ImagingStudy
CREATE TABLE IF NOT EXISTS FOUNDATION.IMAGING_STUDY (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_IDENTIFIER           VARIANT,
    FHIR_STATUS               VARIANT,
    FHIR_SUBJECT              VARIANT,
    FHIR_ENCOUNTER            VARIANT,
    FHIR_STARTED              VARIANT,
    FHIR_NUMBEROFSERIES       VARIANT,
    FHIR_NUMBEROFINSTANCES    VARIANT,
    FHIR_PROCEDURECODE        VARIANT,
    FHIR_LOCATION             VARIANT,
    FHIR_SERIES               VARIANT
);

-- ============================================================================
-- Reference/directory resources (Organization, Location, Practitioner,
-- PractitionerRole) -- these are referenced BY the clinical resources above
-- (e.g. Encounter.serviceProvider, PractitionerRole.organization) but aren't
-- clinical facts about a patient themselves. Same semi-flat pattern.
-- ============================================================================


-- Organization
CREATE TABLE IF NOT EXISTS FOUNDATION.ORGANIZATION (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_ACTIVE               VARIANT,
    FHIR_ADDRESS              VARIANT,
    FHIR_EXTENSION            VARIANT,
    FHIR_IDENTIFIER           VARIANT,
    FHIR_NAME                 VARIANT,
    FHIR_TELECOM              VARIANT,
    FHIR_TYPE                 VARIANT
);

-- Location
CREATE TABLE IF NOT EXISTS FOUNDATION.LOCATION (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_ADDRESS              VARIANT,
    FHIR_DESCRIPTION          VARIANT,
    FHIR_IDENTIFIER           VARIANT,
    FHIR_MANAGINGORGANIZATION VARIANT,
    FHIR_MODE                 VARIANT,
    FHIR_NAME                 VARIANT,
    FHIR_PHYSICALTYPE         VARIANT,
    FHIR_POSITION             VARIANT,
    FHIR_STATUS               VARIANT,
    FHIR_TELECOM              VARIANT
);

-- Practitioner
CREATE TABLE IF NOT EXISTS FOUNDATION.PRACTITIONER (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_ACTIVE               VARIANT,
    FHIR_ADDRESS              VARIANT,
    FHIR_EXTENSION            VARIANT,
    FHIR_GENDER               VARIANT,
    FHIR_IDENTIFIER           VARIANT,
    FHIR_NAME                 VARIANT,
    FHIR_TELECOM              VARIANT
);

-- PractitionerRole
CREATE TABLE IF NOT EXISTS FOUNDATION.PRACTITIONER_ROLE (
    RESOURCE_ID          VARCHAR,                                -- resource's own FHIR id (business key)
    BUNDLE_TRACK_ID_REF  VARCHAR,                                -- FK -> RAW.BUNDLE_RAW.TRACKING_ID
    SOURCE_FILE_NAME     VARCHAR,
    ENTRY_INDEX          NUMBER,                                 -- position of this resource in the bundle's entry[] array
    FOUNDATION_LOAD_TS   TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    FHIR_CODE                 VARIANT,
    FHIR_LOCATION             VARIANT,
    FHIR_ORGANIZATION         VARIANT,
    FHIR_PRACTITIONER         VARIANT,
    FHIR_SPECIALTY            VARIANT,
    FHIR_TELECOM              VARIANT
);
