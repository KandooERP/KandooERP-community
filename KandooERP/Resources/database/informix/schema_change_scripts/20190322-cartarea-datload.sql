--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: cartarea
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/cartarea.unl SELECT * FROM cartarea;
drop table cartarea;


create table "informix".cartarea 
(
cmpy_code char(2),
cart_area_code nchar(3),
desc_text nvarchar(40)
);


LOAD FROM unl20190322/cartarea.unl INSERT INTO cartarea;
