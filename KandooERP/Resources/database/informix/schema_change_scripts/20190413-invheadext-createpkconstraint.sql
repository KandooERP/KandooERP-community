--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: invheadext
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE invheadext ADD CONSTRAINT PRIMARY KEY (
inv_num,
cust_code,
cmpy_code
) CONSTRAINT pk_invheadext;
