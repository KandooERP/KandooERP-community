--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: department
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE department ADD CONSTRAINT PRIMARY KEY (
dept_code,
cmpy_code
) CONSTRAINT pk_department;
