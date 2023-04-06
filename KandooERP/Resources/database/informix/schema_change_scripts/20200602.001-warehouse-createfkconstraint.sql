--# description: this script creates the foreign key from warehouse to cartarea
--# tables list: warehouse
--# author: ericv
--# date: 2020-06-01
--# Ticket # : 	
--# dependencies:
--# more comments: in case of error -297, check the data with the following query, and delete accordingly
--# select  cart_area_code||cmpy_code from warehouse  where cart_area_code||cmpy_code not in ( select cart_area_code||cmpy_code from cartarea )

create index if not exists fk2_warehouse on warehouse (cart_area_code,cmpy_code);
alter table warehouse add constraint foreign key (cart_area_code,cmpy_code) references cartarea (cart_area_code,cmpy_code) constraint fk_warehouse_cartarea ;

