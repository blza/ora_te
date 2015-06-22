create or replace PACKAGE PK_TE_CROSSREF AS 

type ty_te_tbl is table of ty_te index by binary_integer;
g_te_tbl ty_te_tbl;

function insert_te_ref( a_te ty_te ) return pls_integer; 
function get_te_ref( a_id pls_integer ) return ty_te;
function delete_te_ref( a_id pls_integer ) return boolean;

END PK_TE_CROSSREF;
/