--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: contracthead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE contracthead ADD CONSTRAINT PRIMARY KEY (
contract_code,
cust_code,
cmpy_code
) CONSTRAINT pk_contracthead;
