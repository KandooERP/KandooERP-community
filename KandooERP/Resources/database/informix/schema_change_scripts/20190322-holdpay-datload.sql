--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: holdpay
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/holdpay.unl SELECT * FROM holdpay;
drop table holdpay;


create table "informix".holdpay 
(
cmpy_code char(2),
hold_code nchar(2),
hold_text nvarchar(40)
);


LOAD FROM unl20190322/holdpay.unl INSERT INTO holdpay;
