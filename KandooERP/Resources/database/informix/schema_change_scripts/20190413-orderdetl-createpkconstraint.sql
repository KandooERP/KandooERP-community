--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: orderdetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE orderdetl ADD CONSTRAINT PRIMARY KEY (
cust_code,
order_num,
line_num,
cmpy_code
) CONSTRAINT pk_orderdetl;
