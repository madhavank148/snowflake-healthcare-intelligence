-- ============================================================================
-- 02_load_foundation.sql
-- Splits each loaded RAW bundle's entry[] array by resourceType and inserts
-- one row per resource into the matching FOUNDATION table, mapping each
-- root-level JSON field to its FHIR_<FIELD> column.
--
-- Safe to re-run after truncating the target FOUNDATION tables; not
-- idempotent as written (no dedup against BUNDLE_TRACK_ID_REF) since this is
-- the initial setup/load pass.
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;
USE SCHEMA FOUNDATION;


-- Patient
INSERT INTO FOUNDATION.PATIENT
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:identifier,
    e.value:resource:name,
    e.value:resource:gender,
    e.value:resource:birthDate,
    e.value:resource:address,
    e.value:resource:telecom,
    e.value:resource:maritalStatus,
    e.value:resource:multipleBirthBoolean,
    e.value:resource:multipleBirthInteger,
    e.value:resource:communication,
    e.value:resource:deceasedDateTime,
    e.value:resource:extension,
    e.value:resource:text
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'Patient';

-- Encounter
INSERT INTO FOUNDATION.ENCOUNTER
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:identifier,
    e.value:resource:status,
    e.value:resource:class,
    e.value:resource:type,
    e.value:resource:subject,
    e.value:resource:participant,
    e.value:resource:period,
    e.value:resource:reasonCode,
    e.value:resource:hospitalization,
    e.value:resource:location,
    e.value:resource:serviceProvider
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'Encounter';

-- Condition
INSERT INTO FOUNDATION.CONDITION
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:clinicalStatus,
    e.value:resource:verificationStatus,
    e.value:resource:category,
    e.value:resource:code,
    e.value:resource:subject,
    e.value:resource:encounter,
    e.value:resource:onsetDateTime,
    e.value:resource:abatementDateTime,
    e.value:resource:recordedDate
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'Condition';

-- Observation
INSERT INTO FOUNDATION.OBSERVATION
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:status,
    e.value:resource:category,
    e.value:resource:code,
    e.value:resource:subject,
    e.value:resource:encounter,
    e.value:resource:effectiveDateTime,
    e.value:resource:issued,
    e.value:resource:valueQuantity,
    e.value:resource:valueCodeableConcept,
    e.value:resource:valueString,
    e.value:resource:component
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'Observation';

-- Procedure
INSERT INTO FOUNDATION.PROCEDURE
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:status,
    e.value:resource:code,
    e.value:resource:subject,
    e.value:resource:encounter,
    e.value:resource:performedPeriod,
    e.value:resource:reasonCode,
    e.value:resource:reasonReference,
    e.value:resource:location
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'Procedure';

-- Claim
INSERT INTO FOUNDATION.CLAIM
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:status,
    e.value:resource:type,
    e.value:resource:use,
    e.value:resource:patient,
    e.value:resource:billablePeriod,
    e.value:resource:created,
    e.value:resource:provider,
    e.value:resource:priority,
    e.value:resource:facility,
    e.value:resource:prescription,
    e.value:resource:insurance,
    e.value:resource:item,
    e.value:resource:total,
    e.value:resource:diagnosis,
    e.value:resource:procedure,
    e.value:resource:supportingInfo
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'Claim';

-- ExplanationOfBenefit
INSERT INTO FOUNDATION.EXPLANATION_OF_BENEFIT
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:identifier,
    e.value:resource:status,
    e.value:resource:type,
    e.value:resource:use,
    e.value:resource:patient,
    e.value:resource:billablePeriod,
    e.value:resource:created,
    e.value:resource:insurer,
    e.value:resource:provider,
    e.value:resource:outcome,
    e.value:resource:careTeam,
    e.value:resource:diagnosis,
    e.value:resource:insurance,
    e.value:resource:item,
    e.value:resource:total,
    e.value:resource:payment,
    e.value:resource:claim,
    e.value:resource:referral,
    e.value:resource:facility,
    e.value:resource:contained
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'ExplanationOfBenefit';

-- DiagnosticReport
INSERT INTO FOUNDATION.DIAGNOSTIC_REPORT
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:status,
    e.value:resource:category,
    e.value:resource:code,
    e.value:resource:subject,
    e.value:resource:encounter,
    e.value:resource:effectiveDateTime,
    e.value:resource:issued,
    e.value:resource:performer,
    e.value:resource:result,
    e.value:resource:presentedForm
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'DiagnosticReport';

-- DocumentReference
INSERT INTO FOUNDATION.DOCUMENT_REFERENCE
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:identifier,
    e.value:resource:status,
    e.value:resource:type,
    e.value:resource:category,
    e.value:resource:subject,
    e.value:resource:date,
    e.value:resource:author,
    e.value:resource:custodian,
    e.value:resource:content,
    e.value:resource:context
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'DocumentReference';

-- Immunization
INSERT INTO FOUNDATION.IMMUNIZATION
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:status,
    e.value:resource:vaccineCode,
    e.value:resource:patient,
    e.value:resource:encounter,
    e.value:resource:occurrenceDateTime,
    e.value:resource:primarySource,
    e.value:resource:location
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'Immunization';

-- MedicationRequest
INSERT INTO FOUNDATION.MEDICATION_REQUEST
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:status,
    e.value:resource:intent,
    e.value:resource:category,
    e.value:resource:medicationCodeableConcept,
    e.value:resource:medicationReference,
    e.value:resource:subject,
    e.value:resource:encounter,
    e.value:resource:authoredOn,
    e.value:resource:requester,
    e.value:resource:reasonCode,
    e.value:resource:reasonReference,
    e.value:resource:dosageInstruction
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'MedicationRequest';

-- Medication
INSERT INTO FOUNDATION.MEDICATION
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:code,
    e.value:resource:status
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'Medication';

-- MedicationAdministration
INSERT INTO FOUNDATION.MEDICATION_ADMINISTRATION
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:status,
    e.value:resource:medicationCodeableConcept,
    e.value:resource:subject,
    e.value:resource:context,
    e.value:resource:effectiveDateTime,
    e.value:resource:reasonCode,
    e.value:resource:reasonReference
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'MedicationAdministration';

-- CareTeam
INSERT INTO FOUNDATION.CARE_TEAM
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:status,
    e.value:resource:subject,
    e.value:resource:encounter,
    e.value:resource:period,
    e.value:resource:participant,
    e.value:resource:reasonCode,
    e.value:resource:managingOrganization
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'CareTeam';

-- CarePlan
INSERT INTO FOUNDATION.CARE_PLAN
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:status,
    e.value:resource:intent,
    e.value:resource:category,
    e.value:resource:subject,
    e.value:resource:encounter,
    e.value:resource:period,
    e.value:resource:careTeam,
    e.value:resource:addresses,
    e.value:resource:activity,
    e.value:resource:text
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'CarePlan';

-- SupplyDelivery
INSERT INTO FOUNDATION.SUPPLY_DELIVERY
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:status,
    e.value:resource:patient,
    e.value:resource:type,
    e.value:resource:suppliedItem,
    e.value:resource:occurrenceDateTime
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'SupplyDelivery';

-- Provenance
INSERT INTO FOUNDATION.PROVENANCE
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:target,
    e.value:resource:recorded,
    e.value:resource:agent
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'Provenance';

-- AllergyIntolerance
INSERT INTO FOUNDATION.ALLERGY_INTOLERANCE
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:clinicalStatus,
    e.value:resource:verificationStatus,
    e.value:resource:type,
    e.value:resource:category,
    e.value:resource:criticality,
    e.value:resource:code,
    e.value:resource:patient,
    e.value:resource:recordedDate,
    e.value:resource:reaction
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'AllergyIntolerance';

-- Device
INSERT INTO FOUNDATION.DEVICE
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:status,
    e.value:resource:distinctIdentifier,
    e.value:resource:manufactureDate,
    e.value:resource:expirationDate,
    e.value:resource:lotNumber,
    e.value:resource:serialNumber,
    e.value:resource:deviceName,
    e.value:resource:type,
    e.value:resource:patient,
    e.value:resource:udiCarrier
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'Device';

-- ImagingStudy
INSERT INTO FOUNDATION.IMAGING_STUDY
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:identifier,
    e.value:resource:status,
    e.value:resource:subject,
    e.value:resource:encounter,
    e.value:resource:started,
    e.value:resource:numberOfSeries,
    e.value:resource:numberOfInstances,
    e.value:resource:procedureCode,
    e.value:resource:location,
    e.value:resource:series
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'ImagingStudy';

-- Reference/directory resources

-- Organization
INSERT INTO FOUNDATION.ORGANIZATION
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:active,
    e.value:resource:address,
    e.value:resource:extension,
    e.value:resource:identifier,
    e.value:resource:name,
    e.value:resource:telecom,
    e.value:resource:type
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'Organization';

-- Location
INSERT INTO FOUNDATION.LOCATION
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:address,
    e.value:resource:description,
    e.value:resource:identifier,
    e.value:resource:managingOrganization,
    e.value:resource:mode,
    e.value:resource:name,
    e.value:resource:physicalType,
    e.value:resource:position,
    e.value:resource:status,
    e.value:resource:telecom
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'Location';

-- Practitioner
INSERT INTO FOUNDATION.PRACTITIONER
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:active,
    e.value:resource:address,
    e.value:resource:extension,
    e.value:resource:gender,
    e.value:resource:identifier,
    e.value:resource:name,
    e.value:resource:telecom
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'Practitioner';

-- PractitionerRole
INSERT INTO FOUNDATION.PRACTITIONER_ROLE
SELECT
    e.value:resource:id::VARCHAR,
    b.TRACKING_ID,
    b.SOURCE_FILE_NAME,
    e.index,
    CURRENT_TIMESTAMP(),
    e.value:resource:code,
    e.value:resource:location,
    e.value:resource:organization,
    e.value:resource:practitioner,
    e.value:resource:specialty,
    e.value:resource:telecom
FROM RAW.BUNDLE_RAW b,
     LATERAL FLATTEN(input => b.BUNDLE_JSON:entry) e
WHERE e.value:resource:resourceType::VARCHAR = 'PractitionerRole';


SELECT * FROM FOUNDATION.PATIENT LIMIT 5;
SELECT * FROM FOUNDATION.ENCOUNTER LIMIT 5; -- urn:uuid:06476266-59b1-ded7-4138-3c7543fd4981
SELECT * FROM FOUNDATION.CONDITION LIMIT 5;