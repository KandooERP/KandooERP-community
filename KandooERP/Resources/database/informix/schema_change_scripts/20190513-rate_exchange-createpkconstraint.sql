--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: rate_exchange
--# author: ericv
--# date: 2019-05-13
--# Ticket # :  4
--# more comments:
create unique index u_rate_exchange on rate_exchange(currency_code,start_date,cmpy_code);
alter table rate_exchange add constraint primary key (currency_code,start_date,cmpy_code) constraint pk_rate_exchange;
