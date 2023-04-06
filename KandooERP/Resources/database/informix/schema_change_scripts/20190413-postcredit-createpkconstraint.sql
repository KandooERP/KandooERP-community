--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: postcredit
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE postcredit ADD CONSTRAINT PRIMARY KEY (
cred_num,
cmpy_code
) CONSTRAINT pk_postcredit;
