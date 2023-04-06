--# description: this script handles changes in the menu items
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list:  qxt_menu_item_txt,qxt_menu_item
--# author: Alex Bondar
--# date: 2019-04-01
--# Ticket # :
--# more comments: first backup the existing contents (unload to xxx.bkp), then delete contents and load from new data files.
--# set constraints all deferred is necessary because qxt_menu_item has another relationship with qxt_log_run
unload to "unl/qxt_menu_item_txt_org.bkp" select * from qxt_menu_item_txt;
unload to "unl/qxt_menu_item_org.bkp" select * from qxt_menu_item;
begin work;

drop table "informix".qxt_menu_item_txt;
create table "informix".qxt_menu_item_txt
  (
    mb_id integer not null ,
    lang_id nchar(3) not null ,
    mb_label nvarchar(100),
    mb_tooltip nvarchar(100)
  );
load from "unl/20190401_qxt_menu_item_txt.unl" insert into qxt_menu_item_txt;

delete from qxt_menu_item where 1 = 1 ;
load from "unl/20190401_qxt_menu_item.unl" insert into qxt_menu_item;

alter table "informix".qxt_menu_item_txt add constraint (foreign
    key (mb_id) references "informix".qxt_menu_item  constraint
    "informix".fkmenu_item_txt_mb_id);

alter table "informix".qxt_menu_item_txt add constraint (foreign
    key (lang_id) references "informix".qxt_language  constraint
    "informix".fkmenu_item_txt_lang_id);

commit work;

