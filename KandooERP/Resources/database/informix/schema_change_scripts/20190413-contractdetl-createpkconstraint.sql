--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: contractdetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE contractdetl ADD CONSTRAINT PRIMARY KEY (
contract_code,
cust_code,
line_num,
cmpy_code
) CONSTRAINT pk_contractdetl;
