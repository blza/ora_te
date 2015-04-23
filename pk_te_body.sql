create or replace PACKAGE BODY PK_TE AS

/** 
* The package that provides functions to substitute values instead of placeholders.
* @headcom
*/

type ty_vchar_to_vchar is table of varchar2( 32767 char ) index by varchar2( 100 char );

/** Replaces numbered placeholders in compiled Template Expression with values from nested table of varchar2 (p).<br/>
* Using <br/>
* <pre>type p is table of varchar2;</pre>
* makes it possible to use some syntactic sugar for defining values to be placed instead of placeholders.<br/>
* So say if we want to substitute $1 for 'Dolly' and $2 for 'back' in template expression <br/>
* 'I said hello, $1, / Well, hello, $1 / It's so nice to have you $2 where you belong'<br/>
* For it we just pass pk_te.p( 'Dolly', 'back' ) into this version of substitute.<br/>
* @param a_te ty_te template expression compiled for numbered placeholders
* @param a_numbered_replacements nested table of varchar2. Holds  values to place instead of placeholders
* @return clob - a large character lob with substituted values (if any)
* @throws  EX_TE_IS_NULL if null template expression is passed
* @throws EX_TE_OF_WRONG_TYPE if passed template expression was compiled for named placeholders
*/
function substitute( a_te in out nocopy ty_te, a_numbered_replacements p ) return clob AS
  v_res clob;
  EL_STRING constant pls_integer := ty_sph.EL_STRING();
  EL_PH_NUMBERED constant pls_integer := ty_sph.EL_PH_NUMBERED();
  EL_PH_NAMED constant pls_integer := ty_sph.EL_PH_NAMED();
  v_sph ty_sph;
BEGIN
  if ( a_te is null ) then
    raise_application_error( CEX_TE_IS_NULL, 'Null template expression passed' );
  end if;
  
  if ( a_te.type_ != ty_te.EL_NUMBERED() ) then
    raise_application_error( CEX_TE_OF_WRONG_TYPE, 'Template expression is of wrong type' );
  end if;
  
  for idx in a_te.compiled_template_.first .. a_te.compiled_template_.last loop
    v_sph := a_te.compiled_template_( idx );
    if ( v_sph is not null ) then
      if ( EL_STRING = v_sph.type_ ) then
        v_res := v_res || v_sph.string_;
      elsif ( EL_PH_NUMBERED = v_sph.type_ ) then
        if ( a_numbered_replacements.exists( v_sph.ph_number ) ) then
          v_res := v_res || a_numbered_replacements( v_sph.ph_number );
        end if;
      end if;
    end if;
  end loop;
  
  RETURN v_res;
END;


/** Replaces named placeholders in compiled Template Expression with values from nested table of nested tables of varchar2 (m).<br/>
* Using <br/>
* <pre>type m is table of p;</pre>
* makes it possible to use syntactic sugar for defining values to be placed instead of placeholders.<br/>
* So say if we want to substitute {$who} for 'Dolly' and {$how} for 'nice' in template expression<br/>
* 'I said hello, {$who}, / Well, hello, {$who} / It's so {$how} to have you back where you belong'<br/>
* we just pass pk_te.m( pk_te.p( 'who', 'Dolly' ), pk_te.p( 'how' , 'back' ) ) into this version of substitute function.
* @param a_te ty_te template expression compiled for named placeholders
* @param a_named_replacements a nested table of nested tables of varchar2 - named values to place instead of placeholders
* @return clob - a large character lob with substituted values (if any)
* @throws EX_TE_IS_NULL if null template expression is passed
* @throws EX_TE_OF_WRONG_TYPE if passed template expression was compiled for numbered placeholders
*/
function substitute( a_te in out nocopy ty_te, a_named_replacements m ) return clob 
AS
  v_res clob;
  EL_STRING constant pls_integer := ty_sph.EL_STRING();
  EL_PH_NUMBERED constant pls_integer := ty_sph.EL_PH_NUMBERED();
  EL_PH_NAMED constant pls_integer := ty_sph.EL_PH_NAMED();
  v_sph ty_sph;
  v_dict ty_vchar_to_vchar; 
  v_p p;
BEGIN
  if ( a_te is null ) then
    raise_application_error( CEX_TE_IS_NULL, 'Null template expression passed' );
  end if;
  
  if ( a_te.type_ != ty_te.EL_NAMED() ) then
    raise_application_error( CEX_TE_OF_WRONG_TYPE, 'Template expression is of wrong type' );
  end if;
  -- Make associative array from provided map
  for idx in a_named_replacements.first .. a_named_replacements.last loop
    v_p := a_named_replacements( idx );
    if ( v_p is not null and v_p is not empty and v_p.count = 2 ) then 
      v_dict( v_p( 1 ) ) := v_p( 2 );
    end if;
  end loop;
  
  for idx in a_te.compiled_template_.first .. a_te.compiled_template_.last loop
    v_sph := a_te.compiled_template_( idx );
    if ( v_sph is not null ) then
      if ( EL_STRING = v_sph.type_ ) then
        v_res := v_res || v_sph.string_;
      elsif ( EL_PH_NAMED = v_sph.type_ ) then
        if ( v_dict.exists( v_sph.ph_name ) ) then
          v_res := v_res || v_dict( v_sph.ph_name );
        end if;
      end if;
    end if;
  end loop;
  
  RETURN v_res;
END;


/** Substitutes values from p without 'compiling' template expression
* @param a_string a string representing not compiled template expression having numbered placeholders
* @param a_numbered_replacements a nested table of varchar2 - values to place instead of placeholders
* @param a_ph_start a string that denotes the beginning of numbered placeholder
* @return clob - a large character lob with substituted values (if any)
*/
function substitute( a_string in clob, a_numbered_replacements p, a_ph_start in varchar2 := '$' ) return clob as
  v_res clob;
  v_pattern_head varchar2( 30 char ); 
begin
  if ( a_string is null or a_ph_start is null ) then
    return null;
  end if;
  v_pattern_head := ty_te.escape_regexp_special( a_ph_start );
  if ( a_numbered_replacements is null ) or ( a_numbered_replacements is empty ) then
    return regexp_replace( a_string, v_pattern_head || '\d+', '' );
  end if;
  v_res := a_string;
  for idx in a_numbered_replacements.first .. a_numbered_replacements.last loop
    if ( a_numbered_replacements.exists( idx ) ) then
      v_res := regexp_replace( 
        v_res
        , v_pattern_head || to_char( idx ) || '(\D|$)'
        , ty_te.escape_backreference( a_numbered_replacements( idx ) ) || '\1'
        , 1
        , 0
        , 'imn' 
      );
    end if;
  end loop;
  -- Replace remaining template expressions with an empty string
  return regexp_replace( v_res, v_pattern_head || '\d+', '' );
end;

/** Substitutes values from m without 'compiling' template expression
* @param a_string a string representing not compiled template expression having named placeholders
* @param a_named_replacements a nested table of nested tables of varchar2 - named values to place in placeholders
* @param a_ph_start a string that denotes the beginning of named placeholder
* @param a_ph_end a string that denotes the end of named placeholder
* @return clob - a large character lob with substituted values (if any)
*/
function substitute( a_string in clob, a_named_replacements m, a_ph_start in varchar2 := '{$', a_ph_end in varchar2 := '}' ) return clob 
as
  v_res clob;
  v_pattern_head varchar2( 30 char );
  v_pattern_tail varchar2( 30 char );
  v_p p;
begin
  if ( a_string is null or a_ph_start is null or a_ph_end is null ) then
    return null;
  end if;
  v_pattern_head := ty_te.escape_regexp_special( a_ph_start );
  v_pattern_tail := ty_te.escape_regexp_special( a_ph_end );
  if ( a_named_replacements is null ) or ( a_named_replacements is empty ) then
    return regexp_replace( a_string, v_pattern_head || '\w+' || v_pattern_tail, '' );
  end if;

  v_res := a_string;
  for idx in a_named_replacements.first .. a_named_replacements.last loop
    v_p := a_named_replacements( idx );
    if ( v_p is not null and v_p is not empty and v_p.count = 2 ) then 
      -- Case insensitive replace
      v_res := regexp_replace( 
        v_res, v_pattern_head || v_p( 1 ) || v_pattern_tail, ty_te.escape_backreference( v_p( 2 ) ), 1, 0, 'i' 
      );
    end if;
  end loop;
  -- Replace remaining template expressions with an empty string
  return regexp_replace( v_res, v_pattern_head || '\w+' || v_pattern_tail, '' );
end;


END PK_TE;