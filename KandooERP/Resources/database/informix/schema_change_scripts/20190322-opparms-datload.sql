--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: opparms
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/opparms.unl SELECT * FROM opparms;
drop table opparms;


create table "informix".opparms 
(
cmpy_code char(2),
key_num nchar(1),
next_ord_num integer,
next_pick_num integer,
last_del_date date,
days_pick_num smallint,
cal_available_flag nchar(1),
show_seg_flag nchar(1),
sellup_per decimal(5,2),
surcharge_amt decimal(16,2),
log_flag char(1),
ship_label_ind nchar(1),
ship_label_qty float,
so_hold_code nchar(3),
ps_hold_code nchar(3),
cf_hold_code nchar(3),
max_inv_cycle_num integer,
cr_hold_code nchar(3),
pick_batch_num integer,
lim_hold_code nchar(3),
prod_sel_style nchar(1),
cust_notes_popup nchar(1),
allow_edit_flag char(1)
);



LOAD FROM unl20190322/opparms.unl INSERT INTO opparms;
