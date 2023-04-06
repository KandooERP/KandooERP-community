--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: posmatprice
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE posmatprice ADD CONSTRAINT PRIMARY KEY (
cust_code,
cat_code,
cmpy_code
) CONSTRAINT pk_posmatprice;
