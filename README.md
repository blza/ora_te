# ora_te
Simple template engine for Oracle DBMS in a form of UDTs and a package.

This small project is about using simple template expressions in Oracle DBMS.
So one could occasionally abandon an ugly Oracle concat syntax like 
```
  execute immediate 
    'create global temporary table ' || v_d.tmp_table || ' on commit preserve rows 
    as 
    select * from ' || v_d.source_owner || '.' || v_d.source_table || '@' || DBLINK_NAME || '
    where  nvl(id_rec,1) > ' || to_char( v_last_seq_id )
  ;
```  
in favor of more readable one
```
  v_te := ty_te.compile_numbered( 
    'create global temporary table $1 on commit preserve rows
    as
    select * from $2.$3@$4
    where nvl(id_rec,1) > $5'
  );
  execute immediate
    pk_te.substitute( 
      v_te
      , pk_te.p( v_d.tmp_table, v_d.source_owner, v_d.source_table, DBLINK_NAME, v_last_seq_id ) 
    ) 
  ;
```  
or another that is even more suitable for reading and understanding
```
  v_te := ty_te.compile_named( 
    'create global temporary table {$table_name} on commit preserve rows
    as
    select * from {$owner}.{$src_table}@{$dblink}
    where nvl(id_rec,1) > {$lastseq}'
  );
  execute immediate
    pk_te.substitute( 
      v_te
      , pk_te.m( 
        pk_te.p( 'table_name', v_d.tmp_table )
        , pk_te.p( 'owner', v_d.source_owner )
        , pk_te.p( 'src_table', v_d.source_table ) 
        , pk_te.p( 'dblink', DBLINK_NAME )
        , pk_te.p( 'lastseq', v_last_seq_id ) 
      )
    ) 
  ;
```  
...Unit tests are coming

