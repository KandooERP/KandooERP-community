--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: delhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE delhead ADD CONSTRAINT PRIMARY KEY (
del_num,
cmpy_code
) CONSTRAINT pk_delhead;
