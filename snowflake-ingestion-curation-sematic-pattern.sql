-- == Use accountadmin role ==
use role accountadmin;

-- == Use specified compute ==
use warehouse compute_wh;


-- ============================= Database and schema definitions ========================================

-- == Create database if not exists for ingestion layer (elt) ==
create database if not exists ingestion;
use database ingestion;

-- == Create schema if not exists for ingestion layer ==
create schema if not exists bronze;

-- == Create database if not exists for curation layer (etl) ==
create database if not exists curated;
use database curated;

-- == Create schema if not exists for curation layer ==
create schema if not exists silver;

-- == Create database if not exists for semantic layer (etl) ==
create database if not exists semantic;
use database semantic;

-- == Create schema if not exists for semantic layer ==
create schema if not exists gold;


-- ============================= Create tables for all layers ========================================

-- == Create ingestion tables ==
create table if not exists ingestion.bronze.user_data (
    json_variant variant
);

-- == Create curated tables ==
create table if not exists curated.silver.user_transformed (
    name string,
    url string,
    email string,
    country string
);

-- == Create semantic tables ==
create table if not exists semantic.gold.user_country_cnts (
    user_count int,
    country string
);


-- ============================= Setting connectivity between snowflake and aws ========================================

-- == Use ingestion database ==
use database ingestion;

-- == Create storage integration object ==
create or replace storage integration aws_storage_integration
type = external_stage
storage_provider = s3
storage_aws_role_arn = 'arn:aws:iam::891377123177:role/aws-snowflake-external-stage-role'
storage_allowed_locations = ('s3://aws-snowflake-external-stage-ejqdwxm/input/')
enabled = true;

-- == Describe storage integration ==
-- == Populate the principal aws field of the iam role with STORAGE_AWS_IAM_USER_ARN from the describe command ==
-- == Populate sts:ExternalId field of the iam role with STORAGE_AWS_EXTERNAL_ID from the describe command ==
desc storage integration aws_storage_integration;

-- == Create external stage ==
create stage aws_external_stage
url = 's3://aws-snowflake-external-stage-ejqdwxm/input/'
storage_integration = aws_storage_integration;


-- ============================= Ingestion layer jobs ========================================

-- == Create file format for ingestion json data ==
create or replace file format json_ff
type = 'json'
strip_outer_array = true;

-- == Create snowpipe for ingestion streaming data ==
create or replace pipe ingestion.bronze.snowpipe
auto_ingest = true
as
    copy into ingestion.bronze.user_data
    from @ingestion.public.aws_external_stage
    file_format = json_ff;

-- == Describe the created snowpipe ==
-- == Create S3 event notification using notification_channel field from the describe pipe command ==
describe pipe ingestion.bronze.snowpipe;


-- ============================= Curated layer jobs ========================================

-- == Use curated database == 
use database curated;

-- == Set stream for capturing cdc records from ingestion table ==
create or replace stream curated.silver.ingestion_cdc on table ingestion.bronze.user_data;

-- == Create task to copy cdc records from ingestion to curated table ==
create or replace task curated.silver.ingestion_curated_task
warehouse = compute_wh
schedule = '3 minute'
when
    system$stream_has_data('curated.silver.ingestion_cdc')
as
    insert into curated.silver.user_transformed
    select json_variant:name::string as name,
           json_variant:url::string as url,
           json_variant:email::string as email,
           json_variant:country::string as country
    from curated.silver.ingestion_cdc where metadata$action = 'INSERT';

-- == Start the task for ingestion to curated job ==
alter task curated.silver.ingestion_curated_task resume;


-- ============================= Semantic layer jobs ========================================

-- == Use semantic database ==
use database semantic;

-- == Set stream for capturing cdc records from curated table ==
create or replace stream semantic.gold.curated_cdc on table curated.silver.user_transformed;

-- == Create task to aggregate cdc records from curated to semantic table ==
create or replace task semantic.gold.curated_semantic_task
warehouse = compute_wh
schedule = '5 minute'
when
    system$stream_has_data('semantic.gold.curated_cdc')
as
  insert into semantic.gold.user_country_cnts
  select count(*) as user_count,
         country
  from semantic.gold.curated_cdc where metadata$action = 'INSERT'
  group by country;

-- == Start the task for curated to semantic job ==
alter task semantic.gold.curated_semantic_task resume;


-- ============================= Validate results ========================================
select * from ingestion.bronze.user_data;
select * from curated.silver.user_transformed;
select * from semantic.gold.user_country_cnts;


-- ============================= Clean up resources ========================================

-- == Drop databases ==
drop database ingestion;
drop database curated;
drop database semantic;

-- == Drop storage integration ==
drop storage integration aws_storage_integration;

