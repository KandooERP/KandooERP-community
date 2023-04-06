--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: qxt_log_login
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/qxt_log_login.unl SELECT * FROM qxt_log_login;
drop table qxt_log_login;

create table "informix".qxt_log_login
(
session_id serial not null ,
sign_on_code nvarchar(8,0) not null ,
logindt datetime year to second,
logoutdt datetime year to second,
client_host_name nvarchar(128),
client_host_ip_address nvarchar(128),
server_session_id char(64),
unique (server_session_id) constraint "informix".u_log_login,
primary key (session_id) constraint "informix".pk_log_login
);

LOAD FROM unl20190322/qxt_log_login.unl INSERT INTO qxt_log_login;
