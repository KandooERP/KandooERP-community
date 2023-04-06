--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: prodstatlog
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_prodstatlog on prodstatlog(part_code,ware_code,cmpy_code);
alter table prodstatlog add constraint primary key (part_code,ware_code,cmpy_code) constraint pk_prodstatlog;
