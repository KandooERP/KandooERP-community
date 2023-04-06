--# description: this script creates foreign key for prodinfo table to product
--# tables list: prodinfo,product
--# author: ericv
--# date: 2020-09-29

alter table prodinfo add constraint foreign key (part_code,cmpy_code) references product (part_code,cmpy_code) constraint fk_prodinfo_product;	
