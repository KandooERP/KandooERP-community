--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: qxt_menu_list
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/qxt_menu_list.unl SELECT * FROM qxt_menu_list;
drop table qxt_menu_list;

create table "informix".qxt_menu_list 
(
menu_id serial not null ,
menu_root_id integer,
menu_name nvarchar(30),
menu_info nvarchar(100,0),
primary key (menu_id) constraint "informix".pkmenu_list
);

LOAD FROM unl20190322/qxt_menu_list.unl INSERT INTO qxt_menu_list;
