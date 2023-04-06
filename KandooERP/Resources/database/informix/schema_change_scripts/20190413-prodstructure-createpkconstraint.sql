--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: prodstructure
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE prodstructure ADD CONSTRAINT PRIMARY KEY (
class_code,
seq_num,
cmpy_code
) CONSTRAINT pk_prodstructure;
