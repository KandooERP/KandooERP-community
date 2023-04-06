--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: banking
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE banking ADD CONSTRAINT PRIMARY KEY (
doc_num
) CONSTRAINT pk_banking;
