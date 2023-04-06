GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION windecoration_w(pwinname) 
	DEFINE pwinname STRING 
	DEFINE errmsg STRING 

	CASE pwinname 
	# Prog: U11
	# User Parameters

		WHEN "W900" 
			CALL combolist_company ("cmpy_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "W103" 

		WHEN "W118" --cart area / list filter 

		WHEN "W119" 

		WHEN "W120" 
			CALL combolist_company ("cmpy_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_country ("country_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_warehouse ("ware_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,combo_null_space) 
			CALL combolist_bank ("bank_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,combo_null_space) 

		WHEN "W154" --promotions (missing form) 

		WHEN "W170" -- ??? 

		WHEN "W229" --missing form
		WHEN "W232" --missing form

		WHEN "W261" 

		WHEN "W282" 

		WHEN "W339" 


		OTHERWISE 
			LET errmsg = "Invalid Window name passed TO winDecoration_W(", trim(pwinname), ")" 
			CALL fgl_winmessage("Internal 4GL Error",errMsg, "error") 
	END CASE 

END FUNCTION 
