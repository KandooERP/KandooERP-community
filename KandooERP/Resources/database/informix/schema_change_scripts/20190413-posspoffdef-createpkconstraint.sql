--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: posspoffdef
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE posspoffdef ADD CONSTRAINT PRIMARY KEY (
offer_code,
cmpy_code
) CONSTRAINT pk_posspoffdef;
