--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: responsible
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE responsible ADD CONSTRAINT PRIMARY KEY (
resp_code,
cmpy_code
) CONSTRAINT pk_responsible;
