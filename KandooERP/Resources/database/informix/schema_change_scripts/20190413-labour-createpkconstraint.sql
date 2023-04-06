--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: labour
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE labour ADD CONSTRAINT PRIMARY KEY (
cust_code,
type_code,
part_code,
prodgrp_code,
maingrp_code,
ware_code,
effective_date,
cmpy_code
) CONSTRAINT pk_labour;
