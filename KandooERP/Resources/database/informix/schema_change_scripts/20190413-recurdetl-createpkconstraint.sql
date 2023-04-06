--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: recurdetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE recurdetl ADD CONSTRAINT PRIMARY KEY (
recur_code,
line_num,
cmpy_code
) CONSTRAINT pk_recurdetl;
