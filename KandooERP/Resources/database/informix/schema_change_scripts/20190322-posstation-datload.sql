--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: posstation
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/posstation.unl SELECT * FROM posstation;
drop table posstation;


create table "informix".posstation 
(
cmpy_code char(2),
station_code nvarchar(8),
station_desc nvarchar(30),
locn_code nvarchar(8),
default_entry nchar(1),
learn_mode nchar(1),
last_tran_detl nvarchar(35),
item_quick_entry nchar(1),
def_pmnt_type nchar(2)
);


LOAD FROM unl20190322/posstation.unl INSERT INTO posstation;
