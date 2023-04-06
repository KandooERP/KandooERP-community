--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: customertype
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_customertype on customertype(type_code);
alter table customertype add constraint primary key (type_code) constraint pk_customertype;
