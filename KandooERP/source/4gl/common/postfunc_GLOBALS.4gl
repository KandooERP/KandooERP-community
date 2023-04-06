############################################################
# GLOBAL Scope Variables
#
# This global file was added by Eric
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 

GLOBALS 
	#DEFINE modif ericv init #pr_poststatus RECORD LIKE poststatus.*,
	CONSTANT ALL_OK  = false
	CONSTANT NOT_OK  = true
	DEFINE glob_rec_poststatus RECORD LIKE poststatus.* 
	DEFINE glob_post_text CHAR(80) 
	DEFINE glob_err_text CHAR(80) 
	DEFINE glob_st_code SMALLINT 
	DEFINE glob_runner CHAR(80) #where AND why IS this used 
	DEFINE glob_fisc_year LIKE period.year_num 
	DEFINE glob_fisc_period LIKE period.period_num #where AND why IS this used 
	DEFINE glob_one_trans SMALLINT 
	DEFINE glob_in_trans SMALLINT 
	DEFINE glob_posted_journal LIKE batchhead.jour_num 
	DEFINE glob_error_msg LIKE poststatus.error_msg
END GLOBALS 
