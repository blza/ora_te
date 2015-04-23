create or replace type ty_te force as object (
  compiled_template_ ty_sph_tbl
  , type_ number( 1, 0 )
	, CONSTRUCTOR FUNCTION ty_te( SELF IN OUT NOCOPY ty_te, a_type in pls_integer ) 
		RETURN SELF AS RESULT
  , static function compile_numbered( a_template_string in clob, a_ph_start in varchar2 := '$') return ty_te
  , static function compile_named( 
    a_template_string in clob, a_ph_start in varchar2 := '{$', a_ph_end in varchar2 := '}' ) return ty_te
  , static function escape_regexp_special( a_not_escaped in varchar2 ) return varchar2
  , static function escape_backreference( a_not_escaped in varchar2 ) return varchar2
  , static function EL_NUMBERED return pls_integer
  , static function EL_NAMED return pls_integer
);