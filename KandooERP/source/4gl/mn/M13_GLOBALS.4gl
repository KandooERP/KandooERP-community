############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


GLOBALS 

	DEFINE 
	formname CHAR(10), 
	fv_where_part CHAR(500), 
	fv_query_text CHAR(500), 
	fv_runner CHAR(10), 
	fv_type CHAR(1), 
	fv_cnt SMALLINT, 
	fv_reselect SMALLINT, 
	fv_part_code LIKE prodmfg.part_code, 

	pr_menunames RECORD LIKE menunames.*, 

	fa_prodmfg array[500] OF RECORD 
		part_code LIKE prodmfg.part_code, 
		desc_text LIKE product.desc_text, 
		part_type_ind LIKE prodmfg.part_type_ind, 
		part_type_text CHAR(12) 
	END RECORD 

END GLOBALS 
