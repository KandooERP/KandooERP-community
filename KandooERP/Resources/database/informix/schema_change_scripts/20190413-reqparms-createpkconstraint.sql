--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: reqparms
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE reqparms ADD CONSTRAINT PRIMARY KEY (
key_code,
cmpy_code
) CONSTRAINT pk_reqparms;
