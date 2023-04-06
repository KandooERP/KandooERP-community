--# description: this script creates check constraints on batchdetl
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: batchdetl
--# author: eric vercelletto
--# date: 2019-10-31
--# Ticket # :
--# more comments: 

--unload rows that violate the constraint for cleanup purpose (first constraint)
--unload to /tmp/20191031-batchdetl-createckconstraint_1.violations
--select cmpy_code,jour_code,jour_num,acct_code,for_debit_amt,for_credit_amt
--from batchdetl
--where not (for_debit_amt >= 0 and for_credit_amt >= 0 ) ;
alter table batchdetl add constraint check (for_debit_amt >= 0 and for_credit_amt >= 0 ) constraint ck_batchdetl_01;
