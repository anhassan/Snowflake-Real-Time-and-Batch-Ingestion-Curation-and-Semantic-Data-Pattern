-- == Use sysadmin role ==
use role sysadmin;

-- == Create multi-cluster warehouse ==
-- == 1. warehouse size varies from xsmall to x6large
-- == 2. auto_suspend = 300 means that after 300 seconds of inactivity the warehouse would automatically suspended
-- == 3. auto_resume = true means that warehouse will be started from a suspended as soon as a query is issued on it
-- == 4. initially_suspended = true means the warehouse would not be started immediately after it's creation
-- == 5. multi cluster warehouse means that its has number of clusters b/w min_cluster_size and max_cluster_size
-- == 6. multiple scaling policies can be used to automatically scale a cluster; allowed values = ['standard','economy']
create or replace warehouse multi_cluster_warehouse
warehouse_size = 'xsmall'
auto_suspend = 300
auto_resume = true
initially_suspended = true
min_cluster_count = 1
max_cluster_count = 3
scaling_policy = 'standard';

-- == Show warehouse properties ==
show warehouses like 'multi%';

-- == Drop multi-cluster warehouse ==
drop warehouse multi_cluster_warehouse;


