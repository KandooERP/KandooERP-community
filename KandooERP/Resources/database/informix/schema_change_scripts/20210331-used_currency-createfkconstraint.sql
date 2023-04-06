--# description: this script creates a foreign key for used_currency to copany
--# dependencies: 
--# tables list:  used_currency
--# author: erve
--# date: 2021-03-31
--# Ticket: KD-2624
--# more comments:

create index if not exists fk_used_currency_cmpy on used_currency (cmpy_code);
alter table used_currency add constraint foreign key (cmpy_code) references company(cmpy_code) constraint fk_used_currency_company;
