-- ============================================================================
-- 08_mcp_server.sql
-- MCP Server: exposes the Healthcare Intelligence Agent to external
-- consumers (Claude Desktop, custom apps, Slack bots, etc.) via the
-- Model Context Protocol standard.
--
-- Architecture:
--   External MCP Client (Claude, custom UI, etc.)
--     -> MCP Server (this object)
--       -> Healthcare Intelligence Agent (orchestrator)
--         -> 6 domain Semantic Views via Cortex Analyst
--       -> Response back to client
--
-- The MCP server is a "dumb pipe" -- all routing and decision-making
-- happens inside the Intelligence Agent.
--
-- Prerequisites:
--   - 07b_intelligence_agent.sql has been run
--   - The executing role has CREATE MCP SERVER privileges
--
-- IMPORTANT: MCP server hostnames should use hyphens, not underscores.
-- ============================================================================

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;
USE SCHEMA SEMANTIC;

-- ---------------------------------------------------------------------------
-- Main MCP Server: exposes the Intelligence Agent
-- ---------------------------------------------------------------------------
CREATE OR REPLACE MCP SERVER SEMANTIC.HEALTHCARE_MCP_SERVER
  FROM SPECIFICATION $$
  tools:
    - title: "Healthcare Intelligence Agent"
      name: "healthcare_intelligence"
      type: "CORTEX_AGENT_RUN"
      identifier: "HEALTHCARE_INTELLIGENCE_DB.SEMANTIC.HEALTHCARE_INTELLIGENCE_AGENT"
      description: >
        Enterprise healthcare data agent. Answers natural language questions
        about patient visits, diagnoses, medications, claims, lab results,
        and procedures. Supports cross-domain queries (e.g. 'top diagnoses
        for ED visits'). Use this tool for any healthcare analytics question.
  $$;

-- ---------------------------------------------------------------------------
-- Optional: Grant access to the MCP server
-- Uncomment and replace <ROLE_NAME> with the role(s) that should access it.
-- ---------------------------------------------------------------------------
-- GRANT USAGE ON MCP SERVER SEMANTIC.HEALTHCARE_MCP_SERVER TO ROLE <ROLE_NAME>;


-- ---------------------------------------------------------------------------
-- Verify the MCP server was created
-- ---------------------------------------------------------------------------
DESCRIBE MCP SERVER SEMANTIC.HEALTHCARE_MCP_SERVER;

-- ---------------------------------------------------------------------------
-- Show the MCP endpoint URL (use this to connect external clients)
-- ---------------------------------------------------------------------------
SHOW MCP SERVERS IN SCHEMA SEMANTIC;
