--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: qxt_run_arg
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/qxt_run_arg.unl SELECT * FROM qxt_run_arg;
drop table qxt_run_arg;

create table "informix".qxt_run_arg 
(
rc_arg_id serial not null ,
rc_arg nvarchar(100),
rc_arg_info nvarchar(200),
primary key (rc_arg_id) constraint "informix".pk_run_arg
);


LOAD FROM unl20190322/qxt_run_arg.unl INSERT INTO qxt_run_arg;
