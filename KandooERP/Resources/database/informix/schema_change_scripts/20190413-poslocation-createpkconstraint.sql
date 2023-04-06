--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: poslocation
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE poslocation ADD CONSTRAINT PRIMARY KEY (
locn_code,
cmpy_code
) CONSTRAINT pk_poslocation;
