use role accountadmin;
use warehouse compute_wh;

create database demo_db;
create schema demo_schema;

use database demo_db;
use schema demo_schema;

-- ============== User Defined Functions =================
-- Can be SQL, Python, Javascript, Java based

create or replace function two_times(val int)
returns int
as
$$
    select 2*val as doubled_value
$$;


select two_times(64);

create or replace function add_numbers(val1 int, val2 int)
returns int
as
$$
    select val1 + val2
$$;

select add_numbers(3,11);




create or replace function day_name_on(val int)
returns string
as
$$
    select 'In ' || cast(val as string) || ' days, the day would be ' || dayname(dateadd(day,val,current_date()))
$$;

select day_name_on(7);


create or replace function day_name_on(val int)
returns string
language python
runtime_version = '3.9'
handler = 'get_day_name'
as
$$
def get_day_name(val):
   days = ["monday","tuesday","wednesday","thursday","friday","saturday", "sunday"]
   return  days[val%7]
$$;

select day_name_on(6);


create or replace function day_name_on_abb(val int, abb_type int)
returns string
language python
runtime_version = '3.9'
handler = 'get_day_name_abb'
as
$$
def get_day_name_abb(val,abb_type):
    val -=1
    days = ["monday","tuesday","wednesday","thursday","friday","saturday","sunday"]
    days_abb = ["mon","tue","wed","thu","fri","sat","sun"]
    if abb_type == 1:
        return days_abb[val%7]
    elif abb_type == 0:
        return days[val%7]
$$;

select day_name_on_abb(3,1);
select day_name_on_abb(3,0);

-- ===== External Functions =============


-- ============= Stored Procedures ==================

create table demo_table1(
    id int,
    name string
);

create table demo_table2(
    id int,
    name string
);


-- Solved: Need to refer variables in upper case in the procedure body

create or replace procedure insert_values(TABLE_NAME string)
returns string
language javascript
execute as owner
as
$$
    var sql_stmt = "insert into " + TABLE_NAME + " values (1,'John');";
    snowflake.execute({sqlText : sql_stmt});
    return 'Successful..'
$$;


select * from demo_table1;

call insert_values('demo_table1');
call insert_values('demo_table2');


select * from demo_table1;
select * from demo_table2;


create or replace procedure truncate_all(DATABASE_NAME string, SCHEMA_NAME string)
returns string
language javascript
execute as owner
as
$$
    var logs = []
    var sql_stmt = `show tables in ${DATABASE_NAME}.${SCHEMA_NAME};`
    var results = snowflake.execute({sqlText : sql_stmt});
    while (results.next()){
        var table_name = results.getColumnValue(2)
        truncate_stmt = `truncate table ${DATABASE_NAME}.${SCHEMA_NAME}.${table_name};`
        snowflake.execute({sqlText : truncate_stmt})
        logs.push(`truncated table name : ${table_name} `)
    }
    return logs.join("\n")
    
$$;


call truncate_all('demo_db','demo_schema');


select * from demo_table1;


