--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: prochead
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE prochead ADD CONSTRAINT PRIMARY KEY (
proc_code,
cmpy_code
) CONSTRAINT pk_prochead;
