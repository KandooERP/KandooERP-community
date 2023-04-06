--# description: this script modifies tables kandooreport and rmsreps for Kandoo Report Framework
--# dependencies:
--# tables list:  kandooreport, rmsreps
--# author: a.chubar
--# date: 2020-07-01
--# Ticket:

DELETE FROM
	kandooreport
WHERE
	1 = 1;

ALTER TABLE
	kandooreport
ADD
	(
		report_engine smallint BEFORE header_text,
		entry_type smallint BEFORE header_text,
		top_margin smallint BEFORE menupath_text,
		bottom_margin smallint BEFORE menupath_text,
		left_margin smallint BEFORE menupath_text,
		right_margin smallint BEFORE menupath_text,
		titleedit_flag char(1) BEFORE l_report_code,
		printnow_flag char(1) BEFORE l_report_code,
		rmsdialog_flag char(1) BEFORE l_report_code,
		col_pos_1 smallint BEFORE l_report_code,
		col_pos_2 smallint BEFORE l_report_code,
		col_pos_3 smallint BEFORE l_report_code,
		col_pos_4 smallint BEFORE l_report_code,
		col_pos_5 smallint BEFORE l_report_code,
		col_pos_6 smallint BEFORE l_report_code,
		col_pos_7 smallint BEFORE l_report_code,
		col_pos_8 smallint BEFORE l_report_code,
		col_pos_9 smallint BEFORE l_report_code
	);

DELETE FROM
	rmsreps
WHERE
	1 = 1;

ALTER TABLE
	rmsreps
ADD
	(
		entry_type smallint BEFORE report_text,
		report_modid_text nvarchar(5, 3) BEFORE report_time,
		report_func_text nvarchar(30) BEFORE report_time,
		top_margin smallint BEFORE page_num,
		bottom_margin smallint BEFORE page_num,
		left_margin smallint BEFORE page_num,
		right_margin smallint BEFORE page_num,
		report_engine smallint BEFORE page_num,
		sel_option3 nvarchar(150) BEFORE sel_order,
		sel_option4 nvarchar(150) BEFORE sel_order,
		sel_option5 nvarchar(150) BEFORE sel_order,
		sel_option6 nvarchar(150) BEFORE sel_order,
		ref5_code nchar(10) BEFORE ref1_date,
		ref6_code nchar(10) BEFORE ref1_date,
		ref5_date date BEFORE ref1_ind,
		ref6_date date BEFORE ref1_ind,
		ref5_ind nchar(1) BEFORE printnow_flag,
		ref6_ind nchar(1) BEFORE printnow_flag,
		rmsdialog_flag char(1) BEFORE copy_num,
		ref5_num integer BEFORE ref2_text,
		ref6_num integer BEFORE ref2_text,
		ref1_amt decimal(16, 2) BEFORE ref2_text,
		ref2_amt decimal(16, 2) BEFORE ref2_text,
		ref3_text nvarchar(100) BEFORE sub_dest,
		ref4_text nvarchar(100) BEFORE sub_dest,
		ref5_text nvarchar(100) BEFORE sub_dest,
		ref6_text nvarchar(100) BEFORE sub_dest,
		ref3_amt decimal(16, 2) BEFORE printonce_flag,
		ref4_amt decimal(16, 2) BEFORE printonce_flag,
		ref5_amt decimal(16, 2) BEFORE printonce_flag,
		ref6_amt decimal(16, 2) BEFORE printonce_flag,
		ref1_per decimal(6, 2) BEFORE printonce_flag,
		ref2_per decimal(6, 2) BEFORE printonce_flag,
		ref3_per decimal(6, 2) BEFORE printonce_flag,
		ref4_per decimal(6, 2) BEFORE printonce_flag,
		ref5_per decimal(6, 2) BEFORE printonce_flag,
		ref6_per decimal(6, 2) BEFORE printonce_flag,
		ref1_factor decimal(16, 8) BEFORE printonce_flag,
		ref2_factor decimal(16, 8) BEFORE printonce_flag,
		ref3_factor decimal(16, 8) BEFORE printonce_flag,
		ref4_factor decimal(16, 8) BEFORE printonce_flag,
		ref5_factor decimal(16, 8) BEFORE printonce_flag,
		ref6_factor decimal(16, 8) BEFORE printonce_flag,
		col_pos_1 smallint BEFORE printonce_flag,
		col_pos_2 smallint BEFORE printonce_flag,
		col_pos_3 smallint BEFORE printonce_flag,
		col_pos_4 smallint BEFORE printonce_flag,
		col_pos_5 smallint BEFORE printonce_flag,
		col_pos_6 smallint BEFORE printonce_flag,
		col_pos_7 smallint BEFORE printonce_flag,
		col_pos_8 smallint BEFORE printonce_flag,
		col_pos_9 smallint BEFORE printonce_flag,
		titleedit_flag char(1)
	);

ALTER TABLE
	rmsreps
MODIFY
	sel_text nchar(2000);

ALTER TABLE
	rmsreps
MODIFY
	sub_dest decimal(16, 2);