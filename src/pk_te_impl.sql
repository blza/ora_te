create or replace PACKAGE PK_TE_IMPL authid current_user AS 

  subtype p is ty_p;
  subtype m is ty_m;
  
  subtype refcur is sys_refcursor;
  
  type ty_m_tab is table of ty_m;
  type ty_m_cache is table of ty_m_tab index by binary_integer;
  type ty_p_tab is table of ty_p;
  type ty_p_cache is table of ty_p_tab index by binary_integer;
  
  -- Following functions are not to be directly called. Definition in specification is required to support compile order in the body of package
  function substitute_( a_te in ty_te, a_numbered_replacements p
    , a_c1 in pk_te.refcur, a_c2 in pk_te.refcur, a_c3 in pk_te.refcur, a_c4 in pk_te.refcur, a_c5 in pk_te.refcur, a_c6 in pk_te.refcur, a_c7 in pk_te.refcur, a_c8 in pk_te.refcur, a_c9 in pk_te.refcur  
    , a_p_cache in out nocopy ty_p_cache, a_m_cache in out nocopy ty_m_cache 
  ) return clob;
  function substitute_( a_te in ty_te, a_named_replacements m
    , a_c1 in pk_te.refcur, a_c2 in pk_te.refcur, a_c3 in pk_te.refcur, a_c4 in pk_te.refcur, a_c5 in pk_te.refcur, a_c6 in pk_te.refcur, a_c7 in pk_te.refcur, a_c8 in pk_te.refcur, a_c9 in pk_te.refcur  
    , a_p_cache in out nocopy ty_p_cache, a_m_cache in out nocopy ty_m_cache 
  ) return clob; 
  function dispatch_loop_construct_subst_( 
    a_p_cache in out nocopy ty_p_cache, a_m_cache in out nocopy ty_m_cache 
    , a_loop_te in out nocopy ty_te, a_loop_number pls_integer, a_concat_by varchar2
    , a_c1 in pk_te.refcur, a_c2 in pk_te.refcur, a_c3 in pk_te.refcur, a_c4 in pk_te.refcur, a_c5 in pk_te.refcur, a_c6 in pk_te.refcur, a_c7 in pk_te.refcur, a_c8 in pk_te.refcur, a_c9 in pk_te.refcur  
  ) 
  return clob;
  
  function eval( a_cond clob ) return boolean;

END PK_TE_IMPL;
/