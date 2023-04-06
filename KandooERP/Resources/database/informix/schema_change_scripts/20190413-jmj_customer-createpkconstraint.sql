--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: jmj_customer
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE jmj_customer ADD CONSTRAINT PRIMARY KEY (
custno_01,
process_group_01
) CONSTRAINT pk_jmj_customer;
