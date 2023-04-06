--# description: this script loads the new products for prodstatus
--# dependencies: 
--# tables list:  prodstatus
--# author: Eric Vercelletto
--# date: 2020-11-07
--# Ticket: 
--# more comments:
load from unl/20201107_prodstatus.unl
insert into prodstatus;
