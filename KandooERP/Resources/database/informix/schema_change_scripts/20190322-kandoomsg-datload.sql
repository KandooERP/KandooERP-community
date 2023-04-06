--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: kandoomsg
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/kandoomsg.unl SELECT * FROM kandoomsg;
drop table kandoomsg;

create table "informix".kandoomsg 
(
source_ind nchar(1),
msg_num integer,
language_code nchar(3),
msg_ind nchar(1),
format_ind nchar(1),
msg1_text nvarchar(70),
msg2_text nvarchar(70),
help_num integer,
btn1_text nvarchar(70),
btn2_text nvarchar(70)
);


LOAD FROM unl20190322/kandoomsg.unl INSERT INTO kandoomsg;
