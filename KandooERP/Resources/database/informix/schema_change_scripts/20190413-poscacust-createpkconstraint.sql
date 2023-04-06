--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: poscacust
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE poscacust ADD CONSTRAINT PRIMARY KEY (
tran_num,
cmpy_code
) CONSTRAINT pk_poscacust;
