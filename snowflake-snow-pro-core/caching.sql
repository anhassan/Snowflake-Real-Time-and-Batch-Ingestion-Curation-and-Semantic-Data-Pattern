-- == Types of Cache ==
-- == 1. Metadata cache (does not require warehouse) ==
-- == 2. Result set cache ==
-- == 3. Local SSD warehouse cache ==

-- == Use role sysadmin ==
use role sysadmin;

-- ======= META DATA CACHE =======

-- == Suspend the compute_wh (default) warehouse ==
alter warehouse compute_wh suspend;

-- == Turn of auto_resume config of the compute_wh (default) warehouse ==
alter warehouse set auto_resume = false;

-- == Show compute_wh (default) warehouse configurations ==
show warehouses like 'compute_wh';

-- == use desired schema ==
use schema snowflake_sample_data.tpch_sf1000;

-- == Find row counts ==
select count(*) from customer;

-- == Use context function ==
select current_time();

-- == Use object descriptions ==
describe table customer;

-- == Use object listers ==
show tables;

-- == Use system defined functions ==
select system$clustering_information('lineitem');

-- == Select some rows from the table ==
-- == does not use metadata cache and therefore query execution requires warehouse ==
select * from customer;

-- =========== RESULT SET CACHE ============

-- == Start the suspended warehouse ==
alter warehouse compute_wh resume if suspended;

-- == Set auto_resume configuration to be true ==
alter warehouse compute_wh set auto_resume = true;

-- == Issuing a query ==
-- == Local disk I/O --> very less & Remote disk I/O --> very large ==
-- == Query execution time : 32 seconds ==
select c_name, c_address from customer;

-- == Issuing the same query ==
-- == Query execution time : 65 milli seconds ==
-- == Query details : result resue ==
select c_name, c_address from customer;

-- == Issuing sligthly different query ==
-- == Local disk I/O --> very less & Remote disk I/O --> very large ==
-- == Query execution time : 30 seconds ==
-- == Result set cache not used ---> not identical query used ==
select c_address,c_name from customer;

-- == Use time context functions ==
-- == Query execution time : 182 ms ==
select c_nationkey , current_time() from customer limit 100;

-- == Same query but since time context functions are used, result set cache -> not used ==
-- == Query execution time : 117 ms ==
select c_nationkey, current_time() from customer limit 100;

-- == Use accountadmin role ==
use role accountadmin;

-- == Disable result set cache ==
alter account set use_cached_result = false;

-- ======= Virtual Warehouse Local SSD Cache ============

-- == Issuing a query ==
-- == Query exection time: 16 seconds ==
-- == Remote disk I/O = 78% ==
select c_phone from customer;

-- == Issuing the same query ==
-- == Query execution time: 15 seconds ==
-- == Remote disk I/O = 45% ==
-- == Reduced execution time and Remote disk I/O ---> warehouse local cache ==
select c_phone from customer;

-- == Issuing a bit different but overlapping (some part common as above query) query ==
-- == Remote disk I/O = 59% (less than 78%) --> warehouse local cache ==
select c_phone,c_mktsegment from customer;

-- == Suspend warehouse ==
alter warehouse compute_wh suspend;

-- == Resume warehouse ==
alter warehouse compute_wh resume;

-- == Issuing the exact same query as above ==
-- == Query execution time : 16 seconds ==
-- == Remote disk I/O = 87% --> warehouse local cache --> not used ==
select c_phone from customer;

-- == Use accountadmin role ==
use role accountadmin;

-- == Enable result set cache ==
alter account set use_cached_result = true;

-- == Key takeaways ==
-- == 1. Metadata cache --> does not use virtual warehouse + works for count rows, describe,
-- ==    show, system defined & context functions / operations
-- == 2. Result set cache --> works in the case of syntactically identical queries which do not use time context functions ==
-- == 3. Local warehouse cache --> works if warehouse is not restarted, does not require identical queries


