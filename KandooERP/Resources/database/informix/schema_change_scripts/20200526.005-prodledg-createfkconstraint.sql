--# description: this script create foreign key for prodledg table to account
--# tables list: prodledg
--# author: ericv
--# date: 2020-05-26
--# Ticket # : 	
--# dependencies:
--# more comments: check data violations with the following query
--# select acct_code||year_num||cmpy_code from prodledg where acct_code||year_num||cmpy_code not in ( select acct_code||year_num||cmpy_code from account ) 

create index if not exists d02_prodledg on prodledg(acct_code,year_num,cmpy_code);
alter table prodledg add constraint foreign key (acct_code,year_num,cmpy_code) references account (acct_code,year_num,cmpy_code) constraint "informix".fk_prodledg_account ;