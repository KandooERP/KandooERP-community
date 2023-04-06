--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: statware
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE statware ADD CONSTRAINT PRIMARY KEY (
ware_code,
maingrp_code,
prodgrp_code,
part_code,
dept_code,
year_num,
type_code,
int_num,
cmpy_code
) CONSTRAINT pk_statware;
