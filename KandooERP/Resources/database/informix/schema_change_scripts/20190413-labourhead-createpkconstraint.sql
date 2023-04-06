--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: labourhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE labourhead ADD CONSTRAINT PRIMARY KEY (
order_num,
advice_num,
cmpy_code
) CONSTRAINT pk_labourhead;
