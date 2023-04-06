--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: statprod
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE statprod ADD CONSTRAINT PRIMARY KEY (
maingrp_code,
prodgrp_code,
part_code,
dept_code,
year_num,
type_code,
int_num,
cmpy_code
) CONSTRAINT pk_statprod;
