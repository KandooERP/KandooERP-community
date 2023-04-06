############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_from_date DATE
	DEFINE glob_to_date DATE
	DEFINE glob_divn_text LIKE structure.desc_text 
	DEFINE glob_dept_text LIKE structure.desc_text 
	DEFINE glob_tot_wd_amt LIKE invoicehead.total_amt 
END GLOBALS 