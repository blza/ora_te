create or replace PACKAGE BODY PK_TE_IMPL AS 

/** 
* Supporting functions that help to implement PK_TE functionality (mostly dealing with recursive calls to handle loop structures).
* Moved to separate package to expose in PK_TE specification only those types and functions that are to be called by end user.
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
    raise_application_error( pk_te_ex.CEX_TE_IS_NULL, 'Null template expression passed' );
  end if;
  
  if a_te.type_ = EL_NUMBERED then
    if a_p_cache( a_loop_idx ) is empty then
      begin
        fetch a_cursor bulk collect into a_p_cache( a_loop_idx );
      exception 
        when others then 
          if sqlcode = -932 then
            raise_application_error( pk_te_ex.CEX_CURSOR_OF_WRONG_TYPE, 'Cursor does not return ty_p instance' );
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
            raise_application_error( pk_te_ex.CEX_CURSOR_OF_WRONG_TYPE, 'Cursor does not return ty_m instance' );
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



/** Dispatches reqest to substitute cursor values into loop structure to the call of appropriate substitute_ function
*
*/
function dispatch_loop_construct_subst_( 
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
  EL_LOOP_CONSTRUCT constant pls_integer := ty_sph.EL_LOOP_CONSTRUCT();
  EL_IF_CONSTRUCT constant pls_integer := ty_sph.EL_IF_CONSTRUCT();
  v_sph ty_sph;
  v_loop_te ty_te;
  v_if_te ty_te;
  v_cond_subst_res clob;
BEGIN
  if ( a_te is null ) then
    raise_application_error( pk_te_ex.CEX_TE_IS_NULL, 'Null template expression passed' );
  end if;
  
  if ( a_te.type_ != ty_te.EL_NUMBERED() ) then
    raise_application_error( pk_te_ex.CEX_TE_OF_WRONG_TYPE, 'Template expression is of wrong type' );
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
      elsif ( EL_LOOP_CONSTRUCT = v_sph.type_ ) then
        v_loop_te := pk_te_crossref.get_te_ref( v_sph.nested_te_id );
        if v_loop_te is not null then
          v_res := v_res || 
            dispatch_loop_construct_subst_( a_p_cache, a_m_cache, v_loop_te, v_sph.loop_number, v_sph.concat_by, 
              a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9 )
          ;
        end if;
      elsif ( EL_IF_CONSTRUCT = v_sph.type_ ) then
        v_if_te := pk_te_crossref.get_te_ref( v_sph.nested_te_id );
        if v_if_te is not null then
          v_cond_subst_res := pk_te.substitute( v_if_te, a_numbered_replacements, a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9 );
        end if;
        if ( pk_te_impl.eval( v_cond_subst_res ) ) then
          v_if_te := pk_te_crossref.get_te_ref( v_sph.t_te_id );
        else
          v_if_te := pk_te_crossref.get_te_ref( v_sph.f_te_id );
        end if;
        if v_if_te is not null then
          v_res := v_res || 
            pk_te.substitute( v_if_te, a_numbered_replacements, a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9 )
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
  EL_LOOP_CONSTRUCT constant pls_integer := ty_sph.EL_LOOP_CONSTRUCT();
  EL_IF_CONSTRUCT constant pls_integer := ty_sph.EL_IF_CONSTRUCT();
  v_sph ty_sph;
  v_dict ty_vchar_to_vchar; 
  v_if_te ty_te;
  v_cond_subst_res clob;
  v_p p;
  v_loop_te ty_te;
BEGIN
  if ( a_te is null ) then
    raise_application_error( pk_te_ex.CEX_TE_IS_NULL, 'Null template expression passed' );
  end if;
  
  if ( a_te.type_ != ty_te.EL_NAMED() ) then
    raise_application_error( pk_te_ex.CEX_TE_OF_WRONG_TYPE, 'Template expression is of wrong type' );
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
      elsif ( EL_LOOP_CONSTRUCT = v_sph.type_ ) then
        v_loop_te := pk_te_crossref.get_te_ref( v_sph.nested_te_id );
        if v_loop_te is not null then
           v_res := v_res || 
            dispatch_loop_construct_subst_( a_p_cache, a_m_cache, v_loop_te, v_sph.loop_number, v_sph.concat_by, 
              a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9 )
          ;
        end if;
      elsif ( EL_IF_CONSTRUCT = v_sph.type_ ) then
        v_if_te := pk_te_crossref.get_te_ref( v_sph.nested_te_id );
        if v_if_te is not null then
          v_cond_subst_res := pk_te.substitute( v_if_te, a_named_replacements, a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9 );
        end if;
        if ( pk_te_impl.eval( v_cond_subst_res ) ) then
          v_if_te := pk_te_crossref.get_te_ref( v_sph.t_te_id );
        else
          v_if_te := pk_te_crossref.get_te_ref( v_sph.f_te_id );
        end if;
        if v_if_te is not null then
          v_res := v_res || 
            pk_te.substitute( v_if_te, a_named_replacements, a_c1, a_c2, a_c3, a_c4, a_c5, a_c6, a_c7, a_c8, a_c9 )
          ;
        end if;
      end if;
    end if;
  end loop;
  
  RETURN v_res;
END;

/** Evaluates passed expression
* 
* @param a_cond an expression that when evaluated must return true or false
*
* @return boolean value of evaluation
* @trow pk_te_ex.CEX_EVAL_FAILED if evaluation resulted in an exception
*/
function eval( a_cond clob ) return boolean as
  v_res pls_integer;
begin
  execute immediate 'begin :v_res := case when ' || a_cond || ' then 1 else 0 end; end;'
  using out v_res;
  return ( 1 = v_res );
exception
  when others then
    raise_application_error( pk_te_ex.CEX_EVAL_FAILED, 'Evaluation of If condition failed with error code: ' || to_char( SQLCode )
      || ', erorr stack: ' || trim( DBMS_UTILITY.FORMAT_ERROR_STACK ) 
    );
end;



END PK_TE_IMPL;
/