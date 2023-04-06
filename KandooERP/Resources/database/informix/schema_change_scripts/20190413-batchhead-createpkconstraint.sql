--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: batchhead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE batchhead ADD CONSTRAINT PRIMARY KEY (
jour_code,
jour_num,
cmpy_code
) CONSTRAINT pk_batchhead;
