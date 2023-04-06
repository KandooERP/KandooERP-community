--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: cashreceipt
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/cashreceipt.unl SELECT * FROM cashreceipt;
drop table cashreceipt;

create table "informix".cashreceipt 
(
cmpy_code char(2),
cust_code nvarchar(8),
cash_num integer,
cheque_text nvarchar(10),
cash_acct_code nvarchar(18),
entry_code nvarchar(8),
entry_date date,
cash_date date,
year_num smallint,
period_num smallint,
cash_amt decimal(16,2),
applied_amt decimal(16,2),
disc_amt decimal(16,2),
on_state_flag char(1),
posted_flag char(1),
next_num smallint,
com1_text nvarchar(30),
com2_text nvarchar(30),
job_code integer,
cash_type_ind nchar(1),
chq_date date,
drawer_text nvarchar(20),
bank_text nvarchar(15),
branch_text nvarchar(20),
banked_flag char(1),
banked_date date,
currency_code nchar(3),
conv_qty float,
bank_code nvarchar(9),
bank_currency_code nchar(3),
bank_dep_num integer,
jour_num integer,
post_date date,
stat_date date,
locn_code nchar(3),
order_num integer,
card_exp_date char(4),
batch_no smallint
);

LOAD FROM unl20190322/cashreceipt.unl INSERT INTO cashreceipt;
