--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: bsgoodguys
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE bsgoodguys ADD CONSTRAINT PRIMARY KEY (
cust_code
) CONSTRAINT pk_bsgoodguys;
