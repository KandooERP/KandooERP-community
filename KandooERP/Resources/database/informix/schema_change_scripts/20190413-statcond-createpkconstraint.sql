--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: statcond
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE statcond ADD CONSTRAINT PRIMARY KEY (
mgr_code,
sale_code,
cust_code,
cond_code,
year_num,
type_code,
int_num,
cmpy_code
) CONSTRAINT pk_statcond;
