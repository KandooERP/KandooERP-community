--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: userlocn
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/usermsg.unl SELECT * FROM usermsg;
drop table usermsg;

create table "informix".usermsg 
(
cmpy_code char(2),
line1_text nvarchar(60),
line2_text nvarchar(60)
);

LOAD FROM unl20190322/usermsg.unl INSERT INTO usermsg;
