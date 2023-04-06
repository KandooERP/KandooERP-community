--# description: this script create indexes and constraints on accounthist
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: accounthist
--# author: eric vercelletto
--# date: 2019-10-01
--# Ticket # :
--# more comments: 
create index d_accounthist_01 on accounthist (year_num,period_num,cmpy_code) using btree ;
alter table accounthist add constraint foreign key (year_num,period_num,cmpy_code) references period(year_num,period_num,cmpy_code) constraint fk_accounthist_period;
