--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: delivmsg
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE delivmsg ADD CONSTRAINT PRIMARY KEY (
seq_num,
cmpy_code
) CONSTRAINT pk_delivmsg;
