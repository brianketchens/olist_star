-- models/staging/stg_products.sql
--
-- A staging model does exactly ONE job: clean and standardize a single
-- raw table. Rename to snake_case, cast types, trim strings.
-- NO joins. NO aggregation. NO business logic. Those live in marts.

with source as (
    select * from {{ source('olist', 'products') }}
),

renamed as (
    select
        product_id,
        product_category_name,
        product_name_lenght as product_name_length,               -- fixing source's typo
        product_description_lenght as product_description_length, -- fixing source's typo
        product_photos_qty,
        product_weight_g,
        product_length_cm,
        product_height_cm,
        product_width_cm
    from source
)

select * from renamed
