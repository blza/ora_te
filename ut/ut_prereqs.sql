create global temporary table ut_report 
( ut_name varchar2( 30 char ) 
  , status varchar2( 30 char ) 
  , caller_type varchar2( 30 char ) 
  , caller_owner varchar2( 30 char ) 
  , caller_name varchar2( 30 char ) 
  , line_number integer
  , order_ integer
) on commit preserve rows;

create or replace view ut_report_deciphered
as 
select substr( regexp_replace( text, '(procedure|function)\s+([a-zA-Z0-9_\$#]+)(\s|\W|$).*', '\2', 1, 0, 'imn' ), 1, 30 ) ut_name
  , substr( status, 1, 10 ) status
  , line_number
  , substr( caller_owner || '.' || caller_name, 1, 61 ) caller
from (
  select s.* 
    , u.caller_owner
    , u.caller_type 
    , u.caller_name 
    , u.line_number
    , u.status
    , u.order_
    , row_number() over ( partition by s.owner, s.name, u.line_number order by line desc ) rn
  from all_source s
  join ut_report u
    on u.caller_owner = s.owner
    and u.caller_type = s.type
    and u.caller_name = s.name
    and s.line <= u.line_number
  where regexp_like( text, '(procedure|function)\W+(\w+)', 'imn' )
    and s.type like 'PACKAGE BODY'
) 
where rn = 1
order by order_;