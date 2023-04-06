--# description: this script creates a foreign key from accountledger to period and drops fk_accountledger_account, and create fk to coa
--# tables list: period,accountledger,account,coa
--# author: ericv
--# date: 2020-06-28
--# Ticket 	
--# Comments: constraints to account are not correct because account row is not always created. Correct relationship is with period
--# SELECT year_num,period_num,cmpy_code from accountledger WHERE year_num||period_num||cmpy_code not in ( SELECT year_num||period_num||cmpy_code FROM period )

alter table accountledger drop constraint fk_accountledger_account;
drop index if exists fk_accountledger_account;
create index if not exists ifk_accountledger_period on accountledger (year_num,period_num,cmpy_code);
alter table accountledger add constraint foreign key (year_num,period_num,cmpy_code) references period (year_num,period_num,cmpy_code) constraint fk_accountledger_period;
create index if not exists  ifk_accountledger_coa on accountledger (acct_code,cmpy_code);
alter table accountledger add constraint foreign key (acct_code,cmpy_code) references coa (acct_code,cmpy_code) constraint fk_accountledger_coa;