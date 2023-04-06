--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: faresp
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE faresp ADD CONSTRAINT PRIMARY KEY (
faresp_code,
cmpy_code
) CONSTRAINT pk_faresp;
