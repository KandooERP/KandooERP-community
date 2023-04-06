GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION windecoration_f(pwinname) 
	DEFINE pwinname STRING 
	DEFINE errmsg STRING 

	CASE pwinname 
	# Prog: U11
	# User Parameters

		WHEN "F100" --fixed asset financial batch 

			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "F101" --asset transaction 

		WHEN "F103" --asset transaction 
		WHEN "F107" --assets 
		WHEN "F110" --books available 
		WHEN "F112" --categories available 
		WHEN "F113" --responsibilities available 
		WHEN "F114" --books available 
		WHEN "F115" --book parameter entry 
		WHEN "F116" --location details 
		WHEN "F117" --asset locations 
		WHEN "F118" --authority codes 
		WHEN "F119" --authority codes 
		WHEN "F120" --category details 
		WHEN "F121" --asset categories 
		WHEN "F122" --insurance details 
		WHEN "F123" --insurance details 
		WHEN "F124" --leasing details 
		WHEN "F125" --lease details 
		WHEN "F126" --responsibility entries 
		WHEN "F127" --responsibility codes 
		WHEN "F128" --asset browse 
		WHEN "F129" --asset master details 
		WHEN "F130" --vendor 
		WHEN "F131" --fixed asset parameters 
			CALL comboList_journalCode("asset_jnl_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
		WHEN "F133" --asset master details 
		WHEN "F134" --asset information 
		WHEN "F137" --asset master details 
		WHEN "F139" --asset book 
		WHEN "F140" --book enquiry 
		WHEN "F141" --asset transaction enquiry 
		WHEN "F142" --asset transaction list 
		WHEN "F143" --transaction details 
		WHEN "F144" --general ledger integration 
		WHEN "F145" --general ledger integration BY category 
		WHEN "F151" --batch scan 
		WHEN "F152" --batch line details 
		WHEN "F153" --batch line details 
		WHEN "F154" --new asset id 
		WHEN "F155" --fa gl posting 
		WHEN "F157" --batch posting 
		WHEN "F159" --transaction detail 
		WHEN "F163" --category REPORT 
		WHEN "F165" --authority REPORT 
		WHEN "F168" --depreciation code entry / maintenance 
		WHEN "F169" --valid depreciation methods 
		WHEN "F170" --depreciation BY book BY asset entry 
		WHEN "F176" --depreciation calculation 
		WHEN "F178" --stocktake LOAD module 
		WHEN "F180" --asset master details 
		WHEN "F181" --asset register 
		WHEN "F183" --year AND periods 
		WHEN "F184" --depreciation code 
		WHEN "F185" --leasing details 
		WHEN "F186" --insurance details 
		WHEN "F187" --fixed asset financial batch 

		OTHERWISE 
			LET errmsg = "Invalid Window name passed TO winDecoration_E(", trim(pwinname), ")" 
			CALL fgl_winmessage("Internal 4GL Error",errMsg, "error") 
	END CASE 

END FUNCTION 
