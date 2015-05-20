create or replace type TY_SPH force as object (
	type_ number(1, 0)
	, string_ clob
	, ph_name varchar2( 100 char )
	, ph_number number(38, 0)
  , loop_number number(38, 0)
  , concat_by varchar2( 400 char )
  , nested_te_id number( 38, 0 )
	, CONSTRUCTOR FUNCTION TY_SPH( SELF IN OUT NOCOPY TY_SPH ) RETURN SELF AS RESULT
	, static function EL_STRING return pls_integer
	, static function EL_PH_NUMBERED return pls_integer
	, static function EL_PH_NAMED return pls_integer
	, static function EL_NESTED_TE return pls_integer   
	, static function create_numbered_ph( a_number in pls_integer ) return ty_sph
	, static function create_named_ph( a_name in varchar2 ) return ty_sph
	, static function create_wrapped_string( a_string in clob ) return ty_sph
  , static function create_nested_te( a_te_id in pls_integer, a_loop_number in pls_integer := 0, a_concat_by in varchar2 := '' ) return ty_sph
  , member function is_string return pls_integer
);
/