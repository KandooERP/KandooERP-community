--# description: this script creates a foreign key from period to company
--# tables list: company,period
--# author: ericv
--# date: 2020-06-26
--# Ticket 	
--# Comments: check data with this query
--# SELECT cmpy_code from period WHERE cmpy_code not in ( SELECT cmpy_code FROM company )

create index if not exists fk01_period on period (cmpy_code);
alter table period add constraint foreign key (cmpy_code) references company (cmpy_code) constraint fk_period_company;
