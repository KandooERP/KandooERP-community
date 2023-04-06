--# description:  this script resets the contents of the qxt_menu_item_txt table
--# dependencies: 20181218_qxt_menu_item_txt.unl
--# tables list: qxt_menu_item_txt
--# author: alexb
--# date: 2018-12-16
--# Ticket # :
--# more comments:
unload to "qxt_menu_item_txt_org.unl" select * from qxt_menu_item_txt;
delete from qxt_menu_item_txt where 1=1;
load from "20181218_qxt_menu_item_txt.unl" insert into qxt_menu_item_txt;
