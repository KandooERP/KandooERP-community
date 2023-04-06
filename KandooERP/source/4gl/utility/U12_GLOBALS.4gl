############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../utility/U_UT_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_formname CHAR(15) 
	DEFINE glob_rec_kandoouser_specific RECORD LIKE kandoouser.* #needs TO stay separated FOR utilities (user/operators works with other kandoousers properties/column data) 
	DEFINE glob_rec_userlocn RECORD LIKE userlocn.* 
	DEFINE glob_rec_specific_company RECORD LIKE company.* 
	#DEFINE glob_winds_text CHAR(200)
	DEFINE glob_rec_kandooprofile RECORD LIKE kandooprofile.* 
	DEFINE glob_rec_specific_kandoomodule RECORD LIKE kandoomodule.* 
	DEFINE glob_rec_specific_language RECORD LIKE language.* 
	DEFINE glob_rec_printcodes RECORD LIKE printcodes.* #note: data IS copied TO this RECORD but NOT used/retrieved from... 
	DEFINE glob_arr_rec_kandoouser DYNAMIC ARRAY OF t_rec_kandoouser_sc_nt_si_am 
	#	 RECORD --array[800] of record
	#          #scroll_flag CHAR(1),
	#          sign_on_code LIKE kandoouser.sign_on_code,
	#          name_text LIKE kandoouser.name_text,
	#          security_ind LIKE kandoouser.security_ind,
	#          acct_mask_code LIKE kandoouser.acct_mask_code
	#      END RECORD
	#DEFINE glob_mask_code LIKE account.acct_code  #not used ????
	DEFINE glob_cnt SMALLINT #only used in u12 
	DEFINE glob_idx SMALLINT 
	#DEFINE glob_i SMALLINT
	#DEFINE cnt SMALLINT
	#DEFINE glob_delete_flag SMALLINT
	#DEFINE glob_entry_flag SMALLINT

	DEFINE acct_desc_text LIKE coa.desc_text 
	DEFINE glob_rec_grant_deny_access RECORD LIKE grant_deny_access.* #only used in u12a.4gl 
	#DEFINE glob_rec_menunames RECORD LIKE menunames.* not used at all
	DEFINE glob_rec_kandoousercmpy RECORD LIKE kandoousercmpy.* 
	DEFINE glob_rec_location RECORD LIKE location.* #used in u12.4gl AND u12a.4gl 
END GLOBALS 
