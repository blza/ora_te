create or replace PACKAGE BODY PK_TE AS

/** 
* The package that provides functions to substitute values instead of placeholders.
* @headcom 
*/

type ty_vchar_to_vchar is table of varchar2( 32767 char ) index by varchar2( 100 char );

/** Replaces placeholders in compiled Template Expression with values from cursor in iteration.<br/>
* Caches results returned from cursor so there's no need to reopen it if more than one loop structures refering this cursor are defined in template expression.<br/>
* Each individual substitution is concatenated with the following with optional a_concat_by in between.<br/>
* Cursor must return instances of ty_p or ty_m UDTs (depending on ty_te type) otherwise the function will throw. 
*
* @param a_loop_idx loop index (1-9) to select appropriate cache
* @param a_te ty_te compiled template expression
* @param a_cursor a cursor that must return instances of ty_p or of ty_m
* @param a_concat_by if present each individual substitutions are concatenated in a loop with a_concat_by in between
* @param a_c1 a sys_refcursor to be used in loop structure substitution
* @param a_c2 a sys_refcursor to be used in loop structure substitution
* @param a_c3 a sys_refcursor to be used in loop structure substitution
* @param a_c4 a sys_refcursor to be used in loop structure substitution
* @param a_c5 a sys_refcursor to be used in loop structure substitution
* @param a_c6 a sys_refcursor to be used in loop structure substitution
* @param a_c7 a sys_refcursor to be used in loop structure substitution
* @param a_c8 a sys_refcursor to be used in loop structure substitution
* @param a_c9 a sys_refcursor to be used in loop structure substitution
* @param a_p_cache a cache that stores results of cursor fetches returning ty_p instances 
* @param a_m_cache a cache that stores results of cursor fetches returning ty_m instances 
*
* @return clob - a large character lob with substituted values (if any)
*
* @throws EX_TE_IS_NULL if null template expression is passed
* @throws EX_CURSOR_OF_WRONG_TYPE if passed cursor does not return instances of ty_p
* @throws CEX_TE_OF_WRONG_TYPE if passed compiled template expression is not of type ty_te.EL_NUMBERED()
*/
function substitute_( a_loop_idx pls_integer, a_te in ty_te, a_cursor in pk_te.refcur, a_concat_by in varchar2 default null
  , a_c1 in pk_te.refcur, a_c2 in pk_te.refcur, a_c3 in pk_te.refcur, a_c4 in pk_te.refcur, a_c5 in pk_te.refcur, a_c6 in pk_te.refcur, a_c7 in pk_te.refcur, a_c8 in pk_te.refcur, a_c9 in pk_te.refcur  
  , a_p_cache in out nocopy ty_p_cache, a_m_cache in out nocopy ty_m_cache 
) return clob
AS
  v_res clob;
  v_idx pls_integer;
  EL_NUMBERED constant pls_integer := ty_te.EL_NUMBERED();
  EL_NAMED constant pls_integer := ty_te.EL_NAMED();
BEGIN
  if ( a_te is null ) then
    raise_application_error( CEX_TE_IS_NULL, 'Null template expression passed' );
  end if;
  
  if a_te.type_ = EL_NUMBERED then
    if a_p_cache( a_loop_idx ) is empty then
      begin
        fetch a_cursor bulk collect into a_p_cache( a_loop_idx );
      exception 
        when others then 
          if sqlcode = -932 then
            raise_application_error( CEX_CURSOR_OF_WRONG_TYPE, 'Cursor does not return ty_p instance' );
          else
            raise;
          end if;
      end;
    end if;
  else
    if a_m_cache( a_loop_idx ) is empty then
      begin
        fetch a_cursor bulk collect into a_m_cache( a_loop_idx );
      exception 
        when others then 
          if sqlcode = -932 then
            raise_application_error( CEX_CURSOR_OF_WRONG_TYPE, 'Cursor does not return ty_m instance' );
          else
            raise;
          end if;
      end;
    end if;
  end if;
  
  if a_te.type_ = EL_NUMBERED then
    v_idx := a_p_cache( a_loop_idx ).first;
    if v_idx is not null then
      v_res := substitute_( a_te, a_p_cache( a_loop_idx )( v_idx ), a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9, a_p_cache, a_m_cache );
    else 
      goto FIN;
    end if;
    v_idx := a_p_cache( a_loop_idx ).next(v_idx);
    while (v_idx is not null) loop
      v_res := v_res || a_concat_by || substitute_( a_te, a_p_cache( a_loop_idx )( v_idx ), a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9, a_p_cache, a_m_cache );
      v_idx := a_p_cache( a_loop_idx ).next(v_idx);
    end loop;
  else
    v_idx := a_m_cache( a_loop_idx ).first;
    if v_idx is not null then
      v_res := substitute_( a_te, a_m_cache( a_loop_idx )( v_idx ), a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9, a_p_cache, a_m_cache );
    else 
      goto FIN;
    end if;
    v_idx := a_m_cache( a_loop_idx ).next(v_idx);
    while (v_idx is not null) loop
      v_res := v_res || a_concat_by || substitute_( a_te, a_m_cache( a_loop_idx )( v_idx ), a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9, a_p_cache, a_m_cache );
      v_idx := a_m_cache( a_loop_idx ).next(v_idx);
    end loop;
  end if;

<<FIN>>  
  RETURN v_res;
END;


/** Initializes cache with empty collections
* 
* @param a_p_cache a table of nested tables containg ty_p values
* @param a_m_cache a table of nested tables containg ty_m values
*/
procedure init_cache_( a_p_cache in out nocopy ty_p_cache, a_m_cache in out nocopy ty_m_cache ) as
  v_idx pls_integer;
begin
  for v_idx in 1 .. 9 loop
    a_p_cache( v_idx ) := ty_p_tab();
    a_m_cache( v_idx ) := ty_m_tab();
  end loop;
end;


/** Dispatches reqest to substitute cursor values into loop structure to the call of appropriate substitute_ function
*
*/
function dispatch_nested_te_subst_( 
  a_p_cache in out nocopy ty_p_cache, a_m_cache in out nocopy ty_m_cache 
  , a_loop_te in out nocopy ty_te, a_loop_number pls_integer, a_concat_by varchar2
  , a_c1 in pk_te.refcur, a_c2 in pk_te.refcur, a_c3 in pk_te.refcur, a_c4 in pk_te.refcur, a_c5 in pk_te.refcur, a_c6 in pk_te.refcur, a_c7 in pk_te.refcur, a_c8 in pk_te.refcur, a_c9 in pk_te.refcur  
) 
return clob
as
begin
  case
    when a_loop_number = 1 and a_c1 is not null then   
      return substitute_( 1 , a_loop_te, a_c1, a_concat_by , a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9, a_p_cache, a_m_cache );
    when a_loop_number = 2 and a_c2 is not null then   
      return substitute_( 2 , a_loop_te, a_c2, a_concat_by , a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9, a_p_cache, a_m_cache );
    when a_loop_number = 3 and a_c3 is not null then   
      return substitute_( 3 , a_loop_te, a_c3, a_concat_by , a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9, a_p_cache, a_m_cache );
    when a_loop_number = 4 and a_c4 is not null then   
      return substitute_( 4 , a_loop_te, a_c4, a_concat_by , a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9, a_p_cache, a_m_cache );
    when a_loop_number = 5 and a_c5 is not null then   
      return substitute_( 5 , a_loop_te, a_c5, a_concat_by , a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9, a_p_cache, a_m_cache );
    when a_loop_number = 6 and a_c6 is not null then   
      return substitute_( 6 , a_loop_te, a_c6, a_concat_by , a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9, a_p_cache, a_m_cache );
    when a_loop_number = 7 and a_c7 is not null then   
      return substitute_( 7 , a_loop_te, a_c7, a_concat_by , a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9, a_p_cache, a_m_cache );
    when a_loop_number = 8 and a_c8 is not null then   
      return substitute_( 8 , a_loop_te, a_c8, a_concat_by , a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9, a_p_cache, a_m_cache );
    when a_loop_number = 9 and a_c9 is not null then   
      return substitute_( 9 , a_loop_te, a_c9, a_concat_by , a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9, a_p_cache, a_m_cache );
    else 
      return null;
  end case;
end;


/** Replaces numbered placeholders in compiled Template Expression with values from nested table of varchar2 (p).<br/>
* Using <br/>
* <pre>type p is table of varchar2;</pre>
* makes it possible to use some syntactic sugar for defining values to be placed instead of placeholders.<br/>
* So say if we want to substitute $1 for 'Dolly' and $2 for 'back' in template expression <br/>
* 'I said hello, $1, / Well, hello, $1 / It's so nice to have you $2 where you belong'<br/>
* For it we just pass pk_te.p( 'Dolly', 'back' ) into this version of substitute.<br/>
*
* @param a_te ty_te template expression compiled for numbered placeholders
* @param a_numbered_replacements nested table of varchar2. Holds  values to place instead of placeholders
* @param a_c1 a sys_refcursor to be used in loop structure substitution
* @param a_c2 a sys_refcursor to be used in loop structure substitution
* @param a_c3 a sys_refcursor to be used in loop structure substitution
* @param a_c4 a sys_refcursor to be used in loop structure substitution
* @param a_c5 a sys_refcursor to be used in loop structure substitution
* @param a_c6 a sys_refcursor to be used in loop structure substitution
* @param a_c7 a sys_refcursor to be used in loop structure substitution
* @param a_c8 a sys_refcursor to be used in loop structure substitution
* @param a_c9 a sys_refcursor to be used in loop structure substitution
*
* @return clob - a large character lob with substituted values (if any)
*
* @throws  EX_TE_IS_NULL if null template expression is passed
* @throws EX_TE_OF_WRONG_TYPE if passed template expression was compiled for named placeholders
*/
function substitute( a_te in ty_te, a_numbered_replacements p
  , a_c1 in pk_te.refcur := null, a_c2 in pk_te.refcur := null, a_c3 in pk_te.refcur := null, a_c4 in pk_te.refcur := null, a_c5 in pk_te.refcur := null, a_c6 in pk_te.refcur := null, a_c7 in pk_te.refcur := null, a_c8 in pk_te.refcur := null, a_c9 in pk_te.refcur := null  
) return clob AS
  v_res clob;
  EL_STRING constant pls_integer := ty_sph.EL_STRING();
  EL_PH_NUMBERED constant pls_integer := ty_sph.EL_PH_NUMBERED();
  EL_PH_NAMED constant pls_integer := ty_sph.EL_PH_NAMED();
  EL_NESTED_TE constant pls_integer := ty_sph.EL_NESTED_TE();
  v_sph ty_sph;
  v_loop_te ty_te;
  v_p_cache ty_p_cache;
  v_m_cache ty_m_cache;
BEGIN
  if ( a_te is null ) then
    raise_application_error( CEX_TE_IS_NULL, 'Null template expression passed' );
  end if;
  
  if ( a_te.type_ != ty_te.EL_NUMBERED() ) then
    raise_application_error( CEX_TE_OF_WRONG_TYPE, 'Template expression is of wrong type' );
  end if;
  
  init_cache_( v_p_cache, v_m_cache );
  
  for idx in a_te.compiled_template_.first .. a_te.compiled_template_.last loop
    v_sph := a_te.compiled_template_( idx );
    if ( v_sph is not null ) then
      if ( EL_STRING = v_sph.type_ ) then
        v_res := v_res || v_sph.string_;
      elsif ( EL_PH_NUMBERED = v_sph.type_ ) then
        if ( a_numbered_replacements.exists( v_sph.ph_number ) ) then
          v_res := v_res || a_numbered_replacements( v_sph.ph_number );
        end if;
      elsif ( EL_NESTED_TE = v_sph.type_ ) then
        v_loop_te := pk_te_crossref.get_loop_te( v_sph.nested_te_id );
        if v_loop_te is not null then
          v_res := v_res || 
            dispatch_nested_te_subst_( v_p_cache, v_m_cache, v_loop_te, v_sph.loop_number, v_sph.concat_by, 
              a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9 )
          ;
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
* we just pass pk_te.m( pk_te.p( 'who', 'Dolly' ), pk_te.p( 'how' , 'back' ) ) into this version of substitute function.<br/>
* Also accepts up to 9 optional cursor parameters what can be used to substitute values inside loop structures defined in<br/>
* template expression.
* Also accepts two optional cache parameters that cache results from those cursors
*
* @param a_te ty_te template expression compiled for named placeholders
* @param a_named_replacements a nested table of nested tables of varchar2 - named values to place instead of placeholders
* @param a_c1 a sys_refcursor to be used in loop structure substitution
* @param a_c2 a sys_refcursor to be used in loop structure substitution
* @param a_c3 a sys_refcursor to be used in loop structure substitution
* @param a_c4 a sys_refcursor to be used in loop structure substitution
* @param a_c5 a sys_refcursor to be used in loop structure substitution
* @param a_c6 a sys_refcursor to be used in loop structure substitution
* @param a_c7 a sys_refcursor to be used in loop structure substitution
* @param a_c8 a sys_refcursor to be used in loop structure substitution
* @param a_c9 a sys_refcursor to be used in loop structure substitution
*
* @return clob - a large character lob with substituted values (if any)
*
* @throws EX_TE_IS_NULL if null template expression is passed
* @throws EX_TE_OF_WRONG_TYPE if passed template expression was compiled for numbered placeholders
*/
function substitute( a_te in ty_te, a_named_replacements m
  , a_c1 in pk_te.refcur := null, a_c2 in pk_te.refcur := null, a_c3 in pk_te.refcur := null, a_c4 in pk_te.refcur := null, a_c5 in pk_te.refcur := null, a_c6 in pk_te.refcur := null, a_c7 in pk_te.refcur := null, a_c8 in pk_te.refcur := null, a_c9 in pk_te.refcur := null
) return clob 
AS
  v_res clob;
  EL_STRING constant pls_integer := ty_sph.EL_STRING();
  EL_PH_NUMBERED constant pls_integer := ty_sph.EL_PH_NUMBERED();
  EL_PH_NAMED constant pls_integer := ty_sph.EL_PH_NAMED();
  EL_NESTED_TE constant pls_integer := ty_sph.EL_NESTED_TE();
  v_sph ty_sph;
  v_dict ty_vchar_to_vchar; 
  v_p p;
  v_loop_te ty_te;
  v_p_cache ty_p_cache;
  v_m_cache ty_m_cache;
BEGIN
  if ( a_te is null ) then
    raise_application_error( CEX_TE_IS_NULL, 'Null template expression passed' );
  end if;
  
  if ( a_te.type_ != ty_te.EL_NAMED() ) then
    raise_application_error( CEX_TE_OF_WRONG_TYPE, 'Template expression is of wrong type' );
  end if;
  
  init_cache_( v_p_cache, v_m_cache );
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
      elsif ( EL_NESTED_TE = v_sph.type_ ) then
        v_loop_te := pk_te_crossref.get_loop_te( v_sph.nested_te_id );
        if v_loop_te is not null then
           v_res := v_res || 
            dispatch_nested_te_subst_( v_p_cache, v_m_cache, v_loop_te, v_sph.loop_number, v_sph.concat_by, 
              a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9 )
          ;
        end if;
      end if;
    end if;
  end loop;
  
  RETURN v_res;
END;


/** Replaces numbered placeholders in compiled Template Expression with values from nested table of varchar2 (p).<br/>
* Simmilar to function substitute for numbered placeholders but is used in subsequent recursive calls to substitute values into loop structures<br/>
* Redefines cursor parameters as required and adds two cache in out nocopy parameters.
*
* @param a_te ty_te template expression compiled for numbered placeholders
* @param a_numbered_replacements nested table of varchar2. Holds  values to place instead of placeholders
* @param a_c1 a sys_refcursor to be used in loop structure substitution
* @param a_c2 a sys_refcursor to be used in loop structure substitution
* @param a_c3 a sys_refcursor to be used in loop structure substitution
* @param a_c4 a sys_refcursor to be used in loop structure substitution
* @param a_c5 a sys_refcursor to be used in loop structure substitution
* @param a_c6 a sys_refcursor to be used in loop structure substitution
* @param a_c7 a sys_refcursor to be used in loop structure substitution
* @param a_c8 a sys_refcursor to be used in loop structure substitution
* @param a_c9 a sys_refcursor to be used in loop structure substitution
* @param a_p_cache a cache that stores results of cursor fetches returning ty_p instances 
* @param a_m_cache a cache that stores results of cursor fetches returning ty_m instances 
*
* @return clob - a large character lob with substituted values (if any)
*
* @throws  EX_TE_IS_NULL if null template expression is passed
* @throws EX_TE_OF_WRONG_TYPE if passed template expression was compiled for named placeholders
*/
function substitute_( a_te in ty_te, a_numbered_replacements p
  , a_c1 in pk_te.refcur, a_c2 in pk_te.refcur, a_c3 in pk_te.refcur, a_c4 in pk_te.refcur, a_c5 in pk_te.refcur, a_c6 in pk_te.refcur, a_c7 in pk_te.refcur, a_c8 in pk_te.refcur, a_c9 in pk_te.refcur  
  , a_p_cache in out nocopy ty_p_cache, a_m_cache in out nocopy ty_m_cache 
) return clob AS
  v_res clob;
  EL_STRING constant pls_integer := ty_sph.EL_STRING();
  EL_PH_NUMBERED constant pls_integer := ty_sph.EL_PH_NUMBERED();
  EL_PH_NAMED constant pls_integer := ty_sph.EL_PH_NAMED();
  EL_NESTED_TE constant pls_integer := ty_sph.EL_NESTED_TE();
  v_sph ty_sph;
  v_loop_te ty_te;
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
      elsif ( EL_NESTED_TE = v_sph.type_ ) then
        v_loop_te := pk_te_crossref.get_loop_te( v_sph.nested_te_id );
        if v_loop_te is not null then
          v_res := v_res || 
            dispatch_nested_te_subst_( a_p_cache, a_m_cache, v_loop_te, v_sph.loop_number, v_sph.concat_by, 
              a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9 )
          ;
        end if;
      end if;
    end if;
  end loop;
  
  RETURN v_res;
END;


/** Replaces named placeholders in compiled Template Expression with values from nested table of nested tables of varchar2 (m).<br/>
* Simmilar to function substitute for named placeholders but is used in subsequent recursive calls to substitute values into loop structures<br/>
* Redefines cursor parameters as required and adds two cache in out nocopy parameters.
*
* @param a_te ty_te template expression compiled for named placeholders
* @param a_named_replacements a nested table of nested tables of varchar2 - named values to place instead of placeholders
* @param a_c1 a sys_refcursor to be used in loop structure substitution
* @param a_c2 a sys_refcursor to be used in loop structure substitution
* @param a_c3 a sys_refcursor to be used in loop structure substitution
* @param a_c4 a sys_refcursor to be used in loop structure substitution
* @param a_c5 a sys_refcursor to be used in loop structure substitution
* @param a_c6 a sys_refcursor to be used in loop structure substitution
* @param a_c7 a sys_refcursor to be used in loop structure substitution
* @param a_c8 a sys_refcursor to be used in loop structure substitution
* @param a_c9 a sys_refcursor to be used in loop structure substitution
* @param a_p_cache a cache that stores results of cursor fetches returning ty_p instances 
* @param a_m_cache a cache that stores results of cursor fetches returning ty_m instances 
*
* @return clob - a large character lob with substituted values (if any)
*
* @throws EX_TE_IS_NULL if null template expression is passed
* @throws EX_TE_OF_WRONG_TYPE if passed template expression was compiled for numbered placeholders
*/
function substitute_( a_te in ty_te, a_named_replacements m
  , a_c1 in pk_te.refcur, a_c2 in pk_te.refcur, a_c3 in pk_te.refcur, a_c4 in pk_te.refcur, a_c5 in pk_te.refcur, a_c6 in pk_te.refcur, a_c7 in pk_te.refcur, a_c8 in pk_te.refcur, a_c9 in pk_te.refcur  
  , a_p_cache in out nocopy ty_p_cache, a_m_cache in out nocopy ty_m_cache 
) return clob 
AS
  v_res clob;
  EL_STRING constant pls_integer := ty_sph.EL_STRING();
  EL_PH_NUMBERED constant pls_integer := ty_sph.EL_PH_NUMBERED();
  EL_PH_NAMED constant pls_integer := ty_sph.EL_PH_NAMED();
  EL_NESTED_TE constant pls_integer := ty_sph.EL_NESTED_TE();
  v_sph ty_sph;
  v_dict ty_vchar_to_vchar; 
  v_p p;
  v_loop_te ty_te;
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
      elsif ( EL_NESTED_TE = v_sph.type_ ) then
        v_loop_te := pk_te_crossref.get_loop_te( v_sph.nested_te_id );
        if v_loop_te is not null then
           v_res := v_res || 
            dispatch_nested_te_subst_( a_p_cache, a_m_cache, v_loop_te, v_sph.loop_number, v_sph.concat_by, 
              a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9 )
          ;
        end if;
      end if;
    end if;
  end loop;
  
  RETURN v_res;
END;



/** Replaces placeholders in compiled Template Expression with values from cursor in iteration.<br/>
* Each individual substitution is concatenated with the following with optional a_concat_by in between.<br/>
* Cursor must return instances of ty_p or ty_m UDTs otherwise the function will throw. 
*
* @param a_te ty_te compiled template expression
* @param a_cursor a cursor that must return either instances of ty_m or instances of ty_p
* @param a_concat_by if present each individual substitutions are concatenated in a loop with a_concat_by in between
* @return clob - a large character lob with substituted values (if any)
* @throws EX_TE_IS_NULL if null template expression is passed
* @throws EX_CURSOR_OF_WRONG_TYPE if passed cursor does not return instances of ty_m or instances of ty_p
*/
function substitute( a_te in ty_te, a_cursor in pk_te.refcur, a_concat_by in varchar2 default null ) return clob
AS
  v_res clob;
  EL_STRING constant pls_integer := ty_sph.EL_STRING();
  EL_PH_NUMBERED constant pls_integer := ty_sph.EL_PH_NUMBERED();
  EL_PH_NAMED constant pls_integer := ty_sph.EL_PH_NAMED();
  v_p p;
  v_m m;
BEGIN
  if ( a_te is null ) then
    raise_application_error( CEX_TE_IS_NULL, 'Null template expression passed' );
  end if;
  
  if ( a_te.type_ = ty_te.EL_NUMBERED() ) then
    -- expeciting ty_p to be returned from cursor
    begin 
      fetch a_cursor into v_p;
      if ( a_cursor%NOTFOUND ) then
        goto FIN;
      end if;
    exception
      when others then
        if sqlcode = -932 then
          raise_application_error( CEX_CURSOR_OF_WRONG_TYPE, 'Cursor does not return ty_p instance' );
        else
          raise;
        end if;
    end;
    v_res := substitute( a_te, v_p );
    loop
      fetch a_cursor into v_p;
      exit when a_cursor%NOTFOUND;
      v_res := v_res || a_concat_by || substitute( a_te, v_p );
    end loop;
  elsif ( a_te.type_ = ty_te.EL_NAMED() ) then
    -- expecting ty_m to be returned from cursor
    begin 
      fetch a_cursor into v_m;
      if ( a_cursor%NOTFOUND ) then
        goto FIN;
      end if;
    exception
      when others then
        if sqlcode = -932 then
          raise_application_error( CEX_CURSOR_OF_WRONG_TYPE, 'Cursor does not return ty_m instance' );
        else
          raise;
        end if;
    end;
    v_res := substitute( a_te, v_m );
    loop
      fetch a_cursor into v_m;
      exit when a_cursor%NOTFOUND;
      v_res := v_res || a_concat_by || substitute( a_te, v_m );
    end loop;
  end if;
<<FIN>>  
  RETURN v_res;
END;




/** Substitutes values from p without 'compiling' template expression
*
* @param a_string a string representing not compiled template expression having numbered placeholders
* @param a_numbered_replacements a nested table of varchar2 - values to place instead of placeholders
* @param a_ph_start a string that denotes the beginning of numbered placeholder
* @return clob - a large character lob with substituted values (if any)
*/
function substitute( a_string in clob, a_numbered_replacements p, a_ph_start in varchar2 := '$', a_ph_end in varchar2 := '' ) return clob as
  v_res clob;
  v_pattern_head varchar2( 30 char ); 
  v_pattern_tail varchar2( 30 char ); 
  v_pattern varchar2( 100 char );
  v_backref varchar2( 2 char );
begin
  if ( a_string is null or a_ph_start is null ) then
    return null;
  end if;
  v_pattern_head := ty_te.escape_regexp_special( a_ph_start );
  v_pattern_tail := ty_te.escape_regexp_special( a_ph_end );
  if ( a_numbered_replacements is null ) or ( a_numbered_replacements is empty ) then
    return regexp_replace( a_string, v_pattern_head || '\d+' || v_pattern_tail, '' );
  end if;
  v_res := a_string;
  for idx in a_numbered_replacements.first .. a_numbered_replacements.last loop
    if ( a_numbered_replacements.exists( idx ) ) then
      if a_ph_end is null then
        v_pattern := v_pattern_head || to_char( idx ) || '(\D|$)';
        v_backref := '\1';
      else
        v_pattern := v_pattern_head || to_char( idx ) || v_pattern_tail;
        v_backref := '';
      end if;
      v_res := regexp_replace( 
        v_res
        , v_pattern
        , ty_te.escape_backreference( a_numbered_replacements( idx ) ) || v_backref
        , 1
        , 0
        , 'imn' 
      );
    end if;
  end loop;
  -- Replace remaining template expressions with an empty string
  return regexp_replace( v_res, v_pattern_head || '\d+' || v_pattern_tail, '' );
end;

/** Substitutes values from m without 'compiling' template expression
*
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