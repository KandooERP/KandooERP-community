--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: clipboard
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/clipboard.unl SELECT * FROM clipboard;
drop table clipboard;

create table "informix".clipboard 
(
sign_on_code nvarchar(8,0),
char_val nchar(1),
string_val nvarchar(200,0),
int_val integer,
date_val date,
tool_ver integer
);

LOAD FROM unl20190322/clipboard.unl INSERT INTO clipboard;
