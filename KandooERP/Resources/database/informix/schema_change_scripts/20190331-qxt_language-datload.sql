--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: qxt_language
--# author: huho/albo
--# date: 2019-03-28
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/qxt_language.unl SELECT * FROM qxt_language;

begin work;

drop table "informix".qxt_language;
create table "informix".qxt_language 
(
lang_id nchar(3) not null ,
lang_txt nvarchar(255),
primary key (lang_id) constraint "informix".pk_language
);

LOAD FROM unl20190322/qxt_language.unl INSERT INTO qxt_language;

commit work;
