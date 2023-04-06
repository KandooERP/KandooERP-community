############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	--DEFINE glob_msg CHAR(40)
	--DEFINE prog CHAR(40)
	DEFINE glob_itis DATE
	--DEFINE print_option CHAR(1)
	--DEFINE cmd CHAR(3)
	--DEFINE glob_org_customer RECORD LIKE customer.*
	DEFINE glob_v_name_text LIKE customer.name_text
	DEFINE glob_t_name_text LIKE customer.name_text
	DEFINE glob_corp_cust RECORD LIKE customer.*
	DEFINE glob_v_corp_cust SMALLINT
	
	#AB1
	DEFINE glob_org_cust_code LIKE invoicehead.org_cust_code
	DEFINE glob_org_name_text LIKE customer.name_text

	DEFINE glob_use_outer SMALLINT
	DEFINE glob_x SMALLINT
	DEFINE glob_y SMALLINT
	
	DEFINE glob_word CHAR(20)
	DEFINE glob_letter CHAR(1)
	--DEFINE glob_el_yes CHAR(1)

--	DEFINE glob_prg_name CHAR(7) 

END GLOBALS 
