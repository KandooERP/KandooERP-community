--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: delinst
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE delinst ADD CONSTRAINT PRIMARY KEY (
pick_num,
instr_num,
cmpy_code
) CONSTRAINT pk_delinst;
