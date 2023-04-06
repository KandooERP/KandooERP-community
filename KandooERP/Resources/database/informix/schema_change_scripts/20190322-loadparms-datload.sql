--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: loadparms
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/loadparms.unl SELECT * FROM loadparms;
drop table loadparms;

create table "informix".loadparms 
(
cmpy_code char(2),
load_ind nchar(3),
desc_text nvarchar(30),
format_ind nchar(2),
path_text nvarchar(60),
file_text nvarchar(20),
load_date date,
load_num integer,
seq_num integer,
prmpt1_text nvarchar(15),
ref1_text nvarchar(20),
entry1_flag char(1),
prmpt2_text nvarchar(15),
ref2_text nvarchar(20),
entry2_flag char(1),
prmpt3_text nvarchar(15),
ref3_text nvarchar(20),
entry3_flag char(1),
module_code nchar(2),
primary key (cmpy_code,load_ind) constraint "informix".loadparms
);

LOAD FROM unl20190322/loadparms.unl INSERT INTO loadparms;
