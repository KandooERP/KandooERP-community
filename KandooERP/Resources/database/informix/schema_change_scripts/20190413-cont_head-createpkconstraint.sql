--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: cont_head
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE cont_head ADD CONSTRAINT PRIMARY KEY (
batch_no
) CONSTRAINT pk_cont_head;
