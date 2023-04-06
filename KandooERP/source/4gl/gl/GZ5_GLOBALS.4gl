############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_reporthead RECORD LIKE reporthead.* 
	DEFINE glob_arr_rec_reporthead DYNAMIC ARRAY OF t_rec_reporthead_rc_dt_cn_ph 
	#	DEFINE glob_arr_rec_reporthead array[500] OF
	#		RECORD
	#	   report_code LIKE reporthead.report_code,
	#	   desc_text LIKE reporthead.desc_text,
	#	   column_num LIKE reporthead.column_num,
	#	   page_head_flag LIKE reporthead.page_head_flag
	#		END RECORD
	DEFINE glob_id_flag SMALLINT 
	DEFINE glob_cnt SMALLINT 
	#DEFINE glob_err_flag  SMALLINT not used
	#DEFINE glob_rec_kandoouser RECORD LIKE kandoouser.* not used

END GLOBALS 
