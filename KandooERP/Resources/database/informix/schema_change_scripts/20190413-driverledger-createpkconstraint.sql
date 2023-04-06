--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: driverledger
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE driverledger ADD CONSTRAINT PRIMARY KEY (
seq_num,
driver_code,
cmpy_code
) CONSTRAINT pk_driverledger;
