--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: drivertype
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE drivertype ADD CONSTRAINT PRIMARY KEY (
drv_type_code,
cmpy_code
) CONSTRAINT pk_drivertype;
