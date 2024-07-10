-- == Use account admin ==
use role accountadmin;

-- == Grant usage on default warehouse to sysadmin ==
grant usage on warehouse compute_wh to role sysadmin;

-- == Use sysadmin role to create database,schema and tables ==
use role sysadmin;
use warehouse compute_wh;

-- == Create database ==
create database if not exists rc_security_db;

-- == Create schema ==
create schema if not exists rc_security_schema;

-- == Create table ==
create table if not exists rc_table(
    id int,
    region string,
    allowed_role string
);

-- == Inserting data in the table created ==
insert into rc_table values
(1,'USA','sysadmin'),
(2,'CAN','accountadmin'),
(3,'AUS','securityadmin'),
(4,'IND','bi_analyst_role'),
(5,'HKG','bi_analyst_role');

-- == Use securityadmin role to create a custom role ==
use role securityadmin;

-- == Create a custom role (bi_analyst_role) ==
create role bi_analyst_role;

-- == Grant custom role (bi_analyst_role) usage on the required database ==
grant usage on database rc_security_db to role bi_analyst_role;

-- == Grant custom role (bi_anlayst_role) usage on the required schema ==
grant usage on schema rc_security_db.rc_security_schema to role bi_analyst_role;

-- == Grant custom role (bi_analyst_role) select on the the required table ==
grant select on table rc_security_db.rc_security_schema.rc_table to role bi_analyst_role;

-- == Granting custom role (bi_analyst_role) to sysadmin (role inheritance) ==
grant role bi_analyst_role to role sysadmin;

-- == Create a role for defining masking policies ==
create role masking_admin;

-- == Grant masking_admin role usage on the required database ==
grant usage on database rc_security_db to role masking_admin;

-- == Grant masking_admin role usage on the required schema ==
grant usage on schema rc_security_db.rc_security_schema to role masking_admin;

-- == Grant masking_admin role to create column and row level policies on the required schema ==
grant create masking policy, create row access policy on schema rc_security_db.rc_security_schema to role masking_admin;

-- == Grant masking_admin role apply column and role level policies to the required schema tables ==
use role accountadmin;
grant apply masking policy, apply row access policy on account to role masking_admin;

-- == Granting masking_admin role to sysadmin role ==
grant role masking_admin to role sysadmin;

-- == Use masking_admin role ==
use role masking_admin;

-- == Create column level security policy on the required table ==
-- == the input column and output of the policy should have the same data type
create or replace masking policy filter_countries_policy as (val string) returns string ->
    case when current_role() in ('BI_ANALYST_ROLE') then val
         else '***********'
    end;

-- == Use role securityadmin ==
use role securityadmin;

-- == Grant usage on default warehosue to masking_admin == 
grant usage on warehouse compute_wh to role masking_admin;

-- == Grant usage on default warehouse to custom role (bi_analyst_role) ==
grant usage on warehouse compute_wh to role bi_analyst_role;

-- == Use role masking_admin ==
use role masking_admin;
use warehouse compute_wh;

-- == Apply column level policy to the required table ==
alter table rc_security_db.rc_security_schema.rc_table modify column region set masking policy filter_countries_policy;

-- == Use role bi_analyst_role to check whether the column level policy works ==
use role bi_analyst_role;
select * from rc_security_db.rc_security_schema.rc_table;

-- == Entire table can be seen using the bi_analyst_role ==

-- == Use sysadmin role to see whether the column level security works or not ==
use role sysadmin;
select * from rc_security_db.rc_security_schema.rc_table;

-- == The region column is seen as ******* as applied in the column level policy

-- == Use masking_admin to role to apply row level policy ==
use role masking_admin;

-- == Create row level policy using the masking_admin role ==
create or replace row access policy filter_on_role as (val int) returns boolean ->
  case when current_role() in ('BI_ANALYST_ROLE') then true
  else false
  end;

-- == Apply row level policy on the required table ==
alter table rc_security_db.rc_security_schema.rc_table add row access policy filter_on_role on (id);

-- == Use role custom role (bi_analyst_role) to determine whether the row level polciy is working or not ==
use role bi_analyst_role;
select * from rc_security_db.rc_security_schema.rc_table;

-- == Using the bi_analyst_role, we can see all the rows of the table in accordance to the row access policy ==

-- == Use role sysadmin to determine whether the row level policy is working or not ==
use role sysadmin;
select * from rc_security_db.rc_security_schema.rc_table;

-- == Using the sysadmin role, we cannot see any rows of the table in accordance to the row access plociy ==

-- == Use sysadmin role ==
use role sysadmin;

-- == Create a mapping table ==
create table if not exists rc_security_db.rc_security_schema.roles_ids_mappings(
    id int,
    allowed_role string
);

-- == Inserting data in the mapping table ==
insert into rc_security_db.rc_security_schema.roles_ids_mappings values 
(1,'sysadmin'),
(2,'accountadmin'),
(3,'securityadmin'),
(4,'bi_analyst_role'),
(5,'bi_analyst_role');

-- == Use masking_admin role ==
use role masking_admin;

-- == Unset the previous row access policy used on the required table ==
-- == Only one row access policy (RAC) can be applied on one table ==
alter table rc_security_db.rc_security_schema.rc_table drop row access policy filter_on_role;

-- == Grant select access to masking_admin on the required table ==
use role securityadmin;
grant select on table rc_security_db.rc_security_schema.roles_ids_mappings to role masking_admin;
use role masking_admin;

-- == Create another row access policy ==
-- == We cannot attach policies to a table which is used in the policy definition ==
create or replace row access policy filter_on_specific_role as (val string) returns boolean ->
    exists (
        select 1 from rc_security_db.rc_security_schema.roles_ids_mappings
        where upper(val) = current_role() 
    );

-- == Apply row access policy on the required table ==
alter table rc_security_db.rc_security_schema.rc_table add row access policy filter_on_specific_role on (allowed_role);

-- == Use custom role (bi_analyst_role) to test whether the mapping table policy is working or not ==
use role bi_analyst_role;
select * from rc_security_db.rc_security_schema.rc_table;

-- == Output : Only those rows are available which correspond to the bi_analyst_role ==

-- == Key Take Aways ==
-- 1. Use sysadmin role to create database, tables and views ==
-- 2. Use securityadmin to create roles
-- 3. Use securityadmin to grant access to various resources to roles
-- 4. Use the following conditions to create column and row level policies 
--   == Column Level Policies ===> create or replace masking policy <policy_name> as (val string) returns string -> {policy definition}
--   == Row Level Policies ===> create or replace row access policy <policy_name> as (val string) -> returns boolean {policty definition}
-- 5. Use the following code to apply column and row level polices
--   == Column Level Policies ===> alter table <table_name> modify column <column_name> set masking policy <policy_name>;
--   == Row Level Policies ===> alter table <table_name> add row access policy <policy_name> on (<column_name>);
-- 6. Use the following code to unset/drop column and row level policies
--   == Column Level Policies ===> alter table <table_name> modify column <column_name> unset masking policy;
--   == Row Level Policies ===> alter table <table_name> drop row level policy <policy_name>;
-- 7. At a time, one table can be applied only one row level policy and not multiple row level policies
-- 8. At a time, one column cannot be used for both column level and row level policy combined

-- == Dropping the resources created ==

-- == Dropping all the column and row level policies ==
-- == Use masking_admin role ==
use role masking_admin;

-- == Detach masking policy and row access policy from the attached table ==
alter table rc_security_db.rc_security_schema.rc_table modify column region unset masking policy;
alter table rc_security_db.rc_security_schema.rc_table drop row access policy filter_on_specific_role;

-- == Dropping masking policy and row access policies ==
drop masking policy filter_countries_policy;
drop row access policy filter_on_role;
drop row access policy filter_on_specific_role;

-- == Use securityadmin role ==
use role securityadmin;

-- == Dropping the roles created ==
drop role bi_analyst_role;
drop role masking_admin;

-- == Use sysadmin role ==
use role sysadmin;

-- == Dropping the created database ==
drop database rc_security_db;

    







