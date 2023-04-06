--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: resbdgt
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE resbdgt ADD CONSTRAINT PRIMARY KEY (
job_code,
var_code,
activity_code,
res_code,
cmpy_code
) CONSTRAINT pk_resbdgt;
