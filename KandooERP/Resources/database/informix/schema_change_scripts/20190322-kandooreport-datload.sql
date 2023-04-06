--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: kandooreport
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/kandooreport.unl SELECT * FROM kandooreport;
drop table kandooreport;

create table "informix".kandooreport 
(
report_code nchar(10),
language_code nchar(3),
header_text nvarchar(60),
width_num smallint,
length_num smallint,
menupath_text nchar(4),
selection_flag char(1),
line1_text nvarchar(132),
line2_text nvarchar(132),
line3_text nvarchar(132),
line4_text nvarchar(132),
line5_text nvarchar(132),
line6_text nvarchar(132),
line7_text nvarchar(132),
line8_text nvarchar(132),
line9_text nvarchar(132),
line0_text nvarchar(132),
exec_ind nchar(1),
exec_flag nchar(1),
l_report_code integer,
l_report_date date,
l_report_time nchar(5),
l_entry_code nvarchar(8)
);


LOAD FROM unl20190322/kandooreport.unl INSERT INTO kandooreport;
