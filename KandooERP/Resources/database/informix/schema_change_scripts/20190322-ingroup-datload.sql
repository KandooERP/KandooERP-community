--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: ingroup
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/ingroup.unl SELECT * FROM ingroup;
drop table ingroup;

create table "informix".ingroup 
(
cmpy_code char(2),
type_ind nchar(1),
ingroup_code nvarchar(15),
desc_text nvarchar(40,0),
primary key (cmpy_code,type_ind,ingroup_code) 
);

LOAD FROM unl20190322/ingroup.unl INSERT INTO ingroup;
