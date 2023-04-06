--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: qxt_toolbar
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/qxt_toolbar.unl SELECT * FROM qxt_toolbar;
drop table qxt_toolbar;

create table "informix".qxt_toolbar 
(
tb_proj_id nvarchar(30),
tb_module_id nvarchar(30),
tb_menu_id nvarchar(40),
tb_action varchar(30),
tb_label nvarchar(20,0),
tb_icon nvarchar(150),
tb_position integer,
tb_static smallint,
tb_tooltip nvarchar(100,0),
tb_type smallint,
tb_scope smallint,
tb_hide smallint,
tb_key nvarchar(20),
tb_category nvarchar(30,0),
tb_mod_user nvarchar(8),
tb_mod_date datetime year to second,
primary key (tb_proj_id,tb_module_id,tb_menu_id,tb_action) 
);


LOAD FROM unl20190322/qxt_toolbar.unl INSERT INTO qxt_toolbar;
