--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: labeldetl
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/labeldetl.unl SELECT * FROM labeldetl;
drop table labeldetl;


create table "informix".labeldetl 
(
cmpy_code char(2),
label_code nchar(3),
line_num smallint,
line_text nvarchar(70)
);

LOAD FROM unl20190322/labeldetl.unl INSERT INTO labeldetl;
