create or replace type ty_te force as object (
  compiled_template_ ty_sph_tbl
  , type_ number( 1, 0 )
  , CONSTRUCTOR FUNCTION ty_te( SELF IN OUT NOCOPY ty_te, a_type in pls_integer ) 
    RETURN SELF AS RESULT
  , static function EL_NUMBERED return pls_integer
  , static function EL_NAMED return pls_integer
  , static function compile_numbered( a_template_string in clob
      , a_ph_start in varchar2 := '{$', a_ph_end in varchar2 := '}'
      , a_constr_ph_begin varchar2 := '{%', a_constr_ph_end varchar2 := '%}' ) return ty_te      
  , static function compile_named( a_template_string in clob
      , a_ph_start in varchar2 := '{{', a_ph_end in varchar2 := '}}'
      , a_constr_ph_begin varchar2 := '{%', a_constr_ph_end varchar2 := '%}' ) return ty_te            
  , static function compile_numbered_old( a_template_string in clob
      , a_ph_start in varchar2 := '$', a_ph_end in varchar2 := ''
      , a_loop_ph_begin varchar2 := '{%', a_loop_ph_body varchar2 := '%', a_loop_ph_end varchar2 := '%}' ) return ty_te
  , static function compile_named_old( a_template_string in clob
      , a_ph_start in varchar2 := '{$', a_ph_end in varchar2 := '}'
      , a_loop_ph_begin varchar2 := '{%', a_loop_ph_body varchar2 := '%', a_loop_ph_end varchar2 := '%}' ) return ty_te
  , static function compile_generic_( 
      a_template_string in clob
      , a_ph_start in varchar2
      , a_ph_end in varchar2
      , a_type in pls_integer 
      , a_constr_ph_begin varchar2 
      , a_constr_ph_end varchar2 
      , a_constr_ph_body varchar2 := null
    ) return ty_te
  , static function process_loop_( 
      a_template_string in clob
      , a_ph_start in varchar2
      , a_ph_end in varchar2
      , a_type in pls_integer 
      , a_loop_ph_begin varchar2 
      , a_loop_ph_body varchar2 
      , a_loop_ph_end varchar2 
    ) return ty_te
  , static function process_ctrl_tw_( 
      a_template_string in clob
      , a_ph_start in varchar2
      , a_ph_end in varchar2
      , a_type in pls_integer 
      , a_constr_ph_begin varchar2
      , a_constr_ph_end varchar2 
    ) return ty_te    
    
  , static function concat( a_lhv in ty_te, a_rhv in ty_te ) return ty_te
    
  , static function escape_regexp_special( a_not_escaped in varchar2 ) return varchar2
  , static function escape_backreference( a_not_escaped in varchar2 ) return varchar2

  , static function translate_options_delim_( a_delim in varchar2 ) return varchar2
);
/