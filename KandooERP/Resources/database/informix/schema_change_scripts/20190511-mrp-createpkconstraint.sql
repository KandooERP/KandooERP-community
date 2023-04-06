--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: mrp
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_mrp on mrp(item_code,plan_code,cmpy_code);
alter table mrp add constraint primary key (item_code,plan_code,cmpy_code) constraint pk_mrp;
