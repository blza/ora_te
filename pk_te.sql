create or replace PACKAGE PK_TE AS 
  EX_TE_GENERAL exception;
  CEX_TE_GENERAL constant pls_integer := -20999;
  pragma EXCEPTION_INIT( EX_TE_GENERAL, -20999 );
  
  EX_TE_OF_WRONG_TYPE exception;
  CEX_TE_OF_WRONG_TYPE constant pls_integer := -20998;
  pragma EXCEPTION_INIT( EX_TE_OF_WRONG_TYPE, -20998 );
  
  EX_TE_IS_NULL exception;
  CEX_TE_IS_NULL constant pls_integer := -20997;
  pragma EXCEPTION_INIT( EX_TE_IS_NULL, -20997 );
  
  EX_CURSOR_OF_WRONG_TYPE exception;
  CEX_CURSOR_OF_WRONG_TYPE constant pls_integer := -20996;
  pragma EXCEPTION_INIT( EX_CURSOR_OF_WRONG_TYPE, -20996 );
  
  subtype p is ty_p;
  subtype m is ty_m;
  
  subtype refcur is sys_refcursor;
  
  -- These types are for internal use only
  type ty_m_tab is table of ty_m;
  type ty_m_cache is table of ty_m_tab index by binary_integer;
  type ty_p_tab is table of ty_p;
  type ty_p_cache is table of ty_p_tab index by binary_integer;
  -- end types for internal use only
  
  function substitute( a_te in ty_te, a_numbered_replacements p, a_c1 in pk_te.refcur := null
    , a_c2 in pk_te.refcur := null, a_c3 in pk_te.refcur := null, a_c4 in pk_te.refcur := null, a_c5 in pk_te.refcur := null, a_c6 in pk_te.refcur := null, a_c7 in pk_te.refcur := null, a_c8 in pk_te.refcur := null, a_c9 in pk_te.refcur := null 
  ) return clob;
  function substitute( a_te in ty_te, a_named_replacements m
    , a_c1 in pk_te.refcur := null, a_c2 in pk_te.refcur := null, a_c3 in pk_te.refcur := null, a_c4 in pk_te.refcur := null, a_c5 in pk_te.refcur := null, a_c6 in pk_te.refcur := null, a_c7 in pk_te.refcur := null, a_c8 in pk_te.refcur := null, a_c9 in pk_te.refcur := null 
  ) return clob;
  function substitute( a_te in ty_te, a_cursor in pk_te.refcur, a_concat_by in varchar2 default null ) return clob;
   
  function substitute( a_string in clob, a_numbered_replacements p, a_ph_start in varchar2 := '$', a_ph_end in varchar2 := '' ) return clob;
  function substitute( a_string in clob, a_named_replacements m, a_ph_start in varchar2 := '{$', a_ph_end in varchar2 := '}' ) return clob;
  
  -- Following functions are not to be directly called. Definition in specification is required to support compile order in the body of package
  function substitute_( a_te in ty_te, a_numbered_replacements p
    , a_c1 in pk_te.refcur, a_c2 in pk_te.refcur, a_c3 in pk_te.refcur, a_c4 in pk_te.refcur, a_c5 in pk_te.refcur, a_c6 in pk_te.refcur, a_c7 in pk_te.refcur, a_c8 in pk_te.refcur, a_c9 in pk_te.refcur  
    , a_p_cache in out nocopy ty_p_cache, a_m_cache in out nocopy ty_m_cache 
  ) return clob;
  function substitute_( a_te in ty_te, a_named_replacements m
    , a_c1 in pk_te.refcur, a_c2 in pk_te.refcur, a_c3 in pk_te.refcur, a_c4 in pk_te.refcur, a_c5 in pk_te.refcur, a_c6 in pk_te.refcur, a_c7 in pk_te.refcur, a_c8 in pk_te.refcur, a_c9 in pk_te.refcur  
    , a_p_cache in out nocopy ty_p_cache, a_m_cache in out nocopy ty_m_cache 
  ) return clob; 
END PK_TE;