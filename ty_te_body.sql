create or replace TYPE BODY TY_TE AS

/**
* TY_TE (Template Expression)<br/>
* A type that represents a compiled template expression.<br/>
* By template expression (TE) we understand a string with numbered or named placeholders.<br/>
* By compiling TE we understand parsing it, finding numbered or named placeholders and storing the whole expression<br/>
* in the form of a nested table of ty_sph.<br/>
* @headcom
*/

/** Constructor implementation
*
* @param a_type Can be either ty_te.EL_NAMED() or ty_te.EL_NUMBERED(). Denotes the type of placehoders that were<br/>
* searched while compiling.
* @return self
*/
CONSTRUCTOR FUNCTION ty_te( SELF IN OUT NOCOPY ty_te, a_type in pls_integer ) 
  RETURN SELF AS RESULT AS
BEGIN
  self.compiled_template_ := ty_sph_tbl();
  self.type_ := a_type;
  RETURN;
END ty_te;

/** Escapes special chars to use as regexp pattern. Can be used outside of the type as a universal to escape such characters.
*/
static function escape_regexp_special( a_not_escaped in varchar2 ) return varchar2
as 
begin
  return regexp_replace( a_not_escaped, '(\[|\]|\\|\$|\?)', '\\\1' );
end; 

/** Escapes regexp backreference to prevent treating substrings of form '\1' .. '\9' in <br/>
* substitution values as backreference to matched pattern. Can be used as universal function outside the type to escape such backrefs.
*/
static function escape_backreference( a_not_escaped in varchar2 ) return varchar2
as 
begin
  return regexp_replace( a_not_escaped, '\\([1-9])', '\\\\\1' );
end; 


/** Parse string for numbered templates in the from $1, $2, etc.<br>
* Stores result of parsing in compiled_template_ nested table.
*
* @param a_template_string a template string
* @param  a_ph_start a string that denotes the beginning of numbered placeholder 
* @return The instance of template expression (ty_te) or null if no placeholders were found or if a_ph_start is null
*/
static function compile_numbered( a_template_string in clob, a_ph_start in varchar2 := '$' ) return ty_te AS
  v_ph_pos_start pls_integer;
  v_ph_pos_end pls_integer;
  v_pattern varchar2( 30 char );
  v_from_pos pls_integer := 1;
  v_ph_num pls_integer;
  FIND_FIRST_CHAR constant pls_integer := 0;
  FIND_LAST_CHAR constant pls_integer := 1;
  v_instance ty_te;
  v_digit_pos pls_integer;
  v_sph_idx pls_integer := 0;
BEGIN
  if ( a_ph_start is null ) then
    return null;
  end if;
  v_pattern :=  ty_te.escape_regexp_special( a_ph_start ) || '\d+';
  v_digit_pos := length( a_ph_start ) + 1;
  
  v_ph_pos_start := regexp_instr( a_template_string, v_pattern, v_from_pos, 1, FIND_FIRST_CHAR );
  v_ph_pos_end := regexp_instr( a_template_string, v_pattern, v_from_pos, 1, FIND_LAST_CHAR );

  if ( 0 = v_ph_pos_start ) then
    return null;
  end if;  

  v_instance := ty_te( ty_te.EL_NUMBERED() );
  loop
    v_ph_num := to_number( 
      substr( 
        substr( a_template_string, v_ph_pos_start, v_ph_pos_end - v_ph_pos_start )
        , v_digit_pos
      )
    );
    
    v_instance.compiled_template_.extend( 2 );
    
    v_sph_idx := v_sph_idx + 1;
    v_instance.compiled_template_( v_sph_idx ) := ty_sph.create_wrapped_string( 
      substr( a_template_string, v_from_pos, v_ph_pos_start - v_from_pos ) 
    );
    
    v_sph_idx := v_sph_idx + 1;
    v_instance.compiled_template_( v_sph_idx ) := ty_sph.create_numbered_ph( v_ph_num );
    
    v_from_pos := v_ph_pos_end;
    
    v_ph_pos_start := regexp_instr( a_template_string, v_pattern, v_from_pos, 1, FIND_FIRST_CHAR );
    v_ph_pos_end := regexp_instr( a_template_string, v_pattern, v_from_pos, 1, FIND_LAST_CHAR );
    
    if ( 0 = v_ph_pos_start ) then 
      exit;
    end if;
  end loop;

  v_instance.compiled_template_.extend;
  v_sph_idx := v_sph_idx + 1;
  v_instance.compiled_template_( v_sph_idx ) := ty_sph.create_wrapped_string( 
    substr( a_template_string, v_from_pos )
  );

  RETURN v_instance;
END compile_numbered;


/** Parse string for named templates in the from {$placehoder}<br/>
* Stores result of parsing in compiled_template_ nested table.
*
* @param a_template_string a template string
* @param a_ph_start a string that denotes the beginning of named placeholder
* @param a_ph_end a string that denotes the end of named placeholder
* @return The instance of template expression (ty_te) or null if no placeholders were found or if or <br/>
* a_ph_start or a_ph_end is null
*/
static function compile_named( 
  a_template_string in clob, a_ph_start in varchar2 := '{$', a_ph_end in varchar2 := '}' ) return ty_te 
AS
  v_ph_pos_start pls_integer;
  v_ph_pos_end pls_integer;
  v_pattern varchar2( 100 char );
  v_from_pos pls_integer := 1;
  v_ph_name varchar2( 100 char );
  FIND_FIRST_CHAR constant pls_integer := 0;
  FIND_LAST_CHAR constant pls_integer := 1;
  v_instance ty_te;
  v_name_pos pls_integer;
  v_name_len_minus pls_integer;
  v_sph_idx pls_integer := 0;
  v_match varchar2( 100 char );
BEGIN
  if ( a_ph_start is null or a_ph_end is null ) then 
    return null;
  end if;
  v_pattern :=  ty_te.escape_regexp_special( a_ph_start ) || '\w+' || ty_te.escape_regexp_special( a_ph_end );
  v_name_pos := length( a_ph_start ) + 1;
  v_name_len_minus := length( a_ph_end ) - 1;
  
  v_ph_pos_start := regexp_instr( a_template_string, v_pattern, v_from_pos, 1, FIND_FIRST_CHAR );
  v_ph_pos_end := regexp_instr( a_template_string, v_pattern, v_from_pos, 1, FIND_LAST_CHAR );

  if ( 0 = v_ph_pos_start ) then
    return null;
  end if;  

  v_instance := ty_te( ty_te.EL_NAMED() );
  loop
    v_match := substr( a_template_string, v_ph_pos_start, v_ph_pos_end - v_ph_pos_start );
    v_ph_name := lower( 
      substr( 
        v_match
        , v_name_pos
        , length( v_match ) - v_name_len_minus - v_name_pos
      )
    );
    
    v_instance.compiled_template_.extend( 2 );
    
    v_sph_idx := v_sph_idx + 1;
    v_instance.compiled_template_( v_sph_idx ) := ty_sph.create_wrapped_string( 
      substr( a_template_string, v_from_pos, v_ph_pos_start - v_from_pos ) 
    );
    
    v_sph_idx := v_sph_idx + 1;
    v_instance.compiled_template_( v_sph_idx ) := ty_sph.create_named_ph( v_ph_name );
    
    v_from_pos := v_ph_pos_end;
    
    v_ph_pos_start := regexp_instr( a_template_string, v_pattern, v_from_pos, 1, FIND_FIRST_CHAR );
    v_ph_pos_end := regexp_instr( a_template_string, v_pattern, v_from_pos, 1, FIND_LAST_CHAR );
    
    if ( 0 = v_ph_pos_start ) then 
      exit;
    end if;
  end loop;
  
  v_instance.compiled_template_.extend;
  v_sph_idx := v_sph_idx + 1;
  v_instance.compiled_template_( v_sph_idx ) := ty_sph.create_wrapped_string( 
    substr( a_template_string, v_from_pos )
  );

  RETURN v_instance;
END;


/** Just to be used as class constant
*/
static function EL_NUMBERED return pls_integer as
begin
	return 1;
end; 

/** Just to be used as class constant
*/
static function EL_NAMED return pls_integer as
begin
	return 2;
end; 

END;