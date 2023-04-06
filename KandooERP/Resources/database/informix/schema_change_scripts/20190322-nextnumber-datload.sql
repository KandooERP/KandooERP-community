--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: nextnumber
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/nextnumber.unl SELECT * FROM nextnumber;
drop table nextnumber;

create table "informix".nextnumber 
(
cmpy_code char(2),
tran_type_ind nchar(3),
flex_code nvarchar(18),
next_num integer,
alloc_ind nchar(1)
);

LOAD FROM unl20190322/nextnumber.unl INSERT INTO nextnumber;
