-- models/staging/stg_order_items.sql
--
-- A staging model does exactly ONE job: clean and standardize a single
-- raw table. Rename to snake_case, cast types, trim strings.
-- NO joins. NO aggregation. NO business logic. Those live in marts.

with source as (
    select * from {{ source('olist', 'order_items') }}
),

renamed as (
    select
        order_id,
        order_item_id,
        product_id,
        seller_id,
        cast(shipping_limit_date as timestamp) as shipping_limit_at,
        price,
        freight_value
    from source
)

select * from renamed
