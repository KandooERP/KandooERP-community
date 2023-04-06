--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: expdetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE expdetl ADD CONSTRAINT PRIMARY KEY (
export_num,
line_num,
cmpy_code
) CONSTRAINT pk_expdetl;
