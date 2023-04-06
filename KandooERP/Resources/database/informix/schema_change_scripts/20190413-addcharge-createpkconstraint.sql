--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: addcharge
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE addcharge ADD CONSTRAINT PRIMARY KEY (
desc_code,
cmpy_code
) CONSTRAINT pk_addcharge;
