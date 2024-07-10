use role accountadmin;
use warehouse compute_wh;
use snowflake_sample_data;
use schema tpch_sf1;

desc table customer;

show tables;

show tables like 'customer';

select * from table(result_scan(last_query_id()));

create database demo_db;
create schema demo_schema;

use database demo_db;
use schema demo_schema;


-- ======================= TABLES ========================

-- Table Types:
-- 1. Permenant Tables
-- 2. Temporary Tables
-- 3. Transient Tables
-- 4. External  Tables

-- 1. Need to be explicity dropped
-- 2. Can have retention period upto 90 days and fail safe duration of 7 days
create table permenant_table (
    id int,
    name string
);

-- 1. Have lifetime equal to the life of current session
-- 2. Can have maximum retention period of 1 day and have no fail safe period
create temporary table temp_table (
    id int,
    name string
);

-- 1. Need to be explicity dropped
-- 2. Can have retention period upto 1 day maximum and have no fail safe period
create transient table trans_table (
    id int,
    name string
);

-- 1. Just table definition in database schema
-- 2. No retention period and fail safe duration 
create external table ext_table (
    id int,
    name string
)
location = @named_stage/logs
file_format=(type=parquet);

-- manually does a refresh on the external table content
alter external table ext_table refresh;

show tables;

select "name","database_name","schema_name","kind","retention_time" from table(result_scan(last_query_id()));

-- Successful command ==> permenant table can have maximum retention period of 90 days
alter table permenant_table set data_retention_time_in_days = 90;

-- Failed command ==> transient table can have a max retention period of 1 day
alter table trans_table set data_retention_time_in_days = 2;

-- Failed command ==> temporary tables can have a max retentionperiod of 1 day
alter table temp_table set data_retention_time_in_days = 2;

-- ======================= VIEWS ========================

-- View Types:
-- 1. Standard View
-- 2. Materialized View
-- 3. Secure View

create view standard_view as
select * from permenant_table;

create secure view secure_view as
select * from permenant_table;

create materialized view materialized_view as 
select * from permenant_table;

grant usage on database demo_db to role sysadmin;
grant usage on schema demo_schema to role sysadmin;
grant select, references on table standard_view to role sysadmin;
grant select, references on table secure_view to role sysadmin;

-- Successful command since account admin is the owner of the secure view
select get_ddl('view','secure_view');

use role sysadmin;

-- Failed command since sysadmin does not have access to see the view definition
select get_ddl('view','secure_view');

-- Successful as view is not secured
select get_ddl('view','standard_view');

use role accountadmin;

drop database demo_db;




