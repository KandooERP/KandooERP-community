--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: inparms
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/inparms.unl SELECT * FROM inparms;
drop table inparms;


create table "informix".inparms 
(
cmpy_code char(2),
parm_code nchar(1),
inv_journal_code nchar(3),
last_post_date date,
last_del_date date,
last_cost_date date,
next_work_num integer,
auto_trans_flag char(1),
next_trans_num integer,
auto_issue_flag char(1),
next_issue_num integer,
auto_adjust_flag char(1),
next_adjust_num integer,
auto_recpt_flag char(1),
next_recpt_num integer,
int_place_num smallint,
dec_place_num smallint,
gl_post_flag char(1),
gl_del_flag char(1),
hist_flag char(1),
cycle_num smallint,
cost_ind nchar(1),
ref1_text nvarchar(20),
ref2a_text nvarchar(10),
ref2b_text nvarchar(10),
ref_reqd_ind nchar(1),
mast_ware_code nchar(3),
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
auto_class_flag char(1),
next_class_num integer,
ibt_ware_code nchar(3),
rec_post_flag char(1),
barcode_type nvarchar(8),
barcode_flag char(1),
next_barcode_num integer
);


LOAD FROM unl20190322/inparms.unl INSERT INTO inparms;
