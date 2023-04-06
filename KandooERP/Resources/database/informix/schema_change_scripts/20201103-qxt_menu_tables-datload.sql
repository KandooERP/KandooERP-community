--# description: this script handles changes in the menu items
--# dependencies: 20201103.000-qxt_menu_item-dependency
--# tables list:  qxt_menu_item_txt,qxt_menu_item
--# author: Alex Bondar
--# date: 2020-11-03
--# Ticket: KD-2219
--# more comments: 
--# set constraints all deferred is necessary because qxt_menu_item has another relationship with qxt_log_run
set constraints all deferred;
delete from qxt_menu_item_txt where 1=1 ;
delete from qxt_menu_item where 1=1 ;
delete from qxt_run_arg where 1=1 ;
load from unl/20201103_qxt_menu_item.unl insert into qxt_menu_item;
load from unl/20201103_qxt_menu_item_txt.unl insert into qxt_menu_item_txt;
load from unl/20201103_qxt_run_arg.unl insert into qxt_run_arg;
--# description: this script handles changes in the menu items
--# dependencies: put in unl directory any .unl file if the script loads data
--# tables list:  qxt_menu_item_txt,qxt_menu_item
--# author: Alex Bondar
--# date: 2020-11-03
--# Ticket: KD-2219
--# more comments: 
--# set constraints all deferred is necessary because qxt_menu_item has another relationship with qxt_log_run
set constraints all deferred;
delete from qxt_menu_item_txt where 1=1 ;
delete from qxt_menu_item where 1=1 ;
delete from qxt_run_arg where 1=1 ;
load from unl/20201103_qxt_menu_item.unl insert into qxt_menu_item;
load from unl/20201103_qxt_menu_item_txt.unl insert into qxt_menu_item_txt;
load from unl/20201103_qxt_run_arg.unl insert into qxt_run_arg;
