############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS 

	DEFINE 
	pr_jobvars RECORD LIKE jobvars.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_job RECORD LIKE job.*, 
	idx, 
	id_flag, 
	scrn, 
	cnt, 
	err_flag SMALLINT, 
	ans CHAR(1) 
END GLOBALS 
