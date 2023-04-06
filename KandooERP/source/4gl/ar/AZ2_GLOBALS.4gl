############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_DATABASE.4gl"
GLOBALS 
	DEFINE glob_arr_rec_payment_menu array[11] OF RECORD 
		scroll_flag CHAR(1), 
		option_num LIKE term.day_date_ind, 
		option_text CHAR(34) 
	END RECORD 
END GLOBALS