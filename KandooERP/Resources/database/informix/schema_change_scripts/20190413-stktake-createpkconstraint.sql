--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: stktake
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE stktake ADD CONSTRAINT PRIMARY KEY (
cycle_num,
cmpy_code
) CONSTRAINT pk_stktake;
