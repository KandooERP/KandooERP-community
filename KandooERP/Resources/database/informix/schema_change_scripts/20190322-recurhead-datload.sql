--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: recurhead
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/recurhead.unl SELECT * FROM recurhead;
drop table recurhead;



create table "informix".recurhead 
(
cmpy_code char(2),
recur_code nvarchar(8),
desc_text nvarchar(30),
vend_code nvarchar(8),
inv_text nvarchar(20),
term_code nchar(3),
tax_code nchar(3),
start_date date,
end_date date,
int_ind nchar(1),
int_num smallint,
hold_code nchar(2),
group_text nvarchar(8),
goods_amt decimal(16,2),
tax_amt decimal(16,2),
total_amt decimal(16,2),
dist_amt decimal(16,2),
dist_qty float,
curr_code nchar(3),
conv_qty float,
run_date date,
run_code nvarchar(8),
run_num smallint,
max_run_num smallint,
last_vouch_code integer,
last_vouch_date date,
last_year_num smallint,
last_period_num smallint,
next_vouch_date date,
next_due_date date,
rev_num smallint,
rev_date date,
rev_code nvarchar(8),
line_num smallint,
com1_text nvarchar(60)
);



LOAD FROM unl20190322/recurhead.unl INSERT INTO recurhead;
