--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: reqhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE reqhead ADD CONSTRAINT PRIMARY KEY (
req_num,
cmpy_code
) CONSTRAINT pk_reqhead;
