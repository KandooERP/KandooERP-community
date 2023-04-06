--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: menu_group_access
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/menu_group_access.unl SELECT * FROM menu_group_access;
drop table IF EXISTS menu_group_access;

create table "informix".menu_group_access
(
mb_id integer not null ,
group_code nchar(1) not null ,
ga_hidden integer,
unique (mb_id,group_code) 
);

LOAD FROM unl20190322/menu_group_access.unl INSERT INTO menu_group_access;
