--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: address
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE address ADD CONSTRAINT PRIMARY KEY (
address_id
) CONSTRAINT pk_address;
