--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: reqperson
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE reqperson ADD CONSTRAINT PRIMARY KEY (
person_code,
cmpy_code
) CONSTRAINT pk_reqperson;
