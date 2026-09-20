-- ============================================================================
-- 06b_semantic_views.sql
-- Semantic Views: one per healthcare domain.
-- Each semantic view points at the flattened ACCESS.VW_* views and defines
-- typed dimensions, metrics, synonyms, and verified queries that Cortex
-- Analyst uses for text-to-SQL generation.
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;
USE SCHEMA SEMANTIC;

-- ---------------------------------------------------------------------------
-- 1. SV_VISITS
--    Domain: encounter / visit analytics
-- ---------------------------------------------------------------------------
CREATE OR REPLACE SEMANTIC VIEW SEMANTIC.SV_VISITS

  TABLES (
    visits AS HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_VISITS
      PRIMARY KEY (ENCOUNTER_ID)
      COMMENT = 'One row per patient encounter/visit, enriched with organization, location, and practitioner'
  )

  DIMENSIONS (
    visits.patient_id         AS PATIENT_ID
      COMMENT = 'Unique patient identifier',
    visits.patient_name       AS PATIENT_NAME
      WITH SYNONYMS = ('patient', 'member', 'person')
      COMMENT = 'Full name of the patient (given + family)',
    visits.patient_gender     AS PATIENT_GENDER
      WITH SYNONYMS = ('gender', 'sex')
      COMMENT = 'Patient gender: male, female, other',
    visits.patient_birth_date AS PATIENT_BIRTH_DATE
      WITH SYNONYMS = ('DOB', 'date of birth', 'birthday')
      COMMENT = 'Patient date of birth',
    visits.encounter_id       AS ENCOUNTER_ID
      COMMENT = 'Unique encounter/visit identifier',
    visits.encounter_status   AS ENCOUNTER_STATUS
      COMMENT = 'Encounter status: finished, in-progress, cancelled',
    visits.encounter_class    AS ENCOUNTER_CLASS
      WITH SYNONYMS = ('visit type', 'class', 'setting')
      COMMENT = 'Encounter class code: AMB (ambulatory), EMER (emergency), IMP (inpatient), WELLNESS, etc.',
    visits.encounter_type     AS ENCOUNTER_TYPE
      COMMENT = 'Human-readable encounter type description',
    visits.encounter_start    AS ENCOUNTER_START
      WITH SYNONYMS = ('admission date', 'visit date', 'start date')
      COMMENT = 'Encounter start timestamp',
    visits.encounter_end      AS ENCOUNTER_END
      WITH SYNONYMS = ('discharge date', 'end date')
      COMMENT = 'Encounter end timestamp',
    visits.encounter_reason   AS ENCOUNTER_REASON
      WITH SYNONYMS = ('reason for visit', 'chief complaint')
      COMMENT = 'Primary reason for the encounter',
    visits.organization_name  AS ORGANIZATION_NAME
      WITH SYNONYMS = ('facility', 'hospital', 'provider org', 'service provider')
      COMMENT = 'Name of the healthcare organization / facility',
    visits.location_name      AS LOCATION_NAME
      WITH SYNONYMS = ('site', 'clinic')
      COMMENT = 'Name of the physical location where the encounter occurred',
    visits.location_city      AS LOCATION_CITY
      COMMENT = 'City of the encounter location',
    visits.location_state     AS LOCATION_STATE
      COMMENT = 'State of the encounter location',
    visits.practitioner_name  AS PRACTITIONER_NAME
      WITH SYNONYMS = ('doctor', 'physician', 'provider', 'clinician')
      COMMENT = 'Name of the primary practitioner for the encounter'
  )

  METRICS (
    visits.visit_count             AS COUNT(ENCOUNTER_ID)
      WITH SYNONYMS = ('number of visits', 'encounter count', 'total visits')
      COMMENT = 'Total number of encounters/visits',
    visits.distinct_patient_count  AS COUNT(DISTINCT PATIENT_ID)
      WITH SYNONYMS = ('unique patients', 'patient count', 'headcount')
      COMMENT = 'Number of distinct patients',
    visits.avg_length_of_stay      AS AVG(LENGTH_OF_STAY_MINUTES)
      WITH SYNONYMS = ('average LOS', 'mean length of stay')
      COMMENT = 'Average length of stay in minutes across encounters',
    visits.total_los_minutes       AS SUM(LENGTH_OF_STAY_MINUTES)
      WITH SYNONYMS = ('total LOS')
      COMMENT = 'Total length of stay in minutes across all encounters',
    visits.max_length_of_stay      AS MAX(LENGTH_OF_STAY_MINUTES)
      COMMENT = 'Maximum length of stay in minutes for a single encounter'
  )

  COMMENT = 'Healthcare visit/encounter analytics: visit counts, length of stay, facility and practitioner breakdowns'

  AI_SQL_GENERATION 'When filtering by encounter class, use the code values: AMB for ambulatory, EMER for emergency, IMP for inpatient, WELLNESS for wellness visits. Date filters should default to the ENCOUNTER_START column. When asked about readmissions, look for multiple encounters for the same patient within 30 days.'

  AI_VERIFIED_QUERIES (
    visits_by_class AS (
      QUESTION 'How many visits by encounter class?'
      SQL 'SELECT ENCOUNTER_CLASS, COUNT(*) AS VISIT_COUNT FROM HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_VISITS GROUP BY ENCOUNTER_CLASS ORDER BY VISIT_COUNT DESC'
    ),
    ed_visits_by_facility AS (
      QUESTION 'Show me emergency department visits by facility'
      SQL 'SELECT ORGANIZATION_NAME, COUNT(*) AS ED_VISITS FROM HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_VISITS WHERE ENCOUNTER_CLASS = ''EMER'' GROUP BY ORGANIZATION_NAME ORDER BY ED_VISITS DESC'
    ),
    avg_los_by_type AS (
      QUESTION 'What is the average length of stay by encounter type?'
      SQL 'SELECT ENCOUNTER_TYPE, ROUND(AVG(LENGTH_OF_STAY_MINUTES), 2) AS AVG_LOS_MINUTES FROM HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_VISITS GROUP BY ENCOUNTER_TYPE ORDER BY AVG_LOS_MINUTES DESC'
    )
  );


-- ---------------------------------------------------------------------------
-- 2. SV_DIAGNOSES
--    Domain: diagnosis / condition analytics
-- ---------------------------------------------------------------------------
CREATE OR REPLACE SEMANTIC VIEW SEMANTIC.SV_DIAGNOSES

  TABLES (
    diagnoses AS HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_DIAGNOSES
      PRIMARY KEY (CONDITION_ID)
      COMMENT = 'One row per patient diagnosis/condition, linked to encounter'
  )

  DIMENSIONS (
    diagnoses.patient_id         AS PATIENT_ID
      COMMENT = 'Unique patient identifier',
    diagnoses.patient_name       AS PATIENT_NAME
      WITH SYNONYMS = ('patient', 'member')
      COMMENT = 'Full name of the patient',
    diagnoses.condition_id       AS CONDITION_ID
      COMMENT = 'Unique condition/diagnosis identifier',
    diagnoses.icd_code           AS ICD_CODE
      WITH SYNONYMS = ('ICD-10', 'diagnosis code', 'dx code')
      COMMENT = 'ICD-10 or SNOMED code for the diagnosis',
    diagnoses.diagnosis_display  AS DIAGNOSIS_DISPLAY
      WITH SYNONYMS = ('diagnosis', 'condition', 'dx', 'disease')
      COMMENT = 'Human-readable diagnosis name',
    diagnoses.code_system        AS CODE_SYSTEM
      COMMENT = 'Coding system URI (e.g. http://snomed.info/sct)',
    diagnoses.clinical_status    AS CLINICAL_STATUS
      WITH SYNONYMS = ('status')
      COMMENT = 'Clinical status: active, resolved, recurrence, inactive',
    diagnoses.verification_status AS VERIFICATION_STATUS
      COMMENT = 'Verification status: confirmed, unconfirmed, provisional',
    diagnoses.diagnosis_category AS DIAGNOSIS_CATEGORY
      COMMENT = 'Category of the condition (encounter-diagnosis, problem-list-item, etc.)',
    diagnoses.onset_date         AS ONSET_DATE
      WITH SYNONYMS = ('diagnosis date', 'onset', 'start date')
      COMMENT = 'Date/time the condition was first observed',
    diagnoses.recorded_date      AS RECORDED_DATE
      COMMENT = 'Date the diagnosis was recorded in the system',
    diagnoses.encounter_id       AS ENCOUNTER_ID
      COMMENT = 'Linked encounter ID where this diagnosis was recorded'
  )

  METRICS (
    diagnoses.diagnosis_count          AS COUNT(CONDITION_ID)
      WITH SYNONYMS = ('number of diagnoses', 'condition count', 'dx count')
      COMMENT = 'Total number of diagnosis records',
    diagnoses.distinct_patient_count   AS COUNT(DISTINCT PATIENT_ID)
      WITH SYNONYMS = ('unique patients', 'patient count')
      COMMENT = 'Number of distinct patients with diagnoses',
    diagnoses.distinct_diagnosis_count AS COUNT(DISTINCT ICD_CODE)
      WITH SYNONYMS = ('unique diagnoses', 'distinct dx codes')
      COMMENT = 'Number of distinct ICD/SNOMED codes'
  )

  COMMENT = 'Healthcare diagnosis/condition analytics: ICD code distributions, active conditions, patient diagnosis counts'

  AI_SQL_GENERATION 'When users ask about top diagnoses, order by diagnosis_count descending. If asked about a specific ICD code, filter on ICD_CODE. For active conditions, filter CLINICAL_STATUS = active.'

  AI_VERIFIED_QUERIES (
    top_10_diagnoses AS (
      QUESTION 'What are the top 10 most common diagnoses?'
      SQL 'SELECT DIAGNOSIS_DISPLAY, ICD_CODE, COUNT(*) AS DIAGNOSIS_COUNT FROM HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_DIAGNOSES GROUP BY DIAGNOSIS_DISPLAY, ICD_CODE ORDER BY DIAGNOSIS_COUNT DESC LIMIT 10'
    ),
    active_conditions_by_patient AS (
      QUESTION 'How many active conditions does each patient have?'
      SQL 'SELECT PATIENT_NAME, COUNT(*) AS ACTIVE_CONDITIONS FROM HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_DIAGNOSES WHERE CLINICAL_STATUS = ''active'' GROUP BY PATIENT_NAME ORDER BY ACTIVE_CONDITIONS DESC'
    )
  );


-- ---------------------------------------------------------------------------
-- 3. SV_MEDICATIONS
--    Domain: medication / prescription analytics
-- ---------------------------------------------------------------------------
CREATE OR REPLACE SEMANTIC VIEW SEMANTIC.SV_MEDICATIONS

  TABLES (
    medications AS HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_MEDICATIONS
      PRIMARY KEY (MEDICATION_REQUEST_ID)
      COMMENT = 'One row per medication request/prescription for a patient'
  )

  DIMENSIONS (
    medications.patient_id            AS PATIENT_ID
      COMMENT = 'Unique patient identifier',
    medications.patient_name          AS PATIENT_NAME
      WITH SYNONYMS = ('patient', 'member')
      COMMENT = 'Full name of the patient',
    medications.medication_request_id AS MEDICATION_REQUEST_ID
      COMMENT = 'Unique medication request identifier',
    medications.medication_code       AS MEDICATION_CODE
      WITH SYNONYMS = ('NDC', 'RxNorm code', 'drug code')
      COMMENT = 'Code for the medication (RxNorm or NDC)',
    medications.medication_name       AS MEDICATION_NAME
      WITH SYNONYMS = ('drug', 'medication', 'prescription', 'Rx', 'med')
      COMMENT = 'Human-readable medication/drug name',
    medications.medication_status     AS MEDICATION_STATUS
      WITH SYNONYMS = ('status', 'Rx status')
      COMMENT = 'Status of the prescription: active, completed, stopped, cancelled',
    medications.medication_intent     AS MEDICATION_INTENT
      COMMENT = 'Intent: order, plan, proposal',
    medications.authored_date         AS AUTHORED_DATE
      WITH SYNONYMS = ('prescribed date', 'Rx date', 'order date')
      COMMENT = 'Date the prescription was authored/written',
    medications.medication_reason     AS MEDICATION_REASON
      WITH SYNONYMS = ('indication', 'reason for Rx')
      COMMENT = 'Reason/indication for the medication',
    medications.dosage_instruction    AS DOSAGE_INSTRUCTION
      WITH SYNONYMS = ('dosage', 'dose', 'sig')
      COMMENT = 'Dosage instruction text',
    medications.encounter_id          AS ENCOUNTER_ID
      COMMENT = 'Linked encounter ID'
  )

  METRICS (
    medications.prescription_count        AS COUNT(MEDICATION_REQUEST_ID)
      WITH SYNONYMS = ('number of prescriptions', 'Rx count', 'order count')
      COMMENT = 'Total number of medication prescriptions',
    medications.distinct_patient_count    AS COUNT(DISTINCT PATIENT_ID)
      WITH SYNONYMS = ('unique patients')
      COMMENT = 'Number of distinct patients with prescriptions',
    medications.distinct_medication_count AS COUNT(DISTINCT MEDICATION_CODE)
      WITH SYNONYMS = ('unique medications', 'unique drugs')
      COMMENT = 'Number of distinct medications prescribed'
  )

  COMMENT = 'Medication/prescription analytics: drug frequencies, patient polypharmacy, prescription trends'

  AI_SQL_GENERATION 'When asked about most prescribed medications, group by MEDICATION_NAME and order by prescription_count descending. For active prescriptions, filter MEDICATION_STATUS = active.'

  AI_VERIFIED_QUERIES (
    top_medications AS (
      QUESTION 'What are the most commonly prescribed medications?'
      SQL 'SELECT MEDICATION_NAME, COUNT(*) AS RX_COUNT FROM HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_MEDICATIONS GROUP BY MEDICATION_NAME ORDER BY RX_COUNT DESC LIMIT 10'
    )
  );


-- ---------------------------------------------------------------------------
-- 4. SV_CLAIMS
--    Domain: claims / financial analytics
-- ---------------------------------------------------------------------------
CREATE OR REPLACE SEMANTIC VIEW SEMANTIC.SV_CLAIMS

  TABLES (
    claims AS HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_CLAIMS
      PRIMARY KEY (CLAIM_ID)
      COMMENT = 'One row per insurance claim filed for a patient'
  )

  DIMENSIONS (
    claims.patient_id          AS PATIENT_ID
      COMMENT = 'Unique patient identifier',
    claims.patient_name        AS PATIENT_NAME
      WITH SYNONYMS = ('patient', 'member')
      COMMENT = 'Full name of the patient',
    claims.claim_id            AS CLAIM_ID
      COMMENT = 'Unique claim identifier',
    claims.claim_status        AS CLAIM_STATUS
      WITH SYNONYMS = ('status')
      COMMENT = 'Claim status: active, cancelled, draft, entered-in-error',
    claims.claim_type          AS CLAIM_TYPE
      WITH SYNONYMS = ('type of claim', 'claim category')
      COMMENT = 'Type of claim: institutional, professional, pharmacy, oral, vision',
    claims.claim_use           AS CLAIM_USE
      COMMENT = 'Use of the claim: claim, preauthorization, predetermination',
    claims.billable_start      AS BILLABLE_START
      WITH SYNONYMS = ('service date', 'claim start')
      COMMENT = 'Start date of the billable period',
    claims.billable_end        AS BILLABLE_END
      COMMENT = 'End date of the billable period',
    claims.claim_currency      AS CLAIM_CURRENCY
      COMMENT = 'Currency of the claim (e.g. USD)',
    claims.claim_created_date  AS CLAIM_CREATED_DATE
      WITH SYNONYMS = ('filed date', 'submission date')
      COMMENT = 'Date the claim was created/filed',
    claims.encounter_id        AS ENCOUNTER_ID
      COMMENT = 'Linked encounter ID'
  )

  METRICS (
    claims.claim_count        AS COUNT(CLAIM_ID)
      WITH SYNONYMS = ('number of claims', 'total claims')
      COMMENT = 'Total number of claims',
    claims.total_billed       AS SUM(TOTAL_CLAIM_AMOUNT)
      WITH SYNONYMS = ('total cost', 'total charges', 'total billed amount', 'total spend')
      COMMENT = 'Sum of all claim amounts',
    claims.avg_claim_amount   AS AVG(TOTAL_CLAIM_AMOUNT)
      WITH SYNONYMS = ('average claim', 'mean claim cost')
      COMMENT = 'Average claim amount',
    claims.max_claim_amount   AS MAX(TOTAL_CLAIM_AMOUNT)
      COMMENT = 'Maximum single claim amount',
    claims.distinct_patient_count AS COUNT(DISTINCT PATIENT_ID)
      WITH SYNONYMS = ('unique patients')
      COMMENT = 'Number of distinct patients with claims'
  )

  COMMENT = 'Healthcare claims/financial analytics: cost analysis, claim distributions, patient spending'

  AI_SQL_GENERATION 'Financial amounts are in TOTAL_CLAIM_AMOUNT. When filtering by claim type, use lowercase values like institutional or professional. Date-based questions should default to BILLABLE_START.'

  AI_VERIFIED_QUERIES (
    total_by_type AS (
      QUESTION 'What is the total billed amount by claim type?'
      SQL 'SELECT CLAIM_TYPE, SUM(TOTAL_CLAIM_AMOUNT) AS TOTAL_BILLED, COUNT(*) AS CLAIM_COUNT FROM HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_CLAIMS GROUP BY CLAIM_TYPE ORDER BY TOTAL_BILLED DESC'
    ),
    top_patients_by_cost AS (
      QUESTION 'Which patients have the highest total claims?'
      SQL 'SELECT PATIENT_NAME, SUM(TOTAL_CLAIM_AMOUNT) AS TOTAL_BILLED, COUNT(*) AS CLAIM_COUNT FROM HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_CLAIMS GROUP BY PATIENT_NAME ORDER BY TOTAL_BILLED DESC LIMIT 10'
    )
  );


-- ---------------------------------------------------------------------------
-- 5. SV_OBSERVATIONS
--    Domain: lab results / vital signs analytics
-- ---------------------------------------------------------------------------
CREATE OR REPLACE SEMANTIC VIEW SEMANTIC.SV_OBSERVATIONS

  TABLES (
    observations AS HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_OBSERVATIONS
      PRIMARY KEY (OBSERVATION_ID)
      COMMENT = 'One row per clinical observation (lab result, vital sign) for a patient'
  )

  DIMENSIONS (
    observations.patient_id             AS PATIENT_ID
      COMMENT = 'Unique patient identifier',
    observations.patient_name           AS PATIENT_NAME
      WITH SYNONYMS = ('patient', 'member')
      COMMENT = 'Full name of the patient',
    observations.observation_id         AS OBSERVATION_ID
      COMMENT = 'Unique observation identifier',
    observations.observation_code       AS OBSERVATION_CODE
      WITH SYNONYMS = ('LOINC code', 'lab code', 'test code')
      COMMENT = 'LOINC or other code for the observation',
    observations.observation_display    AS OBSERVATION_DISPLAY
      WITH SYNONYMS = ('lab test', 'vital sign', 'observation', 'test name')
      COMMENT = 'Human-readable name of the observation/lab/vital',
    observations.observation_category   AS OBSERVATION_CATEGORY
      WITH SYNONYMS = ('category')
      COMMENT = 'Category: vital-signs, laboratory, survey, social-history, etc.',
    observations.observation_status     AS OBSERVATION_STATUS
      COMMENT = 'Observation status: final, preliminary, amended',
    observations.effective_date         AS EFFECTIVE_DATE
      WITH SYNONYMS = ('test date', 'observation date', 'result date')
      COMMENT = 'Date/time the observation was made',
    observations.value_unit             AS VALUE_UNIT
      WITH SYNONYMS = ('unit', 'UOM')
      COMMENT = 'Unit of measure for the observation value',
    observations.value_codeable_display AS VALUE_CODEABLE_DISPLAY
      COMMENT = 'Display text for coded observation values',
    observations.encounter_id           AS ENCOUNTER_ID
      COMMENT = 'Linked encounter ID'
  )

  METRICS (
    observations.observation_count        AS COUNT(OBSERVATION_ID)
      WITH SYNONYMS = ('number of observations', 'lab count', 'test count')
      COMMENT = 'Total number of observations',
    observations.avg_value                AS AVG(VALUE_QUANTITY)
      WITH SYNONYMS = ('average result', 'mean value')
      COMMENT = 'Average numeric value across observations',
    observations.min_value                AS MIN(VALUE_QUANTITY)
      COMMENT = 'Minimum observed numeric value',
    observations.max_value                AS MAX(VALUE_QUANTITY)
      COMMENT = 'Maximum observed numeric value',
    observations.distinct_patient_count   AS COUNT(DISTINCT PATIENT_ID)
      WITH SYNONYMS = ('unique patients')
      COMMENT = 'Number of distinct patients with observations'
  )

  COMMENT = 'Clinical observation analytics: lab results, vital signs, test frequencies and value distributions'

  AI_SQL_GENERATION 'When asked about specific lab values (e.g., blood pressure, glucose, BMI), filter on OBSERVATION_DISPLAY using ILIKE. For vital signs, filter OBSERVATION_CATEGORY = vital-signs. For lab results, filter OBSERVATION_CATEGORY = laboratory.'

  AI_VERIFIED_QUERIES (
    common_observations AS (
      QUESTION 'What are the most common lab tests and vitals recorded?'
      SQL 'SELECT OBSERVATION_DISPLAY, OBSERVATION_CATEGORY, COUNT(*) AS OBS_COUNT FROM HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_OBSERVATIONS GROUP BY OBSERVATION_DISPLAY, OBSERVATION_CATEGORY ORDER BY OBS_COUNT DESC LIMIT 15'
    )
  );


-- ---------------------------------------------------------------------------
-- 6. SV_PROCEDURES
--    Domain: clinical procedure analytics
-- ---------------------------------------------------------------------------
CREATE OR REPLACE SEMANTIC VIEW SEMANTIC.SV_PROCEDURES

  TABLES (
    procedures AS HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_PROCEDURES
      PRIMARY KEY (PROCEDURE_ID)
      COMMENT = 'One row per clinical procedure performed on a patient'
  )

  DIMENSIONS (
    procedures.patient_id         AS PATIENT_ID
      COMMENT = 'Unique patient identifier',
    procedures.patient_name       AS PATIENT_NAME
      WITH SYNONYMS = ('patient', 'member')
      COMMENT = 'Full name of the patient',
    procedures.procedure_id       AS PROCEDURE_ID
      COMMENT = 'Unique procedure identifier',
    procedures.procedure_code     AS PROCEDURE_CODE
      WITH SYNONYMS = ('CPT code', 'SNOMED code', 'procedure code')
      COMMENT = 'SNOMED or CPT code for the procedure',
    procedures.procedure_display  AS PROCEDURE_DISPLAY
      WITH SYNONYMS = ('procedure', 'operation', 'surgery', 'intervention')
      COMMENT = 'Human-readable procedure name',
    procedures.procedure_status   AS PROCEDURE_STATUS
      WITH SYNONYMS = ('status')
      COMMENT = 'Procedure status: completed, in-progress, not-done',
    procedures.performed_start    AS PERFORMED_START
      WITH SYNONYMS = ('procedure date', 'surgery date')
      COMMENT = 'Date/time the procedure started',
    procedures.procedure_reason   AS PROCEDURE_REASON
      WITH SYNONYMS = ('indication', 'reason')
      COMMENT = 'Reason the procedure was performed',
    procedures.encounter_id       AS ENCOUNTER_ID
      COMMENT = 'Linked encounter ID'
  )

  METRICS (
    procedures.procedure_count        AS COUNT(PROCEDURE_ID)
      WITH SYNONYMS = ('number of procedures', 'procedure volume')
      COMMENT = 'Total number of procedures performed',
    procedures.distinct_patient_count AS COUNT(DISTINCT PATIENT_ID)
      WITH SYNONYMS = ('unique patients')
      COMMENT = 'Number of distinct patients who had procedures',
    procedures.distinct_procedure_types AS COUNT(DISTINCT PROCEDURE_CODE)
      WITH SYNONYMS = ('unique procedures')
      COMMENT = 'Number of distinct procedure types'
  )

  COMMENT = 'Clinical procedure analytics: procedure volumes, patient procedure counts, procedure type distributions'

  AI_SQL_GENERATION 'When asked about common procedures, group by PROCEDURE_DISPLAY and order by procedure_count descending. For completed procedures, filter PROCEDURE_STATUS = completed.'

  AI_VERIFIED_QUERIES (
    top_procedures AS (
      QUESTION 'What are the most commonly performed procedures?'
      SQL 'SELECT PROCEDURE_DISPLAY, PROCEDURE_CODE, COUNT(*) AS PROCEDURE_COUNT FROM HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_PROCEDURES GROUP BY PROCEDURE_DISPLAY, PROCEDURE_CODE ORDER BY PROCEDURE_COUNT DESC LIMIT 10'
    )
  );
