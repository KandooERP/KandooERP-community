--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: salearea
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/salearea.unl SELECT * FROM salearea;
drop table salearea;


create table "informix".salearea 
(
cmpy_code char(2),
area_code nchar(5),
desc_text nvarchar(30),
dept_text nvarchar(60)
);

LOAD FROM unl20190322/salearea.unl INSERT INTO salearea;
