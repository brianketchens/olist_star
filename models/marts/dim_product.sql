-- models/marts/dim_product.sql
--
-- A dimension: one row per business entity, keyed by a SURROGATE key.
-- Kimball convention is to hash a surrogate rather than trust the natural
-- key from the source. The fact joins on this surrogate.

with products as (
    select * from {{ ref('stg_products') }}    -- ref(), not source() — this is downstream
)

select
    {{ dbt_utils.generate_surrogate_key(['product_id']) }} as product_sk,  -- surrogate
    product_id   as product_nk,   -- keep the natural key for lineage/debugging
    product_category_name,
    product_weight_g,
    product_length_cm,
    product_height_cm,
    product_width_cm
from products
