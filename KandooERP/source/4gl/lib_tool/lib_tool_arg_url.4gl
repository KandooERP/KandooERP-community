###########################################################################
# FUNCTION processUrlArguments()
#
#
###########################################################################
FUNCTION processurlarguments() 
	DEFINE i SMALLINT 
	DEFINE s SMALLINT 
	DEFINE p SMALLINT 
	DEFINE l_argsegment STRING #full argument BEFORE processing i.e. db=kandoodb 
	DEFINE l_argvar STRING #variable NAME (left side) i.e. db 
	DEFINE l_argval STRING #variable value (right side) i.e. kandoodb 
	DEFINE l_workingside CHAR #l=left side = variable NAME r=right side = variable value 
	DEFINE l_tempstr STRING 
	LET p = 1 

	#this needs cleaning... when we know more about VDOM
	IF num_args() = 0 THEN --if there are no arguments, only SET none vdom as the default - otherwise, don't do anything 
		CALL set_url_vdom(0) 
	ELSE 

		IF get_debug() THEN #with debug enabled, you will see all arguments passed TO the application 
			FOR i = 1 TO num_args() 
				DISPLAY "arg_val(",trim(i),") = ", trim(arg_val(i)) 
			END FOR 
		END IF 

		FOR i = 1 TO num_args() --for each argument 
			LET l_argsegment = "" 
			LET l_argvar = "" 
			LET l_argval = "" 

			LET l_argsegment = arg_val(i) 
			LET l_workingside = "L" --we START processing the left side / argument NAME 

			FOR s = 1 TO l_argsegment.getlength() 
				IF l_workingside = "L" THEN 
					IF l_argsegment[s] <> "=" THEN 
						LET l_argvar = l_argvar.append(l_argsegment[s]) 
					ELSE 
						LET l_workingside = "R" --we START processing the right side / argument value 
					END IF 
				ELSE --l_workingside = "R" 
					--LET l_argval = l_argval.append(l_argsegment[s]) 
					--LET p = p+1
					-- alch 23.03.2020 - optimize loop a bit
					LET l_argval = l_argval.append(l_argsegment[s, l_argsegment.getlength()]) 
					EXIT FOR 
				END IF 
			END FOR 



			CASE upshift(l_argVar) 

				#WHEN "PROG" #We are going to drop this.. leads to too much confusion on what kind of program instruction it is (child, parent, module or program) broke it down to 4 different arguments 
				#	CALL set_url_prog(l_argval) #Program/or it's wrapper function to call - used as an alternative menu bypass

				WHEN "PROG_PARENT" #Progam ID which run another program char(3)
					CALL set_url_prog_parent(l_argval) 

				WHEN "PROG_CHILD" #Progam ID which run another program char(5)
					CALL set_url_prog_child(l_argval) 

				WHEN "MODULE_PARENT" #ERP SUB MODULE ID which run another program char(3)
					CALL set_url_module_parent(l_argval) 

				WHEN "MODULE_CHILD" #ERP SUB MODULE ID which run another program char(5)
					CALL set_url_module_child(l_argval) 

				WHEN "MAX_CHILD" 
					CALL set_settings_maxchildlaunch(l_argval)
					
				WHEN "CHILD_RUN_ONCE_ONLY" 
					CALL set_url_child_run_once_only(l_argval)
					
				WHEN "MODE" 
					CALL set_url_mode(l_argval) --used TO be setargmode(l_argval)

				WHEN "ACTION" 
					CALL set_url_action(l_argval) --used TO be setargmode(l_argval)
 
				WHEN "DB" --argument db & kandoodb are both valid 
					CALL set_db(l_argval) 

				WHEN "KANDOODB" --argument db & kandoodb are both valid 
					CALL set_db(l_argval) 

				#Authentication
				WHEN "SIGN_ON_CODE" 
					CALL set_ku_sign_on_code(l_argval) 

				WHEN "PASSWORD_TEXT" 
					CALL set_ku_password_text(l_argval) 

				WHEN "LOGIN_NAME" 
					CALL set_ku_login_name(l_argval) 

				WHEN "EMAIL" 
					CALL set_ku_email(l_argval) 


				#Operational Parameters
				WHEN "MAX_LIST_ARRAY_SIZE" 
					CALL set_settings_maxListArraySize(l_argval)

				WHEN "MAX_LIST_ARRAY_SIZE_SWITCH" 
					CALL set_settings_maxListArraySizeSwitch(l_argval)

				WHEN "KANDOO_LOG_FILE" 
					CALL set_settings_logFile(l_argval)
					 
				WHEN "KANDOO_LOG_PATH" 
					CALL set_settings_logFile(l_argval)

				#REPORT parameters					
				WHEN "EXEC_IND" #Report 1=menu 2=background 3=construct only 4 = pass sql query
					CALL set_url_exec_ind(l_argval) 

				WHEN "REPORT_CODE" #rmsreps.report_code INT-PK
					CALL set_url_report_code(l_argval) 

				WHEN "REPORT_FILE_TEXT" #silly name for report file 
					CALL set_url_report_file_text(l_argval) 

				WHEN "REPORT_ID" #rpthead.rpt_id nchar(10) PK 
					CALL set_url_report_id(l_argval) 

				WHEN "REPORT_DATE" 
					CALL set_url_report_date(l_argval) 

				WHEN "PRINTNOW" #rmsreps Y/N local print
					CALL set_url_printnow(l_argval)

				WHEN "PRINTCONFIG" #kandoouser.print_text / rmsreps.dest_print_text
					CALL set_url_printconfig(l_argval)

				WHEN "KANDOO_DATA_PATH" #Path for Read/Write root folder, usually "data" (..../progs/kandooerp/data)
					CALL set_settings_dataPath(l_argval) 		

				WHEN "KANDOO_REPORT_PATH" 
					CALL set_settings_reportPath(l_argval) 		

				#ERP Budiness Parameters					 
				WHEN "VENDOR_CODE" 
					CALL set_url_vendor_code(l_argval) 

				WHEN "COMPANY_CODE" 
					CALL set_url_company_code(l_argval) 

				WHEN "AUTO_COMPANY_CODE" 
					CALL set_url_auto_company_code(l_argval) 

				WHEN "JMJ_COMPANY_CODE" 
					CALL set_url_jmj_company_code(l_argval) 

				WHEN "SALE_CODE" 
					CALL set_url_sale_code(l_argval)
					
				WHEN "SALES_MGR_CODE" 
					CALL set_url_salesmgr_code(l_argval)
					 
				WHEN "AREA_CODE" --area_code
	 				CALL set_url_area_code(l_argval)
	 				
				WHEN "SALES_TERR_CODE" 
					CALL set_url_terr_code(l_argval)
					
				WHEN "ACCT_CODE" 
					CALL set_url_acct_code(l_argval) 

				WHEN "GROUP_CODE" 
					CALL set_url_group_code(l_argval) 

				WHEN "CUSTOMER_CODE" #"CUST_CODE"  duplicate
					CALL set_url_cust_code(l_argval) 

				WHEN "CUST_CODE" #"CUSTOMER_CODE" duplicate
					CALL set_url_cust_code(l_argval) 

				WHEN "SHIP_CODE" 
					CALL set_url_ship_code(l_argval) 

				WHEN "CASHRECEIPT_NUMBER" 
					CALL set_url_cashreceipt_number(l_argval) 

				WHEN "CREDIT_NUMBER" 
					CALL set_url_credit_number(l_argval) 

				WHEN "BANKDEPARTMENT_NUMBER" 
					CALL set_url_bankdepartment_number(l_argval) 

				WHEN "BATCH_NUMBER" 
					CALL set_url_batch_number(l_argval) 

				WHEN "LAST_BATCH_NUMBER" 
					CALL set_url_last_batch_number(l_argval) 

				WHEN "SENT_BATCH_NUMBER" 
					CALL set_url_sent_batch_number(l_argval) 

				WHEN "INVOICE_TEXT" 
					CALL set_url_invoice_text(l_argval) 

				WHEN "INVOICE_NUMBER" #note, we have got both, invoice text and number 
					CALL set_url_invoice_number(l_argval) 
					
				WHEN "CREDIT_TEXT" 
					CALL set_url_credit_text(l_argval) 

				WHEN "TRAN_TYPE_IND" 
					CALL set_url_tran_type_ind(l_argval) 

				WHEN "REF_TEXT" 
					CALL set_url_ref_text(l_argval) 

				WHEN "REF_NUM" 
					CALL set_url_ref_num(l_argval) 

				WHEN "ACCOUNT_LEDGER" 
					CALL set_url_account_ledger(l_argval) 

				WHEN "VOUCHER_OPTION" 
					CALL set_url_voucher_option(l_argval) 

				WHEN "PRODUCT_PART_CODE" 
					CALL set_url_product_part_code(l_argval)

				WHEN "PART_CODE" 
					CALL set_url_product_part_code(l_argval)

				WHEN "WAREHOUSE_CODE" 
					CALL set_url_warehouse_code(l_argval) 

				WHEN "QUERY_TEXT" 
					CALL set_url_query_text(l_argval) 

				WHEN "SEL_TEXT" #Synonym for "QUERY_WHERE_TEXT" - special for REPORTS
					CALL set_url_sel_text(l_argval) 
					
				WHEN "QUERY_WHERE_TEXT" 
					CALL set_url_query_where_text(l_argval) 

				WHEN "POST_RUN_NUM" 
					CALL set_url_post_run_num(l_argval) 

				WHEN "AUTOPOST" 
					CALL set_url_autopost(l_argval) 

				WHEN "TEMPPER" 
					CALL set_url_tempper(l_argval) 

				WHEN "FISCAL_YEAR_NUM" 
					CALL set_url_fiscal_year_num(l_argval) 

				WHEN "FISCAL_PERIOD_NUM" 
					CALL set_url_fiscal_period_num(l_argval) 

				WHEN "FISCAL_MONTH" 
					CALL set_url_fiscal_month_num(l_argval) 

				WHEN "FISCAL_DATE" 
					CALL set_url_fiscal_date(l_argval) 

				WHEN "SWITCH" 
					CALL set_url_switch(l_argval) 

				WHEN "CYCLE_NUM" 
					CALL set_url_cycle_num(l_argval) 

				WHEN "FILE_PATH" 
					CALL set_url_file_path(l_argval) 

				WHEN "FILE_NAME" 
					CALL set_url_file_name(l_argval) 

				WHEN "LOAD_FILE" 
					CALL set_url_load_file(l_argval) 
					
				WHEN "FILE_LIST" --comma seperated argument 
					CALL set_url_file_list(l_argval) 

				WHEN "ARGINT1" 
					CALL set_url_int1(l_argval) 

				WHEN "ARGINT2" 
					CALL set_url_int2(l_argval) 

				WHEN "ARGSTR1" 
					CALL set_url_str1(l_argval) 

				WHEN "ARGSTR2" 
					CALL set_url_str2(l_argval) 

				WHEN "ID_INT" 
					CALL set_url_id_int(l_argval) 

				WHEN "ID_CHAR" 
					CALL set_url_id_char(l_argval) 

				WHEN "CHAR" 
					CALL set_url_char(l_argval) 

				WHEN "ZERO_SUPPRESS" 
					CALL set_url_zero_suppress(l_argval) 

				WHEN "DEBUG" 
					CALL set_debug(l_argval) 

				WHEN "ORDER" 
					CALL set_url_order(l_argval) --used TO be setargmode(l_argval) 

				WHEN "VERBOSE" 
					CALL set_url_verbose(l_argval) 


				WHEN "PROG_PARENT" 
					CALL set_url_prog_parent(l_argval) 

				WHEN "TB_PROJECT_NAME" 
					CALL set_url_tb_project_name(l_argval) 

				WHEN "TB_MODULE_NAME" 
					CALL set_url_tb_module_name(l_argval) 

				WHEN "TB_MENU_NAME" 
					CALL set_url_tb_menu_name(l_argval) 

				WHEN "TB_USER_NAME" 
					CALL set_url_tb_user_name(l_argval) 

				WHEN "DEMO" --demo MENU IS a trim down version OF the MENU (just a few example groups are shown) 
					CALL set_url_demo(l_argval) 

				WHEN "VDOM" 
					CALL set_url_vdom(l_argval) 

				WHEN "HELP_URL" 
					CALL set_help_url(l_argval) 


					#WHEN "AUTHENTICATE_DIALOG"
					#	CALL set_authenticate_dialog(l_argVal)


					#CALL fgl_winmessAGE("!!!!!VDOM",ml_vdom,"info")
				OTHERWISE 
					LET l_tempstr = "Program: ", trim(arg_val(0)), "\n", " l_argVar=",l_argVar clipped, "\n", "l_argVal=", l_argval clipped 
					CALL fgl_winmessage("Invalid argument in URL", "Support information for (Kandoo):\n", l_tempStr,"info") 

			END CASE 



		END FOR 

	END IF 

	IF get_debug() THEN 
		DISPLAY "########### processUrlArguments() ################" 
		DISPLAY "get_ku_sign_on_code() =", get_ku_sign_on_code() 
		DISPLAY "get_ku_password_text() =", get_ku_password_text() 
		DISPLAY "get_ku_login_name() =", get_ku_login_name() 
		DISPLAY "get_ku_email() =", get_ku_email() 

		DISPLAY "get_url_mode() =", get_url_mode() 
		DISPLAY "get_url_id_int() =", get_url_id_int() 
		DISPLAY "get_debug() =", get_debug() 
		DISPLAY "get_url_vdom() =", get_url_vdom() 
		DISPLAY "get_url_demo() =", get_url_demo() 


		DISPLAY "get_db() =", get_db() 
		DISPLAY "get_url_int1() =", get_url_int1() 
		DISPLAY "get_url_int2() =", get_url_int2() 
		DISPLAY "get_url_str1() =", get_url_str1() 
		DISPLAY "get_url_str2() =", get_url_str2() 


		DISPLAY "TB_PROJECT_NAME =", get_url_tb_project_name() 
		DISPLAY "TB_MODULE_NAME =", get_url_tb_module_name() 
		DISPLAY "TB_MENU_NAME =", get_url_tb_menu_name() 
		DISPLAY "TB_USER_NAME =", get_url_tb_user_name() 

		DISPLAY "--------------------------------------------------------------" 
	END IF 

END FUNCTION 


