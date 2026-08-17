-- models/marts/dim_date.sql
--
-- The date dimension isn't built from a raw source — it's generated.
-- Range covers Olist's actual order history (Sep 2016–Oct 2018) with
-- padding on both ends. date_sk is hashed from date_day the SAME way
-- fct_order_items hashes its order_date, so the FK join lines up.

with spine as (
    {{ dbt_utils.date_spine(
        datepart="day",
        start_date="cast('2016-01-01' as date)",
        end_date="cast('2019-01-01' as date)"
    ) }}
),

renamed as (
    select
        {{ dbt_utils.generate_surrogate_key(['date_day']) }} as date_sk,  -- surrogate
        date_day,
        extract(year from date_day) as year,
        extract(quarter from date_day) as quarter,
        extract(month from date_day) as month,
        extract(day from date_day) as day_of_month,
        extract(dayofweek from date_day) as day_of_week,
        dayname(date_day)   as day_name,
        monthname(date_day) as month_name
    from spine
)

select * from renamed
