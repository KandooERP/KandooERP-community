--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: qxt_menu_item
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
alter table qxt_menu_item drop constraint pkmenu_item;
create unique index u_qxt_menu_item on qxt_menu_item(mb_id);
alter table qxt_menu_item add constraint primary key (mb_id) constraint pk_qxt_menu_item;
