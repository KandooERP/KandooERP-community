--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: creditrates
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE creditrates ADD CONSTRAINT PRIMARY KEY (
cred_num,
line_num,
rate_type,
cmpy_code
) CONSTRAINT pk_creditrates;
