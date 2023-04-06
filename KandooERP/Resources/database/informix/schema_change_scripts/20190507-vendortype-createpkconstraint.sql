--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: vendortype
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_vendortype on vendortype(type_code,cmpy_code);
ALTER TABLE vendortype ADD CONSTRAINT PRIMARY KEY ( type_code,cmpy_code)
CONSTRAINT pk_vendortype;
