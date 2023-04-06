--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: mps
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_mps on mps(item_code,plan_code,cmpy_code);
alter table mps add constraint primary key (item_code,plan_code,cmpy_code) constraint pk_mps;
