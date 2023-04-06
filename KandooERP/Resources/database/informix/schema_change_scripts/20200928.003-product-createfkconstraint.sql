--# description: this script creates foreign key for product table to maingrp
--# tables list: product,maingrp
--# author: ericv
--# date: 2020-09-28
--# track bad rows with the following query
--# select maingrp_code||cmpy_code from product where maingrp_code||cmpy_code not in ( select maingrp_code||cmpy_code from maingrp );
alter table product add constraint foreign key (maingrp_code,cmpy_code) references maingrp (maingrp_code,cmpy_code) constraint fk_product_maingrp;	
