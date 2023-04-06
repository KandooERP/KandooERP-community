--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: ipparms
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/ipparms.unl SELECT * FROM ipparms;
drop table ipparms;

create table "informix".ipparms 
(
cmpy_code char(2),
key_num smallint,
ref1_text nvarchar(20),
ref1_shrt_text nvarchar(10),
ref2_text nvarchar(20),
ref2_shrt_text nvarchar(10),
ref3_text nvarchar(20),
ref3_shrt_text nvarchar(10),
ref4_text nvarchar(20),
ref4_shrt_text nvarchar(10),
ref5_text nvarchar(20),
ref5_shrt_text nvarchar(10),
ref6_text nvarchar(20),
ref6_shrt_text nvarchar(10),
ref7_text nvarchar(20),
ref7_shrt_text nvarchar(10),
ref8_text nvarchar(20),
ref8_shrt_text nvarchar(10),
ref9_text nvarchar(20),
ref9_shrt_text nvarchar(10),
refa_text nvarchar(20),
refa_shrt_text nvarchar(10)
);

LOAD FROM unl20190322/ipparms.unl INSERT INTO ipparms;
