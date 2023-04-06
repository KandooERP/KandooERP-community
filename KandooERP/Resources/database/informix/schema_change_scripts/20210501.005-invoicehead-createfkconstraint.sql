--# description: this script foreign keys on invoicehead to period
--# dependencies: 
--# tables list:  invoicehead,period
--# author: Eric Vercelletto
--# date: 2021-05-01
--# Ticket: ongoing fkeys implementation
--# more comments:

alter table invoicehead  add constraint foreign key (year_num,period_num,cmpy_code) references  period (year_num,period_num,cmpy_code)  constraint fk_invoicehead_period;