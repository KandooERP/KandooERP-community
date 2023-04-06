--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: journal
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/journal.unl SELECT * FROM journal;
drop table journal;

create table "informix".journal 
(
cmpy_code char(2),
jour_code nchar(3),
desc_text nvarchar(40),
gl_flag char(1)
);


LOAD FROM unl20190322/journal.unl INSERT INTO journal;
