--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: statsper
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE statsper ADD CONSTRAINT PRIMARY KEY (
sale_code,
mgr_code,
year_num,
type_code,
int_num,
cmpy_code
) CONSTRAINT pk_statsper;
