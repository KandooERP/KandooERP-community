--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: productapn
--# author: spokey
--# date: 2019-04-13
--# Ticket # : 4
--# 


ALTER TABLE productapn ADD CONSTRAINT PRIMARY KEY (
barcode_text,
cmpy_code
) CONSTRAINT pk_productapn;
