--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: ordlinerate
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE ordlinerate ADD CONSTRAINT PRIMARY KEY (
order_num,
line_num,
order_rate_type,
cmpy_code
) CONSTRAINT pk_ordlinerate;
