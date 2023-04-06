--# description: this script creates a primary key constraint on customertype
--# dependencies: n/a
--# tables list: customertype
--# author: ericv
--# date: 2019-12-05
--# Ticket # : 
--# Comments: 
create unique index u_customertype on customertype (type_code,cmpy_code) using btree ;
alter table customertype add constraint primary key (type_code,cmpy_code) constraint pk_customertype;
