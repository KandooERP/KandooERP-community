--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: banktype
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/banktype.unl SELECT * FROM banktype;
drop table banktype;

create table "informix".banktype 
(
type_code nvarchar(8),
type_text nvarchar(40),
eft_format_ind smallint,
eft_path_text nvarchar(40),
eft_file_text nvarchar(20),
stmt_format_ind smallint,
stmt_path_text nvarchar(40),
stmt_file_text nvarchar(20)
);

LOAD FROM unl20190322/banktype.unl INSERT INTO banktype;
