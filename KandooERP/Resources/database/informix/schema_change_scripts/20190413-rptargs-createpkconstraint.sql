--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: rptargs
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE rptargs ADD CONSTRAINT PRIMARY KEY (
job_id,
cmpy_code
) CONSTRAINT pk_rptargs;
