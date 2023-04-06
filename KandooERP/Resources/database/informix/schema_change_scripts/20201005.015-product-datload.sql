--# description: this script loads data for the product table
--# dependencies: 
--# tables list:  product
--# author: Eric Vercelletto
--# date: 2020-10-05
--# Ticket: 
--# more comments: First step of consistent hierarchy design of inventory/products

load from unl/20201005_product.unl
insert into product;