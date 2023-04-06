--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: product
--# author: ericv
--# date: 2019-05-08
--# Ticket # :  4
--# more comments:
create unique index u_product on product(part_code,cmpy_code);
alter table product add constraint primary key (part_code,cmpy_code) constraint pk_product;
