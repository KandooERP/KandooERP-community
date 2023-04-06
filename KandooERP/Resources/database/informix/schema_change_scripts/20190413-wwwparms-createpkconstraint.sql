--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: wwwparms
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE wwwparms ADD CONSTRAINT PRIMARY KEY (
key_num,
cmpy_code
) CONSTRAINT pk_wwwparms;
