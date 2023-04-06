--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: arparms
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/arparms.unl SELECT * FROM arparms;
drop table arparms;


create table "informix".arparms 
(
cmpy_code char(2),
parm_code nchar(1),
nextinv_num integer,
nextcash_num integer,
nextcredit_num integer,
sales_jour_code nvarchar(10),
cash_jour_code nvarchar(10),
freight_tax_code nchar(3),
handling_tax_code nchar(3),
cash_acct_code nvarchar(18),
ar_acct_code nvarchar(18),
freight_acct_code nvarchar(18),
tax_acct_code nvarchar(18),
disc_acct_code nvarchar(18),
exch_acct_code nvarchar(18),
lab_acct_code nvarchar(18),
cust_age_date date,
last_stmnt_date date,
last_post_date date,
last_del_date date,
last_mail_date date,
hist_flag char(1),
inven_tax_flag char(1),
gl_detail_flag char(1),
gl_flag char(1),
detail_to_gl_flag char(1),
last_rec_date date,
costings_ind nchar(1),
interest_per decimal(5,2),
country_code nchar(3),
country_text nvarchar(40),
cred_amt decimal(10,2),
currency_code nchar(3),
job_flag char(1),
price_tax_flag char(1),
inv_ref1_text nvarchar(16),
inv_ref2a_text nvarchar(8),
inv_ref2b_text nvarchar(8),
credit_ref1_text nvarchar(16),
credit_ref2a_text nvarchar(8),
credit_ref2b_text nvarchar(8),
show_tax_flag char(1),
show_seg_flag char(1),
report_ord_flag char(1),
corp_drs_flag char(1),
next_bank_dep_num integer,
reason_code nchar(3),
ref1_text nvarchar(20),
ref1_ind nchar(1),
ref2_text nvarchar(20),
ref2_ind nchar(1),
ref3_text nvarchar(20),
ref3_ind nchar(1),
ref4_text nvarchar(20),
ref4_ind nchar(1),
ref5_text nvarchar(20),
ref5_ind nchar(1),
ref6_text nvarchar(20),
ref6_ind nchar(1),
ref7_text nvarchar(20),
ref7_ind nchar(1),
ref8_text nvarchar(20),
ref8_ind nchar(1),
batch_cash_receipt nchar(1),
batch_no smallint,
consolidate_flag char(1),
stmnt_ind nchar(1)
);


LOAD FROM unl20190322/arparms.unl INSERT INTO arparms;
