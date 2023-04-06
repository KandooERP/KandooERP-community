--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: kandoomodule
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/kandoomodule.unl SELECT * FROM kandoomodule;
drop table kandoomodule;

create table "informix".kandoomodule 
(
cmpy_code char(2),
user_code nvarchar(8,0),
module_code nchar(1),
security_ind nchar(1)
);

LOAD FROM unl20190322/kandoomodule.unl INSERT INTO kandoomodule;
