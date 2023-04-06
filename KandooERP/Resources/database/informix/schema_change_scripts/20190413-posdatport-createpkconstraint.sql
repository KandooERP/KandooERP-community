--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: posdatport
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE posdatport ADD CONSTRAINT PRIMARY KEY (
device_code,
port_code
) CONSTRAINT pk_posdatport;
