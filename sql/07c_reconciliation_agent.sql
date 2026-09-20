-- ============================================================================
-- 07c_reconciliation_agent.sql
-- Reconciliation Agent: monitors pipeline health by querying the
-- RECONCILIATION.LOAD_SUMMARY data through VW_RECONCILIATION.
--
-- This agent is separate from the Intelligence Agent because it serves
-- a different audience (data engineers / pipeline operators) and a
-- different purpose (pipeline health, not clinical analytics).
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;
USE SCHEMA SEMANTIC;

-- ---------------------------------------------------------------------------
-- Semantic View for Reconciliation
-- ---------------------------------------------------------------------------
CREATE OR REPLACE SEMANTIC VIEW SEMANTIC.SV_RECONCILIATION

  TABLES (
    recon AS HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_RECONCILIATION
      PRIMARY KEY (TRACKING_ID, RESOURCE_TYPE)
      COMMENT = 'One row per resource type per loaded FHIR bundle, tracking RAW vs FOUNDATION counts'
  )

  DIMENSIONS (
    recon.tracking_id        AS TRACKING_ID
      COMMENT = 'Unique load tracking ID (one per bundle file)',
    recon.source_file_name   AS SOURCE_FILE_NAME
      WITH SYNONYMS = ('file', 'bundle file', 'source file')
      COMMENT = 'Name of the source FHIR bundle JSON file',
    recon.resource_type      AS RESOURCE_TYPE
      WITH SYNONYMS = ('FHIR resource', 'resource', 'table')
      COMMENT = 'FHIR resource type (Patient, Encounter, Condition, etc.)',
    recon.status             AS LOAD_STATUS
      WITH SYNONYMS = ('status', 'reconciliation status')
      COMMENT = 'Reconciliation status: MATCHED or MISMATCH',
    recon.load_ts            AS LOAD_TIMESTAMP
      WITH SYNONYMS = ('load date', 'load time')
      COMMENT = 'Timestamp when the load was recorded'
  )

  METRICS (
    recon.total_raw_entries         AS SUM(RAW_ENTRY_COUNT)
      WITH SYNONYMS = ('raw count', 'entries in bundle')
      COMMENT = 'Total entries found in RAW bundles',
    recon.total_loaded              AS SUM(FOUNDATION_LOADED_COUNT)
      WITH SYNONYMS = ('loaded count', 'foundation rows')
      COMMENT = 'Total rows loaded into FOUNDATION tables',
    recon.total_mismatch            AS SUM(MISMATCH_COUNT)
      WITH SYNONYMS = ('mismatches', 'missing rows', 'gaps')
      COMMENT = 'Total mismatch (RAW - FOUNDATION) across all loads',
    recon.load_count                AS COUNT(TRACKING_ID)
      WITH SYNONYMS = ('number of loads', 'file count')
      COMMENT = 'Number of load tracking entries',
    recon.mismatch_load_count       AS COUNT_IF(MISMATCH_COUNT <> 0)
      WITH SYNONYMS = ('failed loads', 'loads with issues')
      COMMENT = 'Number of loads where RAW count did not match FOUNDATION count'
  )

  AI_SQL_GENERATION 'When asked about pipeline health, check for MISMATCH status or non-zero MISMATCH_COUNT. Resource types map to FOUNDATION table names (Patient, Encounter, Condition, etc.).'

  AI_VERIFIED_QUERIES (
    pipeline_health AS (
      QUESTION 'Is the pipeline healthy? Any mismatches?'
      SQL 'SELECT RESOURCE_TYPE, SUM(RAW_ENTRY_COUNT) AS RAW_TOTAL, SUM(FOUNDATION_LOADED_COUNT) AS LOADED_TOTAL, SUM(MISMATCH_COUNT) AS MISMATCH_TOTAL FROM HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_RECONCILIATION GROUP BY RESOURCE_TYPE ORDER BY MISMATCH_TOTAL DESC'
    ),
    recent_loads AS (
      QUESTION 'Show me recent load activity'
      SQL 'SELECT SOURCE_FILE_NAME, RESOURCE_TYPE, RAW_ENTRY_COUNT, FOUNDATION_LOADED_COUNT, MISMATCH_COUNT, STATUS, LOAD_TS FROM HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_RECONCILIATION ORDER BY LOAD_TS DESC LIMIT 20'
    )
  )

  COMMENT = 'Pipeline reconciliation analytics: RAW vs FOUNDATION load counts, mismatch detection, load health monitoring';


-- ---------------------------------------------------------------------------
-- Reconciliation Agent
-- ---------------------------------------------------------------------------
CREATE OR REPLACE AGENT SEMANTIC.RECONCILIATION_AGENT
  COMMENT = 'Pipeline health agent: monitors FHIR data loading reconciliation'
  PROFILE = '{"display_name": "Pipeline Health Agent", "color": "gray"}'
  FROM SPECIFICATION
  $$
  models:
    orchestration: auto

  instructions:
    response: >
      You are the Pipeline Health Agent for the ECDH data platform.
      You answer questions about data loading reconciliation: whether
      all FHIR bundle entries made it from RAW to FOUNDATION tables,
      which resource types have mismatches, and overall pipeline health.
      Flag any resource types where RAW count does not equal FOUNDATION count.
    orchestration: >
      Always use the Reconciliation_Analyst tool for any question about
      data loading, pipeline health, reconciliation, mismatches, or
      missing rows.
    sample_questions:
      - question: "Is the pipeline healthy? Any mismatches?"
      - question: "Show me recent load activity"
      - question: "Which resource types have loading issues?"

  tools:
    - tool_spec:
        type: "cortex_analyst_text_to_sql"
        name: "Reconciliation_Analyst"
        description: "Generates SQL for pipeline reconciliation: RAW vs FOUNDATION load counts, mismatch detection, resource type health, and load history."
    - tool_spec:
        type: "data_to_chart"
        name: "data_to_chart"
        description: "Generates visualizations from reconciliation data"

  tool_resources:
    Reconciliation_Analyst:
      semantic_view: "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.SV_RECONCILIATION"
  $$;
