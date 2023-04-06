############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
--	DEFINE org_cust_code LIKE invoicehead.org_cust_code
	DEFINE glob_org_name_text LIKE customer.name_text
	DEFINE glob_corp_cust SMALLINT #pv_corp_cust
--	DEFINE glob_where_part STRING -- CHAR(1500)
--	DEFINE glob_query_text STRING
	DEFINE glob_func_type CHAR(14)
	DEFINE glob_ref_text LIKE arparms.inv_ref1_text
	DEFINE glob_use_outer SMALLINT
	DEFINE glob_x SMALLINT
	DEFINE glob_y SMALLINT
	DEFINE glob_word CHAR(20)
	DEFINE glob_letter CHAR(1)
	--DEFINE glob_del_yes CHAR(1) 
END GLOBALS 
