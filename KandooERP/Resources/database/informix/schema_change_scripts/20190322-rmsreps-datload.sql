--# description: full reorganization of kandoo menus, changing chars to Nchars
--# dependencies:
--# tables list: rmsreps
--# author: huho
--# date: 2019-03-22
--# Ticket # :
--# more comments: full reorganization of kandoo menus, changing chars to Nchars

--UNLOAD TO unl/rmsreps.unl SELECT * FROM rmsreps;
drop table rmsreps;

create table "informix".rmsreps 
(
cmpy_code char(2),
report_code integer,
report_text nvarchar(60),
status_text nvarchar(13),
entry_code nchar(8),
security_ind nchar(1),
report_date date,
report_pgm_text nvarchar(10),
report_time nchar(8),
report_width_num smallint,
page_length_num smallint,
page_num integer,
dest_print_text nvarchar(20),
status_ind nchar(1),
exec_ind nchar(1),
sel_text nchar(2000),
sel_flag char(1),
file_text nchar(20),
ref1_code nchar(10),
ref2_code nchar(10),
ref3_code nchar(10),
ref4_code nchar(10),
ref1_date date,
ref2_date date,
ref3_date date,
ref4_date date,
ref1_ind nchar(1),
ref2_ind nchar(1),
ref3_ind nchar(1),
ref4_ind nchar(1),
printnow_flag char(1),
copy_num smallint,
comp_ind nchar(1),
start_page smallint,
print_page smallint,
align_ind nchar(1),
ref1_num integer,
ref2_num integer,
ref3_num integer,
ref4_num integer,
ref1_text nvarchar(100),
sub_dest nvarchar(40),
printonce_flag char(1)
);


LOAD FROM unl20190322/rmsreps.unl INSERT INTO rmsreps;
