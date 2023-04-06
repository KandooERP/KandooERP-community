--# description: this script loads data for the prodgrp table
--# dependencies: 
--# tables list:  prodgrp
--# author: Eric Vercelletto
--# date: 2020-10-05
--# Ticket: 
--# more comments: First step of consistent hierarchy design of inventory/products

load from unl/20201005_prodgrp.unl
insert into prodgrp;