############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_vendor RECORD LIKE vendor.* #pr_vendor used BY p11, p12, p15, p16, p1a, p1b, p21-p2e, 
	#DEFINE pr_apparms RECORD LIKE apparms.*
	DEFINE glob_rec_apparms RECORD LIKE apparms.* 
	#	DEFINE glob_rec_glparms
	#		RECORD
	#			base_currency_code LIKE glparms.base_currency_code
	#		END RECORD

	#DEFINE pr_vendorgrp RECORD LIKE vendorgrp.*
	#DEFINE msgresp LIKE language.yes_flag  #this joke needs TO go as soon we cleanup all files/functions
END GLOBALS 
