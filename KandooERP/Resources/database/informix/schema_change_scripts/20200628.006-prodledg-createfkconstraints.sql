--# description: this script creates a foreign key from prodledg to period and replaces fk_prodledg_account by fk_prodledg_coa
--# tables list: period,prodledg,account
--# author: ericv
--# date: 2020-06-28
--# Ticket 	
--# Comments: constraints to account are not correct because account row is not always created. Correct relationship is with period
--# SELECT year_num||period_num||cmpy_code from prodledg WHERE year_num||period_num||cmpy_code not in ( SELECT year_num||period_num||cmpy_code FROM period )

alter table prodledg drop constraint fk_prodledg_account;
drop index if exists d02_prodledg;
create index if not exists ifk_prodledg_period on prodledg (year_num,period_num,cmpy_code);
alter table prodledg add constraint foreign key (year_num,period_num,cmpy_code) references period (year_num,period_num,cmpy_code) constraint fk_prodledg_period;
create index if not exists ifk_prodledg_coa on prodledg (acct_code,cmpy_code);
alter table prodledg add constraint foreign key (acct_code,cmpy_code) references coa (acct_code,cmpy_code) constraint fk_prodledg_coa;
