--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: ledgerreln
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE ledgerreln ADD CONSTRAINT PRIMARY KEY (
flex1_code,
flex2_code,
cmpy_code
) CONSTRAINT pk_ledgerreln;
