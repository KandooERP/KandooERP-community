############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE formname CHAR(15) 
	DEFINE pr_glparms RECORD LIKE glparms.* 
	DEFINE gv_aborted INTEGER 
	DEFINE gv_curr_code LIKE currency.currency_code 
	DEFINE gv_curr_slct LIKE currency.currency_code 
	DEFINE gv_base_curr LIKE currency.currency_code 
	DEFINE gv_print_curr CHAR(5) 
	DEFINE gv_col_curr_type CHAR(1) 
	DEFINE gv_always_print CHAR(1) 
	DEFINE gv_wksht_tots SMALLINT 
	DEFINE gv_first_line SMALLINT 
	DEFINE gv_acct_length SMALLINT 
--	DEFINE rpt_wid SMALLINT 
--	DEFINE rpt_pageno LIKE rmsreps.page_num 
--	DEFINE rpt_length LIKE rmsreps.page_length_num 
	DEFINE gv_segment_criteria CHAR(500) 
	DEFINE gv_tempcoa_clause CHAR(100) 
	DEFINE gv_tempcoa_append CHAR(10) 
	DEFINE gv_account_code LIKE coa.acct_code 
	DEFINE gv_job_id LIKE rptargs.job_id 
	DEFINE gr_entry_criteria 
	RECORD 
		cmpy_code LIKE company.cmpy_code, 
		year_num LIKE accounthist.year_num, 
		period_num LIKE accounthist.period_num, 
		col_hdr_per_page LIKE rpthead.col_hdr_per_page, 
		std_head_per_page LIKE rpthead.std_head_per_page, 
		worksheet_rpt CHAR(1), 
		desc_type CHAR(1), 
		rpt_date DATE, 
		run_opt CHAR(1), 
		curr_slct LIKE currency.currency_code, 
		conv_curr LIKE currency.currency_code, 
		base_lit CHAR(5), 
		conv_flag CHAR(1), 
		use_end_date CHAR(1), 
		conv_qty FLOAT 
	END RECORD 
	DEFINE gr_mrwparms RECORD LIKE mrwparms.* 
	DEFINE gr_rpthead_group RECORD LIKE rpthead_group.* 
	DEFINE gr_rpthead RECORD LIKE rpthead.* 
	DEFINE gr_rptcolgrp RECORD LIKE rptcolgrp.* 
	DEFINE gr_rptcol RECORD LIKE rptcol.* 
	DEFINE gr_rptcoldesc RECORD LIKE rptcoldesc.* 
	DEFINE gr_rptcolaa RECORD LIKE rptcolaa.* 
	DEFINE gr_colitem RECORD LIKE colitem.* 
	DEFINE gr_colitemdetl RECORD LIKE colitemdetl.* 
	DEFINE gr_colaccum RECORD LIKE colaccum.* 
	DEFINE gr_colitemcolid RECORD LIKE colitemcolid.* 
	DEFINE gr_colitemval RECORD LIKE colitemval.* 
	DEFINE gr_rptlinegrp RECORD LIKE rptlinegrp.* 
	DEFINE gr_rptline RECORD LIKE rptline.* 
	DEFINE gr_descline RECORD LIKE descline.* 
	DEFINE gr_glline RECORD LIKE glline.* 
	DEFINE gr_gllinedetl RECORD LIKE gllinedetl.* 
	DEFINE gr_segline RECORD LIKE segline.* 
	DEFINE gr_exthead RECORD LIKE exthead.* 
	DEFINE gr_extline RECORD LIKE extline.* 
	DEFINE gr_calchead RECORD LIKE calchead.* 
	DEFINE gr_calcline RECORD LIKE calcline.* 
	DEFINE gr_txtline RECORD LIKE txtline.* 
	DEFINE gr_rndcode RECORD LIKE rndcode.* 
	DEFINE gr_signcode RECORD LIKE signcode.* 
	DEFINE gr_mrwitem RECORD LIKE mrwitem.* 
	DEFINE gr_itemattr RECORD LIKE itemattr.* 
	DEFINE gr_txttype RECORD LIKE txttype.* 
	DEFINE gr_rpttype RECORD LIKE rpttype.* 
	DEFINE gr_rptslect RECORD LIKE rptslect.* 
	DEFINE gr_rptargs RECORD LIKE rptargs.* 
	DEFINE ga_colitem_amt array[30] OF DECIMAL(18,2) 
	DEFINE gv_detl_flag SMALLINT 
	DEFINE gv_num_args SMALLINT 
	DEFINE gv_selected SMALLINT 
	DEFINE gv_chart_operator LIKE gllinedetl.operator 
	DEFINE gv_maxcompany LIKE company.name_text 
	DEFINE gv_kandoousername LIKE kandoouser.name_text 
	DEFINE gv_desc_col_num LIKE descline.seq_num 
	DEFINE gv_analdown_clause CHAR(200) 
	DEFINE gv_acct_group LIKE acctgrp.group_code 
	DEFINE gv_itemattr_colname LIKE itemattr.colname 

END GLOBALS 
