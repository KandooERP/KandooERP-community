--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: calcline
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE calcline ADD CONSTRAINT PRIMARY KEY (
rpt_id,
line_uid,
seq_num,
cmpy_code
) CONSTRAINT pk_calcline;
