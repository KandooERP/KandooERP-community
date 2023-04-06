--# description: this script handles changes in the menu items
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list:  qxt_menu_item_txt,qxt_menu_item
--# author: Alex Bondar
--# date: 2019-07-22
--# Ticket: KD-918, KD-960, KD-963;
--# more comments: first backup the existing contents (unload to xxx.bkp), then delete contents and load from new data files.
--# set constraints all deferred is necessary because qxt_menu_item has another relationship with qxt_log_run
begin work;
-- set constraints all deferred;
delete from qxt_menu_item_txt where 1 = 1 ;
load from "unl/20190722_qxt_menu_item_txt.unl" insert into qxt_menu_item_txt;

delete from qxt_menu_item where 1 = 1 ;
load from "unl/20190722_qxt_menu_item.unl" insert into qxt_menu_item;

commit work;

