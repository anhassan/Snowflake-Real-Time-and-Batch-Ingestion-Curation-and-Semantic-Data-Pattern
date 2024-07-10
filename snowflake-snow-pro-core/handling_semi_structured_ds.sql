create database semi_structures_db;

use database semi_structures_db;

-- creating a table to hold semi-structured data
create table semi_structures (
 name string,
 counts array,
 address object,
 location variant
);

-- populating data in semi-structured table
-- values does not support constructs therefore use select
insert into semi_structures
select 'john'
,array_construct(1,2,3,4,'x','y','z')
,object_construct('postal_code','M4H1J4','street','365 Church Street','Unit',1812)
,'no_location'::variant;

insert into semi_structures
select 'kevin',
array_construct(9,10,11),
object_construct('no_code',182),
object_construct('lat',78.62,'lon',192.34)

select * from semi_structures;

-- loading semi structured data into a stage
create stage stage_ss;

-- PUT file://C:\\<file_location> @stage_ss auto_compress=false;

-- validating whether the file is in the stage or not
ls @stage_ss;

-- creating file format for reading json file
create file format json_ff type='json', strip_outer_array=true;

-- exploring json data housed in the stage
select $1:id, $1:address from @stage_ss/persons.json (file_format => json_ff) ;

-- exploring the ELT approach
create table elt(
  data variant
);

-- copy data from stage into our raw table using elt approach
copy into elt
from @stage_ss
file_format = json_ff;

-- validatin whether the data reached elt table or not
select * from elt;

-- defrencing elt data
select data:name,data:age,data:email,data:address.city,data:phones from elt;

-- flatten table function
-- expects an array,object or variant to be an input
select * from table(flatten(input => select data:phones from elt limit 1));

-- lateral flatten function
select data:name, data:age, data:email,
value as phone_nums
from elt,
lateral flatten(input=>elt.data:phones)


