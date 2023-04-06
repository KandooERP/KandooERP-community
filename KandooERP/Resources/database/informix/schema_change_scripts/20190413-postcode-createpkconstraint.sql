--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: postcode
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE postcode ADD CONSTRAINT PRIMARY KEY (
old_code
) CONSTRAINT pk_postcode;
