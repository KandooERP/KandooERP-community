--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: creditheadext
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE creditheadext ADD CONSTRAINT PRIMARY KEY (
credit_num,
cust_code,
cmpy_code
) CONSTRAINT pk_creditheadext;
