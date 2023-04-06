--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: dangerclass
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE dangerclass ADD CONSTRAINT PRIMARY KEY (
class_code
) CONSTRAINT pk_dangerclass;
