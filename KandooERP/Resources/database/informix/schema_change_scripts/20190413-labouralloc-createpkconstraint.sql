--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: labouralloc
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE labouralloc ADD CONSTRAINT PRIMARY KEY (
order_num,
labour_code,
cmpy_code
) CONSTRAINT pk_labouralloc;
