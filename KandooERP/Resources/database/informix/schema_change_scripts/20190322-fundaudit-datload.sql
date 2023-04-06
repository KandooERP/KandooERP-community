--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: fundaudit
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/fundaudit.unl SELECT * FROM fundaudit;
drop table fundaudit;

create table "informix".fundaudit 
(
cmpy_code char(2),
acct_code nvarchar(18),
old_limit_amt decimal(16,2),
new_limit_amt decimal(16,2),
amend_date date,
amend_code nvarchar(8)
);

LOAD FROM unl20190322/fundaudit.unl INSERT INTO fundaudit;
