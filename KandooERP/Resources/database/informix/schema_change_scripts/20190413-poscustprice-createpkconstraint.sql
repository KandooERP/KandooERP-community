--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: poscustprice
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE poscustprice ADD CONSTRAINT PRIMARY KEY (
cmpy_code,
cust_code,
part_code
) CONSTRAINT pk_poscustprice;
