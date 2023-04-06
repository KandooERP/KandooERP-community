--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: class
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_class on class(class_code,cmpy_code);
alter table class add constraint primary key (class_code,cmpy_code) constraint pk_class;
