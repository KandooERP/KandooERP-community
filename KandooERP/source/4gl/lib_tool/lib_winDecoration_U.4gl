GLOBALS "../common/glob_GLOBALS.4gl" 

FUNCTION windecoration_u(pwinname) 
	DEFINE pwinname STRING 
	DEFINE errmsg STRING 

	CASE pwinname 
	# Prog: U11
	# User Parameters
		WHEN "U101" --user parameters u12.4gl u2b.4gl 

			#CALL comboList_user("sign_on_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_TAB_LABEL,NULL,COMBO_NULL_NOT) huho: no reason for this combo
			CALL comboList_securityLevel("security_ind", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_passwd_ind   ("passwd_ind",   COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_company      ("cmpy_code",    COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --(cb_field_name,pvariable,psort,psingle,phint) 
			CALL comboList_language     ("language_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_memoPriority ("memo_pri_ind", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_accessMode   ("access_ind",   COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_printcodes   ("print_text",   COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_profile      ("profile_codet",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL combolist_country      ("country_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "U102"--Device configuration 
			CALL comboList_device_type_indicator("device_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "U103" --device configuration 

		WHEN "U104" -- level 1 MENU scan 
		WHEN "U105" -- level 1 MENU setup 
		WHEN "U106" -- level 2 MENU setup 

		WHEN "U107" -- REPORT parameter maintenance 

		WHEN "U108" --error LOG PRINT facility 
		WHEN "U110" --street maintenance 
			CALL comboList_suburb_code_text("suburb_text",COMBO_FIRST_ARG_IS_LABEL,COMBO_SORT_BY_LABEL,COMBO_VALUE_IS_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "U111" --company selection
			CALL comboList_company("cmpy_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --(cb_field_name,pvariable,psort,psingle,phint) 

		WHEN "U112" --suburb search 

		WHEN "U113" --report file management 
			CALL comboList_userCode("entry_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "U114" --report query 
			CALL comboList_userCode("entry_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "U115" --printer OPTIONS 
			CALL comboList_printcodes("dest_print_text",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "U116" --street maintenance 

			DISPLAY getlangstr("lb_state") TO lb_state 

		WHEN "U117" --street/suburb file LOAD 
		WHEN "U120" --suburb maintenance 

		WHEN "U121" --user scan 

		WHEN "U122" # notes - combo with DISPLAY ARRAY --field note_code 
			CALL comboList_notes("note_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_TAB_LABEL,NULL,COMBO_NULL_NOT) 
		WHEN "U123" --note scan 
		WHEN "U124" --sql interface 
		WHEN "U125" --supply location maintenance 
		WHEN "U126" --suburb maintenance 
			DISPLAY getlangstr("lb_state") TO lb_state 
			CALL combolist_waregrp ("waregrp_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL combolist_cartarea ("cart_area_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) --price type --psort,psingle,phint) 
			CALL combolist_territory ("terr_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL comboList_salesPerson("sale_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

		WHEN "U127" --kandoo MENU reporting 

		WHEN "U129" --password 

		WHEN "U130" --password entry 

		WHEN "U131" --languages - DISPLAY ARRAY 

		WHEN "U136" --account segment override --acctwind.4gl 
		WHEN "U137" --reporting period 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_period("period_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --price type --fieldname,pvariable,psort,psingle,phint) 

		WHEN "U138" --user defined reference maintenance 
		WHEN "U139" --prompt WHEN "U142" --report selection 
		WHEN "U143" --database tables 
		WHEN "U144" --table utility 
		WHEN "U146" --notes maintenance 
		WHEN "U147" --note 
		WHEN "U149" --user module security 
			CALL comboList_user("pr_user_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_securityLevel("security_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_UD) 

		WHEN "U150" --user module account mask 
		WHEN "U151" --user company security 
			CALL comboList_location("locn_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_company("curr_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --(cb_field_name,pvariable,psort,psingle,phint) 

		WHEN "U152" --user special authority 
		WHEN "U153" --company 
		WHEN "U154" --location user limits DEFAULTS 

		WHEN "U155" --user sales location 
			CALL comboList_company("cmpy_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --(cb_field_name,pvariable,psort,psingle,phint) 

			CALL comboList_location("locn_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 


		WHEN "U156" --menu original - secufunc.4gl 

		WHEN "U157" --posting progress 
		WHEN "U158" --unstallshield program TO install/update erp help ON client pcs 
		WHEN "U159" -- 
			CALL comboList_stnd_group_code("group_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
			CALL comboList_customer("cust_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 

		WHEN "U162" --action view/menu path - secufunc.4gl 

		WHEN "U163" --kandooword / missing FORM - secufunc.4gl 

		WHEN "U190" --database schema comparison 

		WHEN "U200" --message library maintenance language - u31.4gl 
			CALL comboList_language("language_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 

		WHEN "U201" --message - u31.4gl 
			CALL comboList_modules("source_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_MESSAGEAction("msg_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_formatText("format_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 


		WHEN "U202" --message - u31.4gl 

		WHEN "U203" --message - u32.4gl --message library REPORT 
			CALL comboList_language("language_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_modules("source_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_MESSAGEAction("msg_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_formatText("format_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 

		WHEN "U204" --system locking u1a 
		WHEN "U205" --smenu OPTIONS 
		WHEN "U206" --message AND MENU OPTIONS 

		WHEN "U208" -- street copy 
			CALL comboList_suburb_code_text("suburb_text",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

			DISPLAY getlangstr("lb_state") TO lb_state 
			DISPLAY getlangstr("lb_state") TO lb_state2 

		WHEN "U209" --system tailoring - kandoooption - u1t.4gl 

		WHEN "U210" --quadrant data transfer 

		WHEN "U211" --quadrant maintenance 
		WHEN "U212" --interval type information (List) 
		WHEN "U213" --interval type detail 
		WHEN "U214" --payment terms 
		WHEN "U215" --statistics INTERVAL information 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --fieldname,pvariable,psort,psingle,phint) 

		WHEN "U216" --statistics INTERVAL entry 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_stattype_type_text		("type_code",			COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) --fieldname,pvariable,psort,psingle,phint)

		WHEN "U217" --statistics INTERVAL generation 
			CALL combolist_year_from_period("year_num",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) --fieldname,pvariable,psort,psingle,phint) 
		WHEN "U218" --management information STATISTICS parameters 
			CALL comboList_stattype_type_text		("day_type_code",			COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,"1",COMBO_NULL_NOT) --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_stattype_type_text		("week_type_code",		COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,"2",COMBO_NULL_NOT) --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_stattype_type_text		("mth_type_code",			COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,"4",COMBO_NULL_NOT) --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_stattype_type_text		("qtr_type_code",			COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,"7",COMBO_NULL_NOT) --fieldname,pvariable,psort,psingle,phint) 
			CALL comboList_stattype_type_text		("year_type_code",		COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,"8",COMBO_NULL_NOT) --fieldname,pvariable,psort,psingle,phint) 


		WHEN "U219" --interval type codes 

		WHEN "U220" --kandoooption detail (System configuration/taylor) 
			CALL comboList_kandoo_module_groups("module_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,"8",COMBO_NULL_NOT) --fieldname,pvariable,psort,psingle,phint) 



		WHEN "U222" --copy REPORT TO file OR diskette 

		WHEN "U500" --printer definitions 
			CALL comboList_printcodes("dest",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_VALUE_DASH_LABEL,NULL,COMBO_NULL_NOT) 
		WHEN "U501" --table tool 
		WHEN "U503" --table utility 
		WHEN "U504" --table utility 
		WHEN "U505" --report OPTIONS 
		WHEN "U507" --audit REPORT 
		WHEN "U509" --amendment LOG maintenance 
		WHEN "U510" --report OPTIONS 
			CALL comboList_executionMode("exec_ind",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 

		WHEN "U511" --aging DEFAULTS 

		WHEN "U521" --give me a title 
		WHEN "U522" --give me a title 
		WHEN "U523" --used BY 
		WHEN "U524" --supplied & supported by: 
		WHEN "U525" --menu scan 
		WHEN "U526" --system calendar - secufunc.4gl 
		WHEN "U527" --data setup --psk 
		WHEN "U528" --suburb distances LOAD 
		WHEN "U531" --notes 
		WHEN "U532" -- transfer notes 
			CALL comboList_notes("note_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 
			CALL comboList_customer("cust_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL_BRACE_VALUE,NULL,COMBO_NULL_NOT) 

		WHEN "U534" --memo facility 

		WHEN "U535" --send memo 
			CALL comboList_user_cmpy("user_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
			CALL comboList_memoPriority("priority_ind", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
		WHEN "U536" --user lookup 
		WHEN "U537" --view memo 
		WHEN "U538" --reply memo 

		WHEN "U801_dbschema_status" --ut1_schema_fix_mngr 
		WHEN "U802_table_documentation" --ut2 
		WHEN "U803_state_tbl_mngr" --ut3 
		WHEN "U805_translate_widgets" --ut4 
		WHEN "U806_translate_widgets_2" --ut4 
		WHEN "U807_strings_translation" --ut6
			CALL combolist_language ("language_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)
			CALL combolist_country ("country_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)

		WHEN "U960-rpt-language-dialog"  #Report Dialog to change language
			CALL comboList_language     ("language_code",COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)
			CALL combolist_country      ("country_code", COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_LABEL,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)

		WHEN "U998" --sql ERROR REPORT 
		WHEN "U999" -- multi purpose MESSAGE WINDOW (FOR legacy PROMPT etc.. migration) - temp solution 


		WHEN "f_coa" -- data management FOR TABLE coa 
		WHEN "f_coa_g" -- data management FOR TABLE coa (GUI ?) 
		WHEN "UmenuWindow" -- MENU 
		WHEN "vendorLookup_filter" -- vendor lookup 

		OTHERWISE 
			LET errmsg = "Invalid Window name passed TO winDecoration_U(", trim(pwinname), ")" 
			CALL fgl_winmessage("Internal 4GL Error",errMsg, "error") 
	END CASE 

END FUNCTION 
