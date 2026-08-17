-- models/staging/stg_orders.sql
--
-- A staging model does exactly ONE job: clean and standardize a single
-- raw table. Rename to snake_case, cast types, trim strings.
-- NO joins. NO aggregation. NO business logic. Those live in marts.

with source as (
    select * from {{ source('olist', 'orders') }}   -- resolves via _sources.yml
),

renamed as (
    select
        order_id,
        customer_id,
        order_status,
        cast(order_purchase_timestamp as timestamp) as purchased_at,
        cast(order_delivered_customer_date as timestamp) as delivered_at
    from source
)

select * from renamed