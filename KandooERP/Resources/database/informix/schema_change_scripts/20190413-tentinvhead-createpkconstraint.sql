--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: tentinvhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE tentinvhead ADD CONSTRAINT PRIMARY KEY (
inv_num,
cmpy_code
) CONSTRAINT pk_tentinvhead;
