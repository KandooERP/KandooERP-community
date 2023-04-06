--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: labelhead
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/labelhead.unl SELECT * FROM labelhead;
drop table labelhead;

create table "informix".labelhead 
(
cmpy_code char(2),
label_code nchar(3),
desc_text nvarchar(30),
print_code nvarchar(20)
);


LOAD FROM unl20190322/labelhead.unl INSERT INTO labelhead;
