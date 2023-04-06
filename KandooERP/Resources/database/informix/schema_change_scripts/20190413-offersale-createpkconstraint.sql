--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: offersale
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE offersale ADD CONSTRAINT PRIMARY KEY (
offer_code,
cmpy_code
) CONSTRAINT pk_offersale;
