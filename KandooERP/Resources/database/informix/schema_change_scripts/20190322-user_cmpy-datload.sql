--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: user_cmpy
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/user_cmpy.unl SELECT * FROM user_cmpy;
drop table user_cmpy;

create table "informix".user_cmpy 
(
sign_on_code nvarchar(8,0),
cmpy_code char(2)
);

LOAD FROM unl20190322/user_cmpy.unl INSERT INTO user_cmpy;
