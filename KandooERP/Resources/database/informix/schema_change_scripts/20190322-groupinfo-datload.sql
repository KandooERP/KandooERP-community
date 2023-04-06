--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: groupinfo
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/groupinfo.unl SELECT * FROM groupinfo;
drop table groupinfo;

create table "informix".groupinfo 
(
cmpy_code char(2),
group_code nvarchar(7),
desc_text nvarchar(40)
);

LOAD FROM unl20190322/groupinfo.unl INSERT INTO groupinfo;
