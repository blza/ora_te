create or replace PACKAGE BODY PK_TE_CROSSREF AS

/**
* Package that enables referecing ty_te instances from ty_sph instances by unique ID <br/>
* Package global collection variable is used to store instances of ty_te and to return them by ID.<br/>
* This workaround is used while working with loop structures defined in template expression.
* @headcom
*/

/** Store instance of ty_te in global collection 
* 
* @param a_te an instance of ty_te to store
* @return pls_integer -- an unique ID (within sesion) of stored ty_te
*/
function insert_te_ref( a_te ty_te ) return pls_integer AS
  v_seq_num pls_integer;
BEGIN
  select SEQ_TY_TE_REFS.nextval 
  into v_seq_num 
  from dual
  ;
  g_te_tbl( v_seq_num ) := a_te;
  return v_seq_num;
exception 
  when others then 
    return 0;
END;

/** Get instance of ty_te from global collection 
* 
* @param a_id an unique ID of stored ty_te
* @return ty_te or null if the instance of ty_te was not found in the global collection
*/
function get_te_ref( a_id pls_integer ) return ty_te AS
BEGIN
  if g_te_tbl.exists( a_id ) then
    return g_te_tbl( a_id );
  end if;
  RETURN NULL;
END;


/** Delete instance of ty_te from global collection by given ID
* 
* @param a_id an unique ID of stored ty_te to delete
* @return boolean -- true if the instance of ty_te was found in the global collection and deleted, false otherwise
*/
function delete_te_ref( a_id pls_integer ) return boolean AS
BEGIN
  if g_te_tbl.exists( a_id ) then
    g_te_tbl.delete( a_id );
    return true;
  end if;
  RETURN false;

END;

begin
  g_te_tbl( 0 ) := null;

END PK_TE_CROSSREF;
/