--# description: this script creates a foreign key from accounthist to period and replaces fk_accounthist_account by fk_accounthist_coa
--# tables list: period,accounthist,account,coa
--# author: ericv
--# date: 2020-06-28
--# Ticket 	
--# Comments: constraints to account are not correct because account row is not always created. Correct relationship is with period
--# SELECT year_num||period_num||cmpy_code from accounthist WHERE year_num||period_num||cmpy_code not in ( SELECT year_num||period_num||cmpy_code FROM period )

alter table accounthist drop constraint fk_accounthist_account;
drop index if exists fk_accounthist_account;
create index ifk_accounthist_coa on accounthist (acct_code,cmpy_code);
alter table accounthist add constraint foreign key (acct_code,cmpy_code) references coa (acct_code,cmpy_code) constraint fk_accounthist_coa;