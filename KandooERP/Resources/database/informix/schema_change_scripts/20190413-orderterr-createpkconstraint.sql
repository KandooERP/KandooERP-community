--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: orderterr
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE orderterr ADD CONSTRAINT PRIMARY KEY (
area_code,
territory_code,
mgr_code,
sale_code,
cust_code,
year_num,
type_code,
int_num,
cmpy_code
) CONSTRAINT pk_orderterr;
