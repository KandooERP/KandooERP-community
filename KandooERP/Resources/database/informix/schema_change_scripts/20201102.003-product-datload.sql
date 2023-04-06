--# description: this script loads the new products for the RET (retail) class
--# dependencies: 
--# tables list:  category,class,proddept,maingrp,prodgrp,product
--# author: Eric Vercelletto
--# date: 2020-11-02
--# Ticket: 
--# more comments:
load from unl/20201102_category.unl
insert into category;
load from unl/20201102_class.unl
insert into class;
load from unl/20201102_proddept.unl
insert into proddept;
load from unl/20201102_maingrp.unl
insert into maingrp;
load from unl/20201102_prodgrp.unl
insert into prodgrp;
load from unl/20201102_product.unl
insert into product;
