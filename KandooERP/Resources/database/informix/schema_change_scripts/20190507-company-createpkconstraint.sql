--# description: this script creates a primary key constraint from a unique index
--# dependencies: n/a
--# tables list: company
--# author: ericv
--# date: 2019-05-07
--# Ticket # : 4
--# 

create unique index u_company on company(cmpy_code);
ALTER TABLE company ADD CONSTRAINT PRIMARY KEY ( cmpy_code)
CONSTRAINT pk_company;
