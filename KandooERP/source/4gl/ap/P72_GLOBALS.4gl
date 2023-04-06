############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS 
	DEFINE glob_glparms RECORD LIKE glparms.* 
	DEFINE pr_globals RECORD 
		vouch_date LIKE voucher.vouch_date, 
		update_flag CHAR(1), 
		year_num LIKE period.year_num, 
		period_num LIKE period.period_num 
	END RECORD
	--DEFINE glob_temp_text CHAR(200) # disabled this DEFINE because redundant declare with different type
END GLOBALS 