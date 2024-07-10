-- == Query execution details options ==
-- == 1. Query history tab --> contains 14 days of data + cannot be queried
-- == 2. Query profile --> detailed execution plan 
-- == 3. Database : snowflake, schema : account_usage, view : query_history (contains 365 days of data + latency =~ 45 mins)
-- == 4. Information schema , table function --> query_history (contains 7 days of data + no latency)


-- == Use sysadmin role ==
use role sysadmin;

-- == Use desired database and schema ==
use database snowflake_sample_data;
use schema tpch_sf1000;

-- == Query a particular table ==
-- == Explore query execution in query history tab + query profile/details ==
select c_custkey from customer order by c_acctbal limit 10000;

-- == Use accountadmin role ==
use role accountadmin;

-- == Use desired database and schema ==
use database snowflake;
use schema account_usage;

-- == Use query_history view to find 10 longest running queries ==
select query_id,query_text,sum(total_elapsed_time) from query_history 
group by query_id,query_text order by 3 desc limit 10;

-- == Create custom database for getting access to information schema ==
create database if not exists query_analysis_db;

-- == Use information schema of the custom created database ==
use schema query_analysis_db.information_schema;

-- == Use query_history table function to find the 10 longest running queries ==
select query_id,query_text,sum(total_elapsed_time) from table(information_schema.query_history())
group by query_id,query_text order by 3 desc limit 10;

-- == Drop custom created database ==
drop database query_analysis_db;



