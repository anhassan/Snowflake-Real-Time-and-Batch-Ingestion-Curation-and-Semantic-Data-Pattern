-- == Use sysadmin role ==
use role sysadmin;

-- == Create database if not exists ==
create database if not exists bulk_load_db;

-- == Create schema if not exists ==
create schema if not exists bulk_load_schema;

-- == Create table if not exists ==
create table if not exists bulk_load_films(
    id string,
    title string,
    release_date date
);

-- == Create storage integration ==
create storage integration aws_storage_integration
type = external_stage
storage_provider = s3
enabled = true
storage_aws_role_arn = 'arn:aws:iam::134819843120:role/aws-s3-external-storage-snowflake-role'
storage_allowed_locations = ('s3://bulk-load-external-stage-snowflake-ejqdwxm/input/');

-- == Get info from storage integration to link snowflake with aws ==
describe storage integration aws_storage_integration;

-- == Create external stage ==
create stage aws_external_stage
url = 's3://bulk-load-external-stage-snowflake-ejqdwxm/input/'
storage_integration = aws_storage_integration;

-- == Load file in the external stage ==
-- == Files Loaded : films.csv and films.json ==


-- == List files in the external stage ==
ls @aws_external_stage;

-- == Query contents of csv file ==
select metadata$filename, metadata$file_row_number, $1, $2, $3 from @aws_external_stage/films.csv;

-- == Create file format for csv files ==
create file format csv_ff
type = csv
skip_header = 1;

-- == Query contents of csv file with file format ==
select $1, $2, $3 from @aws_external_stage/films.csv (file_format => 'csv_ff');

-- == Copy the contents of csv without file format into "bulk_load_films" table created above ==
-- == Read error ---> header not skipped ---> data type issue error (File Format required) ==
copy into bulk_load_films from @aws_external_stage/films.csv;

-- == File Formats can be applied at 3 places ==
-- == 1. At the Copy into level ==
-- == 2. At the stage level ==
-- == 3. At the table level ==

-- == Set the file format at the copy into activity level ==
copy into bulk_load_films from @aws_external_stage/films.csv file_format = 'csv_ff';

-- == Truncate table and apply file format at different place and validate results ==
truncate table bulk_load_films;

-- == Set the file format at stage level ==
alter stage aws_external_stage set file_format = 'csv_ff';

-- == Copy into "bulk_load_films" table after setting file format at the stage level ==
copy into bulk_load_films from @aws_external_stage/films.csv;

-- == Truncate table and apply file format at different place and validate results ==
truncate table bulk_load_films;

-- == Unset file format at stage level ==
create file format csv_ff_0
type = csv
skip_header = 0;

alter stage aws_external_stage set file_format = 'csv_ff_0';

-- == Confirm copy into table fails when no file format specified since the file format on stage is incorrect ==
-- == Error : mismatch in data types ---> header is read due to incorrect file format ==
copy into bulk_load_films from @aws_external_stage/films.csv;

-- == Set file format at the table level ==
alter table bulk_load_films set stage_file_format = (format_name = 'csv_ff');

-- == Copy into table "bulk_load_films" after setting file format at the table level ==
copy into bulk_load_films from @%bulk_load_films/films.csv;

-- Copy into with files option ==
copy into bulk_load_films from @aws_external_stage
files = ('films.csv')
file_format = 'csv_ff'
force = true;

-- == Copy into with pattern option ==
copy into bulk_load_films from @aws_external_stage
pattern = '.*[.]csv'
file_format = 'csv_ff'
force = true;

-- == Copy into with select option ==
copy into bulk_load_films from (
 select $1,$2,$3 from @aws_external_stage/films.csv
)
file_format = 'csv_ff'
force = true;

-- == Copy into with omitting certains columns ==
copy into bulk_load_films(id,release_date) from (
  select $1,$3 from @aws_external_stage/films.csv
)
file_format = 'csv_ff'
force = true;

-- == Copy into with casting columns ==
copy into bulk_load_films from (
    select $1,$2,to_date($3) from @aws_external_stage/films.csv
)
file_format = 'csv_ff'
force = true;

-- == Copy into with re-ordering columns ==
copy into bulk_load_films from (
    select $2,$1,$3 from @aws_external_stage/films.csv
)
file_format = 'csv_ff'
force = true;

-- == Validation Mode option in copy into statement ==
-- == Validation Mode ---> validates the data before actually loading it to the table ==
-- == Validation Mode ---> 3 types ==
-- ==   1. return_n_rows e.g return_5_rows ---> only validates 5 rows for errors and not the rest
-- ==   2. return_errors ---> returns all errors across all files in a stage/location specified in copy into statement
-- ==   3. return_all_errors ---> returns all errors (errors of current load + errors in partial runs of previous loads)

-- == Validation Mode with 'return_errors' as option ==
copy into bulk_load_films from @aws_external_stage/students.csv
validation_mode = 'return_errors';

-- == Validate Table Function --> read erros after data loading ==
-- == Used to see the errors of a query with a given query id ==

-- == Copy into with on_error = 'continue' option ---> Loading data with error ==
copy into bulk_load_films from @aws_external_stage/films.csv
file_format = 'csv_ff_0'
force = true
on_error = 'continue';

-- == Use validate table function to get errors on partial loads given the load query id ==
select * from table(validate(bulk_load_films,job_id=>'01b58622-3201-4c5e-0005-84ee000242f2'));

-- == Drop database created ==
drop database bulk_load_db;

-- == Drop storage integration object ==
drop storage integration aws_storage_integration;

