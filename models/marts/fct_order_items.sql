-- models/marts/fct_order_items.sql
--
-- The fact table. GRAIN: one row per order line item. Nail the grain first;
-- everything else follows from it. A fact holds foreign keys out to the
-- dimensions + the additive measures. No descriptive text columns here.

with order_items as (
    select * from {{ ref('stg_order_items') }}
),

orders as (
    select * from {{ ref('stg_orders') }}    -- needed to reach customer_id + purchase date
),

joined as (
    select
        oi.order_id,
        oi.order_item_id,
        o.customer_id,          -- customer_id lives on orders, not order_items
        oi.product_id,
        oi.seller_id,
        cast(o.purchased_at as date) as order_date,
        oi.price,
        oi.freight_value
    from order_items oi
    inner join orders o on oi.order_id = o.order_id
)

select
    -- FOREIGN KEYS: same macro, same natural key the dimension used.
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_sk,
    {{ dbt_utils.generate_surrogate_key(['product_id']) }} as product_sk,
    {{ dbt_utils.generate_surrogate_key(['seller_id']) }} as seller_sk,
    {{ dbt_utils.generate_surrogate_key(['order_date']) }} as date_sk,
    {{ dbt_utils.generate_surrogate_key(['order_id', 'order_item_id']) }} as order_item_sk,
    
    -- MEASURES (additive — safe to sum across any dimension):
    price,
    freight_value
from joined
