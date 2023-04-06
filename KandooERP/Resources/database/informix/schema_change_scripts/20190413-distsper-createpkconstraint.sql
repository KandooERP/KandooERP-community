--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: distsper
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE distsper ADD CONSTRAINT PRIMARY KEY (
mgr_code,
sale_code,
maingrp_code,
prodgrp_code,
part_code,
year_num,
int_num,
cmpy_code
) CONSTRAINT pk_distsper;
