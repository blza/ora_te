create or replace PACKAGE PK_TE_CROSSREF AS 

type ty_te_tbl is table of ty_te index by binary_integer;
g_te_tbl ty_te_tbl;

function insert_loop_te( a_te ty_te ) return pls_integer; 
function get_loop_te( a_id pls_integer ) return ty_te;
function delete_loop_te( a_id pls_integer ) return boolean;

END PK_TE_CROSSREF;