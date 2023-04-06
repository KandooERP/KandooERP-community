--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: postrandetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE postrandetl ADD CONSTRAINT PRIMARY KEY (
tran_num,
line_num,
cmpy_code
) CONSTRAINT pk_postrandetl;
