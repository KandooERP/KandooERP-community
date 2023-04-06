############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	--DEFINE glob_org_customer RECORD LIKE customer.* 
	DEFINE glob_name_text LIKE customer.name_text 
	DEFINE glob_rec_corp_cust RECORD LIKE customer.* 
	DEFINE glob_v_corp_cust SMALLINT
	DEFINE glob_v_name_text LIKE customer.name_text 
	DEFINE glob_arr_rec_nametext array[320] OF RECORD 
		name_text LIKE customer.name_text, 
		cust_code LIKE customer.cust_code 
	END RECORD
	DEFINE glob_rec_t_credithead RECORD LIKE credithead.* 
	#glob_rec_arparms record
	#   credit_ref1_text LIKE arparms.credit_ref1_text,
	#   credit_ref2a_text LIKE arparms.credit_ref2a_text,
	#   credit_ref2b_text LIKE arparms.credit_ref2b_text
	#END RECORD,
	--DEFINE i SMALLINT
	--DEFINE glob_cnt SMALLINT
	DEFINE glob_ref_text LIKE arparms.credit_ref1_text 
END GLOBALS 
