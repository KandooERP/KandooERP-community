database kandoodb
DEFINE t_arr_category TYPE AS RECORD 
	cat_code LIKE category.cat_code, 
	desc_text LIKE category.desc_text,
	sale_acct_code LIKE category.sale_acct_code
END RECORD 

DEFINE t_category_prykey TYPE AS RECORD
	cmpy_code LIKE prodgrp.cmpy_code,
	cat_code LIKE category.cat_code
END RECORD

DEFINE t_arr_action TYPE AS RECORD
	ACTION CHAR(1)
END RECORD

DEFINE t_rec_category TYPE AS RECORD LIKE category.*

MAIN
DEFINE l_status INTEGER
DEFINE l_rec_category t_rec_category

	CALL input_category("EDIT","FR","A") RETURNING l_status,l_rec_category.*
	
END MAIN


FUNCTION input_category(p_mode,p_category_prykey) 
	DEFINE p_mode CHAR(5)
	DEFINE p_category_prykey t_category_prykey
	DEFINE l_rec_category RECORD LIKE category.*
	DEFINE l_status INTEGER
	
	OPEN WINDOW i135 with FORM "z_hello_AR" 

		INPUT BY NAME l_rec_category.cat_code, 
		l_rec_category.desc_text, 
		l_rec_category.sale_acct_code, 
		l_rec_category.cogs_acct_code, 
		l_rec_category.stock_acct_code, 
		l_rec_category.adj_acct_code, 
		l_rec_category.int_rev_acct_code, 
		l_rec_category.int_cogs_acct_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			IF p_mode = "EDIT" THEN
				# We do not touch primary key in EDIT mode
				CALL Dialog.setFieldActive("cogs_acct_code",FALSE)
			ELSE
				CALL Dialog.setFieldActive("cogs_acct_code",TRUE)
			END IF

		AFTER FIELD cat_code 
			IF p_mode = "ADD" THEN
				IF l_rec_category.cat_code IS NULL THEN 
					--LET l_msgresp = kandoomsg("I",9038,"") 
					#9038 Category Code must be entered.
					NEXT FIELD cat_code 
				ELSE 
					# since cat_code field is not active for EDIT mode, no need to test
					--IF check_prykey_exists_category(glob_rec_kandoouser.cmpy_code, l_rec_category.cat_code) THEN
						#9093 Category already exists - Please Re-enter
						NEXT FIELD cat_code 
					--END IF 
				END IF
			END IF 

		AFTER FIELD cogs_acct_code
			ERROR "cogs_acct_code should be disABLED" 

		AFTER FIELD desc_text 
			IF l_rec_category.desc_text IS NULL THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN
				DISPLAY l_status 
			END IF 

	END INPUT 

	CLOSE WINDOW i135 

END FUNCTION  # input_category

{
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# MAIN
#
# We are just testing, if public, client side java scripts 
# and lib_tool/lib_db_tool are working for AR
# Note: This is just a "Minimum Test"
############################################################
MAIN 
	DEFINE l_msg STRING
	DEFINE l_value STRING
	#Initial UI Init
	CALL setModuleId("A11") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_a_ar() #init a/ar module 

	DISPLAY "Hello Kandoo World AR (Accounts Receivable)"
	CALL fgl_winmessage("Hello","Hello Kandoo World AR (Accounts Receivable)","info")
	
	LET l_value = trim(db_category_get_first_sale_acct_code(UI_ON)) 
	
	IF l_value IS NULL THEN
		LET l_msg = "Lowest/First Sales Account from the warehouse category table\nsale_acct_code = ", l_value , "\nIf no value is shown, we have a problem"
		CALL fgl_winmessage("lib_tool_db test", l_msg,"ERROR")
	ELSE 
		LET l_msg = "Lowest/First Sales Account from the warehouse category table\nsale_acct_code = ", l_value 
		CALL fgl_winmessage("lib_tool_db test", l_msg,"MESSAGE")
	END IF
		
END MAIN
}