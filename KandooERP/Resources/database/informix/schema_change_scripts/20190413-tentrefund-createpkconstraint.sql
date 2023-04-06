--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: tentrefund
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE tentrefund ADD CONSTRAINT PRIMARY KEY (
cust_code,
order_num,
cmpy_code
) CONSTRAINT pk_tentrefund;
