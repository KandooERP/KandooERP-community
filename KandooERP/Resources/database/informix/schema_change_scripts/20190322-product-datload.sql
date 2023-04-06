--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: product
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/product.unl SELECT * FROM product;
drop table product;

create table "informix".product 
(
cmpy_code char(2),
part_code nchar(15),
desc_text nvarchar(36),
desc2_text nvarchar(36),
cat_code nchar(3),
class_code nvarchar(8),
ref_code nchar(10),
alter_part_code nchar(15),
super_part_code nchar(15),
compn_part_code nchar(15),
tariff_code nchar(12),
oem_text nvarchar(30),
weight_qty float,
cubic_qty float,
serial_flag char(1),
setup_date date,
target_turn_qty float,
stock_turn_qty float,
stock_days_num decimal(7,0),
last_calc_date date,
pur_uom_code nchar(4),
pur_stk_con_qty float,
stock_uom_code nchar(4),
stk_sel_con_qty float,
sell_uom_code nchar(4),
outer_qty decimal(7),
outer_sur_per decimal(6,3),
bar_code_text nvarchar(20),
days_lead_num smallint,
vend_code nchar(8),
min_ord_qty float,
days_warr_num integer,
inven_method_ind nchar(1),
total_tax_flag char(1),
status_ind nchar(1),
status_date date,
short_desc_text nvarchar(15),
min_month_amt decimal(16,2),
min_quart_amt decimal(16,2),
min_year_amt decimal(16,2),
prodgrp_code nchar(3),
maingrp_code nchar(3),
back_order_flag char(1),
disc_allow_flag char(1),
bonus_allow_flag char(1),
trade_in_flag char(1),
price_inv_flag char(1),
ref1_code nvarchar(10),
ref2_code nvarchar(10),
ref3_code nvarchar(10),
ref4_code nvarchar(10),
ref5_code nvarchar(10),
ref6_code nvarchar(10),
ref7_code nvarchar(10),
ref8_code nvarchar(10),
price_uom_code nvarchar(4),
area_qty float,
length_qty float,
pack_qty float,
dg_code nchar(3),
ware_code nchar(3)
);


LOAD FROM unl20190322/product.unl INSERT INTO product;
