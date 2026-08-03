-- Bronze / Silver / Gold schema layout
CREATE SCHEMA IF NOT EXISTS raw;        -- Bronze: raw loaded data
CREATE SCHEMA IF NOT EXISTS staging;    -- Silver: cleaned/typed (managed by dbt)
CREATE SCHEMA IF NOT EXISTS analytics;  -- Gold: marts / KPIs (managed by dbt)
