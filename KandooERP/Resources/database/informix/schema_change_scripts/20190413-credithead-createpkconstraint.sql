--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: credithead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE credithead ADD CONSTRAINT PRIMARY KEY (
cust_code,
cred_num,
cmpy_code
) CONSTRAINT pk_credithead;
