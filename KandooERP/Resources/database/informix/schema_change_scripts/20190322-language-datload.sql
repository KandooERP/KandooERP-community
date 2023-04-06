--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: language
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/language.unl SELECT * FROM language;
drop table language;

create table "informix".language 
(
language_code nchar(3),
language_text nvarchar(80),
yes_flag nchar(1),
no_flag nchar(1),
national_text nvarchar(80)
);

LOAD FROM unl20190322/language.unl INSERT INTO language;
