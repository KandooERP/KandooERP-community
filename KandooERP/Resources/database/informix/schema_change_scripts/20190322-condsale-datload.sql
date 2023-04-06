--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: condsale
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/condsale.unl SELECT * FROM condsale;
drop table condsale;


create table "informix".condsale 
(
cmpy_code char(2),
cond_code nchar(3),
desc_text nvarchar(30),
prodline_disc_flag char(1),
scheme_amt decimal(16,2),
tier_disc_flag char(1)
);


LOAD FROM unl20190322/condsale.unl INSERT INTO condsale;
