--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: langstr_aus
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/langstr_gb.unl SELECT * FROM langstr_gb;
drop table langstr_gb;

create table "informix".langstr_gb 
(
id nvarchar(30),
langstr nvarchar(100)
);

LOAD FROM unl20190322/langstr_gb.unl INSERT INTO langstr_gb;
