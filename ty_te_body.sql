create or replace TYPE BODY TY_TE AS

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


/**
* TY_TE (Template Expression)<br/>
* A type that represents a compiled template expression.<br/>
* By template expression (TE) we understand a string with numbered or named placeholders.<br/>
* By compiling TE we understand parsing it, finding numbered or named placeholders and storing the whole expression in internal<br/>
* structures (a nested table of ty_sph).
* @headcom
*/

/** Constructor implementation
*
* @param a_type Can be either ty_te.EL_NAMED() or ty_te.EL_NUMBERED() - the type of placehoders that were searched while compiling.
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
*
* @param a_template_string a template string
* @param  a_ph_start a string that denotes the beginning of numbered placeholder 
* @param a_loop_ph_begin a string that denotes the beginning of loop structure within template expression
* @param a_loop_ph_body a string that separates loop inner tempate expression from cursor number and from loop structure options
* @param a_loop_ph_end a string that denotes the end of loop structure within template expression
*
* @return The instance of template expression (ty_te) or null if no placeholders were found or if a_ph_start is null
*
* @throw pk_te_ex.EX_WRONG_PH_DENOTATION in case of ph denotation misuse
*/
static function compile_numbered( 
  a_template_string in clob
  , a_ph_start in varchar2 := '$'
  , a_ph_end in varchar2 := ''
  , a_loop_ph_begin varchar2 := '{%'
  , a_loop_ph_body varchar2 := '%'
  , a_loop_ph_end varchar2 := '%}' 
) return ty_te 
AS
BEGIN
  if a_ph_start is null then
    raise_application_error( pk_te_ex.CEX_WRONG_PH_DENOTATION, 'A_PH_START may not be null' );
  end if;
  if ( a_loop_ph_begin is null or a_loop_ph_body is null or a_loop_ph_end is null ) then
    raise_application_error( pk_te_ex.CEX_WRONG_PH_DENOTATION, 'A_LOOP_PH_BEGIN, A_LOOP_PH_BODY, A_LOOP_PH_END may not be null' );
  end if;
  if ( 
    ( a_ph_start = a_loop_ph_begin ) 
    or ( a_ph_start = a_loop_ph_body )
    or ( a_ph_start = a_loop_ph_end ) 
    or ( a_ph_end = a_loop_ph_begin ) 
    or ( a_ph_end = a_loop_ph_body )
    or ( a_ph_end = a_loop_ph_end ) 
  ) then
    raise_application_error( pk_te_ex.CEX_WRONG_PH_DENOTATION, 'A_PH_BEGIN, A_PH_END may not be equal to one of A_LOOP_PH_BEGIN, A_LOOP_PH_BODY, A_LOOP_PH_END' );
  end if;
  
  return ty_te.compile_generic_( a_template_string, a_ph_start, a_ph_end, ty_te.EL_NUMBERED(), a_loop_ph_begin, a_loop_ph_body, a_loop_ph_end );
  
END compile_numbered;


/** Parse string for named templates in the from {$placehoder}<br/>
*
* @param a_template_string a template string
* @param a_ph_start a string that denotes the beginning of named placeholder
* @param a_ph_end a string that denotes the end of named placeholder
* @param a_loop_ph_begin a string that denotes the beginning of loop structure within template expression
* @param a_loop_ph_body a string that separates loop inner tempate expression from cursor number and from loop structure options
* @param a_loop_ph_end a string that denotes the end of loop structure within template expression
*
* @return The instance of template expression (ty_te) or null if no placeholders were found or if or <br/>
* a_ph_start or a_ph_end is null
*
* @throw pk_te_ex.EX_WRONG_PH_DENOTATION in case of ph denotation misuse
*/
static function compile_named( 
  a_template_string in clob
  , a_ph_start in varchar2 := '{$'
  , a_ph_end in varchar2 := '}'
  , a_loop_ph_begin varchar2 := '{%'
  , a_loop_ph_body varchar2 := '%'
  , a_loop_ph_end varchar2 := '%}'
) return ty_te 
AS
BEGIN
  if a_ph_start is null then
    raise_application_error( pk_te_ex.CEX_WRONG_PH_DENOTATION, 'A_PH_START may not be null' );
  end if;
  if a_ph_end is null then
    raise_application_error( pk_te_ex.CEX_WRONG_PH_DENOTATION, 'A_PH_END may not be null' );
  end if;
  if ( a_loop_ph_begin is null or a_loop_ph_body is null or a_loop_ph_end is null ) then
    raise_application_error( pk_te_ex.CEX_WRONG_PH_DENOTATION, 'A_LOOP_PH_BEGIN, A_LOOP_PH_BODY, A_LOOP_PH_END may not be null' );
  end if;
  if ( 
    ( a_ph_start = a_loop_ph_begin ) 
    or ( a_ph_start = a_loop_ph_body )
    or ( a_ph_start = a_loop_ph_end ) 
    or ( a_ph_end = a_loop_ph_begin ) 
    or ( a_ph_end = a_loop_ph_body )
    or ( a_ph_end = a_loop_ph_end ) 
  ) then
    raise_application_error( pk_te_ex.CEX_WRONG_PH_DENOTATION, 'A_PH_BEGIN, A_PH_END may not be equal to one of A_LOOP_PH_BEGIN, A_LOOP_PH_BODY, A_LOOP_PH_END' );
  end if;
  
  return ty_te.compile_generic_( a_template_string, a_ph_start, a_ph_end, ty_te.EL_NAMED(), a_loop_ph_begin, a_loop_ph_body, a_loop_ph_end );
END;

/** Replaces special characters in delimiters part of loop structure options with coresponding character codes
*
* @param a_delim a delimiter string
* @return varchar2 a delimiter string with replaced special chars
*/
static function translate_options_delim_( a_delim in varchar2 ) return varchar2
as
begin
  return replace( replace( replace( a_delim, '\r', chr(13) ), '\n', chr(10) ), '\t', chr(9) );
end;


/** Finds and compiles loop structures inside template expressions
*
* @param a_template_string a template string
* @param a_ph_start a string that denotes the beginning of placeholder
* @param a_ph_end a string that denotes the end of placeholder
* @param a_type a type of placeholders to search in string. Actually just may be used to translate to inner loop structures
* @param a_loop_ph_begin a string that denotes the beginning of loop structure within template expression
* @param a_loop_ph_body a string that separates loop inner tempate expression from cursor number and from loop structure options
* @param a_loop_ph_end a string that denotes the end of loop structure within template expression
*
* @return The instance of template expression (ty_te) containing loop part or null if no loop structures were found
*/
static function process_loop_( 
  a_template_string in clob
  , a_ph_start in varchar2
  , a_ph_end in varchar2
  , a_type in pls_integer 
  , a_loop_ph_begin varchar2 := '{%'
  , a_loop_ph_body varchar2 := '%'
  , a_loop_ph_end varchar2 := '%}'
) return ty_te 
as
  v_head_pattern varchar2( 100 char );
  v_tail_pattern varchar2( 100 char );
  v_compound_pattern varchar2( 200 char );
  v_loop_part_pos_start pls_integer;
  v_loop_part_pos_end pls_integer;
  v_loop_balance pls_integer;
  v_loop_ph_begin_len pls_integer;
  v_loop_ph_end_len pls_integer;
  v_first_loop_begin_pos pls_integer;
  v_loop_found boolean := false;
  
  v_head_string clob;
  v_loop_string clob;
  v_tail_string clob;
  v_head_te ty_te;
  v_tail_te ty_te;
  v_loop_body clob;
  
  v_cursor_num pls_integer;
  v_options varchar2( 200 char );
  type ty_opt_array is varray( 4 ) of varchar2( 400 char );
  v_options_array ty_opt_array := ty_opt_array( 'NOT_SET', 'NOT_SET', 'NOT_SET', 'NOT_SET' );
  
  v_loop_te_id pls_integer;
  v_loop_te ty_te;
  v_loop_sph ty_sph;
  v_new_ph_start varchar2( 30 char );
  v_new_ph_end varchar2( 30 char );
  v_new_type pls_integer;
  
  v_from_pos pls_integer := 1;
  FIND_FIRST_CHAR constant pls_integer := 0;
  FIND_LAST_CHAR constant pls_integer := 1;
  v_instance ty_te;
  
  procedure parse_options ( a_options_string in varchar2, a_options_array in out nocopy ty_opt_array ) 
  as 
    v_option_delim_pos pls_integer;
    v_prev_option_delim_pos pls_integer;
    v_option_idx pls_integer;
  begin
    v_option_idx := 1;
    v_prev_option_delim_pos := 1;
    loop
      v_option_delim_pos := instr( a_options_string, '|', v_prev_option_delim_pos );
      if 0 = v_option_delim_pos then
        exit;
      end if;
      if '\' != substr( a_options_string, v_option_delim_pos - 1, 1 ) then
        a_options_array( v_option_idx ) := substr( a_options_string, v_prev_option_delim_pos, v_option_delim_pos - v_prev_option_delim_pos );
        v_option_idx := v_option_idx + 1;
      end if;
      v_prev_option_delim_pos := v_option_delim_pos + 1;
    end loop;
    a_options_array( v_option_idx ) := substr( a_options_string, v_prev_option_delim_pos );
  end;
begin
  
  -- search for first loop defined in template string
  v_head_pattern := ty_te.escape_regexp_special( a_loop_ph_begin ) || '(\d+)' || ty_te.escape_regexp_special( a_loop_ph_body );
  v_tail_pattern := ty_te.escape_regexp_special( a_loop_ph_body ) || '(.*?)' || ty_te.escape_regexp_special( a_loop_ph_end );
  
  v_loop_part_pos_start := regexp_instr( a_template_string, v_head_pattern, v_from_pos, 1, FIND_FIRST_CHAR );
  v_loop_part_pos_end := regexp_instr( a_template_string, v_head_pattern, v_from_pos, 1, FIND_LAST_CHAR );
  
  if 0 = v_loop_part_pos_start then
    return null;
  end if;
  -- continue to search for closing loop part, using v_loop_balance to balance opening and closing loop parts,
  -- so nested loops are handled and are passed to subsequent recursive compile calls.
  v_first_loop_begin_pos := v_loop_part_pos_start;
  
  v_loop_balance := 1;
  
  v_loop_ph_begin_len := length( a_loop_ph_begin );
  v_loop_ph_end_len := length( a_loop_ph_end );
  loop
    v_from_pos := v_loop_part_pos_end;
    v_compound_pattern := '(' || v_head_pattern || '|' || v_tail_pattern || ')';

    -- first search for compoudn pattern    
    v_loop_part_pos_start := regexp_instr( a_template_string, v_compound_pattern, v_from_pos, 1, FIND_FIRST_CHAR );
    v_loop_part_pos_end := regexp_instr( a_template_string, v_compound_pattern, v_from_pos, 1, FIND_LAST_CHAR );
    
    if 0 = v_loop_part_pos_start then
      -- loop openning or closing part is not found, reached the end of template string
      exit;
    end if;
    
    if substr( a_template_string, v_loop_part_pos_start, v_loop_ph_begin_len ) = a_loop_ph_begin then 
      -- loop openning part is found
      v_loop_balance := v_loop_balance + 1;
    else
      -- loop closing part is found
      v_loop_balance := v_loop_balance - 1;
      if 0 = v_loop_balance then
        v_loop_found := true;
        exit;
      end if;
    end if;
  end loop;
  if not v_loop_found then 
    return null;
  end if;
  v_head_string := substr( a_template_string, 1, v_first_loop_begin_pos - 1 );
  v_tail_string := substr( a_template_string, v_loop_part_pos_end );
  v_loop_string := substr( a_template_string, v_first_loop_begin_pos, v_loop_part_pos_end - v_first_loop_begin_pos );
  
  v_cursor_num := to_number( regexp_replace( v_loop_string , '^' || v_head_pattern || '.*', '\1', 1, 1, 'imn' ) );
  v_loop_body := regexp_replace( v_loop_string , '^' || v_head_pattern || '(.*)' || v_tail_pattern || '$', '\2', 1, 1, 'imn' );
  
  -- parse options
  v_options := regexp_replace( v_loop_string , '.*' || v_tail_pattern || '$', '\1', 1, 1, 'imn' );
  if ( v_options is not null ) then
    parse_options( v_options, v_options_array );
  end if;
  
  -- determine the type of compilation for nested loop structure
  v_new_type := case 
      when v_options_array( 2 ) = 'NOT_SET' then
        a_type
      when lower( v_options_array( 2 ) ) = 'n' then
        ty_te.EL_NUMBERED()
      when lower( v_options_array( 2 ) ) = 'w' then
        ty_te.EL_NAMED()
      else 
        a_type
    end
  ;
  -- determine new placehodlers begin and end
  if v_options_array( 3 ) is not null and v_options_array( 3 ) != 'NOT_SET' then
    v_new_ph_start := v_options_array( 3 );
  else
    if v_new_type = a_type then
      v_new_ph_start := a_ph_start;
    else
      if v_new_type = ty_te.EL_NUMBERED() then
        v_new_ph_start := '$';
      else
        v_new_ph_start := '{$';
      end if;
    end if;
  end if;
   
  if v_options_array( 4 ) is not null and v_options_array( 4 ) != 'NOT_SET' then
    v_new_ph_end := v_options_array( 4 );
  else
    if v_new_type = a_type then
      v_new_ph_end := a_ph_end;
    else
      if v_new_type = ty_te.EL_NUMBERED() then
        v_new_ph_end := '';
      else
        v_new_ph_end := '}';
      end if;
    end if;
  end if;
    
  v_loop_te := ty_te.compile_generic_( 
      v_loop_body 
      , v_new_ph_start
      , v_new_ph_end
      , v_new_type
      , a_loop_ph_begin 
      , a_loop_ph_body
      , a_loop_ph_end 
    )
  ;
  v_loop_te_id := pk_te_crossref.insert_loop_te( v_loop_te );
  if ( 0 != v_loop_te_id ) then
    v_loop_sph := ty_sph.create_nested_te( 
      v_loop_te_id
      , v_cursor_num
      , translate_options_delim_( v_options_array( 1 ) )
    ); 
  end if;
  
  v_head_te := ty_te.compile_generic_( v_head_string, a_ph_start, a_ph_end, a_type, a_loop_ph_begin, a_loop_ph_body, a_loop_ph_end );
  v_head_te.compiled_template_.extend( 1 );
  v_head_te.compiled_template_( v_head_te.compiled_template_.last ) := v_loop_sph;

  v_tail_te := ty_te.compile_generic_( v_tail_string, a_ph_start, a_ph_end, a_type, a_loop_ph_begin, a_loop_ph_body, a_loop_ph_end );

  v_instance := ty_te.concat( v_head_te, v_tail_te );
  return v_instance;
end;


/** Parse string for named or numbered templates<br/>
* Stores result of parsing in compiled_template_ nested table.
*
* @param a_template_string a template string
* @param a_ph_start a string that denotes the beginning of placeholder
* @param a_ph_end a string that denotes the end of placeholder
* @param a_type a type of placeholders to search in string. Accepts either ty_te.EL_NUMBERED() or ty_te.EL_NAMED()
* @param a_loop_ph_begin a string that denotes the beginning of loop structure within template expression
* @param a_loop_ph_body a string that separates loop inner tempate expression from cursor number and from loop structure options
* @param a_loop_ph_end a string that denotes the end of loop structure within template expression
*
* @return The instance of template expression (ty_te) or null if a_type != ty_te.EL_NUMBERED() and a_type != ty_te.EL_NAMED()<br/>
* or if no teplate expressions were found in string.<br/>
* Also returns null if there's misuse of placeholder denotation strings (a_ph_start, a_ph_end, a_loop_ph_begin, a_loop_ph_body, a_loop_ph_end).
*/
static function compile_generic_( 
  a_template_string in clob
  , a_ph_start in varchar2
  , a_ph_end in varchar2
  , a_type in pls_integer 
  , a_loop_ph_begin varchar2 := '{%'
  , a_loop_ph_body varchar2 := '%'
  , a_loop_ph_end varchar2 := '%}'
) return ty_te 
AS
  v_ph_pos_start pls_integer;
  v_ph_pos_end pls_integer;
  v_pattern varchar2( 100 char );
  v_from_pos pls_integer := 1;
  v_ph_name_or_num varchar2( 100 char );
  FIND_FIRST_CHAR constant pls_integer := 0;
  FIND_LAST_CHAR constant pls_integer := 1;
  v_instance ty_te;
  v_name_pos pls_integer;
  v_name_len_minus pls_integer;
  v_sph_idx pls_integer := 0;
  v_match varchar2( 100 char );
BEGIN
  v_instance := process_loop_( 
    a_template_string 
    , a_ph_start 
    , a_ph_end 
    , a_type 
    , a_loop_ph_begin 
    , a_loop_ph_body 
    , a_loop_ph_end 
  );
  if ( v_instance is not null ) then
    return v_instance;
  end if;
  

  v_from_pos := 1;

  v_pattern :=  ty_te.escape_regexp_special( a_ph_start ) 
    || case when a_type = ty_te.EL_NAMED() then '\w+' else '\d+' end 
    || ty_te.escape_regexp_special( a_ph_end )
  ;
  v_name_pos := length( a_ph_start ) + 1;
  if a_ph_end is null then
    v_name_len_minus := -1;
  else
    v_name_len_minus := length( a_ph_end ) - 1;
  end if;
    
  v_ph_pos_start := regexp_instr( a_template_string, v_pattern, v_from_pos, 1, FIND_FIRST_CHAR );
  v_ph_pos_end := regexp_instr( a_template_string, v_pattern, v_from_pos, 1, FIND_LAST_CHAR );

  v_instance := ty_te( a_type );  

  if ( 0 = v_ph_pos_start ) then
    -- if no placeholder found, just wrap entire string
    v_instance.compiled_template_.extend( 1 );
    v_instance.compiled_template_( 1 ) := ty_sph.create_wrapped_string( a_template_string );
    RETURN v_instance;
  end if;  
  
  loop
    v_match := substr( a_template_string, v_ph_pos_start, v_ph_pos_end - v_ph_pos_start );
    v_ph_name_or_num := lower( 
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
    
    if a_type = ty_te.EL_NAMED() then
      v_instance.compiled_template_( v_sph_idx ) := ty_sph.create_named_ph( v_ph_name_or_num );
    else 
      v_instance.compiled_template_( v_sph_idx ) := ty_sph.create_numbered_ph( to_number( v_ph_name_or_num ) );
    end if;
    
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


/** Concatenates two instances of compiled template expressions to costruct new instance<br/>
* with combined compiled_template_ tables peserving the order (values from a_lhv.compiled_template_ first<br/>
* , from a_rhv.compiled_template_ second).
* @param a_lhv first template expression to combine
* @param a_rhv second template expression to combine
* 
* @return ty_te the instance of ty_te with compiled_template_ nested table containg ty_sph instances from a_lhl and plus instances from a_rhv<br/>
* or null if either of parameters is null
*
* @trow
*/
static function concat( a_lhv in ty_te, a_rhv in ty_te ) return ty_te 
as
   v_instance ty_te;
begin
  if a_lhv.type_ != a_rhv.type_ then
    raise_application_error( pk_te_ex.CEX_WRONG_PH_DENOTATION, 'Types of TY_TE instances do not match' );
  end if;
  if a_lhv is null or a_rhv is null then
    return null;
  end if;
  
  v_instance := ty_te( a_lhv.type_ );
  v_instance.compiled_template_ := a_lhv.compiled_template_ multiset union a_rhv.compiled_template_;
  return v_instance;
end;


END;