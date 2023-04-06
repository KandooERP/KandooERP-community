--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: labourpays
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE labourpays ADD CONSTRAINT PRIMARY KEY (
order_num,
advice_num,
labour_code,
seq_num,
cmpy_code
) CONSTRAINT pk_labourpays;
