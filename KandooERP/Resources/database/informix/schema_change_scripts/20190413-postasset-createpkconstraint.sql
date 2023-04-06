--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: postasset
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE postasset ADD CONSTRAINT PRIMARY KEY (
batch_num,
cmpy_code
) CONSTRAINT pk_postasset;
