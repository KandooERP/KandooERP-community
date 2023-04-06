--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: customership
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_customership on customership(cust_code,ship_code,cmpy_code);
alter table customership add constraint primary key (cust_code,ship_code,cmpy_code) constraint pk_customership;
