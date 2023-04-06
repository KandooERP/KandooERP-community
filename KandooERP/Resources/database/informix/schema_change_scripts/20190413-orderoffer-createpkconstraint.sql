--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: orderoffer
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE orderoffer ADD CONSTRAINT PRIMARY KEY (
order_num,
offer_code,
cmpy_code
) CONSTRAINT pk_orderoffer;
