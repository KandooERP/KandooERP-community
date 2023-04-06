--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: supply
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE supply ADD CONSTRAINT PRIMARY KEY (
suburb_code,
ware_code,
cmpy_code
) CONSTRAINT pk_supply;
