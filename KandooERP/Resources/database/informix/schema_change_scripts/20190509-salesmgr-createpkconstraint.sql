--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: salesmgr
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_salesmgr on salesmgr(mgr_code,cmpy_code);
alter table salesmgr add constraint primary key (mgr_code,cmpy_code) constraint pk_salesmgr;
