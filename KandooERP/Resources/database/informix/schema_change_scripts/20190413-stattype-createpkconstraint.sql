--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: stattype
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE stattype ADD CONSTRAINT PRIMARY KEY (
type_code,
cmpy_code
) CONSTRAINT pk_stattype;
