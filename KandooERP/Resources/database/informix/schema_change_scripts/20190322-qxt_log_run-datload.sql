--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: qxt_log_run
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/qxt_log_run.unl SELECT * FROM qxt_log_run;
drop table qxt_log_run;

create table "informix".qxt_log_run 
(
run_id serial not null ,
session_id integer not null ,
mb_id integer not null ,
sign_on_code nvarchar(8,0) not null ,
rundt datetime year to second,
primary key (run_id) constraint "informix".pk_log_run
);

LOAD FROM unl20190322/qxt_log_run.unl INSERT INTO qxt_log_run;
