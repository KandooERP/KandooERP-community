--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: customerpart
--# author: ericv
--# date: 2019-05-13
--# Ticket # :  4
--# more comments:
create unique index u_customerpart on customerpart(cust_code,part_code,cmpy_code);
alter table customerpart add constraint primary key (cust_code,part_code,cmpy_code) constraint pk_customerpart;
