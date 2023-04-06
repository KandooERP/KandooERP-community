--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: cont_line
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE cont_line ADD CONSTRAINT PRIMARY KEY (
batch_cntr
) CONSTRAINT pk_cont_line;
