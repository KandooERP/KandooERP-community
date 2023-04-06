--# description: this script handles changes in the menu items
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list:  qxt_group_access,qxt_menu_item_txt,qxt_menu_item
--# author: Alex Bondar
--# date: 2019-02-06
--# Ticket # :
--# more comments: first backup the existing contents (unload to xxx.bkp), then delete contents and load from new data files.
--# set constraints all deferred is necessary because qxt_menu_item has another relationship with qxt_log_run
unload to "qxt_group_access_org.bkp" select * from qxt_group_access;
unload to "qxt_menu_item_txt_org.bkp" select * from qxt_menu_item_txt;
unload to "qxt_menu_item_org.bkp" select * from qxt_menu_item;
begin work;
set constraints all deferred;
delete from qxt_group_access where 1 = 1 ;
load from "20190205_qxt_group_access.unl" insert into qxt_group_access;

delete from qxt_menu_item_txt where 1 = 1 ;
load from "20190205_qxt_menu_item_txt.unl" insert into qxt_menu_item_txt;

delete from qxt_menu_item where 1 = 1 ;
load from "20190205_qxt_menu_item.unl" insert into qxt_menu_item;
commit work;


