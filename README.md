# ora_te
## Description
Simple template engine for Oracle DBMS in a form of UDTs and a package.

This small project is about developing a simple template engine to be used in Oracle SQL/PL SQL.
So one could occasionally abandon an ugly Oracle concat syntax like 
```plsql
v_who := 'Dolly';
v_where := 'where you belong';
v_text := 'I said hello, '|| v_who ||', / Well, hello, ' 
  || v_who || ' / It''s so nice to have you back ' || v_where || '.'
;
```  
in favor of more readable one
```plsql
v_te := ty_te.compile_numbered( 
  'I said hello, $1, / Well, hello, $1 / It''s so nice to have you back $2.'
);
v_text := pk_te.substitute( v_te, pk_te.p( 'Dolly', 'where you belong' ) );
```  
or another that is even more suitable for reading and understanding
```plsql
v_te := ty_te.compile_named( 
  'I said hello, {$who}, / Well, hello, {$who} / It''s so nice to have you back {$where}.'
);
v_where := 'where you belong';
-- note that we can also use variables, not just literals
v_text := pk_te.substitute( 
  v_te
  , pk_te.m( 
    pk_te.p( 'who', 'Dolly' )
    , pk_te.p( 'where', v_where )
  )
);
```  
## Compatibility and requirements.
Developed for and tested on Oracle 11r2.

UDTs and the package are self contained, no additional dependencies. You only have to have Resource role to deploy and use UDTs and the package.

## Installation
Just download all files and run `deploy_te.sql` from the root directory.

## Documentation
See wiki.

## Regression testing
Unit tests can be found in ut subdirectory.

To deploy unit tests run `ut/deploy_ut.sql`.
To actually run unit tests run `ut/run_tests.sql`.

## Imposed cost of invocation
Profiling info and comparison to standart concat is to come.

## Licence
Mit licence applies.
