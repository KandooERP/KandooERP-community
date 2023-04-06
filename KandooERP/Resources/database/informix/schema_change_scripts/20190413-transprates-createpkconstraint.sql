--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: transprates
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE transprates ADD CONSTRAINT PRIMARY KEY (
rate_code,
transp_type_code,
veh_type_code,
drv_type_code,
driver_code,
cart_area_code,
part_code,
prodgrp_code,
maingrp_code,
ware_code,
cmpy_code
) CONSTRAINT pk_transprates;
