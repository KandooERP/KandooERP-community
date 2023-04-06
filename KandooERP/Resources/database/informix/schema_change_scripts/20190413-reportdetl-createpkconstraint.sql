--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: reportdetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE reportdetl ADD CONSTRAINT PRIMARY KEY (
report_code,
line_num,
cmpy_code
) CONSTRAINT pk_reportdetl;
