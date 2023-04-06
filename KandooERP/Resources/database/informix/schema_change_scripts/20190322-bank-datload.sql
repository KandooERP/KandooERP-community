--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: bank
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/bank.unl SELECT * FROM bank;
drop table bank;

create table "informix".bank 
(
bank_code nvarchar(9),
cmpy_code char(2),
acct_code nvarchar(18),
currency_code nchar(3),
name_acct_text nvarchar(40),
next_cheque_num integer,
iban nvarchar(40),
state_bal_amt decimal(16,2),
sheet_num smallint,
name_text nvarchar(40),
branch_text nvarchar(40),
acct_name_text nvarchar(40),
state_base_bal_amt decimal(16,4),
type_code nvarchar(8),
next_eft_run_num integer,
next_eft_ref_num integer,
remit_text nvarchar(20),
bic_code nvarchar(11),
user_text nvarchar(6),
eft_rpt_ind smallint,
next_cheq_run_num integer,
ext_file_ind nchar(1),
ext_path_text nvarchar(40),
ext_file_text nvarchar(20)
);


LOAD FROM unl20190322/bank.unl INSERT INTO bank;
