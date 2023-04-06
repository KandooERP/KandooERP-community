############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
--	DEFINE glob_cmpy2 LIKE company.cmpy_code
--	DEFINE glob_rec_opparms RECORD LIKE opparms.*
--	DEFINE glob_rec_customership RECORD LIKE customership.*
	DEFINE glob_rec_corpcust RECORD LIKE customer.*
	DEFINE glob_rec_credithead RECORD LIKE credithead.*
	DEFINE glob_rec_jmjdebttype RECORD LIKE jmj_debttype.*
	DEFINE glob_rec_jmjtrantype RECORD LIKE jmj_trantype.*
	DEFINE glob_total_amt LIKE credithead.total_amt 
	DEFINE glob_control_amt LIKE credithead.total_amt 

END GLOBALS 