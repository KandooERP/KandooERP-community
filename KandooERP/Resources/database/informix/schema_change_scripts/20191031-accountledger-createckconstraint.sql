--# description: this script creates check constraints on accountledger
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: accountledger
--# author: eric vercelletto
--# date: 2019-10-31
--# Ticket # :
--# more comments: check the violations with the following query
--unload to /tmp/20191031-accountledger-createckconstraint.violations
--select cmpy_code,jour_code,jour_num,acct_code,for_debit_amt,for_credit_amt
--from accountledger
--where not ((for_debit_amt = 0 and for_credit_amt > 0 ) OR ( for_debit_amt > 0 and for_credit_amt = 0 ));
alter table accountledger add constraint check ((for_debit_amt = 0 and for_credit_amt > 0 ) OR ( for_debit_amt > 0 and for_credit_amt = 0 )) constraint ck_accountledger_debit_or_credit;
