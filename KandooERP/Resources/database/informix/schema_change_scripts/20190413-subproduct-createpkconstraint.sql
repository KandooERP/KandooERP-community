--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: subproduct
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE subproduct ADD CONSTRAINT PRIMARY KEY (
part_code,
type_code,
cmpy_code
) CONSTRAINT pk_subproduct;
