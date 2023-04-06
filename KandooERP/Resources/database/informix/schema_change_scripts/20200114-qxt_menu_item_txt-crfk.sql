--# description: this script create foreign key on qxt_menu_item_txt
--# dependencies: 
--# tables list: qxt_menu_item_txt
--# author: Alex Bondar
--# date: 2020-01-14
--# Ticket # :
--# more comments:
alter table qxt_menu_item_txt add constraint (foreign key (mb_id) references qxt_menu_item  constraint fkmenu_item_txt_mb_id);
