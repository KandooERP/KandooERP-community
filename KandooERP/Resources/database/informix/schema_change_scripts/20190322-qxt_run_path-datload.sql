--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: qxt_run_path
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/qxt_run_path.unl SELECT * FROM qxt_run_path;
drop table qxt_run_path;


create table "informix".qxt_run_path 
(
rc_path_id serial not null ,
rc_path nvarchar(100),
rc_path_info nvarchar(200),
primary key (rc_path_id) constraint "informix".pk_run_path
);


LOAD FROM unl20190322/qxt_run_path.unl INSERT INTO qxt_run_path;
