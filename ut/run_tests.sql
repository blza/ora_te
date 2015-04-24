truncate table ut_report;
exec pk_te_ut.run_tests;
select * from ut_report_deciphered;