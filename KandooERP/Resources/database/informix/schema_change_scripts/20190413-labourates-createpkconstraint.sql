--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: labourates
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE labourates ADD CONSTRAINT PRIMARY KEY (
labour_class_code,
part_code,
class_code,
prodgrp_code,
maingrp_code,
ware_code,
effective_date,
cmpy_code
) CONSTRAINT pk_labourates;
