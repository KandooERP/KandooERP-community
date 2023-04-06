############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

GLOBALS 
	DEFINE 
	whom LIKE kandoouser.sign_on_code, 
	yes_flag CHAR(1), 
	no_flag CHAR(1), 
	pr_company RECORD LIKE company.*, 
	pr_inparms RECORD LIKE inparms.*, 
	pr_product RECORD LIKE product.* 
END GLOBALS 
