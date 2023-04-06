--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: mmdr
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE mmdr ADD CONSTRAINT PRIMARY KEY (
cust_code
) CONSTRAINT pk_mmdr;
