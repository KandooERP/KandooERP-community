--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: ts_detail
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE ts_detail ADD CONSTRAINT PRIMARY KEY (
ts_num,
seq_num,
cmpy_code
) CONSTRAINT pk_ts_detail;
