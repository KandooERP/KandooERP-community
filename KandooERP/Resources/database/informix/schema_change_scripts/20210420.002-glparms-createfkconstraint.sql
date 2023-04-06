--# description: this script foreign keys on glparms to used_currency
--# dependencies: 
--# tables list:  glparms,used_currency
--# author: Eric Vercelletto
--# date: 2021-04-20
--# Ticket: ongoing fkeys implementation
--# more comments:

alter table glparms add constraint foreign key (base_currency_code,cmpy_code) references used_currency (currency_code,cmpy_code)  constraint fk_glparms_used_currency;
