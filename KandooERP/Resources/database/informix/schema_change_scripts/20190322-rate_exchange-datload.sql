--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: rate_exchange
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/rate_exchange.unl SELECT * FROM rate_exchange;
drop table rate_exchange;

create table "informix".rate_exchange 
(
cmpy_code char(2),
currency_code nchar(3),
start_date date,
conv_buy_qty float,
conv_sell_qty float,
conv_budg_qty float
);

LOAD FROM unl20190322/rate_exchange.unl INSERT INTO rate_exchange;
