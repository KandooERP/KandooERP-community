--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: serialinfo
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE serialinfo ADD CONSTRAINT PRIMARY KEY (
part_code,
serial_code,
cmpy_code
) CONSTRAINT pk_serialinfo;
