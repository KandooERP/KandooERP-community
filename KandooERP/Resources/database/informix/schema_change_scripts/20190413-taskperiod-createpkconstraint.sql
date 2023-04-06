--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: taskperiod
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE taskperiod ADD CONSTRAINT PRIMARY KEY (
task_period_ind,
cmpy_code
) CONSTRAINT pk_taskperiod;
