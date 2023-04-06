--# description: this script adds departement code to product and drops the constraint fk_product_warehouse
--# dependencies: 
--# tables list:  product
--# author: Eric Vercelletto
--# date: 2020-10-05
--# Ticket: 
--# more comments: First step of consistent hierarchy design of inventory/products

alter table product add (dept_code NCHAR(3));
alter table product modify (prodgrp_code NCHAR(6));
