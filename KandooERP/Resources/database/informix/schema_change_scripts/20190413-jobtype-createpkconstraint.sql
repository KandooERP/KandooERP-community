--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: jobtype
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE jobtype ADD CONSTRAINT PRIMARY KEY (
type_code,
cmpy_code
) CONSTRAINT pk_jobtype;
