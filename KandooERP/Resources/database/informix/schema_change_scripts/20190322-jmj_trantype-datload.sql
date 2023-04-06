--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: jmj_trantype
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/jmj_trantype.unl SELECT * FROM jmj_trantype;
drop table jmj_trantype;


create table "informix".jmj_trantype 
(
cmpy_code char(2),
trans_code decimal(2,0),
record_ind nchar(1),
imprest_ind nchar(1),
desc_text nvarchar(30),
cr_acct_code nvarchar(18),
db_acct_code nvarchar(18),
debt_type_code nchar(3)
);


LOAD FROM unl20190322/jmj_trantype.unl INSERT INTO jmj_trantype;
