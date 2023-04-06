--# description: this script add a foreign key period->fiscalyear 
--# dependencies: 20201120.000-fiscalyear-dependency
--# tables list: fiscalyear,period
--# author: eric
--# date: 2020-11-20
--# Ticket # : KD-2466
--# 

alter table period drop constraint fk_period_company;
alter table period add constraint foreign key (year_num,cmpy_code) references fiscalyear(year_num,cmpy_code)  constraint fk_period_fiscalyear;
