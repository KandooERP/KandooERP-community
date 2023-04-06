--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: posscruom
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE posscruom ADD CONSTRAINT PRIMARY KEY (
uom_code,
cmpy_code
) CONSTRAINT pk_posscruom;
