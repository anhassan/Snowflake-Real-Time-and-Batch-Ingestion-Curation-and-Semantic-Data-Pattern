-- == Use sysadmin role ==
use role sysadmin;

-- == Use default warehouse ==
use warehouse compute_wh;

-- == Create database ==
create database if not exists external_stage_db;

-- == Create schema ==
create schema if not exists external_stage_shema;

-- == Create table ==
create table if not exists stage_table (
    id int,
    location string
)

-- == Exploring internal stages ==
-- == Three types of internal stages --> [user stage, table stage, named stage]

-- == User stage ==
ls @~;

-- == Table stage ==
ls @%stage_table;

-- == Named stage (internal) ==
create stage internal_named_stage;
ls @internal_named_stage;


-- == Exploring external stages ==

-- == Create aws role ==
-- == 1. Choose 'AWS Account' as the trusted entity type == 
-- == 2. Choose option of 'Require External Id' and populate external id with '0000' (any dummy value) ==
-- == 3. Choose a policy giving full access to S3 ==
-- == 4. Create role and copy it's arn ==
-- == 5. Provide iam role arn to the storage integration as a parameter ==

-- == Link blob storage (s3) with snowflake ==
-- == Aws side ---> iam role arn --> role should have access to s3
-- == Snowflake ---> [external id & storage_aws_iam_user_arn] 
-- == --> update these in the trusted entities of the role created above (use desc storage integration <name> to find this) ==

-- == Create storage integration ==
create storage integration aws_storage_integration
type = external_stage
storage_provider = s3
enabled = true
storage_aws_role_arn = 'arn:aws:iam::891377113823:role/SnowFlakeStorageIntergationRole'
storage_allowed_locations = ('s3://snow-flake-external-stage-ejqdwxm/raw/')

-- == Create external stage ===
create stage aws_external_stage
url = 's3://snow-flake-external-stage-ejqdwxm/raw/'
storage_integration = aws_storage_integration

-- == List the contents of external stage ==
ls @aws_external_stage;

-- == Select csv file contents from external stage ==
select $1 from @aws_external_stage/iot/test.csv;

-- == Create file format for reading stage data ==
create file format csv_ff
type = csv
skip_header = 1;

-- == Select csv file contents from stage using file format ==
select $1 from @aws_external_stage/iot/test.csv (file_format => 'csv_ff');

-- == Select csv file contents along with metadata from stage using file format and selection pattern ==
select metadata$filename, metadata$file_row_number, $1 from @aws_external_stage/iot/test.csv (file_format=>'csv_ff',pattern => '.*[.]csv')

-- == Drop external named stage ==
drop stage aws_external_stage;

-- == Drop storage integration object ==
drop storage integration aws_storage_integration;

-- == Drop internal named stage ==
drop stage internal_named_stage;

-- == Drop internal table stage by dropping table ==
-- == Internal table stage cannot be dropped independently ==
drop table stage_table;

-- == Drop internal user stage ==
-- == User stage cannot be dropped ==

-- == Drop created schema ==
drop schema external_stage_shema;

-- == Drop created database ==
drop database external_stage_db;

-- == Remove files from stage ==
-- == rm <stage_name>/<file_name> ==
-- == example : rm @~/example.json ==

