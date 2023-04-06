--# description: this script creates primary key for accounthistcur table
--# tables list: accounthistcur
--# author: ericv
--# date: 2020-01-20
--# Ticket # : 	
--# more comments:
drop index if exists accthistcurr_key ;
create unique index if not exists pk_accounthistcur 
on accounthistcur (acct_code,currency_code,year_num,period_num,cmpy_code) using btree ;
alter table accounthistcur drop constraint pk_accounthistcur;
alter table accounthistcur add constraint primary key (acct_code,currency_code,year_num,period_num,cmpy_code) constraint pk_accounthistcur  ;
