--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: quotelead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE quotelead ADD CONSTRAINT PRIMARY KEY (
cust_ware_code,
prod_ware_code,
cmpy_code
) CONSTRAINT pk_quotelead;
