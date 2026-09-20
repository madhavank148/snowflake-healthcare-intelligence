# snowflake-healthcare-intelligence

MVP repo for a Snowflake-native healthcare data + AI intelligence platform: it takes raw FHIR R4 patient data, loads it into Snowflake, models it into a layered warehouse, and exposes it to natural-language question-answering through Cortex Analyst semantic views, Cortex Agents, and an MCP server.

## What this repo actually does, end to end

1. **Ingest** — Synthea-generated FHIR R4 Bundles (JSON) are loaded untouched into a `RAW` landing table.
2. **Split & type** — each bundle's `entry[]` array is flattened by `resourceType` into one `FOUNDATION` table per FHIR resource (24 tables), semi-flat (VARIANT columns holding each root-level FHIR field as-is).
3. **Reconcile** — a `RECONCILIATION` table compares RAW entry counts against FOUNDATION load counts per bundle/resource, to catch dropped or incomplete loads.
4. **Expose** — an `ACCESS` layer of views sits on top of `FOUNDATION`: some are plain 1:1 views, some join resources together (patient+encounter, patient+condition, etc.), and a further set of **flattened** views (`VW_*`) extract scalar/typed columns out of the VARIANT data specifically so they can be modeled semantically.
5. **Model** — `SEMANTIC` views (`SV_*`) define dimensions, metrics, and synonyms over the flattened `VW_*` views, in the vocabulary Cortex Analyst needs for text-to-SQL.
6. **Serve** — Cortex **Agents** wrap each semantic view (one agent per clinical domain, plus a top-level orchestrator and a separate pipeline-health agent), and an **MCP Server** exposes the orchestrator agent to external tools (Claude Desktop, custom apps, etc.) over the Model Context Protocol.

Everything lives under one database, `HEALTHCARE_INTELLIGENCE_DB`, in 5 schemas: `RAW`, `FOUNDATION`, `ACCESS`, `RECONCILIATION`, `SEMANTIC`.

## Repo structure

`sql/` is organized by object type, with each top-level folder numbered in the order you actually run it — so the folder listing itself is the run order, no need to cross-reference a separate section to know what comes first:

```
sql/
  1-setup/          -- database + schema creation
  2-tables/         -- RAW / FOUNDATION / RECONCILIATION table DDL (+ RAW's stage/file format)
  3-views/          -- ACCESS layer views (raw VARIANT + flattened typed)
  4-semanticViews/  -- Cortex Analyst SEMANTIC VIEW definitions
  5-agents/         -- Cortex Agent definitions
  6-mcp/            -- MCP Server definition
  7-load/           -- data-loading scripts (PUT/COPY INTO, FOUNDATION split, reconciliation refresh)
  8-queries/        -- read-only verification and demo queries
```

Numeric prefixes on the files *inside* each folder indicate run order within that folder (e.g. `2-tables/01_raw_bundle_raw.sql` before `2-tables/02_foundation_tables.sql`).

## Layer-by-layer object inventory

### RAW — landing zone (`sql/2-tables/01_raw_bundle_raw.sql`)
Untouched FHIR Bundle JSON, one row per file.
- `RAW.JSON_FORMAT` — file format (`TYPE = JSON`)
- `RAW.FHIR_STAGE` — internal stage for `PUT`-ing local files
- `RAW.BUNDLE_RAW` — table: `TRACKING_ID` (UUID, generated per load), `SOURCE_FILE_NAME`, `RAW_LOAD_TS`, `BUNDLE_JSON` (`VARIANT`, the whole Bundle)

### FOUNDATION — split & typed, semi-flat (`sql/2-tables/02_foundation_tables.sql`)
One table per FHIR `resourceType`, 24 total. Every table has the same lineage columns (`RESOURCE_ID`, `BUNDLE_TRACK_ID_REF` → `RAW.BUNDLE_RAW.TRACKING_ID`, `SOURCE_FILE_NAME`, `ENTRY_INDEX`, `FOUNDATION_LOAD_TS`) plus one `FHIR_<FIELD>` `VARIANT` column per root-level JSON field of that resource — nested structure inside each field (e.g. `name[0].given`) is kept as-is, not flattened further.

- **20 clinical resource tables**: `PATIENT`, `ENCOUNTER`, `CONDITION`, `OBSERVATION`, `PROCEDURE`, `CLAIM`, `EXPLANATION_OF_BENEFIT`, `DIAGNOSTIC_REPORT`, `DOCUMENT_REFERENCE`, `IMMUNIZATION`, `MEDICATION_REQUEST`, `MEDICATION`, `MEDICATION_ADMINISTRATION`, `CARE_TEAM`, `CARE_PLAN`, `SUPPLY_DELIVERY`, `PROVENANCE`, `ALLERGY_INTOLERANCE`, `DEVICE`, `IMAGING_STUDY`
- **4 directory/reference tables**: `ORGANIZATION`, `LOCATION`, `PRACTITIONER`, `PRACTITIONER_ROLE` (from Synthea's separate hospital/practitioner bundles — referenced by identifier, not by plain `Type/<id>`, see notes in `sql/3-views/01_access_views.sql`)

### RECONCILIATION — pipeline health (`sql/2-tables/03_reconciliation_table.sql`)
- `RECONCILIATION.LOAD_SUMMARY` — one row per bundle × resource type: `TRACKING_ID`, `SOURCE_FILE_NAME`, `RESOURCE_TYPE`, `RAW_ENTRY_COUNT`, `FOUNDATION_LOADED_COUNT`, `LOAD_TS`, `STATUS` (`MATCHED` / `MISMATCH` / `NOT_TRACKED`)

### ACCESS — consumption views (`sql/3-views/`)
**`01_access_views.sql`** — 52 views directly over `FOUNDATION`, still holding `VARIANT` columns:
- 24 plain `<RESOURCE>_VIEW`s, one per `FOUNDATION` table
- ~17 `PATIENT_<RESOURCE>_VIEW`s joining each clinical resource back to its patient
- 4 `ENCOUNTER_<RESOURCE>_VIEW`s ("what happened during this visit")
- `CLAIM_EXPLANATION_OF_BENEFIT_VIEW` (billing chain)
- `PATIENT_360_VIEW` (per-patient counts across every resource type)
- 5 directory views: `LOCATION_ORGANIZATION_VIEW`, `PRACTITIONER_ROLE_DETAIL_VIEW`, `ENCOUNTER_ORGANIZATION_VIEW`, `ENCOUNTER_LOCATION_VIEW`, `ENCOUNTER_PRACTITIONER_VIEW`

**`02_access_flattened_views.sql`** — 7 more views, this time with clean **typed/scalar** columns (no `VARIANT`), purpose-built as the source for the semantic layer:
- `VW_VISITS` (grain: one row per encounter, enriched with patient/org/location/practitioner)
- `VW_DIAGNOSES` (one row per condition)
- `VW_MEDICATIONS` (one row per medication request)
- `VW_CLAIMS` (one row per claim)
- `VW_OBSERVATIONS` (one row per lab/vital observation)
- `VW_PROCEDURES` (one row per procedure)
- `VW_RECONCILIATION` (clean read of `RECONCILIATION.LOAD_SUMMARY`, adds `MISMATCH_COUNT`)

### SEMANTIC — Cortex Analyst semantic views (`sql/4-semanticViews/`)
7 `CREATE SEMANTIC VIEW` objects, each with `TABLES` / `DIMENSIONS` / `METRICS` / `COMMENT`, one per `VW_*` view:
- `SV_VISITS`, `SV_DIAGNOSES`, `SV_MEDICATIONS`, `SV_CLAIMS`, `SV_OBSERVATIONS`, `SV_PROCEDURES` (in `01_semantic_views.sql`)
- `SV_RECONCILIATION` (in `02_reconciliation_semantic_view.sql`, over `VW_RECONCILIATION`)

These define the business vocabulary (synonyms, comments) Cortex Analyst uses to turn natural-language questions into SQL against the `VW_*` views.

### SEMANTIC — Cortex Agents (`sql/5-agents/`)
- **6 product agents** (`01_product_agents.sql`), one per domain, each with a single `cortex_analyst_text_to_sql` tool bound to its semantic view, plus a `data_to_chart` tool:
  `VISITS_AGENT` → `SV_VISITS`, `DIAGNOSES_AGENT` → `SV_DIAGNOSES`, `MEDICATIONS_AGENT` → `SV_MEDICATIONS`, `CLAIMS_AGENT` → `SV_CLAIMS`, `OBSERVATIONS_AGENT` → `SV_OBSERVATIONS`, `PROCEDURES_AGENT` → `SV_PROCEDURES`
- **`HEALTHCARE_INTELLIGENCE_AGENT`** (`02_intelligence_agent.sql`) — the top-level orchestrator. Holds all 6 semantic views as tools, routes each question to the right domain(s), and synthesizes cross-domain answers (e.g. "top diagnoses for ED visits" → Visits + Diagnoses). This is the agent exposed via MCP.
- **`RECONCILIATION_AGENT`** (`03_reconciliation_agent.sql`) — separate agent for data engineers/pipeline operators, answers pipeline-health questions over `SV_RECONCILIATION` (not part of the clinical orchestrator, different audience).

### SEMANTIC — MCP Server (`sql/6-mcp/01_mcp_server.sql`)
- `SEMANTIC.HEALTHCARE_MCP_SERVER` — exposes `HEALTHCARE_INTELLIGENCE_AGENT` as a single MCP tool (`CORTEX_AGENT_RUN`) to external MCP clients (Claude Desktop, custom apps, Slack bots, etc.). It's a thin pass-through; all routing/reasoning happens inside the agent.

## Run order

Setup (DDL, run once):
`1-setup/01_database_and_schemas.sql` → `2-tables/01_raw_bundle_raw.sql` → `2-tables/02_foundation_tables.sql` → `2-tables/03_reconciliation_table.sql` → `3-views/01_access_views.sql` → `3-views/02_access_flattened_views.sql` → `4-semanticViews/01_semantic_views.sql` → `4-semanticViews/02_reconciliation_semantic_view.sql` → `5-agents/01_product_agents.sql` → `5-agents/02_intelligence_agent.sql` → `5-agents/03_reconciliation_agent.sql` → `6-mcp/01_mcp_server.sql`

Load (data, run after setup, and re-run `7-load/02`/`7-load/03` whenever data changes):
`7-load/01_load_raw.sql` (needs a client with local filesystem access — SnowSQL or the VS Code Snowflake extension, **not** Snowsight's browser worksheet) → `7-load/02_load_foundation.sql` → `7-load/03_load_reconciliation.sql`

Verify:
`8-queries/01_reconciliation_verify.sql` (read-only row counts / samples / mismatch checks across every layer) and `8-queries/02_demo_queries.sql` (end-to-end smoke test: flattened views → semantic views via `SEMANTIC_VIEW()` → agents via `DATA_AGENT_RUN` → MCP server introspection → data-quality spot checks).

## Other files

- `resources/sample_synthetic_data_fhir_r4/` — Synthea-generated FHIR R4 sample data: 109 per-patient transaction Bundles plus two reference bundles (`hospitalInformation...json` → Organization/Location, `practitionerInformation...json` → Practitioner/PractitionerRole).
- `docs/Snowflake_intelligent_dataproduct.html` — the original architecture/vision writeup (Cortex Analyst semantic models, MCP agents) that this platform implements.
