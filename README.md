# snowflake-healthcare-intelligence
MVP Repo for snowflake intelligent Data product

## Data platform setup

`sql/` holds the Snowflake setup scripts for the `HEALTHCARE_INTELLIGENCE_DB` database, run in order:

| File | Purpose |
|---|---|
| `01_setup.sql` | Creates the database and the 5 schemas: `RAW`, `FOUNDATION`, `ACCESS`, `RECONCILIATION`, `SEMANTIC`. |
| `02_raw.sql` | `RAW.BUNDLE_RAW` landing table (whole FHIR Bundle JSON, untouched) + internal stage for loading local files. |
| `03_foundation.sql` | One table per FHIR resource type (24 tables) in `FOUNDATION`: the 20 clinical resource types plus 4 directory/reference types (`Organization`, `Location`, `Practitioner`, `PractitionerRole`). Semi-flat: each root-level JSON field of the resource gets its own `FHIR_<FIELD>` `VARIANT` column, not flattened further. |
| `04_reconciliation.sql` | `RECONCILIATION.LOAD_SUMMARY` table skeleton. |
| `05_access.sql` | 52 `ACCESS` views: 24 plain `<RESOURCE>_VIEW`s (1:1 with FOUNDATION), ~17 `PATIENT_<RESOURCE>_VIEW`s joining each clinical resource back to its patient, 4 `ENCOUNTER_<RESOURCE>_VIEW`s ("what happened during this visit"), `CLAIM_EXPLANATION_OF_BENEFIT_VIEW` (billing chain), `PATIENT_360_VIEW` (per-patient counts across every resource type), and 5 directory views joining `Organization`/`Location`/`Practitioner`/`PractitionerRole` to each other and to `Encounter` (these use FHIR identifier-based and search-style references instead of plain `Type/<id>` references — see the comments in the file). |
| `06_semantic.sql` | Placeholder — Cortex Analyst semantic model YAML stage, built once ACCESS views are in place. |
| `10_load_raw.sql` | `PUT` + `COPY INTO` to load `sample_synthetic_data_fhir_r4/*.json` into `RAW.BUNDLE_RAW`. Must be run from a client with local filesystem access (SnowSQL CLI, VS Code Snowflake extension) — Snowsight's browser worksheet can't run `PUT`. |
| `20_load_foundation.sql` | Splits each RAW bundle's `entry[]` by `resourceType` and inserts into the matching `FOUNDATION` table. |
| `30_load_reconciliation.sql` | Refreshes `RECONCILIATION.LOAD_SUMMARY` — compares RAW entry counts vs. FOUNDATION loaded counts per bundle per resource type. Run after `20_load_foundation.sql`. |
| `40_reconciliation_verify.sql` | Read-only verification queries (row counts, samples, mismatches-only, coverage) across every layer — also the query surface the docs/ECDH_INTELLIGENT_DATAPRODUCT.html Reconciliation Agent is meant to use. |

`sample_synthetic_data_fhir_r4/` contains Synthea-generated FHIR R4 sample data: per-patient transaction Bundles plus two reference bundles (hospital/practitioner directories).

`docs/ECDH_INTELLIGENT_DATAPRODUCT.html` is an architecture/vision writeup for the intelligence layer (Cortex Analyst semantic models, MCP agents) built on top of this data platform — not yet implemented.
