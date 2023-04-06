--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: facat
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE facat ADD CONSTRAINT PRIMARY KEY (
facat_code,
cmpy_code
) CONSTRAINT pk_facat;
