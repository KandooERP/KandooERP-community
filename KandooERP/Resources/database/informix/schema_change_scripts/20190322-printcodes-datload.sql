--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: printcodes
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/printcodes.unl SELECT * FROM printcodes;
drop table printcodes;

create table "informix".printcodes 
(
print_code nvarchar(20),
device_ind nchar(1),
width_num smallint,
length_num smallint,
compress_1 smallint,
compress_2 smallint,
compress_3 smallint,
compress_4 smallint,
compress_5 smallint,
compress_6 smallint,
compress_7 smallint,
compress_8 smallint,
compress_9 smallint,
compress_10 smallint,
normal_1 smallint,
normal_2 smallint,
normal_3 smallint,
normal_4 smallint,
normal_5 smallint,
normal_6 smallint,
normal_7 smallint,
normal_8 smallint,
normal_9 smallint,
normal_10 smallint,
compress_11 smallint,
compress_12 smallint,
compress_13 smallint,
compress_14 smallint,
compress_15 smallint,
compress_16 smallint,
compress_17 smallint,
compress_18 smallint,
compress_19 smallint,
compress_20 smallint,
print_text nvarchar(60),
desc_text nvarchar(30)
);

LOAD FROM unl20190322/printcodes.unl INSERT INTO printcodes;
