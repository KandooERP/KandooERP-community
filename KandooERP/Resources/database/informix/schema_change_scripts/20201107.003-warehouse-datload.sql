--# description: this script loads the new products for warehouse
--# dependencies: 
--# tables list:  warehouse
--# author: Eric Vercelletto
--# date: 2020-11-07
--# Ticket: 
--# more comments:
load from unl/20201107_warehouse.unl
insert into warehouse;
