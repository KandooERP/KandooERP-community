###########################################################################
# This program IS free software; you can redistribute it AND/OR modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, OR (at your
# option) any later version.
#
# This program IS distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY OR FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License FOR more details.
#
# You should have received a copy of the GNU General Public License along
# with this program; IF NOT, write TO the Free Software Foundation, Inc.,
# 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
#
###########################################################################
############################################################
# GLOBAL Scope Variables
############################################################
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AS5_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
DEFINE modu_rec_custpallet RECORD LIKE custpallet.* 
DEFINE modu_rec_aging RECORD 
	age_date DATE, 
	hold_code LIKE holdreas.hold_code, 
	inactive_hold_code LIKE holdreas.hold_code, 
	inactive_days SMALLINT, 
	over90_amt LIKE customer.bal_amt, 
	over60_amt LIKE customer.bal_amt, 
	over30_amt LIKE customer.bal_amt, 
	over1_amt LIKE customer.bal_amt 
	END RECORD 
DEFINE modu_err_cnt SMALLINT 


#########################################################################
# FUNCTION AS5_main()
#
# Allows the user TO UPDATE account aging balances in the Customer
#########################################################################
FUNCTION AS5_main() 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	CALL setModuleId("AS5") 


	LET modu_rec_aging.age_date = glob_rec_arparms.cust_age_date 
	LET modu_rec_aging.over1_amt = NULL 
	LET modu_rec_aging.over30_amt = NULL 
	LET modu_rec_aging.over30_amt = NULL 
	LET modu_rec_aging.over90_amt = NULL 
	LET modu_rec_aging.hold_code = NULL 
	LET modu_rec_aging.inactive_hold_code = NULL 
	LET modu_rec_aging.inactive_days = NULL 
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode  
			OPEN WINDOW A202 with FORM "A202" 
			CALL windecoration_a("A202") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title

			DISPLAY BY NAME modu_rec_aging.*
			DISPLAY BY NAME glob_rec_arparms.cust_age_date 


			MENU " Account Aging" 
				BEFORE MENU 
					CALL publish_toolbar("kandoo","AS5","menu-account-aging") 
					CALL AS5_rpt_process(AS5_rpt_query())
					CALL rpt_rmsreps_reset(NULL)
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "REPORT" #COMMAND "Run" " SELECT Criteria AND PRINT REPORT" 
					CALL AS5_rpt_process(AS5_rpt_query())
					CALL rpt_rmsreps_reset(NULL)

				ON ACTION "Print Manager" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW A202
			 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL AS5_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A202 with FORM "A202" 
			CALL windecoration_a("A202") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(AS5_rpt_query()) #save where clause in env 
			CLOSE WINDOW A202 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL AS5_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 


#########################################################################
# FUNCTION AS5_rpt_query()
#
#
#########################################################################
FUNCTION AS5_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_temp_text CHAR(20) 
	DEFINE l_rec_holdreas RECORD LIKE holdreas.* 


	MESSAGE kandoomsg2("A",1028,"") #1028 Enter criteria - ESC TO continue
	INPUT BY NAME 
		modu_rec_aging.age_date, 
		modu_rec_aging.hold_code, 
		modu_rec_aging.inactive_hold_code, 
		modu_rec_aging.inactive_days, 
		modu_rec_aging.over90_amt, 
		modu_rec_aging.over60_amt, 
		modu_rec_aging.over30_amt, 
		modu_rec_aging.over1_amt WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AS5","inp-aging") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(hold_code) 
				LET l_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
				IF l_temp_text IS NOT NULL THEN 
					SELECT * INTO l_rec_holdreas.* FROM holdreas 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND hold_code = l_temp_text 
					
						LET modu_rec_aging.hold_code = l_temp_text 
						NEXT FIELD hold_code 
				END IF
		ON ACTION "LOOKUP" infield(inactive_hold_code)
				LET l_temp_text = show_hold(glob_rec_kandoouser.cmpy_code,"") 
				IF l_temp_text IS NOT NULL THEN 
					SELECT * INTO l_rec_holdreas.* FROM holdreas 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND hold_code = l_temp_text 
						LET modu_rec_aging.inactive_hold_code = l_temp_text 
						NEXT FIELD inactive_hold_code 
				END IF 
 
			
		AFTER FIELD age_date 
			IF modu_rec_aging.age_date IS NULL THEN 
				LET modu_rec_aging.age_date = today 
				NEXT FIELD age_date 
			END IF 
			IF modu_rec_aging.age_date < (glob_rec_arparms.cust_age_date - 60) THEN 
				ERROR kandoomsg2("A",6001,"") 
				#6001 WARNING: Date IS 60 days less than today.
			END IF 
			IF modu_rec_aging.age_date > (glob_rec_arparms.cust_age_date + 60) THEN 
				ERROR kandoomsg2("A",6000,"") 
				#6001 WARNING: Date IS 60 days FROM today.
			END IF 
			
		AFTER FIELD hold_code 
			IF modu_rec_aging.hold_code IS NOT NULL THEN 
				SELECT * INTO l_rec_holdreas.* 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = modu_rec_aging.hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9040,"") 
					#9040 hold code NOT found, try window
					NEXT FIELD hold_code 
				ELSE 
					CLEAR inactive_hold_code, inactive_days 
					LET modu_rec_aging.inactive_hold_code = NULL 
					LET modu_rec_aging.inactive_days = NULL 
					NEXT FIELD over90_amt 
				END IF 
			END IF 
			
		AFTER FIELD inactive_hold_code 
			IF modu_rec_aging.inactive_hold_code IS NOT NULL THEN 
				SELECT * INTO l_rec_holdreas.* 
				FROM holdreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = modu_rec_aging.inactive_hold_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9040,"") 
					#9040 hold code NOT found, try window
					NEXT FIELD inactive_hold_code 
				END IF 
			ELSE 
				CLEAR inactive_days 
				EXIT INPUT 
			END IF 
			
		BEFORE FIELD inactive_days 
			IF modu_rec_aging.inactive_hold_code IS NULL THEN 
				IF fgl_lastkey() = fgl_keyval("down") OR 
				fgl_lastkey() = fgl_keyval("right") OR 
				fgl_lastkey() = fgl_keyval("tab") OR 
				fgl_lastkey() = fgl_keyval("RETURN") THEN 
					NEXT FIELD over90_amt 
				END IF 
			END IF 
			
		AFTER FIELD inactive_days 
			IF modu_rec_aging.inactive_days IS NULL THEN 
				IF modu_rec_aging.inactive_hold_code IS NOT NULL THEN 
					ERROR kandoomsg2("A",9310,"") 
					#9310 Please indicate how many days inactive
					NEXT FIELD inactive_days 
				END IF 
			ELSE 
				IF modu_rec_aging.inactive_days <= 0 THEN 
					ERROR kandoomsg2("A",9311,"") 
					#9311 The number of days inactive must be greater than 0
					NEXT FIELD inactive_days 
				END IF 
			END IF 
			IF modu_rec_aging.hold_code IS NULL THEN 
				EXIT INPUT 
			END IF 


		AFTER FIELD over90_amt 
			IF modu_rec_aging.over90_amt < 0 THEN 
				ERROR kandoomsg2("A",9149,"") 
				#9149 Negative balance amounts are NOT permitted
				LET modu_rec_aging.over90_amt = NULL 
				NEXT FIELD over90_amt 
			ELSE 
				IF NOT get_is_screen_navigation_forward() THEN 
					IF modu_rec_aging.hold_code IS NOT NULL THEN 
						NEXT FIELD hold_code 
					END IF 
				END IF 
			END IF 
			
		AFTER FIELD over60_amt 
			IF modu_rec_aging.over60_amt < 0 THEN 
				ERROR kandoomsg2("A",9149,"") 
				#9149 Negative balance amounts are NOT permitted
				LET modu_rec_aging.over60_amt = NULL 
				NEXT FIELD over60_amt 
			END IF 

		AFTER FIELD over30_amt 
			IF modu_rec_aging.over30_amt < 0 THEN 
				ERROR kandoomsg2("A",9149,"") 
				#9149 Negative balance amounts are NOT permitted
				LET modu_rec_aging.over30_amt = NULL 
				NEXT FIELD over30_amt 
			END IF 

		AFTER FIELD over1_amt 
			IF modu_rec_aging.over1_amt < 0 THEN 
				ERROR kandoomsg2("A",9149,"") 
				#9149 Negative balance amounts are NOT permitted
				LET modu_rec_aging.over1_amt = NULL 
				NEXT FIELD over1_amt 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET modu_rec_aging.age_date = today 
		LET modu_rec_aging.hold_code = NULL 
		LET modu_rec_aging.inactive_hold_code = NULL 
		LET modu_rec_aging.inactive_days = NULL 
		LET modu_rec_aging.over1_amt = NULL 
		LET modu_rec_aging.over30_amt = NULL 
		LET modu_rec_aging.over60_amt = NULL 
		LET modu_rec_aging.over90_amt = NULL 
		DISPLAY BY NAME modu_rec_aging.* 

		RETURN NULL
	END IF 
	
	MESSAGE kandoomsg2("U",1001,"") 
	#1001 Enter Selection Criteria - ESC TO continue
	CONSTRUCT BY NAME l_where_text ON customer.cust_code, 
	customer.name_text, 
	customer.type_code, 
	customer.term_code 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AS5","construct-customer") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	ELSE
	
		IF modu_rec_aging.over1_amt IS NOT NULL THEN 
			LET glob_rec_rpt_selector.ref1_code = modu_rec_aging.over1_amt USING "&&&&&&&.&&" 
		ELSE 
			LET glob_rec_rpt_selector.ref1_code = NULL 
		END IF 
		IF modu_rec_aging.over30_amt IS NOT NULL THEN 
			LET glob_rec_rpt_selector.ref2_code = modu_rec_aging.over30_amt USING "&&&&&&&.&&" 
		ELSE 
			LET glob_rec_rpt_selector.ref2_code = NULL 
		END IF 
		IF modu_rec_aging.over60_amt IS NOT NULL THEN 
			LET glob_rec_rpt_selector.ref3_code = modu_rec_aging.over60_amt USING "&&&&&&&.&&" 
		ELSE 
			LET glob_rec_rpt_selector.ref3_code = NULL 
		END IF 
		IF modu_rec_aging.over90_amt IS NOT NULL THEN 
			LET glob_rec_rpt_selector.ref4_code = modu_rec_aging.over90_amt USING "&&&&&&&.&&" 
		ELSE 
			LET glob_rec_rpt_selector.ref4_code = NULL 
		END IF 
		LET glob_rec_rpt_selector.ref1_date = modu_rec_aging.age_date 
		#legacy shixxx
		#LET glob_rec_rmsreps.sel_text[1995,2000] = modu_rec_aging.hold_code 
		#LET glob_rec_rmsreps.sel_text[1990,1994] = modu_rec_aging.inactive_hold_code 
		#LET glob_rec_rmsreps.sel_text[1981,1989] = modu_rec_aging.inactive_days USING "&&&&&&&&&" 
		#new appraoch
		LET glob_rec_rpt_selector.sel_option1 = modu_rec_aging.hold_code 
		LET glob_rec_rpt_selector.sel_option2 = modu_rec_aging.inactive_hold_code 
		LET glob_rec_rpt_selector.sel_option3 = modu_rec_aging.inactive_days USING "&&&&&&&&&" 

		RETURN l_where_text
	END IF 
END FUNCTION 


#########################################################################
# FUNCTION AS5_rpt_process()
#
#
#########################################################################
FUNCTION AS5_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AS5_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AS5_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS5_rpt_list")].sel_text
	#------------------------------------------------------------


	LET modu_rec_aging.over1_amt = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS5_rpt_list")].ref1_code 
	LET modu_rec_aging.over30_amt = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS5_rpt_list")].ref2_code 
	LET modu_rec_aging.over60_amt = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS5_rpt_list")].ref3_code 
	LET modu_rec_aging.over90_amt = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS5_rpt_list")].ref4_code 
	LET modu_rec_aging.age_date = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS5_rpt_list")].ref1_date 
	
	#OLD - Replaced
	#LET modu_rec_aging.hold_code = glob_rec_rmsreps.sel_text[1995,2000] 
	#LET modu_rec_aging.inactive_hold_code = glob_rec_rmsreps.sel_text[1990,1994] 
	#LET modu_rec_aging.inactive_days = glob_rec_rmsreps.sel_text[1981,1989]
	#NEW - Replaced	
	LET modu_rec_aging.hold_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS5_rpt_list")].sel_option1 
	LET modu_rec_aging.inactive_hold_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS5_rpt_list")].sel_option2 
	LET modu_rec_aging.inactive_days = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS5_rpt_list")].sel_option3 
	
	 
	IF modu_rec_aging.hold_code = " " THEN 
		LET modu_rec_aging.hold_code = NULL 
	END IF 
	IF modu_rec_aging.inactive_hold_code = " " THEN 
		LET modu_rec_aging.inactive_hold_code = NULL 
	END IF 
	#LET glob_rec_rmsreps.sel_text[1980,2000] = " " # replaced using rmsreps filter columns 
	LET modu_err_cnt = 0 
	CALL set_aging(glob_rec_kandoouser.cmpy_code, modu_rec_aging.age_date) 
	IF glob_rec_company.module_text[23] = "W" THEN 
		IF NOT pallet_aging(rpt_rmsreps_idx_get_idx("AS5_rpt_list")) THEN 
	 
			#------------------------------------------------------------
			FINISH REPORT AS5_rpt_list
			CALL rpt_finish("AS5_rpt_list")
			#------------------------------------------------------------

			RETURN FALSE #not sure why there are 2 finish reports...
		END IF 
	END IF 
	IF cust_ageing(rpt_rmsreps_idx_get_idx("AS5_rpt_list")) THEN 
		IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS5_rpt_list")].exec_ind = "1" THEN 
			IF modu_err_cnt THEN 
				MESSAGE kandoomsg2("A",7035,modu_err_cnt) 
				#7035 "Account Aging Completed, Errors Encounted - Check ", trim(get_settings_logFile())
			ELSE 
				MESSAGE kandoomsg2("A",7034,modu_err_cnt) 
				#7034 Account Aging Completed Successfully "
			END IF 
		END IF 
	END IF 
	
	#------------------------------------------------------------
	FINISH REPORT AS5_rpt_list
	CALL rpt_finish("AS5_rpt_list")
	#------------------------------------------------------------

	IF int_flag THEN
		RETURN FALSE
	ELSE
		RETURN TRUE
	END IF 
END FUNCTION 


#########################################################################
# FUNCTION age_pal_bal(p_dayslate_num,p_overdue_amt)
#
#
#########################################################################
FUNCTION age_pal_bal(p_dayslate_num,p_overdue_amt) 
	DEFINE p_dayslate_num INTEGER 
	DEFINE p_overdue_amt LIKE custpallet.bal_amt 

	LET modu_rec_custpallet.bal_amt = modu_rec_custpallet.bal_amt + p_overdue_amt 
	CASE 
		WHEN p_dayslate_num > 90 
			LET modu_rec_custpallet.over90_amt = modu_rec_custpallet.over90_amt + 
			p_overdue_amt 
		WHEN p_dayslate_num > 60 
			LET modu_rec_custpallet.over60_amt = modu_rec_custpallet.over60_amt + 
			p_overdue_amt 
		WHEN p_dayslate_num > 30 
			LET modu_rec_custpallet.over30_amt = modu_rec_custpallet.over30_amt + 
			p_overdue_amt 
		WHEN p_dayslate_num > 0 
			LET modu_rec_custpallet.over1_amt = modu_rec_custpallet.over1_amt + 
			p_overdue_amt 
		OTHERWISE 
			LET modu_rec_custpallet.curr_amt = modu_rec_custpallet.curr_amt + 
			p_overdue_amt 
	END CASE 
END FUNCTION 



#########################################################################
# FUNCTION pallet_aging(p_rpt_idx) 
#
#
#########################################################################
FUNCTION pallet_aging(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_pallet RECORD LIKE pallet.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_out_amt LIKE customer.bal_amt 
	DEFINE l_err_message CHAR(240) 
	DEFINE l_dayslate_num INTEGER 
	DEFINE l_query_text VARCHAR(500) 

	LET l_query_text = "SELECT custpallet.* FROM custpallet, customer ", 
	"WHERE custpallet.cmpy_code = \'",glob_rec_kandoouser.cmpy_code,"\'", 
	" AND custpallet.cmpy_code = customer.cmpy_code", 
	" AND custpallet.cust_code = customer.cust_code", 
	" AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS5_rpt_list")].sel_text clipped, 
	" ORDER BY cust_code" 
	PREPARE s_custpallet FROM l_query_text 
	DECLARE c_custpallet CURSOR with HOLD FOR s_custpallet 
	DECLARE ci_pallet CURSOR FOR 
	SELECT invoicehead.*, pallet.* 
	FROM invoicehead,pallet 
	WHERE invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND invoicehead.cust_code = modu_rec_custpallet.cust_code 
	AND invoicehead.total_amt != invoicehead.paid_amt 
	AND invoicehead.posted_flag != "V" 
	AND pallet.trans_num = invoicehead.inv_num 
	AND pallet.cust_code = modu_rec_custpallet.cust_code 
	AND pallet.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND pallet.tran_type_ind in (TRAN_TYPE_INVOICE_IN,"RE","WO") 
	AND pallet.unit_price_amt > 0 
	DECLARE cr_pallet CURSOR FOR 
	SELECT credithead.*, pallet.* 
	FROM credithead,pallet 
	WHERE credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND credithead.cust_code = modu_rec_custpallet.cust_code 
	AND credithead.total_amt != credithead.appl_amt 
	AND credithead.posted_flag != "V" 
	AND pallet.trans_num = credithead.cred_num 
	AND pallet.cust_code = modu_rec_custpallet.cust_code 
	AND pallet.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND pallet.tran_type_ind in (TRAN_TYPE_CREDIT_CR,"SC") 
	AND pallet.unit_price_amt > 0 
	DECLARE cc_pallet CURSOR FOR 
	SELECT cashreceipt.*, pallet.* 
	FROM cashreceipt,pallet 
	WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cashreceipt.cust_code = modu_rec_custpallet.cust_code 
	AND cashreceipt.cash_amt != cashreceipt.applied_amt 
	AND cashreceipt.posted_flag != CASHRECEIPT_POST_FLAG_STATUS_VOIDED_V 
	AND pallet.trans_num = cashreceipt.cash_num 
	AND pallet.cust_code = modu_rec_custpallet.cust_code 
	AND pallet.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND pallet.tran_type_ind = "DE" 
	AND pallet.unit_price_amt > 0 
	FOREACH c_custpallet INTO modu_rec_custpallet.* 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			IF kandoomsg("A",8033,"") = "N" THEN 
				RETURN false 
			END IF 
		END IF 
		IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS5_rpt_list")].exec_ind = "1" THEN 
			DISPLAY "Pallet Ageing ",modu_rec_custpallet.cust_code at 1,2 
			attribute(yellow) 
		END IF 
		GOTO bypass 
		LABEL recovery: 
		##
		## IF any error encountered (including locking), roll back,
		## OUTPUT a MESSAGE TO trim(get_settings_logFile()) AND skip TO next customer
		##
		LET l_err_message = " " 
		LET l_err_message[001,060] = "AS5 - Customer Code : ", 
		modu_rec_custpallet.cust_code, 
		" pallet balances NOT updated " 
		LET l_err_message[061,180] = " Error locking customer RECORD ", 
		" - Status: ", status 
		ROLLBACK WORK 
		
		#---------------------------------------------------------
		OUTPUT TO REPORT AS5_rpt_list(p_rpt_idx,modu_rec_custpallet.cust_code,l_err_message)
		IF NOT rpt_int_flag_handler2("Customer:",modu_rec_custpallet.cust_code, NULL, p_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		 
		LET modu_err_cnt = modu_err_cnt + 1 
		CONTINUE FOREACH 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			##
			## Lock the customer record
			##
			DECLARE c1_customer CURSOR FOR 
			SELECT * FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = modu_rec_custpallet.cust_code 
			FOR UPDATE 
			OPEN c1_customer 
			FETCH c1_customer 
			LET modu_rec_custpallet.bal_amt = 0 
			LET modu_rec_custpallet.curr_amt = 0 
			LET modu_rec_custpallet.over1_amt = 0 
			LET modu_rec_custpallet.over30_amt = 0 
			LET modu_rec_custpallet.over60_amt = 0 
			LET modu_rec_custpallet.over90_amt = 0 
			IF modu_rec_custpallet.onorder_amt < 0 THEN 
				LET modu_rec_custpallet.onorder_amt = 0 
			END IF 
			FOREACH ci_pallet INTO l_rec_invoicehead.*, 
				l_rec_pallet.* 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					IF kandoomsg("A",8033,"") = "N" THEN 
						ROLLBACK WORK 
						RETURN false 
					END IF 
				END IF 
				IF (l_rec_invoicehead.total_amt - l_rec_invoicehead.paid_amt) > 
				(l_rec_pallet.trans_qty * l_rec_pallet.unit_price_amt) THEN 
					LET l_out_amt = l_rec_pallet.trans_qty * l_rec_pallet.unit_price_amt 
				ELSE 
					LET l_out_amt = l_rec_invoicehead.total_amt 
					- l_rec_invoicehead.paid_amt 
				END IF 
				LET l_dayslate_num = get_age_bucket(TRAN_TYPE_INVOICE_IN,l_rec_invoicehead.due_date) 
				CALL age_pal_bal(l_dayslate_num,l_out_amt) 
			END FOREACH 
			FOREACH cr_pallet INTO l_rec_credithead.*, 
				l_rec_pallet.* 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					IF kandoomsg("A",8033,"") = "N" THEN 
						ROLLBACK WORK 
						RETURN false 
					END IF 
				END IF 
				IF (l_rec_credithead.total_amt - l_rec_credithead.appl_amt) > 
				((0 - l_rec_pallet.trans_qty) * l_rec_pallet.unit_price_amt) THEN 
					LET l_out_amt = (0 - l_rec_pallet.trans_qty) * 
					l_rec_pallet.unit_price_amt 
				ELSE 
					LET l_out_amt = l_rec_credithead.total_amt 
					- l_rec_credithead.appl_amt 
				END IF 
				LET l_dayslate_num = get_age_bucket(TRAN_TYPE_CREDIT_CR,l_rec_credithead.cred_date) 
				LET l_out_amt = 0 - l_out_amt 
				CALL age_pal_bal(l_dayslate_num,l_out_amt) 
			END FOREACH 
			FOREACH cc_pallet INTO l_rec_cashreceipt.*, 
				l_rec_pallet.* 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					IF kandoomsg("A",8033,"") = "N" THEN 
						ROLLBACK WORK 
						RETURN false 
					END IF 
				END IF 
				IF (l_rec_cashreceipt.cash_amt - l_rec_cashreceipt.applied_amt) > 
				((0 - l_rec_pallet.trans_qty) * l_rec_pallet.unit_price_amt) THEN 
					LET l_out_amt = (0 - l_rec_pallet.trans_qty) * 
					l_rec_pallet.unit_price_amt 
				ELSE 
					LET l_out_amt = l_rec_cashreceipt.cash_amt 
					- l_rec_cashreceipt.applied_amt 
				END IF 
				LET l_dayslate_num = get_age_bucket(TRAN_TYPE_RECEIPT_CA,l_rec_cashreceipt.cash_date) 
				LET l_out_amt = 0 - l_out_amt 
				CALL age_pal_bal(l_dayslate_num,l_out_amt) 
			END FOREACH 
			UPDATE custpallet SET bal_amt = modu_rec_custpallet.bal_amt , 
			curr_amt = modu_rec_custpallet.curr_amt , 
			over1_amt = modu_rec_custpallet.over1_amt , 
			over30_amt = modu_rec_custpallet.over30_amt , 
			over60_amt = modu_rec_custpallet.over60_amt , 
			over90_amt = modu_rec_custpallet.over90_amt , 
			onorder_amt = modu_rec_custpallet.onorder_amt 
			WHERE cust_code = modu_rec_custpallet.cust_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		COMMIT WORK 
	END FOREACH 
	RETURN true 
END FUNCTION 


#########################################################################
# FUNCTION cust_ageing(p_rpt_idx)
#
#
#########################################################################
FUNCTION cust_ageing(p_rpt_idx) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_rec_orderhead RECORD LIKE orderhead.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_total_freight LIKE orderhead.freight_amt 
	DEFINE l_outstg_freight LIKE orderhead.freight_amt 
	DEFINE l_total_hand LIKE orderhead.hand_amt 
	DEFINE l_outstg_hand LIKE orderhead.hand_amt 
	DEFINE l_outstg_amt LIKE orderhead.hand_amt 
	DEFINE l_conv_rate FLOAT 
	DEFINE l_err_message CHAR(240) 
	--DEFINE l_status1 SMALLINT 
	--DEFINE l_status2 SMALLINT 
	DEFINE l_dayslate_num INTEGER 
	DEFINE l_out_amt LIKE customer.bal_amt 
	DEFINE l_query_text VARCHAR(500) 

	LET l_query_text = "SELECT * FROM customer ", 
	"WHERE customer.cmpy_code = \'",glob_rec_kandoouser.cmpy_code,"\'", 
	" AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS5_rpt_list")].sel_text clipped, 
	" AND delete_flag != 'Y' ", 
	" AND delete_date IS NULL ", 
	" ORDER BY cust_code" 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR with HOLD FOR s_customer 
	FOREACH c_customer INTO l_rec_customer.* 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			IF kandoomsg("A",8033,"") = "N" THEN 
				RETURN false 
			END IF 
		END IF 
		IF glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AS5_rpt_list")].exec_ind = "1" THEN 
			DISPLAY l_rec_customer.cust_code," ",l_rec_customer.name_text at 1,2 
			attribute(yellow) 
		END IF 
		GOTO bypass 
		LABEL recovery: 
		##
		## IF any error encountered (including locking), roll back,
		## OUTPUT a MESSAGE TO trim(get_settings_logFile()) AND skip TO next customer
		##
		LET l_err_message = " " 
		LET l_err_message[001,060]="AS5 - Customer Code : ",l_rec_customer.cust_code, " aged balances NOT updated " 
		LET l_err_message[061,180]= " Error locking customer record", 
		" - Status: ",STATUS 

		#---------------------------------------------------------
		OUTPUT TO REPORT AS5_rpt_list(p_rpt_idx,l_rec_customer.cust_code,l_err_message) 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code,NULL, p_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------

		LET modu_err_cnt = modu_err_cnt + 1 
		CONTINUE FOREACH 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			##
			## Lock the customer record
			##
			DECLARE c2_customer CURSOR FOR 
			SELECT * FROM customer 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_rec_customer.cust_code 
			FOR UPDATE 
			OPEN c2_customer 
			FETCH c2_customer INTO l_rec_customer.* 
			LET l_rec_customer.bal_amt = 0 
			LET l_rec_customer.curr_amt = 0 
			LET l_rec_customer.over1_amt = 0 
			LET l_rec_customer.over30_amt = 0 
			LET l_rec_customer.over60_amt = 0 
			LET l_rec_customer.over90_amt = 0 
			LET l_rec_customer.cred_bal_amt = 0 
			IF glob_rec_company.module_text[5] = "E" THEN 
				LET l_rec_customer.onorder_amt = 0 
			END IF 
			DECLARE c_invoicehead CURSOR FOR 
			SELECT * FROM invoicehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_rec_customer.cust_code 
			AND total_amt != invoicehead.paid_amt 
			AND posted_flag != "V" 
			FOREACH c_invoicehead INTO l_rec_invoicehead.* 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					IF kandoomsg("A",8033,"") = "N" THEN 
						ROLLBACK WORK 
						RETURN false 
					END IF 
				END IF 
				LET l_dayslate_num = get_age_bucket(TRAN_TYPE_INVOICE_IN,l_rec_invoicehead.due_date) 
				LET l_out_amt = l_rec_invoicehead.total_amt - l_rec_invoicehead.paid_amt 
				CALL AS5_age_cust_bal(l_dayslate_num,l_out_amt) 
			END FOREACH 
			DECLARE c_credithead CURSOR FOR 
			SELECT * FROM credithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_rec_customer.cust_code 
			AND total_amt != appl_amt 
			AND posted_flag != "V" 
			FOREACH c_credithead INTO l_rec_credithead.* 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					IF kandoomsg("A",8033,"") = "N" THEN 
						ROLLBACK WORK 
						RETURN false 
					END IF 
				END IF 
				LET l_dayslate_num = get_age_bucket(TRAN_TYPE_CREDIT_CR,l_rec_credithead.cred_date) 
				LET l_out_amt = 0 
				- (l_rec_credithead.total_amt - l_rec_credithead.appl_amt) 
				CALL AS5_age_cust_bal(l_dayslate_num,l_out_amt) 
			END FOREACH 
			DECLARE c_cashreceipt CURSOR FOR 
			SELECT * FROM cashreceipt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_rec_customer.cust_code 
			AND cash_amt != cashreceipt.applied_amt 
			AND posted_flag != "V" 
			FOREACH c_cashreceipt INTO l_rec_cashreceipt.* 
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					IF kandoomsg("A",8033,"") = "N" THEN 
						ROLLBACK WORK 
						RETURN false 
					END IF 
				END IF 
				LET l_dayslate_num = get_age_bucket(TRAN_TYPE_RECEIPT_CA,l_rec_cashreceipt.cash_date) 
				LET l_out_amt = 0 
				- (l_rec_cashreceipt.cash_amt 
				- l_rec_cashreceipt.applied_amt) 
				CALL AS5_age_cust_bal(l_dayslate_num,l_out_amt) 
			END FOREACH 
			
			SELECT avg(paid_date-inv_date) 
			INTO l_rec_customer.avg_cred_day_num 
			FROM invoicehead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_rec_customer.cust_code 
			AND total_amt = paid_amt 
			AND total_amt != 0 
			AND paid_date > "01/01/1900" 
			AND inv_date > "01/01/1900" 
			
			IF l_rec_customer.avg_cred_day_num IS NULL THEN 
				LET l_rec_customer.avg_cred_day_num = 0 
			END IF 
			LET l_rec_customer.cred_bal_amt = l_rec_customer.cred_limit_amt - l_rec_customer.bal_amt 
			LET l_conv_rate = get_conv_rate(
				glob_rec_kandoouser.cmpy_code,
				l_rec_customer.currency_code,	
				modu_rec_aging.age_date,
				CASH_EXCHANGE_SELL)
				 
			IF l_rec_customer.cred_override_ind = 0 THEN 
				IF modu_rec_aging.over90_amt IS NOT NULL THEN 
					IF modu_rec_aging.over90_amt < (l_rec_customer.over90_amt/l_conv_rate) THEN 
						IF l_rec_customer.hold_code IS NULL THEN 
							LET l_rec_customer.hold_code = modu_rec_aging.hold_code 
						END IF 
					END IF 
				END IF 
				IF modu_rec_aging.over60_amt IS NOT NULL THEN 
					IF modu_rec_aging.over60_amt < (l_rec_customer.over60_amt/l_conv_rate) THEN 
						IF l_rec_customer.hold_code IS NULL THEN 
							LET l_rec_customer.hold_code = modu_rec_aging.hold_code 
						END IF 
					END IF 
				END IF 
				IF modu_rec_aging.over30_amt IS NOT NULL THEN 
					IF modu_rec_aging.over30_amt < (l_rec_customer.over30_amt/l_conv_rate) THEN 
						IF l_rec_customer.hold_code IS NULL THEN 
							LET l_rec_customer.hold_code = modu_rec_aging.hold_code 
						END IF 
					END IF 
				END IF 
				IF modu_rec_aging.over1_amt IS NOT NULL THEN 
					IF modu_rec_aging.over1_amt < (l_rec_customer.over1_amt/l_conv_rate) THEN 
						IF l_rec_customer.hold_code IS NULL THEN 
							LET l_rec_customer.hold_code = modu_rec_aging.hold_code 
						END IF 
					END IF 
				END IF 
			END IF 
			
			#- Reset the customers last_inv_date COLUMN TO setup_date IF the -#
			#- last_in_date IS NULL OR = "31/12/1899" TO ensure valid checking#
			IF l_rec_customer.last_inv_date = "31/12/1899" 
			OR l_rec_customer.last_inv_date IS NULL THEN 
				UPDATE customer 
				SET last_inv_date = l_rec_customer.setup_date 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_customer.cust_code 
			END IF 
			#- Determine whether TO apply the inactive hold code -#
			IF l_rec_customer.cred_override_ind = 0 THEN 
				IF l_rec_customer.hold_code IS NULL THEN 
					IF modu_rec_aging.inactive_hold_code IS NOT NULL THEN 
						IF (modu_rec_aging.age_date - modu_rec_aging.inactive_days) > 
						l_rec_customer.last_inv_date 
						THEN 
							LET l_rec_customer.hold_code = modu_rec_aging.inactive_hold_code 
						END IF 
					END IF 
				END IF 
			END IF 
			LET l_err_message = "AS5 - Customer Balance Update" 
			IF glob_rec_company.module_text[5] = "E" THEN 
				LET l_total_freight = 0 
				LET l_total_hand = 0 

				DECLARE c_orderhead CURSOR FOR 
				SELECT * FROM orderhead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = l_rec_customer.cust_code 
				AND status_ind != "C" 

				FOREACH c_orderhead INTO l_rec_orderhead.* 
					LET l_outstg_freight = l_rec_orderhead.freight_amt 
					- l_rec_orderhead.freight_inv_amt 
					LET l_outstg_hand = l_rec_orderhead.hand_amt 
					- l_rec_orderhead.hand_inv_amt 
					IF l_outstg_freight IS NULL 
					OR l_outstg_freight < 0 THEN 
						LET l_outstg_freight = 0 
					END IF 
					IF l_outstg_hand IS NULL 
					OR l_outstg_hand < 0 THEN 
						LET l_outstg_hand = 0 
					END IF 
					LET l_outstg_amt = 0 
					SELECT sum((order_qty - inv_qty)*(unit_price_amt+unit_tax_amt)) 
					INTO l_outstg_amt FROM orderdetl 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND order_num = l_rec_orderhead.order_num 
					AND order_qty != 0 
					AND inv_qty != order_qty 
					IF l_outstg_amt IS NULL THEN 
						LET l_outstg_amt = 0 
					END IF 
					LET l_rec_customer.onorder_amt = l_rec_customer.onorder_amt 
					+ l_outstg_freight 
					+ l_outstg_hand 
					+ l_outstg_amt 
					IF int_flag OR quit_flag THEN 
						LET int_flag = false 
						LET quit_flag = false 
						IF kandoomsg("A",8033,"") = "N" THEN 
							ROLLBACK WORK 
							RETURN false 
						END IF 
					END IF 
				END FOREACH 
			END IF 
			
			UPDATE customer 
			SET bal_amt = l_rec_customer.bal_amt, 
			curr_amt = l_rec_customer.curr_amt, 
			over1_amt = l_rec_customer.over1_amt, 
			over30_amt = l_rec_customer.over30_amt, 
			over60_amt = l_rec_customer.over60_amt, 
			over90_amt = l_rec_customer.over90_amt, 
			onorder_amt = l_rec_customer.onorder_amt, 
			cred_bal_amt = l_rec_customer.cred_bal_amt, 
			avg_cred_day_num = l_rec_customer.avg_cred_day_num, 
			hold_code = l_rec_customer.hold_code 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cust_code = l_rec_customer.cust_code 
		COMMIT WORK 
		
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
		# Check that the new bal_amt equals that of araudit record
		DECLARE c_araudit CURSOR FOR 
		SELECT * FROM araudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = l_rec_customer.cust_code 
		ORDER BY cust_code, 
		seq_num desc 
		OPEN c_araudit 
		FETCH c_araudit INTO l_rec_araudit.* 
		IF sqlca.sqlcode = NOTFOUND THEN 
			IF l_rec_customer.bal_amt != 0 THEN 
				LET l_err_message[001,040]="AS5 - AR Audit Entries do NOT exist FOR " 
				LET l_err_message[041,080]=" customer with non-zero balance" 
				LET l_err_message[081,160]=" Customer Code :",l_rec_customer.cust_code 
				LET l_err_message[161,240]=" Customer Balance:",l_rec_customer.bal_amt 

				#---------------------------------------------------------
				OUTPUT TO REPORT AS5_rpt_list(p_rpt_idx,l_rec_customer.cust_code,l_err_message) 
				IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, NULL,p_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------				

				LET modu_err_cnt = modu_err_cnt + 1 
			END IF 
		ELSE 
			IF l_rec_araudit.bal_amt != l_rec_customer.bal_amt THEN 
				LET l_err_message[001,040]="AS5 - AR Audit Balance does NOT equal" 
				LET l_err_message[041,080]="customer's balance" 
				LET l_err_message[081,160]=" Customer Code :",l_rec_customer.cust_code 
				LET l_err_message[161,200]=" Customer Balance:",l_rec_customer.bal_amt 
				LET l_err_message[201,240]=" AR Audit Balance:",l_rec_araudit.bal_amt 
				
				#---------------------------------------------------------
				OUTPUT TO REPORT AS5_rpt_list(p_rpt_idx,l_rec_customer.cust_code,l_err_message) 
				IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code, NULL, p_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------					

				LET modu_err_cnt = modu_err_cnt + 1 
			END IF 
		END IF 
		CLOSE c_araudit 
	END FOREACH 
	WHENEVER ERROR CONTINUE 
	## Locking recovery IS disabled FOR this UPDATE
	UPDATE arparms 
	SET cust_age_date = modu_rec_aging.age_date 
	WHERE arparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND arparms.parm_code = "1" 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	RETURN true 
END FUNCTION 


#########################################################################
# FUNCTION AS5_age_cust_bal(p_dayslate_num,p_overdue_amt)
#
#
#########################################################################
FUNCTION AS5_age_cust_bal(p_dayslate_num,p_overdue_amt) 
	DEFINE p_dayslate_num INTEGER 
	DEFINE p_overdue_amt LIKE customer.bal_amt 

	LET glob_rec_customer.bal_amt = glob_rec_customer.bal_amt + p_overdue_amt 
	CASE 
		WHEN p_dayslate_num > 90 
			LET glob_rec_customer.over90_amt = glob_rec_customer.over90_amt + p_overdue_amt 
		WHEN p_dayslate_num > 60 
			LET glob_rec_customer.over60_amt = glob_rec_customer.over60_amt + p_overdue_amt 
		WHEN p_dayslate_num > 30 
			LET glob_rec_customer.over30_amt = glob_rec_customer.over30_amt + p_overdue_amt 
		WHEN p_dayslate_num > 0 
			LET glob_rec_customer.over1_amt = glob_rec_customer.over1_amt + p_overdue_amt 
		OTHERWISE 
			LET glob_rec_customer.curr_amt = glob_rec_customer.curr_amt + p_overdue_amt 
	END CASE 
END FUNCTION 


#########################################################################
# REPORT AS5_rpt_list(p_cust_code,p_reason)
#
#
#########################################################################
REPORT AS5_rpt_list(p_rpt_idx,p_cust_code,p_reason) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_cust_code LIKE customer.cust_code
	DEFINE p_reason NCHAR(240) 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	
	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01," "
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1  CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2  CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3  CLIPPED #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3  CLIPPED #wasl_arr_line[3] 
			
		ON EVERY ROW 
			CALL db_customer_get_rec(UI_OFF,p_cust_code) RETURNING l_rec_customer.*
--			SELECT * INTO l_rec_customer.* FROM customer 
--			WHERE cust_code = p_cust_code 
--			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			PRINT COLUMN 01,l_rec_customer.cust_code CLIPPED, 
			COLUMN 11,l_rec_customer.name_text CLIPPED, 
			COLUMN 43,p_reason wordwrap right margin glob_arr_rec_rpt_rmsreps[p_rpt_idx].report_width_num #132 
			
		ON LAST ROW 
			PRINT COLUMN 01," "
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = pageno

END REPORT
 