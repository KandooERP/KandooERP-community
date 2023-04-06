--# description: this script creates more check constraints on batchhead
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: batchhead
--# author: eric vercelletto
--# date: 2019-10-31
--# Ticket # :
--# more comments: 

--unload rows that violate the constraint for cleanup purpose (second constraint)
--unload to /tmp/20191031-batchhead-createckconstraint_2.violations
--select cmpy_code,jour_code,jour_num,acct_code,for_debit_amt,for_credit_amt
--from batchhead
--where for_debit_amt <> for_credit_amt 
alter table batchhead add constraint check ( for_debit_amt = for_credit_amt  ) constraint ck_batchhead_02;
