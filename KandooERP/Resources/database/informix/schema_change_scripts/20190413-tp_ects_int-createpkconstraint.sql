--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: tp_ects_int
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE tp_ects_int ADD CONSTRAINT PRIMARY KEY (
trn_num
) CONSTRAINT pk_tp_ects_int;
