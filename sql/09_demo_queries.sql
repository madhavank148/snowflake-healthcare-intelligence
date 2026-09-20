-- ============================================================================
-- 09_demo_queries.sql
-- Verification & Demo Queries
--
-- This file contains queries to:
--   A. Verify each flattened view has data
--   B. Query semantic views directly with SEMANTIC_VIEW()
--   C. Call individual product agents via DATA_AGENT_RUN
--   D. Call the Intelligence Agent (single-domain + cross-domain)
--   E. Verify MCP server setup
--
-- Run these AFTER executing scripts 01 through 08 in order.
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;


-- ============================================================================
-- SECTION A: Verify Flattened ACCESS Views
-- ============================================================================

-- A1. VW_VISITS -- should show encounters with patient + org + location details
SELECT 'VW_VISITS' AS VIEW_NAME, COUNT(*) AS ROW_COUNT FROM ACCESS.VW_VISITS;
SELECT * FROM ACCESS.VW_VISITS LIMIT 5;

-- A2. VW_DIAGNOSES
SELECT 'VW_DIAGNOSES' AS VIEW_NAME, COUNT(*) AS ROW_COUNT FROM ACCESS.VW_DIAGNOSES;
SELECT * FROM ACCESS.VW_DIAGNOSES LIMIT 5;

-- A3. VW_MEDICATIONS
SELECT 'VW_MEDICATIONS' AS VIEW_NAME, COUNT(*) AS ROW_COUNT FROM ACCESS.VW_MEDICATIONS;
SELECT * FROM ACCESS.VW_MEDICATIONS LIMIT 5;

-- A4. VW_CLAIMS
SELECT 'VW_CLAIMS' AS VIEW_NAME, COUNT(*) AS ROW_COUNT FROM ACCESS.VW_CLAIMS;
SELECT * FROM ACCESS.VW_CLAIMS LIMIT 5;

-- A5. VW_OBSERVATIONS
SELECT 'VW_OBSERVATIONS' AS VIEW_NAME, COUNT(*) AS ROW_COUNT FROM ACCESS.VW_OBSERVATIONS;
SELECT * FROM ACCESS.VW_OBSERVATIONS LIMIT 5;

-- A6. VW_PROCEDURES
SELECT 'VW_PROCEDURES' AS VIEW_NAME, COUNT(*) AS ROW_COUNT FROM ACCESS.VW_PROCEDURES;
SELECT * FROM ACCESS.VW_PROCEDURES LIMIT 5;

-- A7. VW_RECONCILIATION
SELECT 'VW_RECONCILIATION' AS VIEW_NAME, COUNT(*) AS ROW_COUNT FROM ACCESS.VW_RECONCILIATION;
SELECT * FROM ACCESS.VW_RECONCILIATION LIMIT 5;

-- A-SUMMARY: All views at a glance
SELECT 'VW_VISITS'          AS VIEW_NAME, COUNT(*) AS ROWS FROM ACCESS.VW_VISITS
UNION ALL
SELECT 'VW_DIAGNOSES',       COUNT(*) FROM ACCESS.VW_DIAGNOSES
UNION ALL
SELECT 'VW_MEDICATIONS',     COUNT(*) FROM ACCESS.VW_MEDICATIONS
UNION ALL
SELECT 'VW_CLAIMS',          COUNT(*) FROM ACCESS.VW_CLAIMS
UNION ALL
SELECT 'VW_OBSERVATIONS',    COUNT(*) FROM ACCESS.VW_OBSERVATIONS
UNION ALL
SELECT 'VW_PROCEDURES',      COUNT(*) FROM ACCESS.VW_PROCEDURES
UNION ALL
SELECT 'VW_RECONCILIATION',  COUNT(*) FROM ACCESS.VW_RECONCILIATION
ORDER BY VIEW_NAME;


-- ============================================================================
-- SECTION B: Query Semantic Views Directly (SEMANTIC_VIEW syntax)
--            This verifies the semantic views work before agents call them.
-- ============================================================================

-- B1. SV_VISITS: visits by encounter class
SELECT * FROM SEMANTIC_VIEW(
    SEMANTIC.SV_VISITS
    DIMENSIONS visits.encounter_class
    METRICS visits.visit_count, visits.avg_length_of_stay
)
ORDER BY visit_count DESC;

-- B2. SV_VISITS: visits by facility
SELECT * FROM SEMANTIC_VIEW(
    SEMANTIC.SV_VISITS
    DIMENSIONS visits.organization_name
    METRICS visits.visit_count, visits.distinct_patient_count
)
ORDER BY visit_count DESC
LIMIT 10;

-- B3. SV_DIAGNOSES: top 10 most common diagnoses
SELECT * FROM SEMANTIC_VIEW(
    SEMANTIC.SV_DIAGNOSES
    DIMENSIONS diagnoses.diagnosis_display, diagnoses.icd_code
    METRICS diagnoses.diagnosis_count
)
ORDER BY diagnosis_count DESC
LIMIT 10;

-- B4. SV_MEDICATIONS: most prescribed medications
SELECT * FROM SEMANTIC_VIEW(
    SEMANTIC.SV_MEDICATIONS
    DIMENSIONS medications.medication_name
    METRICS medications.prescription_count, medications.distinct_patient_count
)
ORDER BY prescription_count DESC
LIMIT 10;

-- B5. SV_CLAIMS: total billed by claim type
SELECT * FROM SEMANTIC_VIEW(
    SEMANTIC.SV_CLAIMS
    DIMENSIONS claims.claim_type
    METRICS claims.claim_count, claims.total_billed, claims.avg_claim_amount
)
ORDER BY total_billed DESC;

-- B6. SV_OBSERVATIONS: most common lab tests / vitals
SELECT * FROM SEMANTIC_VIEW(
    SEMANTIC.SV_OBSERVATIONS
    DIMENSIONS observations.observation_display, observations.observation_category
    METRICS observations.observation_count, observations.avg_value
)
ORDER BY observation_count DESC
LIMIT 15;

-- B7. SV_PROCEDURES: most common procedures
SELECT * FROM SEMANTIC_VIEW(
    SEMANTIC.SV_PROCEDURES
    DIMENSIONS procedures.procedure_display
    METRICS procedures.procedure_count
)
ORDER BY procedure_count DESC
LIMIT 10;

-- B8. SV_RECONCILIATION: pipeline health check
SELECT * FROM SEMANTIC_VIEW(
    SEMANTIC.SV_RECONCILIATION
    DIMENSIONS recon.resource_type, recon.load_status
    METRICS recon.total_raw_entries, recon.total_loaded, recon.total_mismatch
)
ORDER BY total_mismatch DESC;


-- ============================================================================
-- SECTION C: Call Individual Product Agents via SQL
--            Uses SNOWFLAKE.CORTEX.DATA_AGENT_RUN to invoke each agent.
-- ============================================================================

-- C1. Visits Agent: "How many visits by encounter class?"
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.VISITS_AGENT',
    $${
      "messages": [
        {
          "role": "user",
          "content": [
            { "type": "text", "text": "How many visits are there by encounter class?" }
          ]
        }
      ]
    }$$,
    TRUE
  )
) AS RESPONSE;

-- C2. Diagnoses Agent: "What are the top 5 diagnoses?"
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.DIAGNOSES_AGENT',
    $${
      "messages": [
        {
          "role": "user",
          "content": [
            { "type": "text", "text": "What are the top 5 most common diagnoses?" }
          ]
        }
      ]
    }$$,
    TRUE
  )
) AS RESPONSE;

-- C3. Medications Agent: "Most prescribed medications"
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.MEDICATIONS_AGENT',
    $${
      "messages": [
        {
          "role": "user",
          "content": [
            { "type": "text", "text": "What are the most commonly prescribed medications?" }
          ]
        }
      ]
    }$$,
    TRUE
  )
) AS RESPONSE;

-- C4. Claims Agent: "Total billed by claim type"
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.CLAIMS_AGENT',
    $${
      "messages": [
        {
          "role": "user",
          "content": [
            { "type": "text", "text": "What is the total billed amount by claim type?" }
          ]
        }
      ]
    }$$,
    TRUE
  )
) AS RESPONSE;

-- C5. Observations Agent: "Most common lab tests"
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.OBSERVATIONS_AGENT',
    $${
      "messages": [
        {
          "role": "user",
          "content": [
            { "type": "text", "text": "What are the most common lab tests recorded?" }
          ]
        }
      ]
    }$$,
    TRUE
  )
) AS RESPONSE;

-- C6. Procedures Agent: "Most common procedures"
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.PROCEDURES_AGENT',
    $${
      "messages": [
        {
          "role": "user",
          "content": [
            { "type": "text", "text": "What are the most commonly performed procedures?" }
          ]
        }
      ]
    }$$,
    TRUE
  )
) AS RESPONSE;

-- C7. Reconciliation Agent: "Pipeline health"
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.RECONCILIATION_AGENT',
    $${
      "messages": [
        {
          "role": "user",
          "content": [
            { "type": "text", "text": "Is the data pipeline healthy? Show me any mismatches." }
          ]
        }
      ]
    }$$,
    TRUE
  )
) AS RESPONSE;


-- ============================================================================
-- SECTION D: Call the Intelligence Orchestrator Agent
--            Single-domain and cross-domain questions.
-- ============================================================================

-- D1. SINGLE DOMAIN -- routed to Visits_Analyst
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.HEALTHCARE_INTELLIGENCE_AGENT',
    $${
      "messages": [
        {
          "role": "user",
          "content": [
            { "type": "text", "text": "How many emergency department visits are there by facility?" }
          ]
        }
      ]
    }$$,
    TRUE
  )
) AS RESPONSE;

-- D2. SINGLE DOMAIN -- routed to Claims_Analyst
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.HEALTHCARE_INTELLIGENCE_AGENT',
    $${
      "messages": [
        {
          "role": "user",
          "content": [
            { "type": "text", "text": "Which patients have the highest total claims? Show top 10." }
          ]
        }
      ]
    }$$,
    TRUE
  )
) AS RESPONSE;

-- D3. CROSS-DOMAIN -- Visits + Diagnoses
--     The agent should call both Visits_Analyst and Diagnoses_Analyst
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.HEALTHCARE_INTELLIGENCE_AGENT',
    $${
      "messages": [
        {
          "role": "user",
          "content": [
            { "type": "text", "text": "What are the top 10 diagnoses for emergency department encounters?" }
          ]
        }
      ]
    }$$,
    TRUE
  )
) AS RESPONSE;

-- D4. CROSS-DOMAIN -- Medications + Diagnoses
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.HEALTHCARE_INTELLIGENCE_AGENT',
    $${
      "messages": [
        {
          "role": "user",
          "content": [
            { "type": "text", "text": "What medications are commonly prescribed for patients with hypertension?" }
          ]
        }
      ]
    }$$,
    TRUE
  )
) AS RESPONSE;

-- D5. CROSS-DOMAIN -- Claims + Visits + Diagnoses (triple-tool)
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.HEALTHCARE_INTELLIGENCE_AGENT',
    $${
      "messages": [
        {
          "role": "user",
          "content": [
            { "type": "text", "text": "Compare total claim costs for inpatient vs emergency visits. Also show the top 3 diagnoses for each." }
          ]
        }
      ]
    }$$,
    TRUE
  )
) AS RESPONSE;

-- D6. ANALYTICS OVERVIEW -- broad question to test routing
SELECT TRY_PARSE_JSON(
  SNOWFLAKE.CORTEX.DATA_AGENT_RUN(
    'HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.HEALTHCARE_INTELLIGENCE_AGENT',
    $${
      "messages": [
        {
          "role": "user",
          "content": [
            { "type": "text", "text": "Give me a summary dashboard: total visits, total claims cost, top 5 diagnoses, and most common procedures." }
          ]
        }
      ]
    }$$,
    TRUE
  )
) AS RESPONSE;


-- ============================================================================
-- SECTION E: Verify MCP Server & Agent Setup
-- ============================================================================

-- E1. List all agents
SHOW AGENTS IN SCHEMA SEMANTIC;

-- E2. Describe the Intelligence Agent
DESCRIBE AGENT SEMANTIC.HEALTHCARE_INTELLIGENCE_AGENT;

-- E3. List all semantic views
SHOW SEMANTIC VIEWS IN SCHEMA SEMANTIC;

-- E4. Describe the MCP server (shows tools and endpoint)
DESCRIBE MCP SERVER SEMANTIC.HEALTHCARE_MCP_SERVER;

-- E5. List MCP servers
SHOW MCP SERVERS IN SCHEMA SEMANTIC;


-- ============================================================================
-- SECTION F: Quick Data Quality Checks
-- ============================================================================

-- F1. Encounter class distribution (sanity check)
SELECT ENCOUNTER_CLASS, COUNT(*) AS CNT
FROM ACCESS.VW_VISITS
GROUP BY ENCOUNTER_CLASS
ORDER BY CNT DESC;

-- F2. Null check on key join columns
SELECT
    'VW_VISITS'     AS VIEW_NAME,
    COUNT(*)        AS TOTAL,
    COUNT(ORGANIZATION_NAME) AS HAS_ORG,
    COUNT(LOCATION_NAME)     AS HAS_LOC,
    COUNT(PRACTITIONER_NAME) AS HAS_PRAC
FROM ACCESS.VW_VISITS;

-- F3. Claim amount distribution
SELECT
    MIN(TOTAL_CLAIM_AMOUNT)  AS MIN_AMT,
    AVG(TOTAL_CLAIM_AMOUNT)  AS AVG_AMT,
    MAX(TOTAL_CLAIM_AMOUNT)  AS MAX_AMT,
    COUNT(*)                 AS TOTAL_CLAIMS
FROM ACCESS.VW_CLAIMS;
