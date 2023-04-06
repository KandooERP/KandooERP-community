--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: prodquote
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE prodquote ADD CONSTRAINT PRIMARY KEY (
part_code,
vend_code,
expiry_date,
cmpy_code
) CONSTRAINT pk_prodquote;
