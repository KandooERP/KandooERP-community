--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: jobledger
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE jobledger ADD CONSTRAINT PRIMARY KEY (
cmpy_code,
job_code,
var_code,
activity_code,
seq_num
) CONSTRAINT pk_jobledger;
