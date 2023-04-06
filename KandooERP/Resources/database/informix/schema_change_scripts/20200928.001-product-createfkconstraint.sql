--# description: this script creates foreign key for product table to category
--# tables list: product,category
--# author: ericv
--# date: 2020-09-28
--# track bad rows with the following query
--# select cat_code||cmpy_code from product where cat_code||cmpy_code not in ( select cat_code||cmpy_code from category );
alter table product add constraint foreign key (cat_code,cmpy_code) references category (cat_code,cmpy_code) constraint fk_product_category;	
