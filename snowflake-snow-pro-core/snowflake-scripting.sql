use role accountadmin;
use warehouse compute_wh;

create database if not exists demo_db;
use database demo_db;

create schema if not exists demo_schema;
use schema demo_schema;

--====== Snowflake Scripting (anonymous block) ========
declare
    s1 int;
    s2 int;
    hyp int;
begin
    s1 := 3;
    s2 := 4;

    hyp := sqrt(square(s1)+square(s2));
    return hyp;
end;

--===== Snowflake Scripting (Procedure) ============
create or replace procedure pythogras(S1 int,S2 int)
returns float
language sql
as
declare
        hyp float;
begin
        hyp := sqrt(square(S1) + square(S2));
        return hyp;
end;

call pythogras(3,5);
call pythogras(4,4);
call pythogras(3,4);
call pythogras(5,5);

--===== Snowflake Scripting (Branching Constructs)=======
declare
    val int;
begin
    val := 4;
    if (val%2=0) then
        return 'even';
    else
        return 'odd';
    end if;
end;

create or replace procedure even_odd(VAL int)
returns string
language sql
as
declare
    output string;
begin
    if (VAL%2=0) then
        output := 'even number';
    else
        output := 'odd number';
    end if;
    return output;
end;

call even_odd(2);
call even_odd(5);

--======== Snowflake Scripting (Looping Constructs)=============
declare
    end_num int;
begin
    let start_num := 1;
    end_num := 5;
    let total_sum := 0;
    for ind in start_num to end_num do
        total_sum := ind + total_sum;
    end for;
    return total_sum;
end;

create or replace procedure count_nums_loop(START_NUM int, END_NUM int)
returns int
language sql
as
declare
    total_sum int;
begin
    total_sum := 0;
    for ind in START_NUM to END_NUM do
        total_sum := ind + total_sum;
    end for;
    return total_sum;
end;

call count_nums_loop(1,2);
call count_nums_loop(1,102);

---====== Snowflake Scripting (Cursors)========
create table scripting_table(
    id int
);

insert into scripting_table values
(1),(2),(3),(4),(5),(6);

declare
    total_counts int;
    crsr cursor for select * from scripting_table;
begin
    total_counts := 0;
    for record in crsr do
        total_counts := total_counts + record.id;
    end for;
    return total_counts;
end;

---====== Snowflake Scripting (Result Set)==========
declare
    res resultset;
begin
    res := (select id as amount from scripting_table);
    return table(res);
end;


declare
    rs resultset default (select id as amount from scripting_table);
    crsr cursor for rs;
begin
    let total_amount := 0;
    for record in crsr do
        total_amount := record.amount + total_amount;
    end for;
    return total_amount;
end;


declare
    rs resultset;
    crsr cursor for rs;
begin
    let total_counts := 0;
    rs := (select id from scripting_table);
    for record in crsr do
        total_counts := total_counts + record.id;
    end for;
    return total_counts;
end;
    
        
        


