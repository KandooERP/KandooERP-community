--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: work_center
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE work_center ADD CONSTRAINT PRIMARY KEY (
work_center_code,
cmpy_code
) CONSTRAINT pk_work_center;
