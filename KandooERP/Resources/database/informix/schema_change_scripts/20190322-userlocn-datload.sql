--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: userlocn
--# author: huhouserlocn
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/userlocn.unl SELECT * FROM userlocn;
drop table userlocn;

create table "informix".userlocn 
(
cmpy_code char(2),
sign_on_code nvarchar(8),
locn_code nchar(3)
);

LOAD FROM unl20190322/userlocn.unl INSERT INTO userlocn;
