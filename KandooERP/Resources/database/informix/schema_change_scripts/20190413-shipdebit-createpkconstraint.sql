--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: shipdebit
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE shipdebit ADD CONSTRAINT PRIMARY KEY (
vend_code,
ship_code,
debit_code,
line_num,
cmpy_code
) CONSTRAINT pk_shipdebit;
