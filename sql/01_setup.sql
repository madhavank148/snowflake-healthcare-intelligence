-- ============================================================================
-- 01_setup.sql
-- Database + schema setup for the Healthcare Intelligence data platform.
-- Layers: RAW -> FOUNDATION -> ACCESS / RECONCILIATION / SEMANTIC
-- ============================================================================

CREATE DATABASE IF NOT EXISTS HEALTHCARE_INTELLIGENCE_DB;

USE DATABASE HEALTHCARE_INTELLIGENCE_DB;

-- Landing zone: untouched FHIR Bundles, exactly as received.
CREATE SCHEMA IF NOT EXISTS RAW;

-- First split/typed layer: one table per FHIR resource type, semi-flat.
CREATE SCHEMA IF NOT EXISTS FOUNDATION;

-- Consumption layer: RLS-governed, denormalized views per data product (future).
CREATE SCHEMA IF NOT EXISTS ACCESS;

-- Pipeline health: bundle vs. resource load-count tracking.
CREATE SCHEMA IF NOT EXISTS RECONCILIATION;

-- Cortex Analyst semantic views, Cortex Agents, and MCP servers.
CREATE SCHEMA IF NOT EXISTS SEMANTIC;

--     Required so agents can access models in other regions.
ALTER ACCOUNT SET CORTEX_ENABLED_CROSS_REGION = 'ANY_REGION';
