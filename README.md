# snowflake-healthcare-intelligence
MVP Repo for snowflake intelligent Data product

## Data platform setup

`sql/` holds the Snowflake setup scripts for the `HEALTHCARE_INTELLIGENCE_DB` database, run in order:

| File | Purpose |
|---|---|
| `01_setup.sql` | Creates the database and the 5 schemas: `RAW`, `FOUNDATION`, `ACCESS`, `RECONCILIATION`, `SEMANTIC`. |
| `02_raw.sql` | `RAW.BUNDLE_RAW` landing table (whole FHIR Bundle JSON, untouched) + internal stage for loading local files. |
| `03_foundation.sql` | One table per FHIR resource type (20 tables) in `FOUNDATION`. Semi-flat: each root-level JSON field of the resource gets its own `FHIR_<FIELD>` `VARIANT` column, not flattened further. |
| `04_reconciliation.sql` | `RECONCILIATION.LOAD_SUMMARY` skeleton for tracking RAW entry counts vs. FOUNDATION load counts per bundle. |
| `05_access.sql`, `06_semantic.sql` | Placeholders — `ACCESS` (consumption views) and `SEMANTIC` (Cortex Analyst model YAML) are built once FOUNDATION has data. |
| `10_load_raw.sql` | `PUT` + `COPY INTO` to load `sample_synthetic_data_fhir_r4/*.json` into `RAW.BUNDLE_RAW`. |
| `20_load_foundation.sql` | Splits each RAW bundle's `entry[]` by `resourceType` and inserts into the matching `FOUNDATION` table. |

`sample_synthetic_data_fhir_r4/` contains Synthea-generated FHIR R4 sample data: per-patient transaction Bundles plus two reference bundles (hospital/practitioner directories).

`Poc.html` is an architecture/vision writeup for the intelligence layer (Cortex Analyst semantic models, MCP agents) built on top of this data platform — not yet implemented.
