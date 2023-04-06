--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: pickhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE pickhead ADD CONSTRAINT PRIMARY KEY (
ware_code,
pick_num,
cmpy_code
) CONSTRAINT pk_pickhead;
