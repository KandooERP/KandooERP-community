--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: ordrates
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE ordrates ADD CONSTRAINT PRIMARY KEY (
ord_ind,
rate_type_code,
cmpy_code
) CONSTRAINT pk_ordrates;
