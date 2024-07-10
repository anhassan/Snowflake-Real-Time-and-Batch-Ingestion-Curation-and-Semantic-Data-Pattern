-- == Use accountadmin role ==
use role accountadmin;

-- == Use the desired warehouse ==
use warehouse compute_wh;

-- == Use the desired database ==
use database snowflake;

-- == Use the desired schema ==
use schema account_usage;

-- == Use the desired view ==
-- == View : warehouse_metering_history ==
select warehouse_name, sum(credits_used) as total_credits
from warehouse_metering_history group by warehouse_name;

-- == Use the view from information schema ==
select * from table(information_schema.warehouse_metering_history(dateadd('days',-7,current_date())));

-- == Create resource monitor ==
-- == Resource monitors --> used to monitor warehouse costs and raise notifactions ==
create or replace resource monitor custom_resource_monitor with credit_quota = 1
triggers
on 50 percent do notify
on 90 percent do suspend
on 100 percent do suspend_immediate;

-- == Add resource monitor to warehouse ==
alter warehouse compute_wh set resource_monitor = custom_resource_monitor;

-- == Show warehouse ==
-- == resource monitor field contains the attached resource monitor ==
show warehouses;
select "name","state","resource_monitor" from table(result_scan(last_query_id()));

-- == Drop resource monitor ==
drop resource monitor custom_resource_monitor;

-- == Show warehouse ==
-- == resource monitor field does not contain the attached resource ==
show warehouses like 'compute_wh';
select "name","state","resource_monitor" from table(result_scan(last_query_id()));

-- == Key takeways ==
-- 1. database = snowflake ; schema = account_usage ; view = warehouse_metering_history can
--    be used to find the credits consumption per warehouse
-- 2. information schema can also be used with view : warehouse_metering_history to find the last 7 days
--    history of warehouse
-- 3. resource monitors can be attached to warehouse to take some actions (notify,suspend warehouse etc) on
--    the specified credit quotas percentages

