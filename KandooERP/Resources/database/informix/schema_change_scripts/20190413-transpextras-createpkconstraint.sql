--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: transpextras
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE transpextras ADD CONSTRAINT PRIMARY KEY (
rate_code,
transp_type_code,
veh_type_code,
drv_type_code,
driver_code,
cmpy_text,
cart_area_code,
part_code,
prodgrp_code,
maingrp_code
) CONSTRAINT pk_transpextras;
