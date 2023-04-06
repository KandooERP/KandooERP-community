--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: stateinfo
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/stateinfo.unl SELECT * FROM stateinfo;
drop table stateinfo;




create table "informix".stateinfo 
(
cmpy_code char(2),
dun_code nchar(3),
all1_text nvarchar(35),
all2_text nvarchar(35),
cur1_text nvarchar(35),
cur2_text nvarchar(35),
over1_1_text nvarchar(35),
over1_2_text nvarchar(35),
over30_1_text nvarchar(35),
over30_2_text nvarchar(35),
over60_1_text nvarchar(35),
over60_2_text nvarchar(35),
over90_1_text nvarchar(35),
over90_2_text nvarchar(35)
);

LOAD FROM unl20190322/stateinfo.unl INSERT INTO stateinfo;
