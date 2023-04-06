--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: batchdetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE batchdetl ADD CONSTRAINT PRIMARY KEY (
jour_num,
seq_num,
jour_code,
cmpy_code
) CONSTRAINT pk_batchdetl;
