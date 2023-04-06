--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: distterr
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE distterr ADD CONSTRAINT PRIMARY KEY (
area_code,
terr_code,
maingrp_code,
prodgrp_code,
part_code,
year_num,
int_num,
cmpy_code
) CONSTRAINT pk_distterr;
