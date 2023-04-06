--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: statint
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE statint ADD CONSTRAINT PRIMARY KEY (
intseq_num,
year_num,
type_code,
int_num,
cmpy_code
) CONSTRAINT pk_statint;
