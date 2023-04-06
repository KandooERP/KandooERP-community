--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: depositor
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE depositor ADD CONSTRAINT PRIMARY KEY (
cmpy_code,
dep_code
) CONSTRAINT pk_depositor;
