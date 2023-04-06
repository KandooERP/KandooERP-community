--# description: this script creates foreign keys constraints on cashreceipt
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: cashreceipt
--# author: eric vercelletto
--# date: 2020-10-01
--# Ticket # : KD-2383
--# more comments: check the violations with the following query
--#unload to /tmp/20201001-cashreceipt_1-createfkconstraint.violations
--#select currency_code
--#from cashreceipt
--#where currency_code not in ( select currency_code from currency);
--#unload to /tmp/20201001-cashreceipt_2-createfkconstraint.violations
--#select cash_acct_code||cmpy_code 
--#from cashreceipt
--#where cash_acct_code||cmpy_code not in ( select acct_code||cmpy_code from coa) ;
--#unload to /tmp/20201001-cashreceipt_3-createfkconstraint.violations
--#select entry_code,cmpy_code
--#from cashreceipt
--#where entry_code||cmpy_code not in ( select sign_on_code||cmpy_code from kandoouser);
alter table cashreceipt modify (entry_code NVARCHAR(8));
alter table cashreceipt add constraint foreign key (currency_code) references currency(currency_code) constraint fk_cashreceipt_currency;
alter table cashreceipt add constraint foreign key (cash_acct_code,cmpy_code) references coa(acct_code,cmpy_code) constraint fk_cashreceipt_coa;
alter table cashreceipt add constraint foreign key (entry_code,cmpy_code) references kandoouser(sign_on_code,cmpy_code) constraint fk_cashreceipt_kandoouser;