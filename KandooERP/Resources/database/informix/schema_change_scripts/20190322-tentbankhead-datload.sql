--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: salesmgr
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/salesmgr.unl SELECT * FROM salesmgr;
drop table salesmgr;

create table "informix".salesmgr 
(
cmpy_code char(2),
mgr_code nvarchar(8),
name_text nvarchar(30)
);

LOAD FROM unl20190322/salesmgr.unl INSERT INTO salesmgr;
