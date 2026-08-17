-- models/staging/stg_sellers.sql
--
-- A staging model does exactly ONE job: clean and standardize a single
-- raw table. Rename to snake_case, cast types, trim strings.
-- NO joins. NO aggregation. NO business logic. Those live in marts.

with source as (
    select * from {{ source('olist', 'sellers') }}
),

renamed as (
    select
        seller_id,
        seller_city,
        seller_state
    from source
)

select * from renamed
