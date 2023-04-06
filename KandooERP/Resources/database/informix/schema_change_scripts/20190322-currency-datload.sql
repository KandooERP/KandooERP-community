--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: currency
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/currency.unl SELECT * FROM currency;
drop table currency;


create table "informix".currency 
(
currency_code nchar(3),
desc_text nvarchar(30),
symbol_text nchar(3)
);

LOAD FROM unl20190322/currency.unl INSERT INTO currency;
