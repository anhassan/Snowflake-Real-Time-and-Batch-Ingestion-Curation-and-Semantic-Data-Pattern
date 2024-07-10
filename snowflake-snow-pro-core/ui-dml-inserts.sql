-- == Use sysadmin role ==
use role sysadmin;

-- == Create database ==
create database if not exists dml_db;

-- == Create schema ==
create schema if not exists dml_schema;

-- == Create table (original) ==
create table if not exists dml_table_orig (
    id int,
    location string
)

-- == Create table (copy/clone) ==
create table dml_table_clone clone dml_table_orig;

-- == Insert DML options ==
-- == 1. Insert using SELECT ==
-- == 2. Insert using VALUES ==
-- == 3. Insert values for particular columns ==
-- == 4. Insert values for multiple rows
-- == 5. Insert rows from a particular table with particular filters ==
-- == 6. Insert and overwrite (truncate and load) ==

-- == Insert using SELECT statement ==
insert into dml_table_orig select 1, 'USA';

-- == Insert using VALUES statement ==
insert into dml_table_orig values (2,'CAN');

-- == Insert values for a particular columns ==
insert into dml_table_orig (id) values (3);

-- == Insert values for multiple rows ==
insert into dml_table_orig values
(4,'IND'),(5,'AUS'),(6,'KSA');

-- == Insert rows from a particular table with particular filters ==
insert into dml_table_clone select * from dml_table_orig where location is not null;

-- == Verify results ==
select * from dml_table_clone;

-- == Insert and overwrite ==
insert overwrite into dml_table_clone values (1,'IND');

-- == Verify results ==
select * from dml_table_orig;
select * from dml_table_clone;

-- == Drop created tables ==
drop table dml_table_orig;
drop table dml_table_clone;

-- == Drop created schema ==
drop schema dml_schema;

-- == Drop created database ==
drop database dml_db;
