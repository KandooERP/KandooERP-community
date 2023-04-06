--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: postfabatch
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE postfabatch ADD CONSTRAINT PRIMARY KEY (
batch_num,
cmpy_code
) CONSTRAINT pk_postfabatch;
