--# description: this script creates a foreign key from driverledger to period and replaces fk_driverledger_account by fk_driverledger_coa
--# tables list: period,driverledger,account
--# author: ericv
--# date: 2020-06-28
--# Ticket 	
--# Comments: constraints to account are not correct because account row is not always created. Correct relationship is with period
--# SELECT year_num||period_num||cmpy_code from driverledger WHERE year_num||period_num||cmpy_code not in ( SELECT year_num||period_num||cmpy_code FROM period )

alter table driverledger drop constraint fk_driverledger_account;
drop index if exists fk_driverledger_account;
create index if not exists ifk_driverledger_period on driverledger (year_num,period_num,cmpy_code);
alter table driverledger add constraint foreign key (year_num,period_num,cmpy_code) references period (year_num,period_num,cmpy_code) constraint fk_driverledger_period;
create index if not exists ifk_driverledger_coa on driverledger (acct_code,cmpy_code);
alter table driverledger add constraint foreign key (acct_code,cmpy_code) references coa (acct_code,cmpy_code) constraint fk_driverledger_coa;