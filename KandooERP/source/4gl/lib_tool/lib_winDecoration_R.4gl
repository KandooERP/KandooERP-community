GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION windecoration_r(pwinname) 
	DEFINE pwinname STRING 
	DEFINE errmsg STRING 

	# DEFINE cb_field_name      VARCHAR(25)   --form field
	#	DEFINE pVariable SMALLINT	-- 0=first field IS variable 1= 2nd field IS variable
	#	DEFINE pSort SMALLINT  --0=Sort on first 1=Sort on 2nd
	#	DEFINE pSingle SMALLINT	--0=variable AND label 1= variable = label
	#	DEFINE pHint SMALLINT  --1 = show both VALUES in label


	CASE pwinname 
	# Prog: U11
	# User Parameters
		WHEN "R100" -- purchase ORDER HEADER entry 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

			CALL comboList_termCode("term_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_tax_code("tax_code",  COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

			CALL combolist_year_from_period("year_num",      COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",  COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)

		WHEN "R103" --purchase ORDER LINES (list) 
			#nothing TO do

		WHEN "R104" --purchasing parameters 
			CALL comboList_warehouse("usual_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

			CALL comboList_journalCode("receipt_jour_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_journalCode("commit_jour_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_journalCode("purch_jour_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_coa_account("commit_acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_coa_account("goodsin_acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_coa_account("accrued_acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_coa_account("clear_acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 


		WHEN "R105" --p.o. line history (list) 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "R106" -- delivery details 
			#nothing TO do

		WHEN "R107" -- purchase ORDER information 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_currency("curr_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "R108" --scan purchase orders (List) 
			CALL comboList_purchstatus("purchhead.status_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --form field, pvariable,psort,psingle,phint) 

			DISPLAY getlangstr("lb_state") TO lb_state 

		WHEN "R109" -- confirmation 
			#nothing TO do

		WHEN "R111" -- purchase ORDER scan (list) 
			#nothing TO do

		WHEN "R112" -- purchase ORDER receipt 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_termCode("term_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_tax_code("tax_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_currency("curr_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "R113" -- purchase line receipt (list) 
			#nothing TO do

		WHEN "R114" -- line information 
			#nothing TO do
			CALL comboList_uomCode("uom_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "R115" -- commitments 
			CALL comboList_coa_account("acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "R116" -- purchase ORDER status 
			#nothing TO do

		WHEN "R117" -- commitments 
			#nothing TO do

		WHEN "R119" -- goods receipt scan 
			#nothing TO do

		WHEN "R120" -- goods receipt BY job (list) 
			#nothing TO do

		WHEN "R121" -- commitments (list) 
			#nothing TO do

		WHEN "R124" -- purchase ORDER details 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_currency("curr_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_coa_account("acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "R124a" -- purchase ORDER details 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_currency("curr_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_coa_account("acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "R130" -- account ledger 
			CALL comboList_company("cmpy_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_coa_account("acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 

		WHEN "R131" -- goods receipt scan (List) 
			CALL comboList_productCode("ref_text",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "R137" -- goods receipt REPORT 
			CALL comboList_coa_account("acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_productCode("ref_text",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "R139" -- purchase ORDER details 
			CALL comboList_currency("curr_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 

		WHEN "R140" -- p.o. AUDIT detail 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_transationCode("tran_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_journalNum("jour_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "R143" -- general purchase ORDER LINES 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_coa_account("acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_currency("curr_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "R144" -- purchase ORDER payment 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_currency("curr_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "R146" -- purchase ORDER line payment 
			--Needs lookup FOR field			vouch_code
			CALL comboList_currency("currency_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "R147" -- complete purchase orders (list) 
			#nothing TO do

		WHEN "R150" -- pu posting (list) 
			#nothing TO do

		WHEN "R151" -- goods receipt 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL comboList_journalNum("jour_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 

		WHEN "R152" -- purchase ORDER inquiry 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_termCode("term_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_tax_code("tax_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("usual_ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

			CALL comboList_currency("curr_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 


		WHEN "R155" -- purchase ORDER PRINT 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

			CALL comboList_currency("curr_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_printcodes("print_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 


		WHEN "R156" -- purchase ORDER details 
			#NOT sure if it needs work

		WHEN "R157" -- eta DATE entry 
			#nothing TO do, just a date field

		WHEN "R600" --purchase ORDER FORMAT types (list) 
			#nothing TO do

		WHEN "R601" --purchase ORDER FORMAT details 
			CALL comboList_purchtype("purchtype_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_formatText("format_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "R602" --purchase ORDER types (list) 
			#nothing TO do

		WHEN "R603" --purchase ORDER maintenance (list) 
			#nothing TO do

		WHEN "R604" --purchase ORDER HEADER edit 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_warehouse("ware_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL comboList_termCode("term_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_tax_code("tax_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "R605" -- purchase ORDER information 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

			CALL comboList_currency("curr_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_coa_account("acct_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "R606" -- REPORT OPTIONS 
			#nothing TO do

		WHEN "R607" -- purchase ORDER line inquiry (List) 
			#nothing TO do

		WHEN "R608" -- product descriptions (List) 
			#nothing TO do

		OTHERWISE 
			LET errmsg = "Invalid Window name passed TO winDecoration_R(", trim(pwinname), ")" 
			CALL fgl_winmessage("Internal 4GL Error",errMsg, "error") 
	END CASE 

END FUNCTION 
