--# description: this script loads data for the class table
--# dependencies: 
--# tables list:  class
--# author: Eric Vercelletto
--# date: 2020-10-05
--# Ticket: 
--# more comments: First step of consistent hierarchy design of inventory/products

load from unl/20201005_category.unl
insert into category;