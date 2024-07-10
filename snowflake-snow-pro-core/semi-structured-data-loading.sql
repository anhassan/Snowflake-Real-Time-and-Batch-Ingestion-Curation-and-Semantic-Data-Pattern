-- == Use sysadmin role ==
use role sysadmin;

-- == Use specified virtual warehouse ==
use warehouse compute_wh;

-- == Create database if not exists ==
create database if not exists semi_struct_db;

-- == Create schema if not exists ==
create schema if not exists semi_struct_schema;

-- == Create storage integration object ==
create storage integration aws_storage_integration
type = external_stage
storage_provider = s3
storage_aws_role_arn = 'arn:aws:iam::211125308281:role/aws-snowflake-external-stage-semi-structure-role'
storage_allowed_locations = ('s3://aws-snowflake-external-stage-semi-structure-ejqdwxm1/input/')
enabled = true;

-- == Describe storage integration to update the aws iam policy to connect snowflake and aws s3 ==
describe storage integration aws_storage_integration;

-- == Create external stage ==
create stage aws_external_stage
url = 's3://aws-snowflake-external-stage-semi-structure-ejqdwxm1/input/'
storage_integration = aws_storage_integration;

-- == List contents of named external stage ==
ls @aws_external_stage;

-- == Create json file format ==
create or replace file format json_file_format
type = 'json';

-- == Create json file format with strip outer array parameter enabled ==
create or replace file format json_file_format_flattened
type = 'json'
strip_outer_array = true;

-- == Create a table for ELT approach ==
create table films_elt (
    json_variant variant
);

-- == Copy data into etl table from external stage - non stripped data ==
copy into films_elt from @aws_external_stage/films.json
file_format = json_file_format;

-- == View the copied denormalized data - non striped ==
select * from films_elt;

-- == Truncate table to remove non striped data ==
truncate table films_elt;

-- == Copy data into elt from external stage - stripped data ==
copy into films_elt from @aws_external_stage/films.json
file_format = json_file_format_flattened;

-- == View the copied denormalized data - stripped ==
select * from films_elt;

-- == Query semi-structured data using (.) notation ==
select json_variant:title::string as movie_title,
       json_variant:actors[0]::string as actor,
       json_variant:release_date::date as release_date
from films_elt;

-- == Query semi-structured data using ([] - bracket) notation ==
select json_variant['title']::string as movie_title,
       json_variant['actors'][0]::string as first_actor,
       json_variant['ratings']['imdb_rating']::double as movie_rating,
       json_variant['release_date']::date as release_date
from films_elt;

-- == Use flatten table function (works on one row of array) == 
select * from table(flatten(input => select array_construct('Canada','USA','Africa')));

-- == Use flatten on actual stage data ==
select * from table(flatten(input => select json_variant:actors from films_elt limit 1));

-- == Use lateral flatten to join the flatten values back to the base table ==
select json_variant:title::string as movie_title,
       json_variant:release_date::date as movie_release_date,
       flat_actors.value::string as movie_actor
from films_elt f_elt,
     lateral flatten(input => f_elt.json_variant:actors) flat_actors;

-- == Create a table for ETL Approach ==
create table if not exists films_etl (
    id string,
    title string,
    release_date date
);

-- == Create a refined table for ETL Approach ==
create table if not exists films_etl_refined (
    id string,
    title string,
    release_date date,
    ratings double
);

-- == Copy data into "films_etl_refined" table after parsing the stage data ==
copy into films_etl_refined from (
    select $1:id::string, $1:title::string,
           $1:release_date::date, $1:ratings:imdb_rating::double
    from @aws_external_stage/films.json
)
file_format = 'json_file_format_flattened';

-- == View the loaded and transformed/casted data ==
select * from films_etl_refined;

-- == Copy data into "films_etl" table using match_by_column_name option without specifying any select statement ==
copy into films_etl from @aws_external_stage/films.json
file_format = json_file_format_flattened
match_by_column_name = case_insensitive;

-- == View the loaded data by column name matching ==
select * from films_etl;

-- == Drop the storage integration ==
drop storage integration aws_storage_integration;

-- == Drop the database ==
drop database semi_struct_db;






