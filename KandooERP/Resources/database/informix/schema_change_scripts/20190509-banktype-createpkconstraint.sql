--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: banktype
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_banktype on banktype(type_code);
alter table banktype add constraint primary key (type_code) constraint pk_banktype;
