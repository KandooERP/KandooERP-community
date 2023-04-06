--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: vendorhist
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE vendorhist ADD CONSTRAINT PRIMARY KEY (
vend_code,
year_num,
period_num,
cmpy_code
) CONSTRAINT pk_vendorhist;
