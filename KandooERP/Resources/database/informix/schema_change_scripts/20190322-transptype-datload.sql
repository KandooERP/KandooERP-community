--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: transptype
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/transptype.unl SELECT * FROM transptype;
drop table transptype;


create table "informix".transptype 
(
cmpy_code char(2),
transp_type_code nchar(3),
desc_text nvarchar(40),
add_drop_amt decimal(16,4)
);


LOAD FROM unl20190322/transptype.unl INSERT INTO transptype;
