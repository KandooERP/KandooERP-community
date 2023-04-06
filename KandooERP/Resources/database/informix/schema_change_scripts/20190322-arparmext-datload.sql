--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: arparmext
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

-- UNLOAD TO unl/arparmext.unl SELECT * FROM arparmext;
drop table arparmext;

create table "informix".arparmext 
(
cmpy_code char(2),
last_int_date date,
int_acct_code nvarchar(18),
writeoff_acct_code nvarchar(18),
last_writeoff_date date
);

LOAD FROM unl20190322/arparmext.unl INSERT INTO arparmext;
