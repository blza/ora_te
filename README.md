# ora_te
## Description
Simple template engine for Oracle DBMS in a form of UDTs and packages.

This project is about developing a template engine to be used in Oracle SQL/PL SQL.

## Where it excels?

Consider following example code for generating merge statement
```plsql
declare
  v_te ty_te;
  v_merge_stmt varchar2( 32767 char );
  v_join_by varchar2( 30 char ) := 'id_';
  v_dest_tbl varchar2( 30 char ) := 'dummy_test';
begin
  v_te := ty_te.compile_named( '
merge into {$dest_table} t1
using {$tmp_table} t2
  on ( t1.{$join_by} = t2.{$join_by} )
when matched then 
update set {%1%t1.{$column_name} = t2.{$column_name}%\r\n  , %}
delete where t2.status_code = ''D''
when not matched then 
insert( {$join_by}
  , {%1%{$column_name}%\r\n  , %}
) values ( {$seq_name}.nextval
  , t2.{$join_by}
  , {%1%t2.{$column_name}%\r\n  , %}
) 
where t2.status_code <> ''D''
' );
  v_join_by := 'id_';
  select pk_te.substitute( 
      v_te
      , ty_m( 
        ty_p( 'dest_table', v_dest_tbl )
        , ty_p( 'tmp_table', 'tmp_dummy_test' ) 
        , ty_p( 'join_by', v_join_by ) 
        , ty_p( 'seq_name', 'seq_dummy_id' )
      )
      , cursor ( 
        select ty_m( ty_p( 'column_name', column_name ) )
        from user_tab_columns 
        where table_name like upper( v_dest_tbl ) 
          and column_name not like upper( v_join_by )
      )
    )
  into v_merge_stmt 
  from dual
  ;
  dbms_output.put_line( v_merge_stmt );
end;
```
And the result for given arbitrary table
```
desc dummy_test
Name Null     Type              
---- -------- ----------------- 
ID_  NOT NULL NUMBER(38)        
COL1          VARCHAR2(30 CHAR) 
COL2          NUMBER(38) 
```
will be
```sql
merge into dummy_test t1
using tmp_dummy_test t2
  on ( t1.id_ = t2.id_ )
when matched then
update set t1.COL1 = t2.COL1
  , t1.COL2 = t2.COL2
delete where t2.status_code = 'D'
when not matched then 
insert( id_
  , COL1
  , COL2
) values ( seq_dummy_id.nextval
  , t2.id_
  , t2.COL1
  , t2.COL2
) 
where t2.status_code <> 'D'
```

Yes, this is where `ora_te` stands out. With the help of `ora_te` it becomes very convinient to dynamically generate dynamic SQL statements and other costructs at runtime. 

It improves development speed, code readability and maintainability. 

As functionality is cut to the bone it also has small learning curve.

## Compatibility and requirements.
Developed for and tested on Oracle 11r2.

UDTs and the packages are self contained, no additional dependencies. Only one sequence is created during deployment. You only have to have Resource role to deploy `ora_te`.

## Installation
Just download all files and run `deploy_te.sql` from the root directory.

## Documentation
For usage see https://github.com/blza/ora_te/wiki .
For packages and UDTs specifications see `doc` folder.

## Regression testing
Unit tests can be found in ut subdirectory.

To deploy unit tests run `ut/deploy_ut.sql`.
To actually run unit tests run `ut/run_tests.sql`.

## Imposed cost of invocation
Profiling info and comparison to standart concat are to come.

## Licence
Mit licence applies (http://opensource.org/licenses/MIT).
