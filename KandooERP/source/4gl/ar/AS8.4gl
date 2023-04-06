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
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AS8_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################
DEFINE modu_rec_arparmext RECORD LIKE arparmext.* 
DEFINE modu_rec_coa RECORD LIKE coa.* 
DEFINE modu_aging RECORD 
	age_date DATE, 
	service_fee DECIMAL(16,2), 
	over90_amt LIKE customer.bal_amt, 
	over60_amt LIKE customer.bal_amt, 
	over30_amt LIKE customer.bal_amt, 
	over1_amt LIKE customer.bal_amt, 
	current_amt LIKE customer.bal_amt, 
	current_per DECIMAL(6,2), 
	over1_per DECIMAL(6,2), 
	over30_per DECIMAL(6,2), 
	over60_per DECIMAL(6,2), 
	over90_per DECIMAL(6,2), 
	inv_date LIKE invoicehead.inv_date, 
	line_text LIKE invoicedetl.line_text, 
	com1_text LIKE invoicehead.com1_text, 
	com2_text LIKE invoicehead.com2_text, 
	year_num LIKE invoicehead.year_num, 
	period_num LIKE invoicehead.period_num, 
	int_acct_code LIKE arparmext.int_acct_code 
END RECORD 
	DEFINE modu_rec_customer RECORD LIKE customer.*
--DEFINE c LIKE rmsreps.page_num 
--DEFINE modu_where_text CHAR(300)
--DEFINE modu_query_text CHAR(300)


##############################################################################
# FUNCTION AS8_main()
#
#   - Program AS8  - Allows the user TO generate service fees
#                    FOR overdue accounts
##############################################################################
FUNCTION AS8_main()
	DEFINE l_where_text STRING 
	DEFER QUIT 
	DEFER INTERRUPT 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 

	CALL setModuleId("AS8") 
	CALL AS8_init_globals()

	OPEN WINDOW A644 with FORM "A644" 
	CALL windecoration_a("A644") 

 MENU " Service Fee Generation" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","AS8","menu-service-fee") 
			LET l_where_text = AS8_rpt_query()
			IF l_where_text IS NOT NULL THEN 
				IF promptTF("",kandoomsg2("A",8019,""),1) THEN ## Begin Interest/Fee Charge Generation (Y/N)?
					CALL AS8_rpt_process(l_where_text) 
				END IF 
			END IF 
			CALL AS8_init_globals()
			CALL rpt_rmsreps_reset(NULL) 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Generate" #COMMAND "Generate" " Enter generation parameters AND create service fees"
			LET l_where_text = AS8_rpt_query()
			IF l_where_text IS NOT NULL THEN 
				IF promptTF("",kandoomsg2("A",8019,""),1) THEN ## Begin Interest/Fee Charge Generation (Y/N)?
					CALL AS8_rpt_process(l_where_text) 
				END IF 
			END IF 
			CALL AS8_init_globals() 
			CALL rpt_rmsreps_reset(NULL)

		ON ACTION "Print Manager"	#      COMMAND KEY ("P",f11) "Print" " Print Service Fee Report using RMS"
			CALL run_prog("URS","","","","") 

		ON ACTION "Exit" #      COMMAND KEY(interrupt,"E")"Exit" " EXIT PROGRAM"
			EXIT MENU 

	END MENU 

	CLOSE WINDOW A644 
END FUNCTION 


##############################################################################
# FUNCTION AS8_rpt_query()
#
#
##############################################################################
FUNCTION AS8_rpt_query() 
	DEFINE l_where_text STRING
	DEFINE l_failed_it SMALLINT 

	MESSAGE kandoomsg2("A",1070,"") 
	#1070 Enter service fee generation details - ESC TO continue
	INPUT BY NAME modu_aging.age_date, 
	modu_aging.service_fee, 
	modu_aging.current_amt, 
	modu_aging.current_per, 
	modu_aging.over1_amt, 
	modu_aging.over1_per, 
	modu_aging.over30_amt, 
	modu_aging.over30_per, 
	modu_aging.over60_amt, 
	modu_aging.over60_per, 
	modu_aging.over90_amt, 
	modu_aging.over90_per, 
	modu_aging.inv_date, 
	modu_aging.line_text, 
	modu_aging.com1_text, 
	modu_aging.com2_text, 
	modu_aging.year_num, 
	modu_aging.period_num, 
	modu_aging.int_acct_code WITHOUT DEFAULTS 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AS8","inp-aging") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (int_acct_code) 
			LET glob_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_temp_text IS NOT NULL THEN 
				LET modu_aging.int_acct_code = glob_temp_text 
				NEXT FIELD int_acct_code 
			END IF 

		AFTER FIELD age_date 
			IF modu_aging.age_date IS NULL THEN 
				LET modu_aging.age_date = today 
				NEXT FIELD age_date 
			END IF 

		AFTER FIELD service_fee 
			IF modu_aging.service_fee < 0 THEN 
				ERROR kandoomsg2("A",9220,"") 
				#9220 Negative service fees are NOT permitted
				LET modu_aging.service_fee = 0 
				NEXT FIELD service_fee 
			END IF 

		AFTER FIELD current_amt 
			IF modu_aging.current_amt < 0 THEN 
				ERROR kandoomsg2("A",9149,"") 
				#9149 Negative balance amounts are NOT permitted
				LET modu_aging.current_amt = NULL 
				NEXT FIELD current_amt 
			END IF 

		AFTER FIELD current_per 
			IF modu_aging.current_per IS NULL THEN 
				IF modu_aging.current_amt IS NOT NULL THEN 
					ERROR kandoomsg2("A",9224,"") 
					#9224 You must enter a percentage IF a balance amount has been
					#     specified
					NEXT FIELD current_per 
				END IF 
			END IF 
			IF modu_aging.current_per <= 0 THEN 
				ERROR kandoomsg2("A",9221,"") 
				#9221 Negative percentage IS NOT permitted
				LET modu_aging.current_per = NULL 
				NEXT FIELD current_per 
			END IF 
			IF modu_aging.current_per > 100 THEN 
				ERROR kandoomsg2("A",9222,"") 
				#9222 Percentage can NOT be greater than 100
				LET modu_aging.current_per = NULL 
				NEXT FIELD current_per 
			END IF 

		AFTER FIELD over1_amt 
			IF modu_aging.over1_amt < 0 THEN 
				ERROR kandoomsg2("A",9149,"") 
				#9149 Negative balance amounts are NOT permitted
				LET modu_aging.over1_amt = NULL 
				NEXT FIELD over1_amt 
			END IF 

		AFTER FIELD over1_per 
			IF modu_aging.over1_per IS NULL THEN 
				IF modu_aging.over1_amt IS NOT NULL THEN 
					ERROR kandoomsg2("A",9224,"") 
					#9224 You must enter a percentage IF a balance amount has been
					#     specified
					NEXT FIELD over1_per 
				END IF 
			END IF 
			IF modu_aging.over1_per <= 0 THEN 
				ERROR kandoomsg2("A",9221,"") 
				#9221 Negative percentage IS NOT permitted
				LET modu_aging.over1_per = NULL 
				NEXT FIELD over1_per 
			END IF 
			IF modu_aging.over1_per > 100 THEN 
				ERROR kandoomsg2("A",9222,"") 
				#9222 Percentage can NOT be greater than 100
				LET modu_aging.over1_per = NULL 
				NEXT FIELD over1_per 
			END IF 

		AFTER FIELD over30_amt 
			IF modu_aging.over30_amt < 0 THEN 
				ERROR kandoomsg2("A",9149,"") 
				#9149 Negative balance amounts are NOT permitted
				LET modu_aging.over30_amt = NULL 
				NEXT FIELD over30_amt 
			END IF 

		AFTER FIELD over30_per 
			IF modu_aging.over30_per IS NULL THEN 
				IF modu_aging.over30_amt IS NOT NULL THEN 
					ERROR kandoomsg2("A",9224,"") 
					#9224 You must enter a percentage IF a balance amount has been
					#     specified
					NEXT FIELD over30_per 
				END IF 
			END IF 
			IF modu_aging.over30_per <= 0 THEN 
				ERROR kandoomsg2("A",9221,"") 
				#9221 Negative percentage IS NOT permitted
				LET modu_aging.over30_per = NULL 
				NEXT FIELD over30_per 
			END IF 
			IF modu_aging.over30_per > 100 THEN 
				ERROR kandoomsg2("A",9222,"") 
				#9222 Percentage can NOT be greater than 100
				LET modu_aging.over30_per = NULL 
				NEXT FIELD over30_per 
			END IF 

		AFTER FIELD over60_amt 
			IF modu_aging.over60_amt < 0 THEN 
				ERROR kandoomsg2("A",9149,"") 
				#9149 Negative balance amounts are NOT permitted
				LET modu_aging.over60_amt = NULL 
				NEXT FIELD over60_amt 
			END IF 

		AFTER FIELD over60_per 
			IF modu_aging.over60_per IS NULL THEN 
				IF modu_aging.over60_amt IS NOT NULL THEN 
					ERROR kandoomsg2("A",9224,"") 
					#9224 You must enter a percentage IF a balance amount has been
					#     specified
					NEXT FIELD over60_per 
				END IF 
			END IF 
			IF modu_aging.over60_per <= 0 THEN 
				ERROR kandoomsg2("A",9221,"") 
				#9221 Negative percentage IS NOT permitted
				LET modu_aging.over60_per = NULL 
				NEXT FIELD over60_per 
			END IF 
			IF modu_aging.over60_per > 100 THEN 
				ERROR kandoomsg2("A",9222,"") 
				#9222 Percentage can NOT be greater than 100
				LET modu_aging.over60_per = NULL 
				NEXT FIELD over60_per 
			END IF 

		AFTER FIELD over90_amt 
			IF modu_aging.over90_amt < 0 THEN 
				ERROR kandoomsg2("A",9149,"") 
				#9149 Negative balance amounts are NOT permitted
				LET modu_aging.over90_amt = NULL 
				NEXT FIELD over90_amt 
			END IF 

		AFTER FIELD over90_per 
			IF modu_aging.over90_per IS NULL THEN 
				IF modu_aging.over90_amt IS NOT NULL THEN 
					ERROR kandoomsg2("A",9224,"") 
					#9224 You must enter a percentage IF a balance amount has been
					#     specified
					NEXT FIELD over90_per 
				END IF 
			END IF 
			IF modu_aging.over90_per <= 0 THEN 
				ERROR kandoomsg2("A",9221,"") 
				#9221 Negative percentage IS NOT permitted
				LET modu_aging.over90_per = NULL 
				NEXT FIELD over90_per 
			END IF 
			IF modu_aging.over90_per > 100 THEN 
				ERROR kandoomsg2("A",9222,"") 
				#9222 Percentage can NOT be greater than 100
				LET modu_aging.over90_per = NULL 
				NEXT FIELD over60_per 
			END IF 

		AFTER FIELD inv_date 
			IF modu_aging.age_date IS NULL THEN 
				LET modu_aging.inv_date = today 
				NEXT FIELD inv_date 
			END IF 

		AFTER FIELD line_text 
			IF modu_aging.line_text IS NULL THEN 
				ERROR kandoomsg2("A",9212,"") 
				#9212 Description must be entered
				LET modu_aging.line_text = "Service Fee" 
				NEXT FIELD line_text 
			END IF 

		AFTER FIELD int_acct_code 
			SELECT unique 1 FROM coa 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND acct_code = modu_aging.int_acct_code 
			IF status = NOTFOUND THEN 
				ERROR kandoomsg2("A",9219,"") 
				#9219" Service Fee Income GL Account NOT found, try window"
				NEXT FIELD int_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,modu_aging.int_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD int_acct_code 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF modu_aging.current_per IS NULL THEN 
					IF modu_aging.current_amt IS NOT NULL THEN 
						ERROR kandoomsg2("A",9224,"") 
						#9224 You must enter a percentage IF a balance amount has been
						#     specified
						NEXT FIELD current_per 
					END IF 
				END IF 
				IF modu_aging.over1_per IS NULL THEN 
					IF modu_aging.over1_amt IS NOT NULL THEN 
						ERROR kandoomsg2("A",9224,"") 
						#9224 You must enter a percentage IF a balance amount has been
						#     specified
						NEXT FIELD over1_per 
					END IF 
				END IF 
				IF modu_aging.over30_per IS NULL THEN 
					IF modu_aging.over30_amt IS NOT NULL THEN 
						ERROR kandoomsg2("A",9224,"") 
						#9224 You must enter a percentage IF a balance amount has been
						#     specified
						NEXT FIELD over30_per 
					END IF 
				END IF 
				IF modu_aging.over60_per IS NULL THEN 
					IF modu_aging.over60_amt IS NOT NULL THEN 
						ERROR kandoomsg2("A",9224,"") 
						#9224 You must enter a percentage IF a balance amount has been
						#     specified
						NEXT FIELD over60_per 
					END IF 
				END IF 
				IF modu_aging.over90_per IS NULL THEN 
					IF modu_aging.over90_amt IS NOT NULL THEN 
						ERROR kandoomsg2("A",9224,"") #9224 You must enter a percentage IF a balance amount has been
						#     specified
						NEXT FIELD over90_per 
					END IF 
				END IF
				 
				CALL valid_period(
					glob_rec_kandoouser.cmpy_code, 
					modu_aging.year_num,
					modu_aging.period_num, 
					LEDGER_TYPE_AR) 
				RETURNING 
					modu_aging.year_num, 
					modu_aging.period_num,	
					l_failed_it
				 
				IF l_failed_it = 1 THEN 
					NEXT FIELD year_num 
				END IF 
				
				SELECT * INTO modu_rec_coa.* FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = modu_aging.int_acct_code 
				IF status = NOTFOUND THEN 
					ERROR kandoomsg2("A",9219,"") 
					#9219" Service Fee Income GL Account NOT found, try window"
					NEXT FIELD int_acct_code 
				END IF 
			END IF 



	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF
	 
	MESSAGE kandoomsg2("A",1001,"") 
	#1001 Enter Selection criteria - ESC TO continue
	CONSTRUCT BY NAME l_where_text ON type_code, 
	cust_code, 
	name_text 


		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","AS8","construct-customer") 

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
	
	
		LET glob_rec_rpt_selector.ref1_date = modu_aging.age_date				#DATE, 
		LET glob_rec_rpt_selector.ref2_date = modu_aging.inv_date				#LIKE invoicehead.inv_date, 
		
		LET glob_rec_rpt_selector.ref1_amt = modu_aging.service_fee			#DECIMAL(16,2), 
		LET glob_rec_rpt_selector.ref2_amt = modu_aging.over90_amt			#LIKE customer.bal_amt, 
		LET glob_rec_rpt_selector.ref3_amt = modu_aging.over60_amt			#LIKE customer.bal_amt, 
		LET glob_rec_rpt_selector.ref4_amt = modu_aging.over30_amt			#LIKE customer.bal_amt, 
		LET glob_rec_rpt_selector.ref5_amt = modu_aging.over1_amt				#LIKE customer.bal_amt, 
		LET glob_rec_rpt_selector.ref6_amt = modu_aging.current_amt			#LIKE customer.bal_amt, 
	
		LET glob_rec_rpt_selector.ref1_per = modu_aging.current_per			#DECIMAL(6,2), 
		LET glob_rec_rpt_selector.ref2_per = modu_aging.over1_per 			#DECIMAL(6,2), 
		LET glob_rec_rpt_selector.ref3_per = modu_aging.over30_per			#DECIMAL(6,2), 
		LET glob_rec_rpt_selector.ref4_per = modu_aging.over60_per			#DECIMAL(6,2), 
		LET glob_rec_rpt_selector.ref5_per = modu_aging.over90_per			#DECIMAL(6,2), 
	
		LET glob_rec_rpt_selector.ref1_text = modu_aging.line_text			#LIKE invoicedetl.line_text, nvarchar(40,0) 
		LET glob_rec_rpt_selector.ref2_text = modu_aging.com1_text 			#LIKE invoicehead.com1_text, 
		LET glob_rec_rpt_selector.ref3_text = modu_aging.com2_text 			#LIKE invoicehead.com2_text, 
	
		LET glob_rec_rpt_selector.ref1_num = modu_aging.year_num				#LIKE invoicehead.year_num, 
		LET glob_rec_rpt_selector.ref2_num = modu_aging.period_num			#LIKE invoicehead.period_num, 
	
		LET glob_rec_rpt_selector.ref1_code = modu_aging.int_acct_code	#LIKE arparmext.int_acct_code 	
		RETURN l_where_text 
	END IF 
END FUNCTION 


##############################################################################
# FUNCTION AS8_rpt_process(p_where_text) 
#
#
##############################################################################
FUNCTION AS8_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT   
	DEFINE l_msgresp LIKE language.yes_flag 	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_conv_fee DECIMAL(16,2) 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_err_message CHAR(240) 
	--DEFINE l_inv_created INTEGER 
	DEFINE l_err_cnt SMALLINT 
	DEFINE l_x INTEGER 
	DEFINE l_y LIKE customer.bal_amt 


	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"AS8_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AS8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET modu_aging.age_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date 			#DATE, 
	LET modu_aging.inv_date = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_date 			#LIKE invoicehead.inv_date, 
	
	LET modu_aging.service_fee = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_amt 		#DECIMAL(16,2), 
	LET modu_aging.over90_amt	 = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_amt 		#LIKE customer.bal_amt, 
	LET modu_aging.over60_amt = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_amt 		#LIKE customer.bal_amt, 
	LET modu_aging.over30_amt = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_amt 		#LIKE customer.bal_amt, 
	LET modu_aging.over1_amt = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref5_amt 			#LIKE customer.bal_amt, 
	LET modu_aging.current_amt = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref6_amt		#LIKE customer.bal_amt, 

	LET modu_aging.current_per = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_per 		#DECIMAL(6,2), 
	LET modu_aging.over1_per = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_per  			#DECIMAL(6,2), 
	LET modu_aging.over30_per = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_per 			#DECIMAL(6,2), 
	LET modu_aging.over60_per	= glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref4_per 		#DECIMAL(6,2), 
	LET modu_aging.over90_per = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref5_per 			#DECIMAL(6,2), 

	LET modu_aging.line_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_text 			#LIKE invoicedetl.line_text, 
	LET modu_aging.com1_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_text  			#LIKE invoicehead.com1_text, 
	LET modu_aging.com2_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref3_text 			#LIKE invoicehead.com2_text, 

	LET modu_aging.year_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num 				#LIKE invoicehead.year_num, 
	LET modu_aging.period_num = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num 			#LIKE invoicehead.period_num, 

	LET modu_aging.int_acct_code = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_code 	#LIKE arparmext.int_acct_code 


	LET l_err_cnt = 0 
	
	CALL set_aging(glob_rec_kandoouser.cmpy_code, modu_aging.age_date)
	 
	LET l_query_text = "SELECT * FROM customer ", 
	"WHERE customer.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND int_chge_flag = 'Y' ", 
	"AND delete_flag = 'N' ", 
	"AND ",p_where_text clipped," ", 
	"ORDER BY cust_code" 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR with HOLD FOR s_customer
	

	FOREACH c_customer INTO modu_rec_customer.* 
		--DISPLAY modu_rec_customer.cust_code," ",modu_rec_customer.name_text at 2,2	attribute(yellow) 
		LET modu_rec_customer.bal_amt = 0 
		LET modu_rec_customer.curr_amt = 0 
		LET modu_rec_customer.over1_amt = 0 
		LET modu_rec_customer.over30_amt = 0 
		LET modu_rec_customer.over60_amt = 0 
		LET modu_rec_customer.over90_amt = 0 
		LET modu_rec_customer.cred_bal_amt = 0 
		IF modu_rec_customer.onorder_amt < 0 THEN 
			LET modu_rec_customer.onorder_amt = 0 
		END IF
		 
		DECLARE c_invoicehead CURSOR FOR 
		SELECT * FROM invoicehead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = modu_rec_customer.cust_code 
		AND total_amt != invoicehead.paid_amt 
		AND posted_flag != "V" 
		AND due_date > "01/01/1980" 

		FOREACH c_invoicehead INTO l_rec_invoicehead.* 
			LET l_x = get_age_bucket(TRAN_TYPE_INVOICE_IN,l_rec_invoicehead.due_date) 
			LET l_y = l_rec_invoicehead.total_amt - l_rec_invoicehead.paid_amt 
			CALL AS8_age_cust_bal(l_x,l_y) 
		END FOREACH 

		DECLARE c_credithead CURSOR FOR 
		SELECT * FROM credithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = modu_rec_customer.cust_code 
		AND total_amt != appl_amt 
		AND posted_flag != "V" 

		FOREACH c_credithead INTO l_rec_credithead.* 
			LET l_x = get_age_bucket(TRAN_TYPE_CREDIT_CR,l_rec_credithead.cred_date) 
			LET l_y = 0 - (l_rec_credithead.total_amt - l_rec_credithead.appl_amt) 
			#### reverse sign on outstanding amount FOR credits
			CALL AS8_age_cust_bal(l_x,l_y) 
		END FOREACH 

		DECLARE c_cashreceipt CURSOR FOR 
		SELECT * FROM cashreceipt 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cust_code = modu_rec_customer.cust_code 
		AND cash_amt != cashreceipt.applied_amt 
		AND posted_flag != "V" 

		FOREACH c_cashreceipt INTO l_rec_cashreceipt.* 
			LET l_x = get_age_bucket(TRAN_TYPE_RECEIPT_CA,l_rec_cashreceipt.cash_date) 
			LET l_y = 0 - (l_rec_cashreceipt.cash_amt - l_rec_cashreceipt.applied_amt) 
			#### reverse sign on outstanding amount FOR cash receipts
			CALL AS8_age_cust_bal(l_x,l_y) 
		END FOREACH 

		INITIALIZE l_rec_invoicehead.* TO NULL 
		INITIALIZE l_rec_invoicedetl.* TO NULL 
		
		LET l_rec_invoicehead.total_amt = 0 
		LET l_rec_invoicehead.conv_qty = get_conv_rate(
			glob_rec_kandoouser.cmpy_code, 
			modu_rec_customer.currency_code, 
			today,
			CASH_EXCHANGE_SELL) 

		LET l_conv_fee = modu_aging.service_fee * l_rec_invoicehead.conv_qty 
		IF modu_aging.service_fee > 0 THEN 
			LET l_rec_invoicehead.total_amt = l_rec_invoicehead.total_amt + l_conv_fee 
		END IF 

		IF modu_aging.over90_amt IS NOT NULL THEN 
			IF modu_aging.over90_amt < (modu_rec_customer.over90_amt) THEN 
				LET l_rec_invoicehead.total_amt = l_rec_invoicehead.total_amt +	(modu_rec_customer.over90_amt * (modu_aging.over90_per / 100)) 
			END IF 
		END IF 

		IF modu_aging.over60_amt IS NOT NULL THEN 
			IF modu_aging.over60_amt < (modu_rec_customer.over60_amt) THEN 
				LET l_rec_invoicehead.total_amt = l_rec_invoicehead.total_amt +	(modu_rec_customer.over60_amt * (modu_aging.over60_per / 100)) 
			END IF 
		END IF 
		
		IF modu_aging.over30_amt IS NOT NULL THEN 
			IF modu_aging.over30_amt < (modu_rec_customer.over30_amt) THEN 
				LET l_rec_invoicehead.total_amt = l_rec_invoicehead.total_amt +	(modu_rec_customer.over30_amt * (modu_aging.over30_per / 100)) 
			END IF 
		END IF 
		
		IF modu_aging.over1_amt IS NOT NULL THEN 
			IF modu_aging.over1_amt < (modu_rec_customer.over1_amt) THEN 
				LET l_rec_invoicehead.total_amt = l_rec_invoicehead.total_amt +	(modu_rec_customer.over1_amt * (modu_aging.over1_per / 100)) 
			END IF 
		END IF 
		
		IF modu_aging.current_amt IS NOT NULL THEN 
			IF modu_aging.current_amt < (modu_rec_customer.curr_amt) THEN 
				LET l_rec_invoicehead.total_amt = l_rec_invoicehead.total_amt +	(modu_rec_customer.curr_amt * (modu_aging.current_amt / 100)) 
			END IF 
		END IF 

		IF l_rec_invoicehead.total_amt > 0 THEN 
			GOTO bypass 
			LABEL recovery: 
			IF error_recover(l_err_message,status) = "Y" THEN 
				LET l_err_message= "**** Customer excluded FROM service charge ",	"Customer Code :",modu_rec_customer.cust_code," ","Service Fee:", l_rec_invoicehead.total_amt 
				
				#---------------------------------------------------------
				OUTPUT TO REPORT AS8_rpt_list(l_rpt_idx,modu_rec_customer.*,l_rec_invoicehead.*,l_err_message)  
				IF NOT rpt_int_flag_handler2("Customer:",modu_rec_customer.cust_code, modu_rec_customer.name_text,l_rpt_idx) THEN
					EXIT FOREACH 
				END IF 
				#---------------------------------------------------------
				 
				LET l_err_cnt = l_err_cnt + 1 
				CONTINUE FOREACH 
			END IF 

			LABEL bypass: 
			WHENEVER ERROR GOTO recovery 
			BEGIN WORK 
				##
				## Lock the customer record
				##
				DECLARE c1_customer CURSOR FOR 
				SELECT * FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = modu_rec_customer.cust_code 
				FOR UPDATE 
				OPEN c1_customer 
				FETCH c1_customer INTO modu_rec_customer.* 
				##
				## Obtain next invoice number
				##
				LET l_rec_invoicehead.inv_num = next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_INVOICE_IN,"") 
				IF l_rec_invoicehead.inv_num < 0 THEN 
					LET l_err_message = "AS8 - Next invoice number UPDATE" 
					LET status = l_rec_invoicehead.inv_num 
					GOTO recovery 
				END IF 
				LET l_rec_invoicehead.inv_date = modu_aging.inv_date 
				
				SELECT * INTO l_rec_term.* 
				FROM term 
				WHERE term_code = modu_rec_customer.term_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code
				 
				LET l_rec_invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_invoicedetl.cust_code = modu_rec_customer.cust_code 
				LET l_rec_invoicedetl.inv_num = l_rec_invoicehead.inv_num 
				LET l_rec_invoicedetl.line_num = 1 
				LET l_rec_invoicedetl.part_code = NULL 
				LET l_rec_invoicedetl.line_text = modu_aging.line_text 
				LET l_rec_invoicedetl.ware_code = NULL 
				LET l_rec_invoicedetl.cat_code = NULL 
				LET l_rec_invoicedetl.ord_qty = 0 
				LET l_rec_invoicedetl.ship_qty = 1 
				LET l_rec_invoicedetl.prev_qty = 0 
				LET l_rec_invoicedetl.back_qty = 0 
				LET l_rec_invoicedetl.ser_flag = NULL 
				LET l_rec_invoicedetl.ser_qty = 0 
				LET l_rec_invoicedetl.uom_code = NULL 
				LET l_rec_invoicedetl.unit_cost_amt = 0 
				LET l_rec_invoicedetl.ext_cost_amt = 0 
				LET l_rec_invoicedetl.disc_amt = 0 
				LET l_rec_invoicedetl.unit_sale_amt = l_rec_invoicehead.total_amt 
				LET l_rec_invoicedetl.ext_sale_amt = l_rec_invoicehead.total_amt 
				LET l_rec_invoicedetl.unit_tax_amt = 0 
				LET l_rec_invoicedetl.ext_tax_amt = 0 
				LET l_rec_invoicedetl.line_total_amt = l_rec_invoicehead.total_amt 
				LET l_rec_invoicedetl.seq_num = 0 
				LET l_rec_invoicedetl.line_acct_code = modu_aging.int_acct_code 
				LET l_rec_invoicedetl.level_code = NULL 
				LET l_rec_invoicedetl.comm_amt = 0 
				LET l_rec_invoicedetl.comp_per = 0 
				LET l_rec_invoicedetl.tax_code = modu_rec_customer.tax_code 
				LET l_rec_invoicedetl.order_line_num = 0 
				LET l_rec_invoicedetl.order_num = NULL 
				LET l_rec_invoicedetl.disc_per = 0 
				LET l_rec_invoicedetl.offer_code = NULL 
				LET l_rec_invoicedetl.sold_qty = 1 
				LET l_rec_invoicedetl.bonus_qty = 0 
				LET l_rec_invoicedetl.ext_bonus_amt = 0 
				LET l_rec_invoicedetl.ext_stats_amt = 0 
				LET l_rec_invoicedetl.prodgrp_code = NULL 
				LET l_rec_invoicedetl.maingrp_code = NULL 
				LET l_rec_invoicedetl.list_price_amt = 0 
				LET l_rec_invoicedetl.price_uom_code = NULL 
				LET l_rec_invoicedetl.return_qty = 0 
				LET l_rec_invoicedetl.km_qty = 0 
				LET l_rec_invoicedetl.proddept_code = NULL 

				#INSERT invoiceDetl Record
				IF db_invoicedetl_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicedetl.*) THEN
					INSERT INTO invoicedetl VALUES (l_rec_invoicedetl.*)		
				ELSE
					DISPLAY l_rec_invoicedetl.*
					CALL fgl_winmessage("Error","Could not insert new invoiceDetl record","ERROR")
				END IF 

				#--------------------------------
				# Insert invoicehead
				#
				LET l_err_message = "AS8 - Customer Update Inv" 
				LET l_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_invoicehead.cust_code = modu_rec_customer.cust_code 
				LET l_rec_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
				LET l_rec_invoicehead.entry_date = today 
				LET l_rec_invoicehead.sale_code = modu_rec_customer.sale_code 
				LET l_rec_invoicehead.term_code = modu_rec_customer.term_code 
				LET l_rec_invoicehead.disc_per = 0 
				LET l_rec_invoicehead.tax_code = modu_rec_customer.tax_code 
				LET l_rec_invoicehead.tax_per = 0 
				LET l_rec_invoicehead.goods_amt = l_rec_invoicehead.total_amt 
				LET l_rec_invoicehead.hand_amt = 0 
				LET l_rec_invoicehead.hand_tax_amt = 0 
				LET l_rec_invoicehead.freight_amt = 0 
				CALL get_due_and_discount_date(l_rec_term.*, l_rec_invoicehead.inv_date) 
				RETURNING l_rec_invoicehead.due_date, l_rec_invoicehead.disc_date 
				LET l_rec_invoicehead.freight_tax_amt = 0 
				LET l_rec_invoicehead.tax_amt = 0 
				LET l_rec_invoicehead.disc_amt = 0 
				LET l_rec_invoicehead.cost_amt = 0 
				LET l_rec_invoicehead.paid_amt = 0 
				LET l_rec_invoicehead.paid_date = NULL 
				LET l_rec_invoicehead.disc_taken_amt = 0 
				LET l_rec_invoicehead.disc_date = l_rec_invoicehead.inv_date 
				LET l_rec_invoicehead.expected_date = NULL 
				LET l_rec_invoicehead.on_state_flag = "N" 
				LET l_rec_invoicehead.posted_flag = "N" 
				LET l_rec_invoicehead.seq_num = 0 
				LET l_rec_invoicehead.line_num = 1 
				LET l_rec_invoicehead.printed_num = 0 
				LET l_rec_invoicehead.rev_num = 0 
				LET l_rec_invoicehead.rev_date = today 
				LET l_rec_invoicehead.com1_text = modu_aging.com1_text 
				LET l_rec_invoicehead.com2_text = modu_aging.com2_text 
				LET l_rec_invoicehead.year_num = modu_aging.year_num 
				LET l_rec_invoicehead.period_num = modu_aging.period_num 
				LET l_rec_invoicehead.ship_code = modu_rec_customer.cust_code 
				LET l_rec_invoicehead.name_text = modu_rec_customer.name_text 
				LET l_rec_invoicehead.addr1_text = modu_rec_customer.addr1_text 
				LET l_rec_invoicehead.addr2_text = modu_rec_customer.addr2_text 
				LET l_rec_invoicehead.city_text = modu_rec_customer.city_text 
				LET l_rec_invoicehead.state_code = modu_rec_customer.state_code 
				LET l_rec_invoicehead.post_code = modu_rec_customer.post_code 
				LET l_rec_invoicehead.country_code = modu_rec_customer.country_code --@db-patch_2020_10_04--
				LET l_rec_invoicehead.ship_date = today 
				LET l_rec_invoicehead.currency_code = modu_rec_customer.currency_code 
				LET l_rec_invoicehead.inv_ind = "9" 
				LET l_rec_invoicehead.prev_paid_amt = 0 
				LET l_rec_invoicehead.invoice_to_ind = modu_rec_customer.invoice_to_ind 
				LET l_rec_invoicehead.territory_code = modu_rec_customer.territory_code 
				LET l_rec_invoicehead.jour_num = NULL 
				LET l_rec_invoicehead.post_date = NULL 
				LET l_rec_invoicehead.stat_date = NULL

				#INSERT invoicehead Record
				IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicehead.*) THEN
					INSERT INTO invoicehead VALUES (l_rec_invoicehead.*)			
				ELSE
					DISPLAY l_rec_invoicehead.*
					CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
				END IF 

				#---------------------------------------
				# Insert araudit record
				
				LET l_err_message = "AS8 - AR Audit Row Insert" 
				LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_araudit.tran_date = l_rec_invoicehead.inv_date 
				LET l_rec_araudit.cust_code = l_rec_invoicehead.cust_code 
				LET l_rec_araudit.seq_num = modu_rec_customer.next_seq_num + 1 
				LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
				LET l_rec_araudit.source_num = l_rec_invoicehead.inv_num 
				LET l_rec_araudit.tran_text = modu_aging.line_text 
				LET l_rec_araudit.tran_amt = l_rec_invoicehead.total_amt 
				LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
				LET l_rec_araudit.sales_code = modu_rec_customer.sale_code 
				LET l_rec_araudit.year_num = l_rec_invoicehead.year_num 
				LET l_rec_araudit.period_num = l_rec_invoicehead.period_num 
				LET l_rec_araudit.bal_amt = modu_rec_customer.bal_amt 
				+ l_rec_invoicehead.total_amt 
				LET l_rec_araudit.currency_code = modu_rec_customer.currency_code 
				LET l_rec_araudit.conv_qty = l_rec_invoicehead.conv_qty 
				LET l_rec_araudit.entry_date = today 
				INSERT INTO araudit VALUES (l_rec_araudit.*) 
				##
				##  Update customer
				##
				LET l_err_message = "AS8 - Update customer" 
				LET modu_rec_customer.next_seq_num = modu_rec_customer.next_seq_num + 1 
				LET modu_rec_customer.bal_amt = modu_rec_customer.bal_amt	+ l_rec_invoicehead.total_amt 
				LET modu_rec_customer.curr_amt = modu_rec_customer.curr_amt	+ l_rec_invoicehead.total_amt 
				LET modu_rec_customer.cred_bal_amt = modu_rec_customer.cred_limit_amt	- modu_rec_customer.bal_amt 
				LET modu_rec_customer.last_inv_date = l_rec_invoicehead.inv_date 
				LET l_err_message = "AS8 - Customer Balance Update" 
				
				UPDATE customer 
				SET bal_amt = modu_rec_customer.bal_amt, 
				curr_amt = modu_rec_customer.curr_amt, 
				cred_bal_amt = modu_rec_customer.cred_bal_amt, 
				last_inv_date = modu_rec_customer.last_inv_date, 
				next_seq_num = modu_rec_customer.next_seq_num 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = modu_rec_customer.cust_code 
			
			COMMIT WORK 
			
			LET l_err_message = NULL 
			#---------------------------------------------------------
			OUTPUT TO REPORT AS8_rpt_list(l_rpt_idx,modu_rec_customer.*,l_rec_invoicehead.*,l_err_message)  
			IF NOT rpt_int_flag_handler2("Customer:",modu_rec_customer.cust_code, modu_rec_customer.name_text,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

			WHENEVER ERROR stop
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
		END IF 
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT AS8_rpt_list
	CALL rpt_finish("AS8_rpt_list")
	#------------------------------------------------------------
	  	 
	WHENEVER ERROR CONTINUE 

	## Locking recovery IS disabled FOR this UPDATE
	UPDATE arparmext 
	SET last_int_date = modu_aging.age_date 
	WHERE arparmext.cmpy_code = glob_rec_kandoouser.cmpy_code 
	WHENEVER ERROR stop 
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	IF l_err_cnt THEN 
		ERROR kandoomsg2("A",7073,l_err_cnt) 
		#7035 "Service Fee Generation Completed, Errors Encounted - Refer Report"
	ELSE 
		MESSAGE kandoomsg2("A",7072,l_err_cnt) 
		#7034 Service Fee Generation Completed Successfully "
	END IF 
END FUNCTION 



##############################################################################
# FUNCTION AS8_age_cust_bal(p_dayslate_num,p_overdue_amt)
#
#
##############################################################################
FUNCTION AS8_age_cust_bal(p_dayslate_num,p_overdue_amt) 
	DEFINE p_dayslate_num INTEGER 
	DEFINE p_overdue_amt LIKE customer.bal_amt 

	LET modu_rec_customer.bal_amt = modu_rec_customer.bal_amt + p_overdue_amt 
	
	CASE 
		WHEN p_dayslate_num > 90 
			LET modu_rec_customer.over90_amt = modu_rec_customer.over90_amt + p_overdue_amt 
		WHEN p_dayslate_num > 60 
			LET modu_rec_customer.over60_amt = modu_rec_customer.over60_amt + p_overdue_amt 
		WHEN p_dayslate_num > 30 
			LET modu_rec_customer.over30_amt = modu_rec_customer.over30_amt + p_overdue_amt 
		WHEN p_dayslate_num > 0 
			LET modu_rec_customer.over1_amt = modu_rec_customer.over1_amt + p_overdue_amt 
		OTHERWISE 
			LET modu_rec_customer.curr_amt = modu_rec_customer.curr_amt + p_overdue_amt 
	END CASE 
END FUNCTION 


##############################################################################
# REPORT AS8_rpt_list(p_rec_customer,p_rec_invoicehead,p_err)
#
#
##############################################################################
REPORT AS8_rpt_list(p_rpt_idx,p_rec_customer,p_rec_invoicehead,p_err) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_err CHAR(80) 
	DEFINE p_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE p_rec_customer RECORD LIKE customer.* 
	DEFINE l_line1 CHAR(80) 
	DEFINE l_offset1 SMALLINT 
	DEFINE l_offset2 SMALLINT 

	OUTPUT 
--	PAGE length 66 
--	left margin 0 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 1,"Code", 
			COLUMN 10,"Name" 
			PRINT COLUMN 10,"Invoice", 
			COLUMN 22,"Service Charge", 
			COLUMN 45,"Balance", 
			COLUMN 60,"Current", 
			COLUMN 75,"1 TO 30", 
			COLUMN 90,"31 TO 60", 
			COLUMN 105,"61 TO 90", 
			COLUMN 120,"90 + days" 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
 
		ON EVERY ROW 
			PRINT COLUMN 1,p_rec_customer.cust_code, 
			COLUMN 10,p_rec_customer.name_text 
			IF p_err IS NOT NULL THEN 
				PRINT COLUMN 40,p_rec_customer.bal_amt USING "---,---,--$.&&", 
				COLUMN 55,p_rec_customer.curr_amt USING "---,---,--$.&&", 
				COLUMN 70,p_rec_customer.over1_amt USING "---,---,--$.&&", 
				COLUMN 85,p_rec_customer.over30_amt USING "---,---,--$.&&", 
				COLUMN 100,p_rec_customer.over60_amt USING "---,---,--$.&&", 
				COLUMN 115,p_rec_customer.over90_amt USING "---,---,--$.&&", 
				COLUMN 130,p_rec_customer.currency_code 
				PRINT COLUMN 1,"***** Errors Encountered *****",p_err 
			ELSE 
				PRINT COLUMN 10,p_rec_invoicehead.inv_num USING "########", 
				COLUMN 22,p_rec_invoicehead.total_amt USING "-,---,--$.&&", 
				COLUMN 40,p_rec_customer.bal_amt USING "---,---,--$.&&", 
				COLUMN 55,p_rec_customer.curr_amt USING "---,---,--$.&&", 
				COLUMN 70,p_rec_customer.over1_amt USING "---,---,--$.&&", 
				COLUMN 85,p_rec_customer.over30_amt USING "---,---,--$.&&", 
				COLUMN 100,p_rec_customer.over60_amt USING "---,---,--$.&&", 
				COLUMN 115,p_rec_customer.over90_amt USING "---,---,--$.&&", 
				COLUMN 130,p_rec_customer.currency_code 
			END IF 
		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 1,"Totals in ",glob_rec_glparms.base_currency_code 
			PRINT COLUMN 22,"------------", 
			COLUMN 40,"--------------", 
			COLUMN 55,"--------------", 
			COLUMN 70,"--------------", 
			COLUMN 85,"--------------", 
			COLUMN 100,"--------------", 
			COLUMN 115,"-------------- ---" 
			PRINT COLUMN 22,sum(p_rec_invoicehead.total_amt/p_rec_invoicehead.conv_qty) 
			USING "-,---,--$.&&", 
			COLUMN 40,sum(p_rec_customer.bal_amt/p_rec_invoicehead.conv_qty) 
			USING "---,---,--$.&&", 
			COLUMN 55,sum(p_rec_customer.curr_amt/p_rec_invoicehead.conv_qty) 
			USING "---,---,--$.&&", 
			COLUMN 70,sum(p_rec_customer.over1_amt/p_rec_invoicehead.conv_qty) 
			USING "---,---,--$.&&", 
			COLUMN 85,sum(p_rec_customer.over30_amt/p_rec_invoicehead.conv_qty) 
			USING "---,---,--$.&&", 
			COLUMN 100,sum(p_rec_customer.over60_amt/p_rec_invoicehead.conv_qty) 
			USING "---,---,--$.&&", 
			COLUMN 115,sum(p_rec_customer.over90_amt/p_rec_invoicehead.conv_qty) 
			USING "---,---,--$.&&", 
			COLUMN 130,glob_rec_glparms.base_currency_code 
			SKIP 4 LINES 
			PRINT COLUMN 1,"Service Fee Criteria:", 
			COLUMN 40,"Service Fee",modu_aging.service_fee USING "--,--$.##" 
			PRINT COLUMN 40,"Current > ",modu_aging.current_amt USING "-,---,---.##", 
			COLUMN 57," %",modu_aging.current_per USING "###.##" 
			PRINT COLUMN 40,"1 TO 30 > ",modu_aging.over1_amt USING "-,---,---.##", 
			COLUMN 57," %",modu_aging.over1_per USING "###.##" 
			PRINT COLUMN 40,"31 TO 60> ",modu_aging.over30_amt USING "-,---,---.##", 
			COLUMN 57," %",modu_aging.over30_per USING "###.##" 
			PRINT COLUMN 40,"61 TO 90> ",modu_aging.over60_amt USING "-,---,---.##", 
			COLUMN 57," %",modu_aging.over60_per USING "###.##" 
			PRINT COLUMN 40,"90 + > ",modu_aging.over90_amt USING "-,---,---.##", 
			COLUMN 57," %",modu_aging.over90_per USING "###.##" 
			SKIP 2 LINES 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 


##############################################################################
# FUNCTION AS8_init_globals()
#
#
##############################################################################
FUNCTION AS8_init_globals()
 
	LET modu_aging.age_date = today 
	LET modu_aging.service_fee = 0 
	LET modu_aging.over1_amt = NULL 
	LET modu_aging.over30_amt = NULL 
	LET modu_aging.over30_amt = NULL 
	LET modu_aging.over90_amt = NULL 
	LET modu_aging.current_per = NULL 
	LET modu_aging.over1_per = NULL 
	LET modu_aging.over30_per = NULL 
	LET modu_aging.over30_per = NULL 
	LET modu_aging.over90_per = NULL 
	LET modu_aging.inv_date = today 
	LET modu_aging.line_text = "Service Fee" 
	LET modu_aging.int_acct_code = modu_rec_arparmext.int_acct_code 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, modu_aging.age_date) 
	RETURNING modu_aging.year_num, 
	modu_aging.period_num 
	DISPLAY BY NAME modu_aging.*, 
	modu_rec_arparmext.last_int_date, 
	glob_rec_arparms.cust_age_date 

END FUNCTION 