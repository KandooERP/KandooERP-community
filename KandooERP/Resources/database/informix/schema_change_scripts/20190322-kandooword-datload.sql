--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: kandooword
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/kandooword.unl SELECT * FROM kandooword;
drop table kandooword;

create table "informix".kandooword 
(
language_code nchar(3),
reference_code nchar(3),
reference_text nvarchar(40),
response_text nvarchar(70)
);



LOAD FROM unl20190322/kandooword.unl INSERT INTO kandooword;
