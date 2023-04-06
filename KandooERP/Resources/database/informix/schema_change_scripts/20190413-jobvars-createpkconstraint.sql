--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: jobvars
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE jobvars ADD CONSTRAINT PRIMARY KEY (
job_code,
var_code,
cmpy_code
) CONSTRAINT pk_jobvars;
