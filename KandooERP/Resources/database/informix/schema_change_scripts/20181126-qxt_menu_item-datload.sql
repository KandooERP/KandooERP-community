--# description:  this script updates the contents of the qxt_menu_item table
--# dependencies: 20181126-qxt_menu_item.unl
--# tables list: qxt_menu_item
--# author: huho
--# date: 2018-12-21
--# Ticket # :
--# more comments:
truncate table qxt_menu_item;
load from 20181126-qxt_menu_item.unl
insert into qxt_menu_item
