--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: stnd_grp
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/stnd_grp.unl SELECT * FROM stnd_grp;
drop table stnd_grp;

create table "informix".stnd_grp 
(
cmpy_code char(2),
group_code nchar(2),
desc_text nvarchar(40)
);

LOAD FROM unl20190322/stnd_grp.unl INSERT INTO stnd_grp;
