--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: faparms
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE faparms ADD CONSTRAINT PRIMARY KEY (
cmpy_code
) CONSTRAINT pk_faparms;
