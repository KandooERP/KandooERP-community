--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: loadline
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE loadline ADD CONSTRAINT PRIMARY KEY (
load_num,
load_line_num,
cmpy_code
) CONSTRAINT pk_loadline;
