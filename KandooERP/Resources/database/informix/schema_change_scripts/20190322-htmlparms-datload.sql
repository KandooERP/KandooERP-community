--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: htmlparms
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/htmlparms.unl SELECT * FROM htmlparms;
drop table htmlparms;

create table "informix".htmlparms 
(
cmpy_code char(2),
sign_on_code nvarchar(8,0),
hold_code nchar(3),
prod_list_ind nchar(1),
cart_area_code nchar(3)
);

LOAD FROM unl20190322/htmlparms.unl INSERT INTO htmlparms;
