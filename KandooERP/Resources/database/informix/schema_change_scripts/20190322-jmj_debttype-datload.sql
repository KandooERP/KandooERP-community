--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: jmj_debttype
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/jmj_debttype.unl SELECT * FROM jmj_debttype;
drop table jmj_debttype;


create table "informix".jmj_debttype 
(
cmpy_code char(2),
debt_type_code nchar(3),
desc_text nvarchar(30)
);

LOAD FROM unl20190322/jmj_debttype.unl INSERT INTO jmj_debttype;
