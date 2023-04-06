--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: kandoousercmpy
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/kandoousercmpy.unl SELECT * FROM kandoousercmpy;
drop table kandoousercmpy;

create table "informix".kandoousercmpy 
(
sign_on_code nvarchar(8,0),
cmpy_code char(2),
acct_mask_code char(18)
);

LOAD FROM unl20190322/kandoousercmpy.unl INSERT INTO kandoousercmpy;
