GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION windecoration_j(pwinname) 
	DEFINE pwinname STRING 
	DEFINE errmsg STRING 

	CASE pwinname 
	# Prog: U11
	# User Parameters
		WHEN "JA00" --report submenu
		WHEN "J100" --job addition 
			CALL combolist_customer ("cust_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL comboList_salesPerson("sale_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "J101" --job description 
		WHEN "J103" --billing details 
		WHEN "J104" --activity addition 
		WHEN "J105" --activity detail 
		WHEN "J106" --jobtype scan 
		WHEN "J107" --job edit 
		WHEN "J109" --activity description 
		WHEN "J110" --responsibility codes 
		WHEN "J111" --job scan 

		WHEN "J112" -- job units 

		WHEN "J113" -- job management parameters 
			CALL comboList_journalCode("jm_jour_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL comboList_journalCode("cos_jour_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL comboList_journalCode("adj_jour_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_kandooword ("cost_alloc_ind", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,"resgrp.res_type_ind",COMBO_NULL_NOT) 

			CALL comboList_job_report_prompt_indicator("prompt1_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_job_report_prompt_indicator("prompt2_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_job_report_prompt_indicator("prompt3_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_job_report_prompt_indicator("prompt4_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_job_report_prompt_indicator("prompt5_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_job_report_prompt_indicator("prompt6_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_job_report_prompt_indicator("prompt7_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_job_report_prompt_indicator("prompt8_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "J116" --activity edit 
			CALL combolist_customer ("cust_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "J117" --scan job ledger 
			CALL combolist_job_code ("job_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,combo_null_space) 
			CALL combolist_customer ("cust_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "J118" --scan activities 
			CALL combolist_job_code ("job_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,combo_null_space) 
			CALL combolist_customer ("cust_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 


		WHEN "J119" --job variations 
		WHEN "J120" --job management resource 
			CALL combolist_coa_account ("acct_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,combo_null_space) 
			CALL combolist_unit_code ("unit_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,combo_null_space) 
			CALL combolist_tax_code ("tax_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,combo_null_space) 


		WHEN "J121" --resource scan 
		WHEN "J121a" --resource scan 
		WHEN "J122" --resource allocation inquiry 

		WHEN "J123" --job adjustments 
			CALL combolist_year_from_period ("year_num", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_period ("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "J125" --inquiry 
		WHEN "J127c" --job invoicing 
		WHEN "J128" --invoice details 
			CALL combolist_currency ("currency_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period ("year_num", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_usercode ("entry_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_period ("period_num", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL comboList_salesPerson("sale_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_termcode ("term_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_tax_code ("tax_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,combo_null_space) 


		WHEN "J129" --invoice summary 
		WHEN "J130" --cost plus markup 
		WHEN "J131" --job inquiry 
			CALL combolist_customer ("cust_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_salesPerson("sale_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "J133" --scan job ledger 
		WHEN "J134" --resource allocation 
			CALL combolist_year_from_period ("year_num", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_period ("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "J135" --adjust costing AND billing rates 
		WHEN "J136" --job 

		WHEN "J137" --payroll posting information 
			CALL combolist_env_code ("env_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_pay_code ("pay_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL comboList_rate_code("rate_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "J139" --timesheet entry 
			CALL combolist_year_from_period ("year_num", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_period ("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "J140" --timesheet DATE summary (List) 
		WHEN "J141" --timesheet activity summary 
		WHEN "J142" --person scan (list) 
		WHEN "J143" --timesheet scan 
		WHEN "J144" --person entry 
		WHEN "J147" --job management ap distribution 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
		WHEN "J148" --job management line distribution 
			CALL comboList_vendorCode("vend_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
		WHEN "J149" --xxxxxxxxxxxxxxxxxx 
			CALL combolist_year_from_period ("from_year_num", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_period ("from_period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_year_from_period ("to_year_num", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_period ("to_period_num", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 



		WHEN "J151" --resource REPORT selection 
			CALL combolist_tax_code ("tax_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,combo_null_space) 


		WHEN "J167" --job type scan 
		WHEN "J168" --job types 
			CALL comboList_billing_method("bill_way_ind", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL comboList_billing_issues("bill_issue_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 


		WHEN "J186" --departments scan 

		WHEN "J193" --task period maintenance 

		WHEN "J195" --contract user prompts 
			CALL comboList_contract_user_prompt_indicator("cntrhd_prmpt_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_contract_user_prompt_indicator("cntrdt_prmpt1_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_contract_user_prompt_indicator("cntrdt_prmpt2_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "J196" --adjust resource allocation MODE --psu_j 
			CALL comboList_allocation_ind("allocation_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 

		WHEN "J199" --resource groups 

		WHEN "J210" --responsibility codes 

		OTHERWISE 
			LET errmsg = "Invalid Window name passed TO winDecoration_J(", trim(pwinname), ")" 
			CALL fgl_winmessage("Internal 4GL Error",errMsg, "error") 
	END CASE 

END FUNCTION 
