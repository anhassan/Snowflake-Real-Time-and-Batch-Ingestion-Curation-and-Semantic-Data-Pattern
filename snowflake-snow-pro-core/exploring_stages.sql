create database data_stages;

use data_stages;

-- listing a default created user stage
ls @~;
list @~;

-- listing table stages
create table students(
 id int,
 name string,
 enrolled_date date
)

ls @%students;

-- listing a created stage
create stage int_created_stage;

ls @int_created_stage;


-- select from user stage

-- select * ===> does not work for user stage

select $1,$2,$3 from @~; -- get rows of all the files combined

select $1,$2,$3 from @~/employees_data.csv; -- columns are referenced as $column_number

select metadata$filename, metadata$file_row_number,$1,$2,$3 from @~/students_data_diff.csv; --can also get metadata information using metadata


-- select from table stage

select * from @%students;

select metadata$filename,$1 from @%students;

-- select from internal name stage

-- select * ===> does not work for named internal stage

-- creating file formart to skip csv headers
create file format csv_ff type=csv skip_header=1;

-- select with file format defined
select metadata$filename, metadata$file_row_number, $1,$2,$3 from @int_created_stage (file_format => 'csv_ff');

-- select a particular file's content from internal name stage
select metadata$filename, metadata$file_row_number, $1, $2, $3 from @int_created_stage/students_data_diff.csv (file_format => 'csv_ff');

-- select a file through a filter pattern from internal name stage
select metadata$filename, metadata$file_row_number, $1, $2, $3 from @int_created_stage (file_format=>'csv_ff', pattern => '.*[.]csv') 

-- removing data from stages
rm @~/students_data_diff.csv
rm @%students
rm @int_created_stage;






