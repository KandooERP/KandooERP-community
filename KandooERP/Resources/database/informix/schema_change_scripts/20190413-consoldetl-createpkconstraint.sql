--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: consoldetl
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE consoldetl ADD CONSTRAINT PRIMARY KEY (
consol_code,
flex_code,
cmpy_code
) CONSTRAINT pk_consoldetl;
