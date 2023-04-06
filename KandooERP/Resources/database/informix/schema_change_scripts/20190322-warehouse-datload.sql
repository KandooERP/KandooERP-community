--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list:  warehouse
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/warehouse.unl SELECT * FROM warehouse;
drop table warehouse;

create table "informix".warehouse 
(
cmpy_code char(2),
ware_code nchar(3),
desc_text nvarchar(30,0),
addr1_text nvarchar(40,0),
addr2_text nvarchar(40,0),
city_text nvarchar(40,0),
state_code nvarchar(6,0),
post_code nvarchar(10,0),
country_code nvarchar(40,0),
contact_text nvarchar(40,0),
tele_text nchar(20),
auto_run_num smallint,
back_order_ind nchar(1),
confirm_flag nchar(1),
pick_flag char(1),
pick_print_code nvarchar(20),
connote_flag char(1),
connote_print_code nvarchar(20),
ship_label_flag char(1),
ship_print_code nvarchar(20),
inv_flag char(1),
inv_print_code nvarchar(20),
acct_mask_code char(18),
next_pick_num integer,
pick_reten_num integer,
next_sched_date datetime year to minute,
cart_area_code nchar(3),
map_ref_text nvarchar(10),
waregrp_code nvarchar(8),
primary key (cmpy_code,ware_code) 
);



LOAD FROM unl20190322/warehouse.unl INSERT INTO warehouse;
