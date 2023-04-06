--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: custcard
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE custcard ADD CONSTRAINT PRIMARY KEY (
card_code,
cmpy_code
) CONSTRAINT pk_custcard;
