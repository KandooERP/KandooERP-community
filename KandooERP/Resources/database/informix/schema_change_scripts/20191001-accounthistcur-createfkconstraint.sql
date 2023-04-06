--# description: this script create indexes and constraints on accounthistcur
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: accounthistcur
--# author: eric vercelletto
--# date: 2019-10-01
--# Ticket # :
--# more comments: 
create index d_accounthistcur_01 on accounthistcur (year_num,period_num,cmpy_code) using btree ;
alter table accounthistcur add constraint foreign key (year_num,period_num,cmpy_code) references period(year_num,period_num,cmpy_code) constraint fk_accounthistcur_period;
alter table accounthistcur drop constraint fk_accounthistcur_account;
create index d_accounthistcur_03 on accounthistcur (acct_code,year_num,currency_code,cmpy_code) using btree ;
alter table accounthistcur add constraint (foreign key (acct_code,year_num,currency_code,cmpy_code) references accountcur(acct_code,year_num,currency_code,cmpy_code) constraint fk_accounthistcur_accountcur);
