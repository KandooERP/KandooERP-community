--# description: this script reorganizes fk constraints from product
--# tables list:  product
--# author: Eric Vercelletto
--# date: 2020-10-05
--# Ticket: 
--# more comments: First step of consistent hierarchy design of inventory/products

on exception -623 status=OKE;
alter table product drop constraint fk_product_warehouse;
-- we drop the direct constraint from product to maingrp, but we'll set constraints between department->maingrp,prodgrp
on exception -623 status=OKE;
alter table product drop constraint fk_product_maingrp;
alter table product add constraint foreign key (prodgrp_code,maingrp_code,dept_code,cmpy_code) references prodgrp (prodgrp_code,maingrp_code,dept_code,cmpy_code) constraint fk_product_prodgrp;