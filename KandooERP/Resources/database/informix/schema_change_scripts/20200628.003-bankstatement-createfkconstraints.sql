--# description: this script creates a foreign key from bankstatement to period and replaces fk_bankstatement_account by fk_bankstatement_coa
--# tables list: period,bankstatement,account,coa
--# author: ericv
--# date: 2020-06-28
--# Ticket 	
--# Comments: constraints to account are not correct because account row is not always created. Correct relationship is with period
--# SELECT year_num||period_num||cmpy_code from bankstatement WHERE year_num||period_num||cmpy_code not in ( SELECT year_num||period_num||cmpy_code FROM period )

alter table bankstatement drop constraint fk_bankstatement_account;
drop index if exists fk_bankstatement_account;
create index if not exists ifk_bankstatement_period on bankstatement (year_num,period_num,cmpy_code);
alter table bankstatement add constraint foreign key (year_num,period_num,cmpy_code) references period (year_num,period_num,cmpy_code) constraint fk_bankstatement_period;

create index ifk_bankstatement_coa on bankstatement (acct_code,cmpy_code);
alter table bankstatement add constraint foreign key (acct_code,cmpy_code) references coa (acct_code,cmpy_code) constraint fk_bankstatement_coa;