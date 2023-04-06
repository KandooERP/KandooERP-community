--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: tax
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/tax.unl SELECT * FROM tax;
drop table tax;

create table "informix".tax 
(
cmpy_code char(2),
tax_code nchar(3),
desc_text nvarchar(30),
tax_per decimal(6,3),
start_date date,
buy_acct_code nvarchar(18),
sell_acct_code nvarchar(18),
calc_method_flag char(1),
freight_per decimal(6,3),
hand_per decimal(6,3),
uplift_per float,
buy_ctl_acct_code nvarchar(18),
buy_clr_acct_code nvarchar(18),
buy_adj_acct_code nvarchar(18),
sell_ctl_acct_code nvarchar(18),
sell_clr_acct_code nvarchar(18),
sell_adj_acct_code nvarchar(18),
badj_ctl_acct_code nvarchar(18),
sadj_ctl_acct_code nvarchar(18)
);

LOAD FROM unl20190322/tax.unl INSERT INTO tax;
