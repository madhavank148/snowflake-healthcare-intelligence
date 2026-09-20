-- ============================================================================
-- 03_reconciliation_agent.sql
-- Reconciliation Agent: monitors pipeline health by querying the
-- RECONCILIATION.LOAD_SUMMARY data through VW_RECONCILIATION /
-- SV_RECONCILIATION (sql/semanticViews/02_reconciliation_semantic_view.sql).
--
-- This agent is separate from the Intelligence Agent because it serves
-- a different audience (data engineers / pipeline operators) and a
-- different purpose (pipeline health, not clinical analytics).
--
-- Split out of the original 07c_reconciliation_agent.sql, which combined
-- this agent and the semantic view it uses in one file.
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;
USE SCHEMA SEMANTIC;

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
