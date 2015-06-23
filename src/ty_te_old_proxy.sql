create or replace type ty_te_old_proxy force as object (
  c_ number(1, 0)
  , CONSTRUCTOR FUNCTION ty_te_old_proxy( SELF IN OUT NOCOPY ty_te_old_proxy ) RETURN SELF AS RESULT
  
  , member function compile_numbered( a_template_string in clob
      , a_ph_start in varchar2 := '$', a_ph_end in varchar2 := ''
      , a_loop_ph_begin varchar2 := '{%', a_loop_ph_body varchar2 := '%', a_loop_ph_end varchar2 := '%}' ) return ty_te
  , member function compile_named( a_template_string in clob
      , a_ph_start in varchar2 := '{$', a_ph_end in varchar2 := '}'
      , a_loop_ph_begin varchar2 := '{%', a_loop_ph_body varchar2 := '%', a_loop_ph_end varchar2 := '%}' ) return ty_te  
      
  , member function substitute( a_string in clob, a_numbered_replacements ty_p, a_ph_start in varchar2 := '$', a_ph_end in varchar2 := '' ) return clob
  , member function substitute( a_string in clob, a_named_replacements ty_m, a_ph_start in varchar2 := '{$', a_ph_end in varchar2 := '}' ) return clob
);
/