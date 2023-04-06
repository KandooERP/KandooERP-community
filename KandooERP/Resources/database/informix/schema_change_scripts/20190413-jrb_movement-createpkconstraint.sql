--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: jrb_movement
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE jrb_movement ADD CONSTRAINT PRIMARY KEY (
job_code,
var_code,
activity_code,
cmpy_code
) CONSTRAINT pk_jrb_movement;
