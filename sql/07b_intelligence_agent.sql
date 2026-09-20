-- ============================================================================
-- 07b_intelligence_agent.sql
-- Intelligence Orchestrator Agent: the single top-level agent that owns
-- ALL six domain semantic views as Cortex Analyst tools.
--
-- This is the agent exposed via MCP to external consumers.
-- It decides which domain(s) to query based on the user's question,
-- and can synthesize cross-domain answers by calling multiple tools.
--
-- Architecture:
--   User Question
--     -> Intelligence Agent (this agent)
--       -> Visits_Analyst      (SV_VISITS)
--       -> Diagnoses_Analyst   (SV_DIAGNOSES)
--       -> Medications_Analyst (SV_MEDICATIONS)
--       -> Claims_Analyst      (SV_CLAIMS)
--       -> Observations_Analyst(SV_OBSERVATIONS)
--       -> Procedures_Analyst  (SV_PROCEDURES)
--       -> data_to_chart       (visualization)
--     -> Natural language response
--
-- Prerequisites:
--   - 06b_semantic_views.sql has been run
--   - The executing role has CREATE AGENT on SEMANTIC schema
--   - SNOWFLAKE.CORTEX_AGENT_USER database role is granted
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;
USE SCHEMA SEMANTIC;

CREATE OR REPLACE AGENT SEMANTIC.HEALTHCARE_INTELLIGENCE_AGENT
  COMMENT = 'Intelligence orchestrator: routes healthcare questions to the right domain agent and synthesizes cross-domain answers'
  PROFILE = '{"display_name": "Healthcare Intelligence", "color": "indigo"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  orchestration:
    budget:
      seconds: 60
      tokens: 32000

  instructions:
    response: >
      You are the Healthcare Intelligence Agent -- the top-level AI assistant
      for the ECDH (Enterprise Clinical Data Hub) data platform.

      You have access to six domain-specific data tools covering:
        1. Visits/Encounters (admissions, length of stay, facilities)
        2. Diagnoses/Conditions (ICD codes, disease prevalence)
        3. Medications/Prescriptions (drug utilization, polypharmacy)
        4. Claims/Financials (billing, costs, reimbursement)
        5. Observations (lab results, vital signs)
        6. Procedures (surgeries, interventions)

      Response guidelines:
        - Be concise but thorough. Use tables for multi-row results.
        - Format currency with $ and two decimal places.
        - Format dates as YYYY-MM-DD.
        - Include relevant counts and percentages where useful.
        - When a question spans multiple domains, call multiple tools
          and synthesize the results into a unified answer.
        - If the question is ambiguous, ask for clarification.
        - Never fabricate data -- only report what the tools return.

    orchestration: >
      ROUTING RULES -- choose the right tool(s) for each question:

      - Visits_Analyst: visits, encounters, admissions, discharges, length of
        stay, readmissions, facility/organization, location, practitioner,
        encounter class (AMB/EMER/IMP/WELLNESS).

      - Diagnoses_Analyst: diagnoses, conditions, ICD codes, SNOMED codes,
        disease prevalence, clinical status (active/resolved), comorbidities.

      - Medications_Analyst: medications, prescriptions, drugs, dosages,
        polypharmacy, drug utilization, pharmacy.

      - Claims_Analyst: claims, billing, costs, charges, financial totals,
        reimbursement, payer, cost per patient, spend.

      - Observations_Analyst: lab results, vital signs, BMI, blood pressure,
        glucose, hemoglobin, clinical measurements, LOINC codes.

      - Procedures_Analyst: procedures, surgeries, operations, interventions,
        CPT codes, procedure volumes.

      CROSS-DOMAIN QUESTIONS:
      When a question spans two or more domains, call ALL relevant tools.
      The common join key across domains is ENCOUNTER_ID or PATIENT_ID.
      For example:
        "What are the top diagnoses for ED visits?" -> Visits + Diagnoses
        "Total cost of inpatient stays by diagnosis" -> Claims + Visits + Diagnoses
        "Medications prescribed for diabetic patients" -> Medications + Diagnoses
      Synthesize the results into one coherent answer.

      CHART GUIDANCE:
      Use data_to_chart when the result has 3+ rows and a natural visual
      representation (bar chart for rankings, line chart for trends,
      pie chart for distributions).

    sample_questions:
      - question: "How many visits by encounter class?"
      - question: "What are the top 10 diagnoses?"
      - question: "Which patients have the highest total claims?"
      - question: "Compare readmission rates by facility"
      - question: "What medications are prescribed for patients with hypertension?"
      - question: "Show me the most common lab tests and their average values"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Visits_Analyst"
        description: "Answers questions about patient visits/encounters: visit counts, length of stay, encounter class (AMB/EMER/IMP/WELLNESS), facilities, locations, practitioners, admission/discharge dates, and visit trends. Use for any question about visits, admissions, or facilities."

    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Diagnoses_Analyst"
        description: "Answers questions about patient diagnoses/conditions: ICD codes, disease prevalence, clinical status (active/resolved), comorbidities, diagnosis trends. Use for any question about diagnoses, conditions, or diseases."

    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Medications_Analyst"
        description: "Answers questions about medications/prescriptions: drug frequencies, polypharmacy, prescription status, dosages, medication reasons. Use for any question about medications, drugs, or prescriptions."

    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Claims_Analyst"
        description: "Answers questions about insurance claims and finances: total billed amounts, claim types, cost per patient, financial trends. Use for any question about claims, billing, costs, or spending."

    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Observations_Analyst"
        description: "Answers questions about lab results and vital signs: test frequencies, average values, vital sign trends, clinical measurements. Use for any question about labs, vitals, BMI, blood pressure, or glucose."

    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Procedures_Analyst"
        description: "Answers questions about clinical procedures: procedure volumes, surgery types, intervention frequencies. Use for any question about procedures, surgeries, or operations."

    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates charts and visualizations from query results."

  tool_resources:
    Visits_Analyst:
      semantic_view: "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.SV_VISITS"
    Diagnoses_Analyst:
      semantic_view: "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.SV_DIAGNOSES"
    Medications_Analyst:
      semantic_view: "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.SV_MEDICATIONS"
    Claims_Analyst:
      semantic_view: "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.SV_CLAIMS"
    Observations_Analyst:
      semantic_view: "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.SV_OBSERVATIONS"
    Procedures_Analyst:
      semantic_view: "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.SV_PROCEDURES"
  $$;
