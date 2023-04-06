--# description: this script modifies tables kandooreport and rmsreps for Kandoo Report Framework: increase size of char variables
--# dependencies:
--# tables list:  kandooreport, rmsreps
--# author: a.chubar
--# date: 2020-07-30
--# Ticket:

ALTER TABLE
	kandooreport
MODIFY
	(
		line1_text nvarchar(160),
		line2_text nvarchar(160),
		line3_text nvarchar(160),
		line4_text nvarchar(160),
		line5_text nvarchar(160),
		line6_text nvarchar(160),
		line7_text nvarchar(160),
		line8_text nvarchar(160),
		line9_text nvarchar(160),
		line0_text nvarchar(160)
	);

ALTER TABLE
	rmsreps
MODIFY
	(
		sel_option1 nvarchar(160),
		sel_option2 nvarchar(160),
		sel_option3 nvarchar(160),
		sel_option4 nvarchar(160),
		sel_option5 nvarchar(160),
		sel_option6 nvarchar(160),
		sel_order nvarchar(160),
		ref1_text nvarchar(160),
		ref2_text nvarchar(160),
		ref3_text nvarchar(160),
		ref4_text nvarchar(160),
		ref5_text nvarchar(160),
		ref6_text nvarchar(160)
	);