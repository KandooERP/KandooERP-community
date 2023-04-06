--# description: this script creates a foreign key from postpurchase to period and replaces fk_postpurchase_account by fk_postpurchase_coa
--# tables list: period,postpurchase,account
--# author: ericv
--# date: 2020-06-28
--# Ticket 	
--# Comments: constraints to account are not correct because account row is not always created. Correct relationship is with period
--# SELECT year_num||period_num||cmpy_code from postpurchase WHERE year_num||period_num||cmpy_code not in ( SELECT year_num||period_num||cmpy_code FROM period )

alter table postpurchase drop constraint fk_postpurchase_account;
drop index if exists fk_postpurchase_account;
create index if not exists ifk_postpurchase_period on postpurchase (year_num,period_num,cmpy_code);
alter table postpurchase add constraint foreign key (year_num,period_num,cmpy_code) references period (year_num,period_num,cmpy_code) constraint fk_postpurchase_period;

create index ifk_postpurchase_coa on postpurchase (acct_code,cmpy_code);
alter table postpurchase add constraint foreign key (acct_code,cmpy_code) references coa (acct_code,cmpy_code) constraint fk_postpurchase_coa;