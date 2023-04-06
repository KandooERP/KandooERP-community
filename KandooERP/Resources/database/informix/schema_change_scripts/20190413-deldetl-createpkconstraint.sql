--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: deldetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE deldetl ADD CONSTRAINT PRIMARY KEY (
del_num,
line_num,
cmpy_code
) CONSTRAINT pk_deldetl;
