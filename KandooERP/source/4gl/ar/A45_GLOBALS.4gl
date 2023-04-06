############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_rec_credithead RECORD LIKE credithead.*
	--DEFINE glob_org_cust_code LIKE invoicehead.org_cust_code
	DEFINE glob_org_name_text LIKE customer.name_text
	--DEFINE glob_corp_cust SMALLINT
	DEFINE glob_use_outer SMALLINT
	DEFINE glob_x SMALLINT
	DEFINE glob_y SMALLINT
	DEFINE glob_word CHAR(20)
	DEFINE glob_letter CHAR(1)
END GLOBALS 
