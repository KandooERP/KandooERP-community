--# description: this script handles changes in the menu items
--# dependencies: put in unl directory any .unl file if the script loads data
--# tables list:  qxt_menu_item_txt,qxt_menu_item
--# author: Alex Bondar
--# date: 2020-11-03
--# Ticket: KD-2222
--# more comments: 
--# set constraints all deferred is necessary because qxt_menu_item has another relationship with qxt_log_run
set constraints all deferred;
delete from qxt_menu_item_txt where 1=1 ;
delete from qxt_menu_item where 1=1 ;
delete from qxt_run_arg where 1=1 ;
load from unl/20201119_qxt_menu_item.unl insert into qxt_menu_item;
load from unl/20201119_qxt_menu_item_txt.unl insert into qxt_menu_item_txt;
load from unl/20201119_qxt_run_arg.unl insert into qxt_run_arg;
-- set mb_level = 0 to the lowest level of menu groups(just above root )
update qxt_menu_item
set mb_level = 0
WHERE mb_type = 0
and mb_parent_id = 0;
-- set mb_level = 1 to upper level of menu groups (just above 0 level )
update qxt_menu_item
set mb_level = 1
WHERE mb_type = 0
and mb_parent_id > 0;
-- set mb_level = 10  to items running a command (i.e not a menu group) . T
update qxt_menu_item
set mb_level = 10
WHERE mb_type > 0
and mb_parent_id > 0 ;
