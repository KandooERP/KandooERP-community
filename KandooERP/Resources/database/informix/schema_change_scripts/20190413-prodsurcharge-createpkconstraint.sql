--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: prodsurcharge
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE prodsurcharge ADD CONSTRAINT PRIMARY KEY (
part_code,
cmpy_code
) CONSTRAINT pk_prodsurcharge;
