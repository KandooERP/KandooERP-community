--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: deposit
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE deposit ADD CONSTRAINT PRIMARY KEY (
deposit_no
) CONSTRAINT pk_deposit;
