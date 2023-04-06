--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: orderledg
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE orderledg ADD CONSTRAINT PRIMARY KEY (
order_num,
seq_num,
cmpy_code
) CONSTRAINT pk_orderledg;
