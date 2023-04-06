--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: custstmnt
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_custstmnt on custstmnt(cust_code);
alter table custstmnt add constraint primary key (cust_code) constraint pk_custstmnt;
