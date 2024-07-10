-- == Use sysadmin role ==
use role sysadmin;

-- == Create database ==
create database if not exists clone_db;

-- == Create schema ==
create schema if not exists clone_schema;

-- == Create table ==
create table if not exists clone_db.clone_schema.clone_table(
    id int,
    location string
);

-- == Populate table ==
insert into clone_table values
(1,'USA'),(2,'CAN'),(3,'IND');

-- == Cloning the table above ==
-- == Zero copy cloning --> no new micro-partitions are used but new pointers are created for existing micro-partitions ==
create table clone_table1 clone clone_table;

-- == Select from cloned table ==
-- == Same data as the cloned table ==
select * from clone_table1;

-- == Insert new rows in the base table ==
insert into clone_table values
(4,'AUS'),(5,'UK');

-- == Select from cloned_table ==
-- == No new rows added in the cloned table due to addition of rows in the base table ==
select * from clone_table1;

-- == Insert new rows in the cloned table ==
insert into clone_table1 values (4,'ARG');

-- == Select from base table ==
-- == No new rows added in the base table ==
select * from clone_table;

-- == Use cloning and time travel together ==
-- == Revert to a previous version of base table ==
create table clone_time_travel_table clone clone_table at(offset => -60*5);

-- == Select cloned + time traveled table ==
-- == Contains only 3 rows --> same as initial version of the base table ==
select * from clone_time_travel_table;

-- == Clone database ==
create database clone_db1 clone clone_db;

-- == Show tables ==
-- == Cloning is recursve --> cloning parent object --> clones all the child objects ==
-- == All the three tables present in the base db --> copied in the cloned database ==
use schema clone_schema;
show tables;

-- == Drop cloned database ==
drop database clone_db1;

-- == Drop base database ==
drop database clone_db;



