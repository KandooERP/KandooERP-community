--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: termdetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE termdetl ADD CONSTRAINT PRIMARY KEY (
term_code,
days_num,
cmpy_code
) CONSTRAINT pk_termdetl;
