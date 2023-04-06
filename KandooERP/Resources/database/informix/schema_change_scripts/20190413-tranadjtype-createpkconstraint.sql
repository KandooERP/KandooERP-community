--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: tranadjtype
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE tranadjtype ADD CONSTRAINT PRIMARY KEY (
adj_type_code,
cmpy_code
) CONSTRAINT pk_tranadjtype;
