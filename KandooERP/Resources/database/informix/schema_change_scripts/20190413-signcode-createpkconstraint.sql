--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: signcode
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE signcode ADD CONSTRAINT PRIMARY KEY (
sign_code
) CONSTRAINT pk_signcode;
