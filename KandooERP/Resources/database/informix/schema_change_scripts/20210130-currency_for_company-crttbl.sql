--# description: this script create the used_currency table which manages which currencies a company uses
--# dependencies: 
--# tables list: used_currency
--# author: erve
--# date: 2021-01-30
--# Ticket # : 	KD-2583
create table used_currency
  (
    cmpy_code nchar(2),
    currency_code nchar(3)
  );

create unique index pk_used_currency on used_currency (currency_code,cmpy_code) using btree ;
create index d_currency on used_currency (currency_code) using btree ;
alter table used_currency add constraint foreign key (currency_code) references currency (currency_code) constraint fk_used_currency_currency;
