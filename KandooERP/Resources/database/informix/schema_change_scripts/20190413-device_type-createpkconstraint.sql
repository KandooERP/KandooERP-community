--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: device_type
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE device_type ADD CONSTRAINT PRIMARY KEY (
device_type_id
) CONSTRAINT pk_device_type;
