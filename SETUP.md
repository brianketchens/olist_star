# Environment Setup

Commands to stand up a working dbt Core environment for this project from scratch.
Run everything from the project root (`olist_star/`) unless noted otherwise.

## 0. Clone the repository

```bash
git clone https://github.com/brianketchens/olist_star.git
cd olist_star
```

## 1. Python environment

Developed on Python 3.14; dbt-core supports 3.9+.

```bash
python -m venv .venv
```

Activate it:

```bash
# Windows (PowerShell)
.venv\Scripts\Activate.ps1

# Windows (Git Bash) / macOS / Linux
source .venv/Scripts/activate   # Git Bash
source .venv/bin/activate       # macOS/Linux
```

## 2. Install dbt and the Snowflake adapter

```bash
pip install dbt-snowflake
```

This pulls in `dbt-core`, `snowflake-connector-python`, and `PyYAML` — everything
both dbt and `scripts/load_raw_to_snowflake.py` need.

## 3. Configure the dbt profile

dbt Core reads connection info from `~/.dbt/profiles.yml` (a machine-local file,
outside this repo — never commit credentials). Create it with:

```yaml
olist_ecommerce_supplychain:
  outputs:
    dev:
      type: snowflake
      account: <your_account_locator>
      user: <your_username>
      password: <your_password>
      role: ACCOUNTADMIN
      warehouse: COMPUTE_WH
      database: OLIST
      schema: DBT_DEV
      threads: 4
  target: dev
```
`ACCOUNTADMIN` is used here for trial simplicity; a scoped role with `CREATE SCHEMA` on the target databases is preferable in a real deployment

Verify the connection:

```bash
dbt debug
```

## 4. Install dbt package dependencies

```bash
dbt deps
```

Installs `dbt_utils` per `packages.yml` (must be named exactly `packages.yml` —
dbt does not recognize `packages.yaml`).

## 5. Acquire and load raw data into Snowflake

**Download the Olist dataset from Kaggle: `https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce` and place the CSV files into `raw_data/` matching the exact filenames the loader's `TABLES` dict expects (the loader uses five: orders, order_items, customers, products, sellers -- keep snakecase CSV file names as downloaded).**

 Raw data lands in `OLIST_RAW`, dbt reads from that location then builds into `OLIST`.

Raw CSVs live in `raw_data/` but are never loaded automatically — run the loader
explicitly whenever you need to (re)populate `OLIST_RAW.RAW`:

```bash
python scripts/load_raw_to_snowflake.py
```

Safe to re-run: each table is dropped and recreated from the current CSV on every run.

## 6. Build and test the models

```bash
dbt build
```

Runs every model and every test in dependency order. Use `dbt run` / `dbt test`
individually while iterating, and `dbt compile` to check that models and refs
resolve without touching the warehouse.

## Troubleshooting

- **`dbt deps` says "No packages were found"** — check the file is named
  `packages.yml`, not `packages.yaml`.
- **`Model 'X' depends on 'Y' which was not found`** — a `ref()` points to a
  staging/mart model that doesn't exist yet; check `models/staging/` and `models/marts/`.
- **`This session does not have a current database`** from the loader script —
  shouldn't happen with the current version, but if it recurs, add explicit
  `USE DATABASE` / `USE SCHEMA` calls before any `PUT`/`COPY INTO`.
- **`dbt test` UserWarning: You have an incompatible version of `pyarrow` installed...**   
  this warning is cosmetic and safe to ignore for SQL-only model building.
