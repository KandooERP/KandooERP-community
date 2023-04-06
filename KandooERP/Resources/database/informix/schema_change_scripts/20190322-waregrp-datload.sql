--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: waregrp
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/waregrp.unl SELECT * FROM waregrp;
drop table waregrp;


create table "informix".waregrp 
(
cmpy_code char(2),
waregrp_code nvarchar(8),
name_text nvarchar(40),
cartage_ind nchar(1),
conv_uom_ind nchar(1),
cmpy1_text nvarchar(60),
cmpy2_text nvarchar(60),
cmpy3_text nvarchar(60)
);


LOAD FROM unl20190322/waregrp.unl INSERT INTO waregrp;
