create or replace TYPE BODY TY_TE_OLD_PROXY AS

CONSTRUCTOR FUNCTION ty_te_old_proxy( SELF IN OUT NOCOPY ty_te_old_proxy ) RETURN SELF AS RESULT AS
BEGIN
  RETURN;
END ty_te_old_proxy;

member function compile_numbered( a_template_string in clob
    , a_ph_start in varchar2 := '$', a_ph_end in varchar2 := ''
    , a_loop_ph_begin varchar2 := '{%', a_loop_ph_body varchar2 := '%', a_loop_ph_end varchar2 := '%}' ) return ty_te AS
BEGIN
  RETURN ty_te.compile_numbered_old( a_template_string, a_ph_start, a_ph_end, a_loop_ph_begin, a_loop_ph_body, a_loop_ph_end );
END compile_numbered;

member function compile_named( a_template_string in clob
    , a_ph_start in varchar2 := '{$', a_ph_end in varchar2 := '}'
    , a_loop_ph_begin varchar2 := '{%', a_loop_ph_body varchar2 := '%', a_loop_ph_end varchar2 := '%}' ) return ty_te AS
BEGIN
  RETURN ty_te.compile_named_old( a_template_string, a_ph_start, a_ph_end, a_loop_ph_begin, a_loop_ph_body, a_loop_ph_end );
END compile_named;

member function substitute( 
  a_string in clob, a_numbered_replacements ty_p, a_ph_start in varchar2 := '$', a_ph_end in varchar2 := '' 
) return clob
as
begin
  return pk_te.substitute( a_string, a_numbered_replacements, a_ph_start, a_ph_end );
end;

member function substitute( 
  a_string in clob, a_named_replacements ty_m, a_ph_start in varchar2 := '{$', a_ph_end in varchar2 := '}' 
) return clob
as 
begin
  return pk_te.substitute( a_string, a_named_replacements, a_ph_start, a_ph_end );
end;

END;
/