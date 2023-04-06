--# description: this script handles changes in the menu items
--# dependencies: put in unl directory any .unl file if the script loads data
--# tables list:  qxt_menu_item_txt,qxt_menu_item
--# author: alch
--# date: 2020-06-09
--# Ticket: KD-2137
--# more comments: 
--# set constraints all deferred is necessary because qxt_menu_item has another relationship with qxt_log_run
--begin work;
-- set constraints all deferred;
delete from qxt_menu_item_txt where 1=1 ;
delete from qxt_menu_item where 1=1 ;
load from unl/20200609_qxt_menu_item.unl insert into qxt_menu_item;
load from unl/20200609_qxt_menu_item_txt.unl insert into qxt_menu_item_txt;
--commit work;

