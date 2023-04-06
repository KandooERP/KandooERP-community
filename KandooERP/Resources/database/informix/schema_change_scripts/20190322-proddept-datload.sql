--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: proddept
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/proddept.unl SELECT * FROM proddept;
drop table proddept;


create table "informix".proddept 
(
cmpy_code char(2),
dept_ind nchar(1),
dept_code nchar(3),
desc_text nvarchar(30)
);


LOAD FROM unl20190322/proddept.unl INSERT INTO proddept;
