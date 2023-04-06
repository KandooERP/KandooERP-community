--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: accumulator
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE accumulator ADD CONSTRAINT PRIMARY KEY (
rpt_id,
accum_id,
cmpy_code
) CONSTRAINT pk_accumulator;
