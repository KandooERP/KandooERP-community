--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: qxt_user_group
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/qxt_user_group.unl SELECT * FROM qxt_user_group;
drop table qxt_user_group;

create table "informix".qxt_user_group 
(
group_code nchar(1) not null ,
group_name nvarchar(50),
group_info nvarchar(100),
group_active integer,
primary key (group_code) constraint "informix".pk_user_group
);

LOAD FROM unl20190322/qxt_user_group.unl INSERT INTO qxt_user_group;
