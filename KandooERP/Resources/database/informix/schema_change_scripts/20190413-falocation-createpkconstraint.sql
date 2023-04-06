--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: falocation
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE falocation ADD CONSTRAINT PRIMARY KEY (
location_code,
cmpy_code
) CONSTRAINT pk_falocation;
