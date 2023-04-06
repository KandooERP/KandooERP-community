--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: prodmfg
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
create unique index u_prodmfg on prodmfg(part_code,part_type_ind,cust_code,cmpy_code);
alter table prodmfg add constraint primary key (part_code,part_type_ind,cust_code,cmpy_code) constraint pk_prodmfg;
