--# description: this script creates the foreign key from product to warehouse
--# tables list: product
--# author: ericv
--# date: 2020-05-21
--# Ticket # : 	
--# dependencies:
--# more comments:

create index d2_product on product (ware_code,cmpy_code);
alter table product add constraint foreign key (ware_code,cmpy_code) references warehouse (ware_code,cmpy_code) constraint fk_product_warehouse ;

