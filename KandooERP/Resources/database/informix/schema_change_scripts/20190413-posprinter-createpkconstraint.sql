--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: posprinter
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE posprinter ADD CONSTRAINT PRIMARY KEY (
device_code
) CONSTRAINT pk_posprinter;
