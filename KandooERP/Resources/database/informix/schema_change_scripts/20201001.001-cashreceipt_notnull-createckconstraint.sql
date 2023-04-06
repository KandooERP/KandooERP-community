--# description: this script creates not null constraints on cashreceipt
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: cashreceipt
--# author: eric vercelletto
--# date: 2020-10-01
--# Ticket # : KD-2383
--# more comments: check the violations with the following query
--unload to /tmp/20201001-cashreceipt_1-createckconstraint.violations
--select *
--from cashreceipt
--where bank_currency_code IS NULL;
--unload to /tmp/20201001-cashreceipt_2-createckconstraint.violations
--select *
--from cashreceipt
--where cash_acct_code IS NULL ;
--unload to /tmp/20201001-cashreceipt_3-createckconstraint.violations
--select *
--from cashreceipt
--where entry_code IS NULL ;
alter table cashreceipt modify (bank_currency_code nchar(3) NOT NULL);
alter table cashreceipt modify (cash_acct_code nchar(18) NOT NULL) ;
alter table cashreceipt modify (entry_code nchar(8) NOT NULL);
