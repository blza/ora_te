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
 
  type p is table of varchar2( 32767 char );
  type m is table of p;

  function substitute( a_te in out nocopy ty_te, a_numbered_replacements p ) return clob;
  function substitute( a_te in out nocopy ty_te, a_named_replacements m ) return clob;
  
  function substitute( a_string in clob, a_numbered_replacements p, a_ph_start in varchar2 := '$' ) return clob;
  function substitute( a_string in clob, a_named_replacements m, a_ph_start in varchar2 := '{$', a_ph_end in varchar2 := '}' ) return clob;
 
END PK_TE;