create or replace TYPE BODY TY_TE_TWIG_PROXY AS

CONSTRUCTOR FUNCTION ty_te_twig_proxy ( SELF IN OUT NOCOPY ty_te_twig_proxy ) RETURN SELF AS RESULT AS
BEGIN
  RETURN;
END ty_te_twig_proxy;

member function compile_numbered( a_template_string in clob
    , a_ph_start in varchar2 := '{{', a_ph_end in varchar2 := '}}'
    , a_constr_ph_begin varchar2 := '{%', a_constr_ph_end varchar2 := '%}' ) return ty_te AS
BEGIN
  RETURN ty_te.compile_numbered( a_template_string, a_ph_start, a_ph_end, a_constr_ph_begin, a_constr_ph_end );
END compile_numbered;

member function compile_named( a_template_string in clob
    , a_ph_start in varchar2 := '{{', a_ph_end in varchar2 := '}}'
    , a_constr_ph_begin varchar2 := '{%', a_constr_ph_end varchar2 := '%}' ) return ty_te AS
BEGIN
  RETURN ty_te.compile_named( a_template_string, a_ph_start, a_ph_end, a_constr_ph_begin, a_constr_ph_end );
END compile_named;

member function substitute( a_string in clob, a_numbered_replacements ty_p, a_ph_start in varchar2 := '{{', a_ph_end in varchar2 := '}}' ) return clob AS
BEGIN
  RETURN pk_te.substitute( a_string, a_numbered_replacements, a_ph_start, a_ph_end );
END substitute;

member function substitute( a_string in clob, a_named_replacements ty_m, a_ph_start in varchar2 := '{{', a_ph_end in varchar2 := '}}' ) return clob AS
BEGIN
  RETURN pk_te.substitute( a_string, a_named_replacements, a_ph_start, a_ph_end );
END substitute;

END;
/