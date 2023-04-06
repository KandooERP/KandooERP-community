--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: customerhist
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE customerhist ADD CONSTRAINT PRIMARY KEY (
cust_code,
year_num,
period_num,
cmpy_code
) CONSTRAINT pk_customerhist;
