--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: invoicedetl
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/invoicedetl.unl SELECT * FROM invoicedetl;
drop table invoicedetl;

create table "informix".invoicedetl 
(
cmpy_code nchar(2),
cust_code nchar(8),
inv_num integer,
line_num smallint,
part_code nchar(15),
ware_code nchar(3),
cat_code nchar(3),
ord_qty float,
ship_qty float,
prev_qty float,
back_qty float,
ser_flag char(1),
ser_qty float,
line_text nvarchar(40),
uom_code nchar(4),
unit_cost_amt decimal(16,4),
ext_cost_amt decimal(16,2),
disc_amt decimal(16,2),
unit_sale_amt decimal(16,4),
ext_sale_amt decimal(16,2),
unit_tax_amt decimal(16,4),
ext_tax_amt decimal(16,2),
line_total_amt decimal(16,2),
seq_num integer,
line_acct_code nvarchar(18),
level_code nchar(1),
comm_amt decimal(16,2),
comp_per decimal(6,3),
tax_code nchar(3),
order_line_num smallint,
order_num integer,
disc_per decimal(6,3),
offer_code nchar(6),
sold_qty float,
bonus_qty float,
ext_bonus_amt decimal(16,2),
ext_stats_amt decimal(16,2),
prodgrp_code nchar(3),
maingrp_code nchar(3),
list_price_amt decimal(16,4),
var_code smallint,
activity_code nchar(8),
jobledger_seq_num integer,
contract_line_num smallint,
price_uom_code nchar(4),
return_qty float,
km_qty float,
proddept_code nchar(3)
);

LOAD FROM unl20190322/invoicedetl.unl INSERT INTO invoicedetl;
