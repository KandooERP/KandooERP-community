--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: labourdetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE labourdetl ADD CONSTRAINT PRIMARY KEY (
order_num,
advice_num,
line_num,
cmpy_code
) CONSTRAINT pk_labourdetl;
