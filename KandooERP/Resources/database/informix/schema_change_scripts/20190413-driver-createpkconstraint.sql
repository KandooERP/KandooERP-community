--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: driver
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE driver ADD CONSTRAINT PRIMARY KEY (
driver_code,
cmpy_code
) CONSTRAINT pk_driver;
