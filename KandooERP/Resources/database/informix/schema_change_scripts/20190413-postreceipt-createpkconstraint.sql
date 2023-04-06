--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: postreceipt
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE postreceipt ADD CONSTRAINT PRIMARY KEY (
cash_num,
cmpy_code
) CONSTRAINT pk_postreceipt;
