GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION windecoration_t(pwinname) 
	DEFINE pwinname STRING 
	DEFINE errmsg STRING 

	CASE pwinname 

		WHEN "TG500" --management REPORT processing 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 

		WHEN "TG501" --report HEADER browse (list) 
		WHEN "TG509" --print REPORT writer definitions 
		WHEN "TG510" --report HEADER maintenance 
		WHEN "TG511" --report COLUMN browse 
		WHEN "TG512" --column item type 
		WHEN "TG513" --column maintenance 
		WHEN "TG514" --time item type 
		WHEN "TG515" --value item type 
		WHEN "TG516" --underline maintenance 
		WHEN "TG521" --accumulator 
		WHEN "TG522" --accumulator maintenance 
		WHEN "TG523" --column description line maintenance 
		WHEN "TG524" --general ledger line maintenance 
		WHEN "TG525" --report line maintenance 
		WHEN "TG530" --segment maintenance 
		WHEN "TG566" --report groups 
		WHEN "TG567" --list OF reports 
		WHEN "TG568" --list OF REPORT groups 
		WHEN "TG569" --group management REPORT processing 
		WHEN "TG570" --report HEADER selection 
		WHEN "TG571" --management REPORT processing 
		WHEN "TG572" --segment maintenance 
		WHEN "TG573" --external link maintenance 
		WHEN "TG574" --image line GROUP 
		WHEN "TG575" --print REPORT writer definitions 
		WHEN "TG576" --print REPORT writer definitions 
		WHEN "TG577" --print REPORT writer definitions 
		WHEN "TG578" --print REPORT writer definitions 
		WHEN "TG579" --account GROUP scan 
		WHEN "TG580" --account GROUP maintenance 
		WHEN "TG581" --chart OF accounts 
		WHEN "TG582" --line lookup 
		WHEN "TG583" --column lookup 

		OTHERWISE 
			LET errmsg = "Invalid Window name passed TO winDecoration_T(", trim(pwinname), ")" 
			CALL fgl_winmessage("Internal 4GL Error",errMsg, "error") 
	END CASE 

END FUNCTION 
