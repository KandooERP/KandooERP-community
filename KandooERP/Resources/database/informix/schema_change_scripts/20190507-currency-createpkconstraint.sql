--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: currency
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_currency on currency(currency_code);
ALTER TABLE currency ADD CONSTRAINT PRIMARY KEY ( currency_code)
CONSTRAINT pk_currency;
