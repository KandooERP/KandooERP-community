--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: item_master
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE item_master ADD CONSTRAINT PRIMARY KEY (
item_code,
item_type_code,
cmpy_code
) CONSTRAINT pk_item_master;
