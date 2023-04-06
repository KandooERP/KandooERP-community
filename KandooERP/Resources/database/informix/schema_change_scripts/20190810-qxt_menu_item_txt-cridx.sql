--# description: this script create indexes on qxt_menu_item_txt
--# dependencies: put here any .unl file if the script loads data, any other script if required
--# tables list: qxt_menu_item_txt
--# author: eric vercelletto
--# date: 2019-08-10
--# Ticket # :
--# more comments:
create index qxt_menu_item_txt_01 on qxt_menu_item_txt(mb_id);
create unique index u_qxt_menu_item_txt on qxt_menu_item_txt(mb_id,lang_id);

