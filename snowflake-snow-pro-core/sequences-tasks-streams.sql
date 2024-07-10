use role accountadmin;
use warehouse compute_wh;

create database if not exists demo_db;
use database demo_db;

create schema if not exists demo_schema;
use schema demo_schema;

-- ====== sequences ====
create sequence seq start = 50 increment = 5;

select seq.nextval;

-- ======= creating tables with auto-incrementing feature =======
create sequence seq_id start = 1 increment = 1;

create table ingestion_table (
    id int default seq_id.nextval,
    source string
);

insert into ingestion_table (source) values
('SAP'),
('SFMC'),
('Salesforce'),
('Oracle');

select * from ingestion_table;

-- ========= streams ============
-- Stream enable us to get CDC (DELTA) on the base table

create table base_table(
    id int,
    name string
);

insert into base_table values
(1,'A'),(2,'B'),(3,'C');

create stream base_table_cdc on table base_table;

select * from base_table_cdc;

insert into base_table values
(4,'D'),(5,'E'),(6,'F');

select * from base_table;
select * from base_table_cdc;

-- === Copying changes from stream table to another table removes them from the stream (this is known as stream progression)
create table copy_base_table_cdc as 
select * from base_table_cdc;

select * from copy_base_table_cdc;
select * from base_table_cdc; -- no records found in this stream after copying them to another table

insert into base_table values
(7,'G'),(8,'H'),(9,'I');

select * from base_table;
select * from base_table_cdc;

CREATE TASK T1
WAREHOUSE = MYWH
AS
COPY INTO MY_TABLE
FROM $MY_STAGE;

-- ========= tasks ==========
-- Tasks are used to schedule a particular task in snowflake
create table task_table (
    id int,
    name string
);

create stream task_stream on table task_table;

insert into task_table values (1,'A-000000');
insert into task_table values (1,concat('A',to_varchar(current_timestamp())));

select * from task_table;
select * from task_stream;

-- ====== Task Creation ========
create task insert_task
warehouse = compute_wh
schedule = '1 MINUTE'
as
insert into task_table values (2,concat('A-',to_varchar(current_timestamp())));

-- ======== Start the Task ==========
alter task insert_task resume;

select * from task_table;
select * from task_stream;

-- ======= Stop the Task =========
alter task insert_task suspend;




