create or replace type body TY_SPH as

/**
  TY_SPH (String Or Placeholder)
  A type that represents wrapped clob or numbered/named placeholder.
  
  You can create ty_sph of particular type by calling corresponding static functions.
*/
CONSTRUCTOR FUNCTION TY_SPH( SELF IN OUT NOCOPY TY_SPH ) RETURN SELF AS RESULT
as
begin
  	return;
end TY_SPH ;

static function create_numbered_ph( a_number in pls_integer ) return ty_sph 
as
  v_instance ty_sph;
begin
  v_instance := ty_sph();
  v_instance.type_ := ty_sph.EL_PH_NUMBERED();
  v_instance.ph_number := a_number;
  return v_instance;
end;

static function create_named_ph( a_name in varchar2 ) return ty_sph 
as
  v_instance ty_sph;
begin
  v_instance := ty_sph();
  v_instance.type_ := ty_sph.EL_PH_NAMED();
  v_instance.ph_name := a_name;
  return v_instance;
end;


static function create_wrapped_string( a_string in clob ) return ty_sph 
as
  v_instance ty_sph;
begin
  v_instance := ty_sph();
  v_instance.type_ := ty_sph.EL_STRING();
  v_instance.string_ := a_string;
  return v_instance;
end;

/**
Just to be used as class constant
*/		
STATIC FUNCTION EL_STRING RETURN PLS_INTEGER as
begin
	return 1;
end;

/**
Just to be used as class constant
*/
STATIC FUNCTION EL_PH_NUMBERED RETURN PLS_INTEGER as
begin
	return 2;
end;

/**
Just to be used as class constant
*/
STATIC FUNCTION EL_PH_NAMED RETURN PLS_INTEGER as
begin
	return 3;
end;

/**
Returns 1 if current instance is the wrapper of clob. 0 otherwise.
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