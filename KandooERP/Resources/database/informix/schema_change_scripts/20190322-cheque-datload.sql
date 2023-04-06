--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: cheque
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/cheque.unl SELECT * FROM cheque;
drop table cheque;


create table "informix".cheque 
(
cmpy_code char(2),
vend_code nvarchar(8),
cheq_code integer,
com3_text nvarchar(20),
bank_acct_code char(18),
entry_code nvarchar(8),
entry_date date,
cheq_date date,
year_num smallint,
period_num smallint,
pay_amt decimal(16,2),
apply_amt decimal(16,2),
disc_amt decimal(16,2),
hist_flag char(1),
jour_num integer,
post_flag char(1),
recon_flag char(1),
next_appl_num smallint,
com1_text nvarchar(30),
com2_text nvarchar(30),
rec_state_num smallint,
rec_line_num smallint,
part_recon_flag char(1),
currency_code nchar(3),
conv_qty float,
bank_code nvarchar(9),
bank_currency_code nchar(3),
post_date date,
net_pay_amt decimal(16,2),
withhold_tax_ind nchar(1),
tax_code nchar(3),
tax_per decimal(6,3),
pay_meth_ind nchar(1),
eft_run_num integer,
doc_num serial not null ,
source_ind nchar(1),
source_text nvarchar(8),
tax_amt decimal(16,2),
contra_amt decimal(16,2),
contra_trans_num integer,
whtax_rep_ind nchar(1)
);


LOAD FROM unl20190322/cheque.unl INSERT INTO cheque;
