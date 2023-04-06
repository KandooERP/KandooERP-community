--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: orderinst
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE orderinst ADD CONSTRAINT PRIMARY KEY (
order_num,
instr_num,
cmpy_code
) CONSTRAINT pk_orderinst;
