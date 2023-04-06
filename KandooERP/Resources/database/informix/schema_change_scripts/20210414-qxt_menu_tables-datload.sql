--# description: this script handles changes in the menu items
--# dependencies: put in unl directory any .unl file if the script loads data
--# tables list:  qxt_menu_item_txt,qxt_menu_item
--# author: Alex Bondar
--# date: 2021-04-14
--# Ticket: KD-2738
--# more comments: 
--# set constraints all deferred is necessary because qxt_menu_item has another relationship with qxt_log_run
set constraints all deferred;
delete from qxt_menu_item_txt where 1=1 ;
delete from qxt_menu_item where 1=1 ;
delete from qxt_run_arg where 1=1 ;
load from unl/20210414_qxt_menu_item.unl insert into qxt_menu_item;
load from unl/20210414_qxt_menu_item_txt.unl insert into qxt_menu_item_txt;
load from unl/20210414_qxt_run_arg.unl insert into qxt_run_arg;
