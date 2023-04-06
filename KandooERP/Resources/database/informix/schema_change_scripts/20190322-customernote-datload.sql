--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: customernote
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/customernote.unl SELECT * FROM customernote;
drop table customernote;



create table "informix".customernote 
(
cmpy_code char(2),
cust_code nvarchar(8),
note_date date,
note_num decimal(5,2),
note_text nvarchar(200)
);


LOAD FROM unl20190322/customernote.unl INSERT INTO customernote;
