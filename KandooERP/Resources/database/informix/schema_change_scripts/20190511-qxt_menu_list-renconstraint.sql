--# description: this script remove implicit primary key constraint, create a unique index then PK on top
--# dependencies: 
--# tables list: qxt_menu_list
--# author: ericv
--# date: 2019-05-11
--# Ticket # :  4
--# more comments:
alter table qxt_menu_list drop constraint pkmenu_list;
create unique index u_qxt_menu_list on qxt_menu_list(menu_id);
alter table qxt_menu_list add constraint primary key (menu_id) constraint pk_qxt_menu_list;
