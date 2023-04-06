--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: tax
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_tax on tax(tax_code,cmpy_code);
ALTER TABLE tax ADD CONSTRAINT PRIMARY KEY ( tax_code,cmpy_code)
CONSTRAINT pk_tax;
