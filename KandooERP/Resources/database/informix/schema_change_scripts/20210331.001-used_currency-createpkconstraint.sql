--# description: this script creates a primary key for used_currency + adds columns
--# dependencies: 
--# tables list:  used_currency
--# author: erve
--# date: 2021-03-31
--# Ticket: KD-2624
--# more comments:


alter table used_currency add constraint primary key (currency_code,cmpy_code) constraint pk_used_currency;
alter table used_currency add (start_date date,end_date date);
