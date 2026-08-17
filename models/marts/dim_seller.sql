-- models/marts/dim_seller.sql
--
-- A dimension: one row per business entity, keyed by a SURROGATE key.
-- Kimball convention is to hash a surrogate rather than trust the natural
-- key from the source. The fact joins on this surrogate.

with sellers as (
    select * from {{ ref('stg_sellers') }}    -- ref(), not source() — this is downstream
)

select
    {{ dbt_utils.generate_surrogate_key(['seller_id']) }} as seller_sk,  -- surrogate
    seller_id   as seller_nk,   -- keep the natural key for lineage/debugging
    seller_city,
    seller_state
from sellers
