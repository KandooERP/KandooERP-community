--# description: this script loads data for the maingrp table
--# dependencies: 
--# tables list:  maingrp
--# author: Eric Vercelletto
--# date: 2020-10-05
--# Ticket: 
--# more comments: First step of consistent hierarchy design of inventory/products

load from unl/20201005_maingrp.unl
insert into maingrp;