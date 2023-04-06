--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: tentpays
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE tentpays ADD CONSTRAINT PRIMARY KEY (
vend_code,
vouch_code,
cmpy_code
) CONSTRAINT pk_tentpays;
