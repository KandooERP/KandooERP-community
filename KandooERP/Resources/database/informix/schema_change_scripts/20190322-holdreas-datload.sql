--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: holdreas
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/holdreas.unl SELECT * FROM holdreas;
drop table holdreas;


create table "informix".holdreas 
(
cmpy_code char(2),
hold_code nchar(3),
reason_text nvarchar(30)
);


LOAD FROM unl20190322/holdreas.unl INSERT INTO holdreas;
