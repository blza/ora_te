create or replace type body TY_SPH as
/**
* TY_SPH (String Or Placeholder)<br/>
* A type that represents wrapped clob or numbered/named placeholder or contains references to nested compiled tempate expressions (ty_te).<br/>
* You can create ty_sph of particular type by calling corresponding static functions.<br/>
* This type is used in internals of TY_TE as a container of either string, or numbered/named placeholder<br/>
* @headcom
*/

/** Constructor implementation
* @return self
*/
CONSTRUCTOR FUNCTION TY_SPH( SELF IN OUT NOCOPY TY_SPH ) RETURN SELF AS RESULT
as
begin
    return;
end TY_SPH ;

/** Creates instance of ty_sph by wrapping numbered placeholder
* @param a_number placeholder number
* @return instance of ty_sph
*/
static function create_numbered_ph( a_number in pls_integer ) return ty_sph 
as
  v_instance ty_sph;
begin
  v_instance := ty_sph();
  v_instance.type_ := ty_sph.EL_PH_NUMBERED();
  v_instance.ph_number := a_number;
  return v_instance;
end;

/** Creates instance of ty_sph by wrapping numbered placeholder
* @param a_name placeholder name
* @return instance of ty_sph
*/
static function create_named_ph( a_name in varchar2 ) return ty_sph 
as
  v_instance ty_sph;
begin
  v_instance := ty_sph();
  v_instance.type_ := ty_sph.EL_PH_NAMED();
  v_instance.ph_name := a_name;
  return v_instance;
end;

/** Creates instance of ty_sph by wrapping string
* @param a_string a string to wrap
* @return instance of ty_sph
*/
static function create_wrapped_string( a_string in clob ) return ty_sph 
as
  v_instance ty_sph;
begin
  v_instance := ty_sph();
  v_instance.type_ := ty_sph.EL_STRING();
  v_instance.string_ := a_string;
  return v_instance;
end;


/** Creates instance of ty_sph by wrapping an instance of ty_te. Can also assign loop number if nested template expression comes <br/>
* from loop declaration and the string that will be inserted between individual loop substitutions.
* @param a_te a nested te
* @param a_loop_number an optional loop number if template expression comes from loop declaration
* @param a_concat_by a string that comes from loop declaration and that will be inserted between individual loop substitutions.
* @return instance of ty_sph
*/
static function create_loop_construct( a_te_id in pls_integer, a_loop_number in pls_integer := 0, a_concat_by in varchar2 := '' ) return ty_sph
as
  v_instance ty_sph;
begin
  v_instance := ty_sph();
  v_instance.type_ := ty_sph.EL_LOOP_CONSTRUCT();
  v_instance.loop_construct_id := a_te_id;
  v_instance.loop_number := a_loop_number;
  v_instance.concat_by := a_concat_by;
  return v_instance;
end;


static function create_if_construct( a_if_te_id in pls_integer, a_true_te_id in pls_integer, a_false_te_id in pls_integer ) return ty_sph
as
  v_instance ty_sph;
begin
  v_instance := ty_sph();
  v_instance.type_ := ty_sph.EL_IF_CONSTRUCT();
  v_instance.loop_construct_id := a_if_te_id;
  v_instance.t_te_id := a_true_te_id;
  v_instance.f_te_id := a_false_te_id;
  return v_instance;
end;


/** Just to be used as class constant
*/    
STATIC FUNCTION EL_STRING RETURN PLS_INTEGER as
begin
  return 1;
end;

/** Just to be used as class constant
*/
STATIC FUNCTION EL_PH_NUMBERED RETURN PLS_INTEGER as
begin
  return 2;
end;

/** Just to be used as class constant
*/
STATIC FUNCTION EL_PH_NAMED RETURN PLS_INTEGER as
begin
  return 3;
end;

/** Just to be used as class constant
*/
static function EL_LOOP_CONSTRUCT return pls_integer as 
begin
  return 4;
end;

/** Just to be used as class constant
*/
static function EL_IF_CONSTRUCT return pls_integer as
begin
  return 5;
end;


/** Check if current instance is the wrapper of clob.
* @return 1 if the instance is a wrapper of clob, 0 otherwise.
*/
member function is_string return pls_integer
as 
begin
  if ( ty_sph.EL_STRING() = self.type_ ) then
    return 1;
  end if;
  return 0;
end;


end;
/