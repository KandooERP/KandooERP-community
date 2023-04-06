--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: prodadjtype
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/prodadjtype.unl SELECT * FROM prodadjtype;
drop table prodadjtype;


create table "informix".prodadjtype 
(
cmpy_code char(2),
adj_type_code nvarchar(8),
desc_text nvarchar(40),
adj_acct_code nvarchar(18)
);

LOAD FROM unl20190322/prodadjtype.unl INSERT INTO prodadjtype;
