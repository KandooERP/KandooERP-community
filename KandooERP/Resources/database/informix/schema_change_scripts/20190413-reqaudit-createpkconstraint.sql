--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: reqaudit
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE reqaudit ADD CONSTRAINT PRIMARY KEY (
req_num,
line_num,
seq_num,
cmpy_code
) CONSTRAINT pk_reqaudit;
