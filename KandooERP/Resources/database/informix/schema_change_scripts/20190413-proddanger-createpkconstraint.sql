--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: proddanger
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE proddanger ADD CONSTRAINT PRIMARY KEY (
dg_code,
cmpy_code
) CONSTRAINT pk_proddanger;
