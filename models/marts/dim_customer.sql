-- models/marts/dim_customer.sql
--
-- A dimension: one row per business entity, keyed by a SURROGATE key.
-- Kimball convention is to hash a surrogate rather than trust the natural
-- key from the source. The fact joins on this surrogate.

with customers as (
    select * from {{ ref('stg_customers') }}    -- ref(), not source() — this is downstream
)

select
    {{ dbt_utils.generate_surrogate_key(['customer_id']) }} as customer_sk,  -- surrogate
    customer_id   as customer_nk,   -- keep the natural key for lineage/debugging
    customer_city,
    customer_state
from customers