--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: tenthead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE tenthead ADD CONSTRAINT PRIMARY KEY (
cycle_num,
cmpy_code
) CONSTRAINT pk_tenthead;
