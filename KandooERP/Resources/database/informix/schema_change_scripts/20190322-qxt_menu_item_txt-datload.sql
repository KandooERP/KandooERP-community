--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: qxt_menu_item_txt
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

drop table qxt_menu_item_txt;

create table "informix".qxt_menu_item_txt 
(
mb_id integer not null ,
lang_id nchar(3) not null ,
mb_label nvarchar(100),
mb_tooltip nvarchar(100)
);

LOAD FROM unl20190322/qxt_menu_item_txt.unl INSERT INTO qxt_menu_item_txt;
