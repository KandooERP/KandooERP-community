--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: credreas
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/credreas.unl SELECT * FROM credreas;
drop table credreas;

create table "informix".credreas 
(
cmpy_code char(2),
reason_code nchar(3),
reason_text nvarchar(30)
);

LOAD FROM unl20190322/credreas.unl INSERT INTO credreas;
