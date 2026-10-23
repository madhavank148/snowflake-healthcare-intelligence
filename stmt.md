The Problem
 
Healthcare organizations generate massive volumes of clinical and operational data across labs, encounters, diagnoses, medications, claims, procedures, admissions, and discharges. Although this data is available in Snowflake, business users often need SQL expertise and knowledge of complex schemas, relationships, and clinical terminology to access it.
As more teams adopt AI, each domain risks building its own agent from scratch. This leads to duplicated engineering effort, inconsistent answers, fragmented security reviews, and no common standard for row-level security, data quality, ownership, or agent accountability.
 
Our Solution
 
Intelligent Data Products (IDP) transforms governed healthcare data into reusable, domain-specific, AI-powered products that users can discover and interact with using natural language. Each data product includes its schema, semantic definitions, RLS role, data-quality rules, and accountable owner.
Instead of every team independently building an agent, a domain registers its data product once and the IDP framework provisions a governed agent grounded in the real FHIR data model. The platform routes questions to the appropriate domain agents, supports cross-product analysis, and makes the same intelligence available through Snowflake Intelligence, Streamlit, SQL, or Sage through MCP. We will validate the framework with Risk & Quality and then onboard a second domain to prove it is scalable and reusable.
 
High-Level Architecture
Ingest FHIR Data
Raw FHIR bundles are loaded into Snowflake and preserved for traceability.
Organize and Validate
FHIR resources are split into foundation tables, while reconciliation checks confirm that data was loaded completely.
Create Data Products
Access views organize the data into domains such as encounters, diagnoses, medications, labs, and claims.
Add Business Semantics
Semantic views define business terms, metrics, relationships, and synonyms so AI agents understand the data correctly.
Provision Domain Agents
Each data product is connected to a specialized Cortex Agent that answers natural-language questions.
Orchestrate Responses
A central agent routes questions to the appropriate domain agents and combines results for cross-domain analysis.
Connect to Users and Applications
Users access the intelligence through Snowflake Intelligence, Streamlit, SQL, or Sage using MCP.
Apply Governance
Row-level security, data quality rules, ownership, audit logging, and observability apply across the platform.
 
Key Differentiators
Governed by design: Security, RLS, data quality, ownership, and auditability are built into every registered data product.
Reusable enterprise framework: Teams register a data product once and receive a standardized AI agent instead of building separate solutions.
Trusted and extensible: FHIR-grounded semantic models, reconciliation checks, cross-domain orchestration, and MCP integration with Sage enable reliable answers across multiple channels.
Business Use Cases
Risk and Quality: Identify care gaps, quality trends, and high-risk populations.
Clinical Operations: Analyze admissions, ED visits, readmissions, length of stay, and facility performance.
Data Operations: Monitor pipeline health, reconciliation issues, missing records, and data freshness.
