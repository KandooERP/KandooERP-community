--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: cartrates
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE cartrates ADD CONSTRAINT PRIMARY KEY (
rate_code,
cmpy_code,
effect_date
) CONSTRAINT pk_cartrates;
