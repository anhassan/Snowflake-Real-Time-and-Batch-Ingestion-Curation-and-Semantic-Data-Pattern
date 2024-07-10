-- == Use sysadmin role ==
use role sysadmin;

-- == Create custom warehouse with desired configurations ==
-- 1. warehouse size ranges from xsmall to x6large
-- 2. auto_suspend = 300 means that after 300 seconds of in activity the warehouse will get suspended
-- 3. auto_resume = true means that on issuing of a query on the warehouse the warehouse will get resumed if in the state of suspended
-- 4. initially_suspended = true means that after creation of the warehouse, warehouse will get immediately started
create warehouse custom_warehouse
warehouse_size = 'xsmall'
auto_suspend = 300
auto_resume = true
initially_suspended = true;

-- == Use the desired warehouse ==
use warehouse custom_warehouse;
use schema snowflake_sample_data.tpch_sf1000;

-- == Start the initially suspended warehouse ==
alter warehouse custom_warehouse resume;

-- == Show custom warehouse ==
show warehouses;

-- == Manually suspend custom warehouse ==
alter warehouse custom_warehouse suspend;

-- == Show custom warehouse ==
-- == Warehouse state = suspended ==
show warehouses like 'custom_warehouse';


-- == Test the auto resume configuration of the custom warehouse ==
-- == Expected result : suspended custom warehouse should get started on submission of a query ==
select c_custkey,c_name from customer limit 10;

-- == Show custom warehouse ==
-- == Warehouse state = started ==
show warehouses like 'custom_warehouse';

-- == Change warehouse configurations on the fly (even when warehouse is running) ==
alter warehouse custom_warehouse set warehouse_size = 'small';

-- == Show custom warehouse ==
-- == Warehouse configurations changed without any downtime ==
show warehouses like 'custom_warehouse';

-- == Drop custom warehouse ==
drop warehouse custom_warehouse;

