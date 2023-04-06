--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: uom
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/uom.unl SELECT * FROM uom;
drop table uom;

create table "informix".uom 
(
cmpy_code char(2),
uom_code nchar(4),
desc_text nvarchar(30,0),
primary key (cmpy_code,uom_code) 
);
LOAD FROM unl20190322/uom.unl INSERT INTO uom;
