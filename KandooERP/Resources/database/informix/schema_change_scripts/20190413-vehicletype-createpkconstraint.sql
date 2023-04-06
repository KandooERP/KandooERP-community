--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: vehicletype
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE vehicletype ADD CONSTRAINT PRIMARY KEY (
veh_type_code,
cmpy_code
) CONSTRAINT pk_vehicletype;
