--# description: this script loads data for the proddept table
--# dependencies: 
--# tables list:  proddept
--# author: Eric Vercelletto
--# date: 2020-10-05
--# Ticket: 
--# more comments: First step of consistent hierarchy design of inventory/products

load from unl/20201005_proddept.unl
insert into proddept;