--# description: this script creates foreign key for product table to prodgrp
--# tables list: product,prodgrp
--# author: ericv
--# date: 2020-09-28
--# track bad rows with the following query
--# select prodgrp_code||cmpy_code from product where prodgrp_code||cmpy_code not in ( select prodgrp_code||cmpy_code from prodgrp );
alter table product add constraint foreign key (prodgrp_code,maingrp_code,dept_code,cmpy_code) references prodgrp (prodgrp_code,maingrp_code,dept_code,cmpy_code) constraint fk_product_prodgrp;	
