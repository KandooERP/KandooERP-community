--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: apparms
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/apparms.unl SELECT * FROM apparms;
drop table apparms;

create table "informix".apparms 
(
cmpy_code char(2),
parm_code nchar(1),
next_vouch_num integer,
next_deb_num integer,
pur_jour_code nvarchar(10),
chq_jour_code nvarchar(10),
pay_acct_code nvarchar(18),
bank_acct_code nvarchar(18),
freight_acct_code nvarchar(18),
salestax_acct_code nvarchar(18),
disc_acct_code nvarchar(18),
exch_acct_code nvarchar(18),
last_chq_prnt_date date,
last_post_date date,
last_aging_date date,
last_del_date date,
last_mail_date date,
gl_flag char(1),
hist_flag char(1),
gl_detl_flag char(1),
vouch_approve_flag char(1),
report_ord_flag char(1),
distrib_style nchar(1)
);

LOAD FROM unl20190322/apparms.unl INSERT INTO apparms;
