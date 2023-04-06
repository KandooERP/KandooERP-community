--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: delivdetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE delivdetl ADD CONSTRAINT PRIMARY KEY (
pick_num,
pick_line_num,
cmpy_code
) CONSTRAINT pk_delivdetl;
