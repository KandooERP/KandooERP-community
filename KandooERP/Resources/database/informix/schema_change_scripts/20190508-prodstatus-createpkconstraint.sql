--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: prodstatus
--# author: ericv
--# date: 2019-05-08
--# Ticket # :
--# more comments:
create unique index u_prodstatus on prodstatus(part_code,ware_code,cmpy_code);
alter table prodstatus add constraint primary key (part_code,ware_code,cmpy_code) constraint pk_prodstatus;
