-- ====== PRODUCER ACCOUNT CODE =======

-- == Use sysadmin role ==
use role sysadmin;

-- == Create database ==
create database if not exists base_db;

-- == Create schema ==
create schema if not exists base_schema;

-- == Create table ==
create table if not exists base_table(
    id int,
    location string
);

-- == Populate table ==
insert into base_table values
(1,'USA'),(2,'CAN'),(3,'IND');

-- == Create secure view ==
create secure view base_secure_view as
select * from base_table;

-- == Create share object ==
create share share_obj;

-- == Grant usage on database to share object ==
grant usage on database base_db to share share_obj;

-- == Grant usage on schema to share object ==
grant usage on schema base_schema to share share_obj;

-- == Grant select on table to share object ==
grant select on table base_table to share share_obj;

-- == Grant select on view to share object ==
grant select on view base_secure_view to share share_obj;

-- == Create reader account ==
-- == accountLocator : EF88865
-- == url: https://ejqdwxm-snowflake_reader_account.snowflakecomputing.com
-- == accountLocatorUrl:https://ef88865.ca-central-1.aws.snowflakecomputing.com
create managed account snowflake_reader_account
admin_name = 'admin'
admin_password = 'Passw0rd_Admin'
type = reader;

-- == Assign share to reader account ==
alter share share_obj add accounts = EF88865;

-- == Show managed accounts ==
show managed accounts;

-- == Create new table after creating the share ==
create table new_table (
    id int,
    location string
);

-- == Populate the new table ==
insert into new_table values (1,'XYZ')

-- == Grant select usage on created table to share ==
-- == Without explicitly grant select on the share object, the new table does not appear automatically in the reader account ==
grant select on table new_table to share share_obj;

-- == Remove reader account access ==
alter share share_obj remove accounts = EF88865;

-- == Drop reader account ==
drop managed account snowflake_reader_account;

-- == Drop share ==
drop share share_obj;

-- == Drop database ==
drop database base_db;


-- ===== READER/CONSUMER ACCOUNT CODE ======

-- == Use accountadmin role ==
use role accountadmin;

-- == Create database from share ==
create database reader_db from share KO91675.share_obj;

-- == Grant usage on database to sysadmin ==
-- == Granting individual privileges on imported database is not allowed. Use 'GRANT IMPORTED PRIVILEGES' instead ==
grant imported privileges on database reader_db to role sysadmin;

-- == Use sysadmin role ==
use role sysadmin;

-- == Create virtual compute ==
create warehouse reader_warehouse with warehouse_size = 'xsmall';

-- == Use warehouse ==
use warehouse reader_warehouse;

-- == Use database ==
use database reader_db;

-- == Use schema ==
use schema base_schema;

-- == Select table contents ==
select * from base_table;

-- == Select view contents ==
select * from base_secure_view;

-- == Select from newly created table after sharing the data share ==
select * from new_table








