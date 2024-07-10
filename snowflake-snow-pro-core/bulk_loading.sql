-- load is called bulk if copy into command is called manually by a user 
-- to copy data from a stage to a table

-- using databases and stages from exploring stages worksheet

use database data_stages;

ls @int_created_stage;

select metadata$filename, metadata$file_row_number, $1, $2, $3 from @int_created_stage;

-- defining a table with no metadata
create table students_no_meta (
   id int,
   name string,
   enrolled_date date
);

-- defining a table on which file format will be added
create table students_ff(
 id int,
 name string,
 enrolled_date date
);

-- defining a table for checking validation with validation_mode (dry run)
create table students_validation(
 id int,
 name string,
 enrolled_date date
);

-- defining a table with metadata
create table students_bulk_load (
  file_name string,
  row_num int,
  id int,
  name string,
  enrolled_date date
);

-- bulk load from stage to table : students_bulk_load ==> fails due to no file format (skips header)
copy into students_no_meta from @int_created_stage/students_data_diff.csv;

-- file format inside copy command
copy into students_no_meta from @int_created_stage/students_data_diff.csv 
file_format = (type = csv, skip_header=1);

select * from students_no_meta order by id;

-- file format applied to stage
alter stage int_created_stage set file_format = 'csv_ff';
copy into students_no_meta from @int_created_stage force = true;

select * from students_no_meta order by id;

-- file format added to the table
alter table students_ff set stage_file_format='csv_ff';
copy into students_ff from @~/students_data_diff.csv;

select * from students_ff order by id;

-- == COPY options ==

--1. copy with choosen number of files from stage; max number of files used through this option = 1000 files
copy into students_no_meta from @~ 
file_format = 'csv_ff'
files=('students_data_diff.csv')
force = true;

--2. copy from stage into table using a pattern
copy into students_no_meta from @int_created_stage
file_format = 'csv_ff'
pattern = '.*[.]csv'
force = true;

--3. copy from stage after transforming(casting,column order change,custom transformation) the stage data
copy into students_bulk_load from (
  select concat('filename:',metadata$filename), metadata$file_row_number, $1, $2, $3
  from @int_created_stage
)
file_format = 'csv_ff';

select * from students_bulk_load;

-- validation stratergies

-- 1. validation before the copy commnad (dry run)
copy into students_validation from @~
file_format = (type='csv',skip_header=0)
files = ('students_data_diff.csv')
validation_mode = 'return_errors';

--2. get validation result of a failed query run
copy into students_no_meta from @int_created_stage
file_format = (type='csv',skip_header=0)
files = ('students_data_diff.csv')
on_error=continue
force = true;

-- get the error details of the failed query id
select * from table(validate(students_no_meta,job_id=>'01b46764-3201-3b13-0000-0005734e46ed'));


-- drop created tables
drop table students_bulk_load;
drop table students_ff;
drop table students_validation;
drop table students_no_meta;




