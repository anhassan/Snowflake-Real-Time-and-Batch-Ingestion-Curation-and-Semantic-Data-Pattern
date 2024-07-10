--====== Account Heirarchy =========
-- orgadmin ==> accountadmin ==> [sysadmin,securityadmin]
-- securityadmin ==> useradmin ==> public
-- sysadmin ==> custom roles

use role accountadmin;

--==== showing all the roles that exist in the account ====
show roles;
select "name","comment" from table(result_scan(last_query_id()));

--- ==== Getting the grants assigned to securityadmin role ====
show grants to role securityadmin;

-- === Using systemadmin role to create databases,schemas and tables ===
use role sysadmin;

create database if not exists access_db;

create schema if not exists access_schema;

create table if not exists access_table(
    id int,
    name string
);

-- === Using securityadmin role to create a custom role and assign permissions to it accordingly ===
use role securityadmin;

-- === Creating a custom role ===
create role analyst_role;

-- == Granting usage access to custom role (analyst_role) on the access_db ==
grant usage on database access_db to role analyst_role;

-- == Granting usage and create table access to custom role (analyst_role) on the access_schema ==
grant usage, create table on schema access_db.access_schema to role analyst_role;

-- == Granting usage access to custom role (analyst_role) on compute warehouse ==
grant usage on warehouse compute_wh to role analyst_role;

-- == Assign custom role (analyst_role) to sysadmin role - role heirarchy/ inheritance (best practice) ==
grant role analyst_role to role sysadmin;

-- == Verify the previliges assigned above ==

-- == Showing the grants of sysadmin role ==
show grants to role sysadmin;

-- == Showing the grants of custom role (analyst_role) ==
show grants to role analyst_role;

-- == Showing the roles to which custom role (analyst_role) has been granted ==
show grants of role analyst_role;

-- == Switching to custom role (analyst_role) for table creation ==
use role analyst_role;

-- == Using the desired database and desired schema ==
use database access_db;
use schema access_schema;

-- == Creating table using custom role (analyst_role) ===
create table access_table_role (
    id int,
    name string
);

-- == Show tables via custom role (analyst_role) only shows the tables created by custom role (analyst_role) ==
-- == Tables created by sysadmin (access_table) not visible ==
-- == Tables created only by custom role (analyst_role) visible ==
show tables;

-- == Show databases via the custom role (analyst_role) ==
show databases;
select "name","owner" from table(result_scan(last_query_id()));

-- == Using the sysadmin role ==
use role sysadmin;

-- == Show tables via the sysadmin role ==
-- == Able to see both the tables created by both custom role (analyst_role) and sysadmin since sysadmin inherits
-- == objects created by custom role (analyst_role) due to role heirarchy ===
show tables;
select "name","owner" from table(result_scan(last_query_id()));

-- ============ Future Grants ==============

-- ==== Using the securityadmin role ====
use role securityadmin;


-- == Using the sysadmin ==
use role sysadmin;

-- === Creating schema using the sysadmin ===
create schema access_schema_non_future;

-- === Using the analyst role ===
use role analyst_role;

-- == Getting the tables custom role (analyst_role) has access to ==
-- == Do not get table name : access_schema_non_future table ==
show tables;

-- === Granting future grants to custom role (analyst_role) ===
use role securityadmin;
grant usage on future schemas in database access_db to role analyst_role;

-- == Using system admin and creating new schema and table ===
use role sysadmin;
create schema if not exists access_db.access_schema_with_future_grants;
create table if not exists access_table_future_grants(
    id int,
    name string
)

-- == Getting all the schemas sysadmin has access to ==
show schemas;

-- === Using custom role (analyst_role) ===
use role analyst_role;

-- == Getting all the schemas ==
-- == Gets all the schemas (access_schema_with_future_grants) which were created after the future grants ==
show schemas;

-- == Gets all the schemas (access_schema_with_future_grants) which were created after the future grants ==
show grants to role analyst_role;

-- === Creating user in Snowflake ===

-- === Using user admin role to create a user in snowflake ===
use role useradmin;

-- === Creating a user ===
-- === password = 'Temp_123' ===
create user cloud_user
password = 'temp'
default_role = 'analyst_role'
default_warehouse = 'compute_wh'
must_change_password=true

-- === Apply analyst role to the custom user (cloud_user) created above ===
use role securityadmin;
grant role analyst_role to user cloud_user;






