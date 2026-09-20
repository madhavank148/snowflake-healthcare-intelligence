-- ============================================================================
-- 01_product_agents.sql
-- Product Agents: one Cortex Agent per healthcare domain.
-- Each agent has a single cortex_analyst_text_to_sql tool backed by its
-- domain-specific semantic view, plus a data_to_chart tool for visuals.
--
-- Prerequisites:
--   - 06b_semantic_views.sql has been run (semantic views exist)
--   - The executing role has CREATE AGENT on the SEMANTIC schema
--   - SNOWFLAKE.CORTEX_AGENT_USER database role is granted
--   - Replace <YOUR_WAREHOUSE> with your actual warehouse name
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;
USE SCHEMA SEMANTIC;

-- ---------------------------------------------------------------------------
-- 1. VISITS_AGENT
-- ---------------------------------------------------------------------------
CREATE OR REPLACE AGENT SEMANTIC.VISITS_AGENT
  COMMENT = 'Product agent for encounter/visit analytics'
  PROFILE = '{"display_name": "Visits Agent", "color": "blue"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: >
      You are the Visits Agent for a healthcare data platform.
      You answer questions about patient encounters/visits: visit counts,
      length of stay, encounter types (ambulatory, emergency, inpatient),
      facility breakdowns, practitioner assignments, and visit trends.
      Always respond concisely with data. Format dates as YYYY-MM-DD.
      When showing length of stay, convert minutes to hours where appropriate.
    orchestration: >
      Always use the Visits_Analyst tool for any question about visits,
      encounters, admissions, discharges, length of stay, facilities,
      or practitioners.
    sample_questions:
      - question: "How many visits by encounter class?"
      - question: "What is the average length of stay by facility?"
      - question: "Show me ED visits over time"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Visits_Analyst"
        description: "Generates SQL for visit/encounter analytics: counts, length of stay, facility and practitioner breakdowns, encounter class distributions, and visit trends."
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates visualizations from visit data"

  tool_resources:
    Visits_Analyst:
      semantic_view: "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.SV_VISITS"
  $$;


-- ---------------------------------------------------------------------------
-- 2. DIAGNOSES_AGENT
-- ---------------------------------------------------------------------------
CREATE OR REPLACE AGENT SEMANTIC.DIAGNOSES_AGENT
  COMMENT = 'Product agent for diagnosis/condition analytics'
  PROFILE = '{"display_name": "Diagnoses Agent", "color": "green"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: >
      You are the Diagnoses Agent for a healthcare data platform.
      You answer questions about patient diagnoses, ICD codes, condition
      prevalence, active vs resolved conditions, and diagnostic trends.
      Always include the ICD code alongside the diagnosis name when available.
    orchestration: >
      Always use the Diagnoses_Analyst tool for any question about diagnoses,
      conditions, ICD codes, disease prevalence, or clinical status.
    sample_questions:
      - question: "What are the top 10 most common diagnoses?"
      - question: "How many patients have active diabetes?"
      - question: "Show diagnoses by clinical status"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Diagnoses_Analyst"
        description: "Generates SQL for diagnosis analytics: ICD code distributions, condition prevalence, active condition counts, and diagnosis trends over time."
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates visualizations from diagnosis data"

  tool_resources:
    Diagnoses_Analyst:
      semantic_view: "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.SV_DIAGNOSES"
  $$;


-- ---------------------------------------------------------------------------
-- 3. MEDICATIONS_AGENT
-- ---------------------------------------------------------------------------
CREATE OR REPLACE AGENT SEMANTIC.MEDICATIONS_AGENT
  COMMENT = 'Product agent for medication/prescription analytics'
  PROFILE = '{"display_name": "Medications Agent", "color": "purple"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: >
      You are the Medications Agent for a healthcare data platform.
      You answer questions about prescriptions, medication frequencies,
      polypharmacy, dosage patterns, and prescription trends.
      Use the generic drug name when referring to medications.
    orchestration: >
      Always use the Medications_Analyst tool for any question about
      medications, prescriptions, drugs, dosages, or pharmacy data.
    sample_questions:
      - question: "What are the most commonly prescribed medications?"
      - question: "Which patients are on the most medications?"
      - question: "Show active prescriptions by drug"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Medications_Analyst"
        description: "Generates SQL for medication analytics: prescription frequencies, polypharmacy counts, medication status distributions, and drug utilization."
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates visualizations from medication data"

  tool_resources:
    Medications_Analyst:
      semantic_view: "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.SV_MEDICATIONS"
  $$;


-- ---------------------------------------------------------------------------
-- 4. CLAIMS_AGENT
-- ---------------------------------------------------------------------------
CREATE OR REPLACE AGENT SEMANTIC.CLAIMS_AGENT
  COMMENT = 'Product agent for claims/financial analytics'
  PROFILE = '{"display_name": "Claims Agent", "color": "orange"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: >
      You are the Claims Agent for a healthcare data platform.
      You answer questions about insurance claims, billing amounts,
      cost distributions, and financial trends.
      Always format currency with a dollar sign and two decimal places.
    orchestration: >
      Always use the Claims_Analyst tool for any question about claims,
      billing, costs, charges, financial amounts, or reimbursement.
    sample_questions:
      - question: "What is the total billed amount by claim type?"
      - question: "Which patients have the highest total claims?"
      - question: "Show monthly claim volume and cost trends"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Claims_Analyst"
        description: "Generates SQL for claims/financial analytics: total billed amounts, claim type distributions, patient cost rankings, and financial trend analysis."
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates visualizations from claims data"

  tool_resources:
    Claims_Analyst:
      semantic_view: "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.SV_CLAIMS"
  $$;


-- ---------------------------------------------------------------------------
-- 5. OBSERVATIONS_AGENT
-- ---------------------------------------------------------------------------
CREATE OR REPLACE AGENT SEMANTIC.OBSERVATIONS_AGENT
  COMMENT = 'Product agent for lab results and vital signs analytics'
  PROFILE = '{"display_name": "Observations Agent", "color": "teal"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: >
      You are the Observations Agent for a healthcare data platform.
      You answer questions about lab results, vital signs, clinical
      measurements, and observation trends.
      Include units of measure when presenting numeric values.
    orchestration: >
      Always use the Observations_Analyst tool for any question about
      lab results, vitals, clinical measurements, BMI, blood pressure,
      glucose, or any clinical observation.
    sample_questions:
      - question: "What are the most common lab tests recorded?"
      - question: "What is the average BMI across patients?"
      - question: "Show vital sign trends for a patient"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Observations_Analyst"
        description: "Generates SQL for clinical observation analytics: lab test frequencies, vital sign averages, result distributions, and observation trends."
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates visualizations from observation data"

  tool_resources:
    Observations_Analyst:
      semantic_view: "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.SV_OBSERVATIONS"
  $$;


-- ---------------------------------------------------------------------------
-- 6. PROCEDURES_AGENT
-- ---------------------------------------------------------------------------
CREATE OR REPLACE AGENT SEMANTIC.PROCEDURES_AGENT
  COMMENT = 'Product agent for clinical procedure analytics'
  PROFILE = '{"display_name": "Procedures Agent", "color": "red"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: >
      You are the Procedures Agent for a healthcare data platform.
      You answer questions about clinical procedures, surgeries,
      interventions, procedure volumes, and trends.
      Include the procedure code alongside the name when available.
    orchestration: >
      Always use the Procedures_Analyst tool for any question about
      procedures, surgeries, operations, interventions, or treatments.
    sample_questions:
      - question: "What are the most commonly performed procedures?"
      - question: "How many procedures per patient on average?"
      - question: "Show procedure volume over time"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Procedures_Analyst"
        description: "Generates SQL for procedure analytics: procedure volumes, type distributions, patient procedure counts, and surgical trends."
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates visualizations from procedure data"

  tool_resources:
    Procedures_Analyst:
      semantic_view: "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.SV_PROCEDURES"
  $$;
