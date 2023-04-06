--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: purchtype
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/purchtype.unl SELECT * FROM purchtype;
drop table purchtype;


create table "informix".purchtype 
(
cmpy_code char(2),
purchtype_code nchar(3),
desc_text nvarchar(30),
format_ind nchar(2),
rms_flag char(1),
footer1_text nvarchar(60),
footer2_text nvarchar(60),
footer3_text nvarchar(60)
);


LOAD FROM unl20190322/purchtype.unl INSERT INTO purchtype;
