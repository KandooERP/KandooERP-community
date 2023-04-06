--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: postcredhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE postcredhead ADD CONSTRAINT PRIMARY KEY (
cred_num,
cmpy_code
) CONSTRAINT pk_postcredhead;
