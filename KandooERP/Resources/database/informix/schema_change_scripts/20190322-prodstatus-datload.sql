--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: prodstatus
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/prodstatus.unl SELECT * FROM prodstatus;
drop table prodstatus;

create table "informix".prodstatus 
(
cmpy_code char(2),
part_code nvarchar(15),
ware_code nchar(3),
onhand_qty float,
onord_qty float,
reserved_qty float,
back_qty float,
forward_qty float,
reorder_point_qty float,
reorder_qty float,
max_qty float,
critical_qty float,
special_flag char(1),
list_amt decimal(16,4),
price1_amt decimal(16,4),
price2_amt decimal(16,4),
price3_amt decimal(16,4),
price4_amt decimal(16,4),
price5_amt decimal(16,4),
price6_amt decimal(16,4),
price7_amt decimal(16,4),
price8_amt decimal(16,4),
price9_amt decimal(16,4),
status_ind nchar(1),
status_date date,
nonstk_pick_flag char(1),
pricel_per float,
pricel_ind nchar(1),
price1_per float,
price1_ind nchar(1),
price2_per float,
price2_ind nchar(1),
price3_per float,
price3_ind nchar(1),
price4_per float,
price4_ind nchar(1),
price5_per float,
price5_ind nchar(1),
price6_per float,
price6_ind nchar(1),
price7_per float,
price7_ind nchar(1),
price8_per float,
price8_ind nchar(1),
price9_per float,
price9_ind nchar(1),
last_list_date date,
last_price_date date,
est_cost_amt decimal(16,4),
act_cost_amt decimal(16,4),
wgted_cost_amt decimal(16,4),
for_cost_amt decimal(16,4),
for_curr_code nchar(3),
last_cost_date date,
bin1_text nvarchar(15),
bin2_text nvarchar(15),
bin3_text nvarchar(15),
last_sale_date date,
last_receipt_date date,
seq_num integer,
phys_count_qty float,
stocked_flag char(1),
last_stcktake_date date,
stcktake_days smallint,
min_ord_qty float,
replenish_ind nchar(1),
abc_ind nchar(1),
avg_qty float,
avg_cost_amt decimal(16,4),
stockturn_qty float,
transit_qty float,
sale_tax_code nchar(3),
purch_tax_code nchar(3),
sale_tax_amt decimal(16,4),
purch_tax_amt decimal(16,4)
);

LOAD FROM unl20190322/prodstatus.unl INSERT INTO prodstatus;