--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: fundsapproved
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

-- UNLOAD TO unl/fundsapproved.unl SELECT * FROM fundsapproved;
drop table fundsapproved;


create table "informix".fundsapproved 
(
cmpy_code char(2),
acct_code nvarchar(18),
fund_type_ind nchar(3),
limit_amt decimal(16,2),
locn_text nvarchar(30),
approval_date date,
capital_ref nvarchar(20),
entry_date date,
entry_code nvarchar(8),
amend_date date,
amend_code nvarchar(8),
active_flag char(1),
complete_date date
);

LOAD FROM unl20190322/fundsapproved.unl INSERT INTO fundsapproved;
