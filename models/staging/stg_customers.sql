-- models/staging/stg_customers.sql
--
-- A staging model does exactly ONE job: clean and standardize a single
-- raw table. Rename to snake_case, cast types, trim strings.
-- NO joins. NO aggregation. NO business logic. Those live in marts.

with source as (
    select * from {{ source('olist', 'customers') }}
),

renamed as (
    select
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    from source
)

select * from renamed
