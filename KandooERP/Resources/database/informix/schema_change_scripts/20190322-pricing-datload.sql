--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: pricing
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/pricing.unl SELECT * FROM pricing;
drop table pricing;

create table "informix".pricing 
(
cmpy_code char(2),
offer_code nchar(6),
desc_text nvarchar(40),
type_ind smallint,
start_date date,
end_date date,
maingrp_code nchar(3),
prodgrp_code nchar(3),
part_code nvarchar(15),
disc_price_amt decimal(16,4),
disc_per decimal(6,3),
uom_code nchar(4),
class_code nvarchar(8),
list_level_ind nchar(1),
prom1_text nvarchar(60),
prom2_text nvarchar(60),
ware_code nchar(3)
);

LOAD FROM unl20190322/pricing.unl INSERT INTO pricing;
