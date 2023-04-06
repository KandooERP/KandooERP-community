--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: glparms
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/glparms.unl SELECT * FROM glparms;
drop table glparms;

create table "informix".glparms 
(
cmpy_code char(2),
key_code nchar(1),
next_jour_num integer,
next_seq_num integer,
next_post_num integer,
next_load_num integer,
next_consol_num integer,
gj_code nchar(3),
last_depr_date date,
rj_code nchar(3),
cb_code nchar(3),
last_post_date date,
last_update_date date,
last_close_date date,
last_del_date date,
cash_book_flag char(1),
post_susp_flag char(1),
susp_acct_code nvarchar(18),
exch_acct_code nvarchar(18),
unexch_acct_code nvarchar(18),
clear_acct_code nvarchar(18),
post_total_amt money(17,2),
control_tot_flag char(1),
use_clear_flag char(1),
use_currency_flag char(1),
base_currency_code nchar(3),
budg1_text nvarchar(30),
budg1_close_flag nchar(1),
budg2_text nvarchar(30),
budg2_close_flag nchar(1),
budg3_text nvarchar(30),
budg3_close_flag nchar(1),
budg4_text nvarchar(30),
budg4_close_flag nchar(1),
budg5_text nvarchar(30),
budg5_close_flag nchar(1),
budg6_text nvarchar(30),
budg6_close_flag nchar(1),
style_ind smallint,
site_code nchar(3),
acrl_code nchar(3),
rev_acrl_code nchar(3),
last_acrl_yr_num smallint,
last_acrl_per_num smallint
);

LOAD FROM unl20190322/glparms.unl INSERT INTO glparms;
