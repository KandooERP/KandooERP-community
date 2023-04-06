--# description: this script creates foreign key for product table to class
--# tables list: product,class
--# author: ericv
--# date: 2020-09-28
--# track bad rows with the following query
--# select class_code||cmpy_code from product where class_code||cmpy_code not in ( select class_code||cmpy_code from class );
alter table product add constraint foreign key (class_code,cmpy_code) references class (class_code,cmpy_code) constraint fk_product_class;	
