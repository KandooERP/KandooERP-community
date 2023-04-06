--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: denomination
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE denomination ADD CONSTRAINT PRIMARY KEY (
denom_code
) CONSTRAINT pk_denomination;
