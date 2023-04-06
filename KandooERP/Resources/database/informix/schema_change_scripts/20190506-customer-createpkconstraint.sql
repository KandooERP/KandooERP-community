--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: customer
--# author: ericv
--# date: 2019-05-06
--# Ticket # : 4
--# 

create unique index u_customer on customer(cust_code,cmpy_code);
ALTER TABLE customer ADD CONSTRAINT PRIMARY KEY ( cust_code,cmpy_code)
CONSTRAINT pk_customer;
