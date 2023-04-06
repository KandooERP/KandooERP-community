--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: backorder
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE backorder ADD CONSTRAINT PRIMARY KEY (
part_code,
order_num,
line_num,
cmpy_code
) CONSTRAINT pk_backorder;
