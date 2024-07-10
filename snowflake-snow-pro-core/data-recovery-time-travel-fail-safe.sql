-- == Use sysadmin role ==
use role accountadmin;

-- == create database ==
create database if not exists time_travel_db;

-- == create schema ==
create schema if not exists time_travel_schema;

-- == create table ==
create table if not exists time_travel_db.time_travel_schema.table_tt(
    id int,
    location string
);

-- == insert data in table ==
insert into table_tt values
(1,'USA'),(2,'CAN'),(3,'IND');

-- ====== Configuring Time Travel Property =========
-- == This property can be configured by setting "data_retention_time_in_days" on the salesforce object ==

-- == Show default data retention period = 1 day ==
show databases like 'time_travel_db';
select "name","retention_time" from table(result_scan(last_query_id()));

-- == Set data retention period = 90 days on the account level ==
-- == Max retention period allowed in snowflake enterprise and above editions is 90 days and minimum is 0 days
-- == For standard edition, the max retention period allowed is = 1 day
alter account set data_retention_time_in_days = 90;

-- == Confirm whether the database shows updated retention period ==
show databases like 'time_travel_db';
select "name","retention_time" from table(result_scan(last_query_id()));

-- == Update retention period on the database different than that at the account level ==
alter database time_travel_db set data_retention_time_in_days = 45;

-- == Confirm whether the database shows the retention period marked on the database object and not at the account ==
-- == Updated retention period = 45 days ==
show databases like 'time_travel_db';
select "name","retention_time" from table(result_scan(last_query_id()));

-- == See what is the retention period value on the child objects ==
-- == Same as the immediate parent (database and not account object) retention period ==
show schemas like 'time_travel_schema';
select "name" , "retention_time" from table(result_scan(last_query_id()));

-- == Update table retention period = 10 days ==
alter table time_travel_db.time_travel_schema.table_tt set data_retention_time_in_days = 10;

-- == Confirm whether the table got updated with the table object level retention period ==
-- == Updated retention period = 10 days ==
show tables like 'table_tt';
select "name","retention_time" from table(result_scan(last_query_id()));

-- == How to use time travel in snowflake ==
-- == 1. Undrop command
-- == 2. at command (inclusive of the changes of the query id provided) + 3 options (offset,timestamp,statement)
-- == 3. before command (exclusive of the changes of the query id provided) + 1 option (statement)

-- == View history of a table ==
-- == drop_period = null --> table not dropped
show tables history like 'table_tt';
select "name","retention_time","dropped_on" from table(result_scan(last_query_id()));

-- == Drop table ==
drop table table_tt;

-- == View table drop status ==
-- == dropped_on <> null ==
show tables history like 'table_tt';
select "name","retention_time","dropped_on" from table(result_scan(last_query_id()));

-- == Undrop table ==
undrop table table_tt;

-- == View table drop status ==
-- == dropped_on = null ==
show tables history like 'table_tt';
select "name","retention_time","dropped_on" from table(result_scan(last_query_id()));

-- == View tables content ==
select * from table_tt;

-- == Insert additional rows in the table  ==
-- Query id : '01b51b5e-3201-4598-0005-84ee000127f2' ==
insert into table_tt values 
(4,'UK'),(5,'AUS');

-- == Use at command with offset ==
select * from table_tt at(offset => -60*5);

-- == Use at command with statement ==
-- == Includes the 2 inserted rows (inclusive behaviour) ==
select * from table_tt at(statement => '01b51b5e-3201-4598-0005-84ee000127f2');

-- == Use at command with timestamp ==
select * from table_tt at(timestamp => dateadd('minute',-5,current_timestamp()));

-- == Use before command ==
-- == Does not include the 2 inserted rows (exclusive behaviour)
select * from table_tt before(statement => '01b51b5e-3201-4598-0005-84ee000127f2');

-- == Drop database ==
drop database time_travel_db;

-- == Set retention period back to the default period of 1 day ==
alter account set data_retention_time_in_days = 1;







