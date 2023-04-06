--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: structure
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/structure.unl SELECT * FROM structure;
drop table structure;

create table "informix".structure 
(
cmpy_code char(2),
start_num smallint,
length_num smallint,
desc_text nvarchar(20),
default_text nvarchar(18),
type_ind nchar(1),
primary key (cmpy_code,start_num) 
);


LOAD FROM unl20190322/structure.unl INSERT INTO structure;
