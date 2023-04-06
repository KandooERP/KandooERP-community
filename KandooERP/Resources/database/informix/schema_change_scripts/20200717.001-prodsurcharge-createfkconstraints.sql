--# description: this script creates a foreign key from prodsurcharge to product and replaces fk_prodsurcharge_product by fk_prodsurcharge_product
--# tables list: prodsurcharge,product
--# author: ericv
--# date: 2020-06-28
--# Ticket 	
--# Comments: constraints to product are not correct because product row is not always created. Correct relationship is with product
--# SELECT year_num||part_code||cmpy_code from prodsurcharge WHERE year_num||part_code||cmpy_code not in ( SELECT year_num||part_code||cmpy_code FROM product )

create unique index if not exists ifk_prodsurcharge_product on prodsurcharge (part_code,cmpy_code);
alter table prodsurcharge add constraint foreign key (part_code,cmpy_code) references product (part_code,cmpy_code) constraint fk_prodsurcharge_product;
