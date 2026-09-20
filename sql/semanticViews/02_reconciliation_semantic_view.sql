-- ============================================================================
-- 02_reconciliation_semantic_view.sql
-- Semantic View for Reconciliation: models VW_RECONCILIATION for Cortex
-- Analyst, so the Reconciliation Agent (sql/agents/03_reconciliation_agent.sql)
-- can answer pipeline-health questions in natural language.
--
-- Split out of the original 07c_reconciliation_agent.sql, which combined
-- this semantic view and the agent that uses it in one file.
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;
USE SCHEMA SEMANTIC;

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
    recon.load_status        AS STATUS
      WITH SYNONYMS = ('status', 'reconciliation status')
      COMMENT = 'Reconciliation status: MATCHED or MISMATCH',
    recon.load_timestamp     AS LOAD_TS
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

  COMMENT = 'Pipeline reconciliation analytics: RAW vs FOUNDATION load counts, mismatch detection, load health monitoring';

-- NOTE: AI_SQL_GENERATION / AI_VERIFIED_QUERIES are not valid CREATE SEMANTIC VIEW
-- clauses -- commented out below (kept for reference / reapplying once the correct
-- mechanism -- e.g. Snowsight's verified query repository -- is confirmed).
--   AI_SQL_GENERATION 'When asked about pipeline health, check for MISMATCH status or non-zero MISMATCH_COUNT. Resource types map to FOUNDATION table names (Patient, Encounter, Condition, etc.).'
--
--   AI_VERIFIED_QUERIES (
--     pipeline_health AS (
--       QUESTION 'Is the pipeline healthy? Any mismatches?'
--       SQL 'SELECT RESOURCE_TYPE, SUM(RAW_ENTRY_COUNT) AS RAW_TOTAL, SUM(FOUNDATION_LOADED_COUNT) AS LOADED_TOTAL, SUM(MISMATCH_COUNT) AS MISMATCH_TOTAL FROM HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_RECONCILIATION GROUP BY RESOURCE_TYPE ORDER BY MISMATCH_TOTAL DESC'
--     ),
--     recent_loads AS (
--       QUESTION 'Show me recent load activity'
--       SQL 'SELECT SOURCE_FILE_NAME, RESOURCE_TYPE, RAW_ENTRY_COUNT, FOUNDATION_LOADED_COUNT, MISMATCH_COUNT, STATUS, LOAD_TS FROM HEALTHCARE_INTELLIGENCE_DB.ACCESS.VW_RECONCILIATION ORDER BY LOAD_TS DESC LIMIT 20'
--     )
--   );
