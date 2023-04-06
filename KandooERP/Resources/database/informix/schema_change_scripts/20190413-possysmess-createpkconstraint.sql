--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: possysmess
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE possysmess ADD CONSTRAINT PRIMARY KEY (
mess_code,
cmpy_code
) CONSTRAINT pk_possysmess;
