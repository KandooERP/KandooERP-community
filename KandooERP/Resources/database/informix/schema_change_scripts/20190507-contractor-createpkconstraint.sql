--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: contractor
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_contractor on contractor(vend_code,cmpy_code);
ALTER TABLE contractor ADD CONSTRAINT PRIMARY KEY ( vend_code,cmpy_code)
CONSTRAINT pk_contractor;
