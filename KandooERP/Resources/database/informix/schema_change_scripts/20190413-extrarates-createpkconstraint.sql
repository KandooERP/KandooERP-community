--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: extrarates
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE extrarates ADD CONSTRAINT PRIMARY KEY (
rate_code,
cmpy_code,
effect_date
) CONSTRAINT pk_extrarates;
