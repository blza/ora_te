create or replace PACKAGE BODY PK_TE_UT AS
/**
* Unit tests for pk_te package
* @headcom
*/

/** Gets calling module info including owner, type, name, line at desired call stack depth 
* The refactored version of one that
* <a href="http://tkyte.blogspot.com/2009/10/httpasktomoraclecomtkytewhocalledme.html">Tom Kyte wrote<a>
*
* @param a_desired_depth the depth in the call stack from this function and up <br/> 
* So say providing 2 as a depth we can get not the caller of GET_CALLER_INFO but the caller of the function that called GET_CALLER_INFO
* @param a_real_depth returns the real depth if it's less then desired
* @param a_caller_type returns caller type ('PACKAGE', 'PACKAGE BODY', etc.)
* @param a_caller_owner returns caller owner
* @param a_caller_name returns caller name
* @param a_line_number returns caller line number
*/
procedure GET_CALLER_INFO( 
  a_desired_depth in pls_integer
  , a_real_depth out pls_integer
  , a_caller_type out varchar2
  , a_caller_owner out varchar2
  , a_caller_name out varchar2
  , a_line_number out pls_integer
)
AS
  v_rowDelimPos pls_integer;
  v_rowStartingPos pls_integer := 1;
  v_line varchar2( 32767 char );
  ROW_DELIMITER constant varchar2( 30 char ):= chr(10);
  ROW_DELIMITER_LEN constant pls_integer := Length( ROW_DELIMITER );
  v_call_stack varchar2( 32767 char ) := dbms_utility.format_call_stack();
  v_found_level_0_title boolean := false;
  v_type_and_name varchar2( 32767 char );
  v_caller_and_owner varchar2( 32767 char );
  v_dot_pos pls_integer;
BEGIN
  
  if ( a_desired_depth is null ) then
    return;
  end if;
  a_real_depth := 0;
  if ( v_call_stack is null ) then
    return;
  end if;
  
  loop  
    v_rowDelimPos := InStr( v_call_stack, ROW_DELIMITER, v_rowStartingPos );
    if ( 0 = v_rowDelimPos ) then
      v_line := SubStr( v_call_stack, v_rowStartingPos );
    else
      v_line := SubStr( v_call_stack, v_rowStartingPos, v_rowDelimPos - v_rowStartingPos  );
    end if;
    exit when v_line is null;

    if ( not v_found_level_0_title ) then
      if ( v_line like '%handle%number%name%' ) then
        v_found_level_0_title := true;
      end if;
    else
      a_real_depth := a_real_depth + 1;  

      if ( a_desired_depth = a_real_depth ) then
        
        a_line_number := to_number( regexp_replace( v_line, '^.*\s+(\d+)\s+.*$', '\1' ) );
        v_type_and_name := regexp_replace( v_line, '^.*\s+(\d+)\s+(.*)$', '\2' );
        
        if ( v_type_and_name not like 'anonymous block%' ) then 
          
          v_caller_and_owner := regexp_replace( v_type_and_name , '^.*\s(.*)$', '\1' );
          if ( v_caller_and_owner = v_type_and_name ) then
            a_caller_type := 'TRIGGER';
          else
            a_caller_type := upper( regexp_replace( v_type_and_name , '^(.*)\s.*$', '\1' ) );
          end if;
          v_dot_pos := instr( v_caller_and_owner, '.', 1 );
          if ( 0 = v_dot_pos ) then
            a_caller_name := v_caller_and_owner;
          else
            a_caller_name := upper( regexp_replace( v_caller_and_owner, '^.+\.(.+)$', '\1' ) ); 
            a_caller_owner := upper( regexp_replace( v_caller_and_owner, '^(.+)\..+$', '\1' ) );
          end if;
        else
          a_caller_type := 'ANONYMOUS BLOCK'; 
        end if;
        
        exit;      
      
      end if;
    end if;
      
    if ( 0 = v_rowDelimPos ) then
      exit;
    end if;
    
    v_rowStartingPos := v_rowDelimPos + ROW_DELIMITER_LEN;
  end loop;
  return;
END;


/** Accert procedure. Is to be called from unit test functions. Automatically gets caller info and stores<br/>
* it and the result of accertion in ut_report table. As all unit tests are Package body procedures their name can only<br/>
* be infered during analysis of package body source code. This analysis is done when accessing ut_report_deciphered view
* @param a accertion as a boolean value. If accertion is true, 'Passed' is inserted in ut_report along with caller info, 'Failed' otherwise.
*/
procedure assert( a in boolean ) as 
  desired_depth pls_integer := 3;
  v_real_depth binary_integer;
  v_caller_type varchar2( 32767 char );
  v_caller_owner varchar2( 32767 char );
  v_caller_name varchar2( 32767 char );
  v_line_number binary_integer;
  STRIKE constant varchar2( 100 char ) := rpad( '-', 100, '-' );
  v_status varchar2( 30 char );
  v_order pls_integer;
begin 
  get_caller_info(
    a_desired_depth => desired_depth,
    a_real_depth => v_real_depth,
    a_caller_type => v_caller_type,
    a_caller_owner => v_caller_owner,
    a_caller_name => v_caller_name,
    a_line_number => v_line_number
  );
  
  if ( a ) then 
    v_status := 'Passed';
  else 
    v_status := 'Failed';
  end if;
  
  select nvl( max( order_ ), 0 ) + 1
  into v_order
  from ut_report 
  ;
  
  insert into ut_report( ut_name, status, caller_type, caller_owner, caller_name, line_number, order_ )
  values ( 
    null
    , v_status
    , v_caller_type
    , v_caller_owner
    , v_caller_name
    , v_line_number
    , v_order
  );
  commit;

end;


/** Prints values stored in pk_te.m nested table of nested tables of varchar.
* Only pk_te.p having 2 elements ( key => value ) are considered appropriate
* @param a_map a map to print contents of
*/
procedure print_map( a_map in pk_te.m ) as 
  v_p pk_te.p;
begin
  if a_map is empty then
    dbms_output.put_line( 'map is empty' );
    return;
  end if;
  for idx in a_map.first .. a_map.last loop
    v_p := a_map( idx );
    if ( v_p is not null and v_p is not empty and v_p.count = 2 ) then 
      dbms_output.put_line( v_p( 1 ) || '=>' || v_p( 2 ) );
    end if;
  end loop;
end;

--
-- Number self explanatory unit tests
--

procedure numbered_straight as
  v_te ty_te;
  v_clob clob;
begin
  v_te := ty_te.compile_numbered( '$4''ve been $1 $2 for $o $3' );
  v_clob := pk_te.substitute( v_te, pk_te.p( 'missing', 'you', 'long.', 'I') );
  assert( v_clob = 'I''ve been missing you for $o long.' );
end;

procedure numbered_user_start as
  v_te ty_te;
  v_clob clob;
begin
  v_te := ty_te.compile_numbered( '##4''ve been ##1 ##2 for $o ##3', '##' );
  v_clob := pk_te.substitute( v_te, pk_te.p( 'missing', 'you', 'long.', 'I') );
  assert( v_clob = 'I''ve been missing you for $o long.' );
end;


procedure numbered_repeated as
  v_te ty_te;
  v_clob clob;
begin
  v_te := ty_te.compile_numbered( '$4''ve been $1 $2 for $3 $3 long' );
  v_clob := pk_te.substitute( v_te, pk_te.p( 'missing', 'you', 'so', 'I') );
  -- 
  assert( v_clob = 'I''ve been missing you for so so long' );
end;


procedure skipped_$2_null_in_map as
  v_te ty_te;
  v_clob clob;
begin
  v_te := ty_te.compile_numbered( 'I''ve been $1 $3 for so $4.' );
  v_clob := pk_te.substitute( v_te, pk_te.p( 'missing', null ,'you', 'long') );

  assert( v_clob = 'I''ve been missing you for so long.' );
end;

procedure no_$_templates_numbered as
  v_te ty_te;
begin
  v_te := ty_te.compile_numbered( 'I''ve been missing you for so long' );
  assert( v_te is null );
end;

procedure numbered_$1_follewed_by_$2 as 
  v_te ty_te;
  v_clob clob;
begin
  v_te := ty_te.compile_numbered( 'I''ve been $1$2 for so $3.' );
  v_clob := pk_te.substitute( v_te, pk_te.p( 'missing', ' you', 'long') );

  assert( v_clob = 'I''ve been missing you for so long.' );
end;

procedure numbered_empty_p as 
  v_te ty_te;
  v_clob clob;
begin
  v_te := ty_te.compile_numbered( 'I''ve been $1$2 for so $3.' );
  v_clob := pk_te.substitute( v_te, pk_te.p() );

  assert( v_clob = 'I''ve been  for so .' );
end;

procedure substitute_m_and_numbered as 
  v_te ty_te;
  v_clob clob;
  v_sqlcode pls_integer;
begin
  v_te := ty_te.compile_numbered( 'I''ve been $1$2 for so $3.' );
  begin
    v_clob := pk_te.substitute( v_te, pk_te.m() );  
  exception
    when others then
      v_sqlcode := sqlcode;
  end;
  assert( v_sqlcode = -20998 );
end;


procedure substitute_null_te as 
  v_te ty_te;
  v_clob clob;
  v_sqlcode pls_integer;
begin
  begin
    v_clob := pk_te.substitute( v_te, pk_te.m() );  
  exception
    when others then
      v_sqlcode := sqlcode;
  end;
  assert( v_sqlcode = -20997 );
end;



procedure named_straight as
  v_te ty_te;
  v_clob clob;
begin
  v_te := ty_te.compile_named( '{$i}''ve been {$miSSing} {$you} for $o {$long}.' );
  v_clob := pk_te.substitute( 
    v_te
    , pk_te.m (
      pk_te.p( 'i', 'I' )
      , pk_te.p( 'missing', 'missing' )
      , pk_te.p( 'you', 'you' )
      , pk_te.p( 'long', 'long' )
    )
  );

  assert( v_clob = 'I''ve been missing you for $o long.' );
end;


procedure named_repeated as
  v_te ty_te;
  v_clob clob;
begin
  v_te := ty_te.compile_named( '{$i}''ve been {$miSSing} {$you} for {$so} {$so} {$long}.' );
  v_clob := pk_te.substitute( 
    v_te
    , pk_te.m (
      pk_te.p( 'i', 'I' )
      , pk_te.p( 'missing', 'missing' )
      , pk_te.p( 'you', 'you' )
      , pk_te.p( 'long', 'long' )
      , pk_te.p( 'so', 'so' )
    )
  );

  assert( v_clob = 'I''ve been missing you for so so long.' );
end;



procedure dot_in_named_te as
  v_te ty_te;
  v_clob clob;
begin
  v_te := ty_te.compile_named( '{$i}''ve been {$miSSing} {$you} for $o {$long.}' );
  v_clob := pk_te.substitute( 
    v_te
    , pk_te.m (
      pk_te.p( 'i', 'I' )
      , pk_te.p( 'missing', 'missing' )
      , pk_te.p( 'you', 'you' )
      , pk_te.p( 'long', 'long' )
    )
  );

  assert( v_clob = 'I''ve been missing you for $o {$long.}' );
end;


procedure named_missing_in_m as
  v_te ty_te;
  v_clob clob;
begin
  v_te := ty_te.compile_named( '{$i}''ve been {$miSS} {$you} for $o {$long}' );
  v_clob := pk_te.substitute( 
    v_te
    , pk_te.m (
      pk_te.p( 'i', 'I' )
      , pk_te.p( 'missing', 'missing' )
      , pk_te.p( 'you', 'you' )
      , pk_te.p( 'long', 'long' )
    )
  );

  assert( v_clob = 'I''ve been  you for $o long' );
end;


procedure substitute_p_and_named as 
  v_te ty_te;
  v_clob clob;
  v_sqlcode pls_integer;
begin
  v_te := ty_te.compile_named( 'I''ve {$been} $1$2 for so $3.' );
  begin
    v_clob := pk_te.substitute( v_te, pk_te.p() );  
  exception
    when others then
      v_sqlcode := sqlcode;
  end;
  assert( v_sqlcode = -20998 );
end;


procedure named_encapsulated_te as
  v_te ty_te;
  v_clob clob;
begin
  v_te := ty_te.compile_named( '{$i}''ve been {$miS{$soso}Sing} {$you} for $o {$long}' );
  v_clob := pk_te.substitute( 
    v_te
    , pk_te.m (
      pk_te.p( 'i', 'I' )
      , pk_te.p( 'missing', 'missing' )
      , pk_te.p( 'you', 'you' )
      , pk_te.p( 'long', 'long' )
      , pk_te.p( 'soso', 'XXX' )
    )
  );

  assert( v_clob = 'I''ve been {$miSXXXSing} you for $o long' );
end;


procedure named_user_start as
  v_te ty_te;
  v_clob clob;
begin
  v_te := ty_te.compile_named( '{?i}''ve been {?miSSing} {?you} for $o {?long}.', '{?' );
  v_clob := pk_te.substitute( 
    v_te
    , pk_te.m (
      pk_te.p( 'i', 'I' )
      , pk_te.p( 'missing', 'missing' )
      , pk_te.p( 'you', 'you' )
      , pk_te.p( 'long', 'long' )
    )
  );

  assert( v_clob = 'I''ve been missing you for $o long.' );
end;

procedure named_user_start_user_end as
  v_te ty_te;
  v_clob clob;
begin
  v_te := ty_te.compile_named( '[?i]]''ve been [?miSSing]] [?you]] for $o [?long]].', '[?', ']]' );
  v_clob := pk_te.substitute( 
    v_te
    , pk_te.m (
      pk_te.p( 'i', 'I' )
      , pk_te.p( 'missing', 'missing' )
      , pk_te.p( 'you', 'you' )
      , pk_te.p( 'long', 'long' )
    )
  );

  assert( v_clob = 'I''ve been missing you for $o long.' );
end;

procedure subst_num_straight as 
  v_clob clob;
begin
  v_clob := pk_te.substitute( '$4''ve been $1 $2 for $o $3', pk_te.p( 'missing', 'you', 'long.', 'I') );

  assert( v_clob = 'I''ve been missing you for $o long.' );
end;

procedure subst_num_backref as 
  v_clob clob;
begin
  v_clob := pk_te.substitute( '$4''ve been $1 $2 for $o $3', pk_te.p( 'missing', 'you', 'long.', '\1') );

  assert( v_clob = '\1''ve been missing you for $o long.' );
end;

procedure subst_num_null_repl as 
  v_clob clob;
begin
  v_clob := pk_te.substitute( '$4''ve been $1 $2 for $o $3', pk_te.p( null, 'you', 'long.', 'I') );
  assert( v_clob = 'I''ve been  you for $o long.' );
end;

procedure subst_num_no_te_in_map as 
  v_clob clob;
begin
  v_clob := pk_te.substitute( '$4''ve been $1 $2 for $o $3 $5', pk_te.p( null, 'you', 'long.', 'I') );

  assert( v_clob = 'I''ve been  you for $o long. ' );
end;

procedure subst_num_user_start as 
  v_clob clob;
begin
  v_clob := pk_te.substitute( '??4''ve been ??1 ??2 for $o ??3 ??12', pk_te.p( 'missing', 'you', 'long.', 'I'), '??' );

  assert( v_clob = 'I''ve been missing you for $o long. ' );
end;


procedure subst_named_straight as
  v_clob clob;
begin
  v_clob := pk_te.substitute( '{$i}''ve been {$miSSing} {$you} for $o {$long}.' 
    , pk_te.m (
      pk_te.p( 'i', 'I' )
      , pk_te.p( 'missing', 'missing' )
      , pk_te.p( 'you', 'you' )
      , pk_te.p( 'long', 'long' )
    )
  );

  assert( v_clob = 'I''ve been missing you for $o long.' );
end;


procedure subst_named_empty_and_null_p as
  v_clob clob;
begin
  v_clob := pk_te.substitute( '{$i}''ve been {$miSSing} {$you} for $o {$long}.' 
    , pk_te.m (
      pk_te.p( 'i', 'I' )
      , pk_te.p()
      , pk_te.p( 'you', 'you' )
      , null
    )
  );

  assert( v_clob = 'I''ve been  you for $o .' );
end;


procedure subst_named_backref as
  v_clob clob;
begin
  v_clob := pk_te.substitute( '{$i}''ve been {$miSSing} {$you} for $o {$long}.' 
    , pk_te.m (
      pk_te.p( 'i', 'I' )
      , pk_te.p( 'missing', 'missing' )
      , pk_te.p( 'you', '\2' )
      , pk_te.p( 'long', 'long' )
    )
  );

  assert( v_clob = 'I''ve been missing \2 for $o long.' );
end;


procedure subst_named_repeadted as
  v_clob clob;
begin
  v_clob := pk_te.substitute( '{$i}''ve been {$miSSing} {$you} for {$so} {$so} $o {$long}.' 
    , pk_te.m (
      pk_te.p( 'i', 'I' )
      , pk_te.p( 'missing', 'missing' )
      , pk_te.p( 'you', 'you' )
      , pk_te.p( 'long', 'long' )
      , pk_te.p( 'so', 'so' )
    )
  );

  assert( v_clob = 'I''ve been missing you for so so $o long.' );
end;

/** Public package procedure that actually run tests. Test results are stored in ut_report.
*/
procedure run_tests as
begin
  numbered_straight;
  numbered_user_start;
  numbered_repeated;
  skipped_$2_null_in_map;
  no_$_templates_numbered;
  numbered_$1_follewed_by_$2;
  numbered_empty_p;
  substitute_m_and_numbered;
  substitute_null_te;
  named_straight;
  named_repeated;
  dot_in_named_te;
  named_missing_in_m;
  substitute_p_and_named;
  named_encapsulated_te;
  named_user_start;
  named_user_start_user_end;
  subst_num_straight;
  subst_num_null_repl;
  subst_num_no_te_in_map;
  subst_num_user_start;
  subst_named_straight;
  subst_named_empty_and_null_p;
  subst_num_backref;
  subst_named_backref;
  subst_named_repeadted;
end;

END PK_TE_UT;