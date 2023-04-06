############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	##	DEFINE gv_aborted INTEGER

	#	DEFINE glob_rpt_id LIKE rpthead.rpt_id
	#	DEFINE glob_year_num LIKE period.year_num
	#	DEFINE glob_period_num LIKE period.period_num
	#	DEFINE glob_group_code LIKE coa.group_code
	#	DEFINE glob_acct_code LIKE coa.acct_code
	#	DEFINE glob_report_date DATE


	DEFINE glob_rpt_id LIKE rpthead.rpt_id 
	DEFINE glob_year_num LIKE period.year_num 
	DEFINE glob_period_num LIKE period.period_num 
	DEFINE glob_group_code LIKE coa.group_code 
	DEFINE glob_acct_code LIKE coa.acct_code 
	--DEFINE glob_report_date DATE 
	DEFINE glob_entry_criteria CHAR(200) 

	DEFINE glob_consol_criteria CHAR(100) 
	DEFINE glob_segment_criteria CHAR(500) 
	DEFINE glob_full_criteria CHAR(2000) 
	DEFINE glob_account_code LIKE coa.acct_code 
	DEFINE glob_rec_entry_criteria 
	RECORD 
		year_num LIKE accounthist.year_num, 
		period_num LIKE accounthist.period_num, 
		detailed_rpt CHAR(1), 
		glob_rpt_date DATE 
	END RECORD 
	DEFINE glob_rec_mrwparms RECORD LIKE mrwparms.* 
	DEFINE glob_rec_rpthead RECORD LIKE rpthead.* 
	DEFINE glob_rec_rptcol RECORD LIKE rptcol.* 
	#DEFINE glob_rec_rptcoldesc RECORD LIKE rptcoldesc.*
	#DEFINE glob_re_rptcolaa RECORD LIKE rptcolaa.*
	#DEFINE glob_rec_colitem RECORD LIKE colitem.*
	#DEFINE glob_rec_colitemdetl RECORD LIKE colitemdetl.*
	#DEFINE glob_rec_colaccum RECORD LIKE colaccum.*
	#DEFINE glob_rec_accumulator RECORD LIKE accumulator.*
	#DEFINE glob_rec_colitemcolid RECORD LIKE colitemcolid.*
	#DEFINE glob_rec_colitemval RECORD LIKE colitemval.*
	DEFINE glob_rec_rptline RECORD LIKE rptline.* 
	#DEFINE glob_rec_saveline RECORD LIKE saveline.*
	#DEFINE glob_rec_descline RECORD LIKE descline.*

	DEFINE glob_rec_structure RECORD LIKE structure.* 
	DEFINE glob_rec_signcode RECORD LIKE signcode.* 
	DEFINE glob_rec_calchead RECORD LIKE calchead.* 
	DEFINE glob_rec_calcline RECORD LIKE calcline.* 



	DEFINE glob_rec_glline RECORD LIKE glline.* 
	DEFINE glob_rec_gllinedetl RECORD LIKE gllinedetl.* 
	DEFINE glob_rec_segline RECORD LIKE segline.* 
	DEFINE glob_rec_extline RECORD LIKE extline.* 

	DEFINE glob_rec_txtline RECORD LIKE txtline.* 
	DEFINE glob_rec_rndcode RECORD LIKE rndcode.* 

	DEFINE glob_rec_mrwitem RECORD LIKE mrwitem.* 
	DEFINE glob_rec_itemattr RECORD LIKE itemattr.* 
	DEFINE glob_rec_txttype RECORD LIKE txttype.* 
	DEFINE glob_rec_rpttype RECORD LIKE rpttype.* 

	DEFINE glob_arr_colitem_amt array[80] OF DECIMAL(18,2) 
	DEFINE glob_consolidations_exist SMALLINT 
	DEFINE glob_start_num SMALLINT 
	DEFINE glob_length_num SMALLINT 
	DEFINE glob_col_amt DECIMAL(18,2) 
	DEFINE glob_print_ledg CHAR(1) 
	DEFINE glob_report_type CHAR(1) 
	DEFINE glob_curr_code LIKE currency.currency_code 
	DEFINE glob_conv_qty LIKE batchdetl.conv_qty 
	DEFINE glob_range CHAR(200) 
END GLOBALS 
