-- == Clustering Types ==
-- == 1. Natural clustering --> micro-partitions created in the same order as the ingested data order ==
-- == 2. Automatic clustering --> specify clustering key(s) according to which the data is sorted in micro-partitions +
-- ==                             backgorund process mantains the sorted order after DML queries (inserts,updates,deletes)

-- == Use role sysadmin ==
use role sysadmin;

-- ====== NATURAL CLUSTERING =======

-- == Use a specific database ==
use snowflake_sample_data;

-- == Use a specific schema ==
use schema tpch_sf1000;

-- == Find clustering columns for tables in above schema ==
show tables;
select "name","database_name","cluster_by" from table(result_scan(last_query_id()));


-- == Find clustering information of a table ==
-- == Two system defined functions used : system$clustering_information & system$clustering_depth ==

-- == Use system$clustering_information --> gives info about average depth, average overlap and const partitions ==
select system$clustering_information('lineitem');

-- == Use system$clustering_depth --> gives info about average depth only ==
select system$clustering_depth('lineitem');

-- == Use on system$clustering_information on non clustered table ==
-- == Find clustering information on non clustered table --> error ==
-- == Error : Invalid clustering keys or table CUSTOMER is not clustered ==
select system$clustering_information('customer');

-- == Use clustered field in a filter on a table ==
-- == Queries faster on a clustered column ==
select l_orderkey from lineitem where l_shipdate > '2020-01-01';


-- ======== AUTOMATIC CLUSTERING ==========

-- == Create database ==
create database if not exists ck_db;

-- == Create schema ==
create schema if not exists ck_schema;

-- == Use created database and schema ==
use database ck_db;
use schema ck_schema;

-- === Create table with clustering keys ===
create table if not exists ck_db.ck_schema.ck_table1 (
    id int,
    name string,
    state string
)
cluster by (name,state);

-- == Show clustering columns in table above ==
show tables like 'ck_table1';
select "name","database_name","cluster_by" from table(result_scan(last_query_id()));

-- == Create table with no clustering key ==
create table if not exists ck_db.ck_schema.ck_table2(
    id int,
    name string,
    state string
);

-- == Show clustering column information ==
-- == Cluster by is empty due to no clustering column ==
show tables like 'ck_table2';
select "name","database_name","cluster_by" from table(result_scan(last_query_id()));

-- == Add clustering column to non-clustered table ==
alter table ck_db.ck_schema.ck_table2 cluster by (name);

-- == Show clustering information after adding clustering column ==
-- == Clustering column added in the table definition ==
show tables like 'ck_table2';
select "name","database_name","cluster_by" from table(result_scan(last_query_id()));

-- == Monitoring automatic clustering costs ==

-- == Use accountadmin role ==
use role accountadmin;

-- == Use required database ==
use database snowflake;

-- == Use required schema ==
use schema account_usage;

-- == Use standard view for getting clustering costs ==
-- == View name : automatic_clustering_history ==
select * from automatic_clustering_history;

-- == Use sysadmin role ==
use role sysadmin;

-- == Drop the created database above ==
drop database ck_db;


