--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: cartage
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/cartage.unl SELECT * FROM cartage;
drop table cartage;


create table "informix".cartage 
(
cmpy_code char(2),
ord_ind nchar(1),
cartarea_code nchar(3),
effective_date date,
type_code nchar(3),
part_code nvarchar(15),
prodgrp_code nchar(3),
maingrp_code nchar(3),
cust_code nvarchar(8),
unit_rate_amt decimal(16,4),
uom_code nchar(4),
rate_ind nchar(1),
class_code nvarchar(8),
ware_code nchar(3),
cart_calc_ind nchar(1),
notion_cart_code nchar(5)
);


LOAD FROM unl20190322/cartage.unl INSERT INTO cartage;
