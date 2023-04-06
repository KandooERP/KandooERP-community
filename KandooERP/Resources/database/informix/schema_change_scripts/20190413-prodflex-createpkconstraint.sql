--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: prodflex
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE prodflex ADD CONSTRAINT PRIMARY KEY (
class_code,
start_num,
flex_code,
cmpy_code
) CONSTRAINT pk_prodflex;
