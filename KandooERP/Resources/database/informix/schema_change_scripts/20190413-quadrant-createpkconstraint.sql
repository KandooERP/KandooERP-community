--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: quadrant
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE quadrant ADD CONSTRAINT PRIMARY KEY (
ware_code,
map_num,
cmpy_code
) CONSTRAINT pk_quadrant;
