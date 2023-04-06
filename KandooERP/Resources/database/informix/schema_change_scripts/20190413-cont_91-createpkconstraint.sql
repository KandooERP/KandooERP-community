--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: cont_91
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE cont_91 ADD CONSTRAINT PRIMARY KEY (
cont_code
) CONSTRAINT pk_cont_91;
