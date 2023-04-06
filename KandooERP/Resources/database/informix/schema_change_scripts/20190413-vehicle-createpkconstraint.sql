--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: vehicle
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE vehicle ADD CONSTRAINT PRIMARY KEY (
vehicle_code,
cmpy_code
) CONSTRAINT pk_vehicle;
