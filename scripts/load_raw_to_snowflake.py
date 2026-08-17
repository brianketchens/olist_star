"""
Reloads the in-scope Olist CSVs into OLIST_RAW.RAW in Snowflake.

Usage:
    python scripts/load_raw_to_snowflake.py

Reads connection info from the dbt profile (~/.dbt/profiles.yml, target 'dev').
Lands everything as VARCHAR (schema-on-read) — the dbt staging models
(models/staging/stg_*.sql) do the casting. Safe to re-run: tables are
recreated and reloaded from scratch each time (CREATE OR REPLACE).

To bring a new raw table into scope, add an entry to TABLES below with its
exact CSV filename and column headers, then add it to models/staging/_sources.yaml.
"""
import os
import yaml
import snowflake.connector

PROJECT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
RAW_DIR = os.path.join(PROJECT_DIR, "raw_data")

TABLES = {
    "OLIST_ORDERS_DATASET": {
        "file": "olist_orders_dataset.csv",
        "columns": [
            "order_id", "customer_id", "order_status", "order_purchase_timestamp",
            "order_approved_at", "order_delivered_carrier_date",
            "order_delivered_customer_date", "order_estimated_delivery_date",
        ],
    },
    "OLIST_ORDER_ITEMS_DATASET": {
        "file": "olist_order_items_dataset.csv",
        "columns": [
            "order_id", "order_item_id", "product_id", "seller_id",
            "shipping_limit_date", "price", "freight_value",
        ],
    },
    "OLIST_CUSTOMERS_DATASET": {
        "file": "olist_customers_dataset.csv",
        "columns": [
            "customer_id", "customer_unique_id", "customer_zip_code_prefix",
            "customer_city", "customer_state",
        ],
    },
    "OLIST_PRODUCTS_DATASET": {
        "file": "olist_products_dataset.csv",
        "columns": [
            "product_id", "product_category_name", "product_name_lenght",
            "product_description_lenght", "product_photos_qty", "product_weight_g",
            "product_length_cm", "product_height_cm", "product_width_cm",
        ],
    },
    "OLIST_SELLERS_DATASET": {
        "file": "olist_sellers_dataset.csv",
        "columns": ["seller_id", "seller_zip_code_prefix", "seller_city", "seller_state"],
    },
}


def main():
    with open(os.path.expanduser("~/.dbt/profiles.yml")) as f:
        profile = yaml.safe_load(f)["olist_ecommerce_supplychain"]["outputs"]["dev"]

    conn = snowflake.connector.connect(
        account=profile["account"],
        user=profile["user"],
        password=profile["password"],
        role=profile["role"],
        warehouse=profile["warehouse"],
    )
    cur = conn.cursor()

    try:
        cur.execute("CREATE DATABASE IF NOT EXISTS OLIST_RAW")
        cur.execute("CREATE SCHEMA IF NOT EXISTS OLIST_RAW.RAW")
        # CREATE DATABASE/SCHEMA only auto-switches session context when it
        # actually creates something; force it explicitly so PUT's unqualified
        # table-stage reference (@%table) always resolves, even on a re-run
        # against objects that already exist.
        cur.execute("USE DATABASE OLIST_RAW")
        cur.execute("USE SCHEMA RAW")
        cur.execute("""
            CREATE OR REPLACE FILE FORMAT OLIST_RAW.RAW.CSV_FF
            TYPE = CSV
            FIELD_OPTIONALLY_ENCLOSED_BY = '"'
            SKIP_HEADER = 1
            NULL_IF = ('')
            EMPTY_FIELD_AS_NULL = TRUE
            ENCODING = 'UTF8'
        """)

        for table, spec in TABLES.items():
            fq_table = f"OLIST_RAW.RAW.{table}"
            col_defs = ", ".join(f"{c} VARCHAR" for c in spec["columns"])
            cur.execute(f"CREATE OR REPLACE TABLE {fq_table} ({col_defs})")

            local_path = os.path.join(RAW_DIR, spec["file"]).replace("\\", "/")
            cur.execute(
                f"PUT 'file://{local_path}' @%{table} AUTO_COMPRESS=TRUE OVERWRITE=TRUE"
            )
            cur.execute(f"""
                COPY INTO {fq_table}
                FROM @%{table}
                FILE_FORMAT = (FORMAT_NAME = OLIST_RAW.RAW.CSV_FF)
                ON_ERROR = 'ABORT_STATEMENT'
            """)
            cur.execute(f"REMOVE @%{table}")

            count = cur.execute(f"SELECT COUNT(*) FROM {fq_table}").fetchone()[0]
            print(f"{fq_table}: {count} rows loaded")

    finally:
        cur.close()
        conn.close()


if __name__ == "__main__":
    main()
