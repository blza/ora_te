create or replace type ty_p force is table of clob;
/
create or replace type ty_m force is table of ty_p;
/
create sequence  seq_ty_te_refs  minvalue 1 MAXVALUE 9999999999999999999999999999 INCREMENT BY 1 START WITH 1 CACHE 20 NOORDER CYCLE;
/

