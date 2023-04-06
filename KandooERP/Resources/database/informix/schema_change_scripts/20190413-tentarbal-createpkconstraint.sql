--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: tentarbal
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE tentarbal ADD CONSTRAINT PRIMARY KEY (
cust_code,
cmpy_code
) CONSTRAINT pk_tentarbal;
