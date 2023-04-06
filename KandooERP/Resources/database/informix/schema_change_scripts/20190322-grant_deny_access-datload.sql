--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: grant_deny_access
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/grant_deny_access.unl SELECT * FROM grant_deny_access;
drop table grant_deny_access;

create table "informix".grant_deny_access 
(
cmpy_code char(2),
menu1_code nchar(1),
menu2_code nchar(1),
menu3_code nchar(1),
sign_on_code nvarchar(8,0),
grant_deny_flag char(1)
);

LOAD FROM unl20190322/grant_deny_access.unl INSERT INTO grant_deny_access;
