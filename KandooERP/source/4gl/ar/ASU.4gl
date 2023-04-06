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

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/AS_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/ASU_GLOBALS.4gl" 

###########################################################################
# Module Scope Variables
###########################################################################
DEFINE modu_year_num SMALLINT 
DEFINE modu_period_num SMALLINT 
DEFINE modu_ret_year SMALLINT 
DEFINE modu_time_char CHAR(8) 
DEFINE modu_date_stop DATE 
DEFINE modu_err_counter INTEGER 
DEFINE modu_rpt_total INTEGER 
DEFINE modu_counter INTEGER 

###########################################################################
# FUNCTION ASU_main()
#
# AR transaction purge program.
# NOTE: 2 reports are generated - for successful and exceptions
###########################################################################
FUNCTION ASU_main()
	DEFER QUIT 
	DEFER INTERRUPT 

	CALL setModuleId("ASU") 

	CREATE temp TABLE t_summary (
		summary_type CHAR(2), 
		inv_num INTEGER, 
		pay_amt DECIMAL(16,4), 
		ref_num INTEGER, 
		pay_type_ind CHAR(2) 
	) 
	
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW A679 with FORM "A679" 
			CALL windecoration_a("A679")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Purge AR Transactions" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","ASU","menu-purge-ar-transaction") 
					CALL rpt_rmsreps_reset(NULL)
					CALL ASU_rpt_process(ASU_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "REPORT" #COMMAND "Run" " Enter selection criteria AND begin purge" 
					CALL rpt_rmsreps_reset(NULL)
					CALL ASU_rpt_process(ASU_rpt_query())

				ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" " Print purge reports"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E") "Exit" " RETURN TO Menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW A679 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL ASU_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW A679 with FORM "A679" 
			CALL windecoration_a("A679") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(ASU_rpt_query()) #save where clause in env 
			CLOSE WINDOW A679 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL ASU_rpt_process(get_url_sel_text())
	END CASE 	

END FUNCTION 
####################################################################
# END FUNCTION ASU_main()
####################################################################


####################################################################
# FUNCTION ASU_rpt_query()
# 3 sections input, construct and input
# RETURN r_where_text
####################################################################
FUNCTION ASU_rpt_query() 
	DEFINE r_where_text STRING 
	DEFINE l_backup_flag CHAR(1) 
	DEFINE l_update_flag CHAR(1) 
	DEFINE l_user_flag CHAR(1) 
	DEFINE l_auth_flag CHAR(1) 
	DEFINE l_time_stop SMALLINT 
	DEFINE l_time_char5 CHAR(5) 

	LET modu_rpt_total = 0 
	LET modu_ret_year = NULL 
	LET modu_time_char = NULL 
	LET modu_date_stop = TODAY + 1 

	LET l_time_stop = 0600 
	CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,TODAY) 
	RETURNING modu_year_num, modu_period_num 

	MESSAGE " Enter details; OK to continue."

	CLEAR FORM 
	DIALOG ATTRIBUTES(UNBUFFERED)

		INPUT 
		modu_ret_year, 
		modu_date_stop, 
		l_time_stop WITHOUT DEFAULTS
		FROM
		ret_year, 
		date_stop, 
		time_stop

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","ISU","input-pr_ret_year-1") -- albo kd-505 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "WEB-HELP" -- albo kd-372 
				CALL onlinehelp(getmoduleid(),null) 

			AFTER FIELD ret_year 
				IF modu_ret_year IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD ret_year 
				END IF 
				IF modu_ret_year > modu_year_num THEN 
					ERROR kandoomsg2("U",9046,modu_year_num) 
					#9046 Value must be less than OR equal TO ????
					NEXT FIELD ret_year 
				END IF 
				IF modu_ret_year < 1988 THEN 
					ERROR kandoomsg2("G",9529,"1987") 
					#9529 Year entered must be greater THEN 1987
					NEXT FIELD ret_year
				END IF
				IF modu_year_num = modu_ret_year THEN 
					MESSAGE kandoomsg2("I",6001,"") 
					#6001 Less than a years worth of prodledg will be left
				END IF 

			AFTER FIELD date_stop 
				IF modu_date_stop IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD date_stop 
				END IF 
				IF modu_date_stop < TODAY THEN 
					ERROR kandoomsg2("U",9907,TODAY) 
					#9907 Value must be greater than OR equal TO TODAY
					NEXT FIELD date_stop 
				END IF 

			AFTER FIELD time_stop 
				IF l_time_stop IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD time_stop 
				END IF 
				IF l_time_stop < 0 THEN 
					LET l_time_stop = -l_time_stop
				END IF 
				IF l_time_stop > 2400 THEN 
					ERROR kandoomsg2("W",9449,"") 
					#9449 Time IS NOT in 24 hour FORMAT.
					NEXT FIELD time_stop 
				ELSE
					IF l_time_stop = 2400 THEN
						LET l_time_stop = 2359
					END IF				
				END IF 
				LET modu_time_char = l_time_stop USING "&&&&" 
				IF modu_time_char[3,4] > 59 THEN 
					ERROR kandoomsg2("W",9449,"") 
					#9449 Time IS NOT in 24 hour FORMAT.
					NEXT FIELD time_stop 
				END IF 
				LET modu_time_char = modu_time_char[1,2],":",modu_time_char[3,4],":00" 
				IF modu_time_char < TIME 
				AND modu_date_stop = TODAY THEN 
					LET l_time_char5 = TIME 
					ERROR kandoomsg2("U",9907,l_time_char5) 
					#9907 Value must be greater than OR equal TO current TIME
					NEXT FIELD time_stop 
				END IF 

			AFTER INPUT 
				IF int_flag = 0 AND quit_flag = 0 THEN 
					IF modu_ret_year IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD ret_year 
					END IF 
					IF modu_date_stop IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD date_stop 
					END IF 
					IF l_time_stop IS NULL THEN 
						ERROR kandoomsg2("U",9102,"") 
						#9102 Value must be entered
						NEXT FIELD time_stop 
					END IF 
					LET modu_time_char = l_time_stop USING "&&&&" 
					IF modu_time_char[3,4] > 59 THEN 
						ERROR kandoomsg2("W",9449,"") 
						#9449 Time IS NOT in 24 hour FORMAT.
						NEXT FIELD time_stop 
					END IF 
					LET modu_time_char = modu_time_char[1,2],":",modu_time_char[3,4],":00" 
					IF modu_time_char < TIME 
					AND modu_date_stop = TODAY THEN 
						LET l_time_char5 = TIME 
						ERROR kandoomsg2("U",9907,l_time_char5) 
						#9907 Value must be greater than OR equal TO current TIME
						NEXT FIELD time_stop 
					END IF
				END IF 

		END INPUT 

		CONSTRUCT BY NAME r_where_text ON 
		customer.cust_code, 
		customer.name_text, 
		customer.type_code, 
		customer.term_code, 
		customer.tax_code, 
		customer.currency_code 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","ASU","construct-customer") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null)
				 
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		ON ACTION "WEB-HELP" -- albo kd-372 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "ACCEPT" 
			ACCEPT DIALOG
			
		ON ACTION "CANCEL" 
			EXIT DIALOG

	END DIALOG

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 

	OPEN WINDOW A680 with FORM "A680" 
	CALL windecoration_a("A680") 
	MESSAGE kandoomsg2("U",1020,"Confirmation") #1020 Enter Confirmation Details
	INPUT  
	l_backup_flag, 
	l_update_flag, 
	l_user_flag, 
	l_auth_flag 
	FROM
	backup_flag, 
	update_flag, 
	user_flag, 
	auth_flag 		

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","ASU","inp-confirmation") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER INPUT
			IF int_flag = 0 AND quit_flag = 0 THEN 
				IF l_backup_flag IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD backup_flag 
				END IF 
				IF l_update_flag IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD update_flag 
				END IF 
				IF l_user_flag IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD user_flag 
				END IF 
				IF l_auth_flag IS NULL THEN 
					ERROR kandoomsg2("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD auth_flag 
				END IF 
			END IF

	END INPUT 
	CLOSE WINDOW A680

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL 
	END IF 
		
	IF l_backup_flag = "N" 
	OR l_update_flag = "Y" 
	OR l_user_flag = "N" 
	OR l_auth_flag = "N" THEN 
		CALL msgcontinue("","Please re-run this program after you have completed all the steps and  have the authority to run the purge.")
		#LET l_msgresp = kandoomsg("U",7008,"")	
		#7008 Complete Steps AND Get Authority THEN rerun program.
		EXIT PROGRAM 
	ELSE
		LET glob_rec_rpt_selector.ref1_code = modu_ret_year 
		LET glob_rec_rpt_selector.ref1_date = modu_date_stop 
		LET glob_rec_rpt_selector.ref2_code = modu_time_char 
		RETURN r_where_text	
	END IF 

END FUNCTION 
####################################################################
# FUNCTION ASU_rpt_query()
####################################################################


####################################################################
# FUNCTION ASU_rpt_process(p_where_text) 
#
#
####################################################################
FUNCTION ASU_rpt_process(p_where_text) 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx_1 SMALLINT
	DEFINE l_rpt_idx_2 SMALLINT
	DEFINE l_rec_rpt_info RECORD 
		invhead INTEGER, 
		invdetl INTEGER, 
		invrates INTEGER, 
		credhead INTEGER, 
		creddetl INTEGER, 
		creditrates INTEGER, 
		cashrcpt INTEGER, 
		araudit INTEGER, 
		invoicepay INTEGER, 
		invheadext INTEGER, 
		credheadaddr INTEGER, 
		creditheadext INTEGER, 
		summ_invc INTEGER, 
		summ_cred INTEGER, 
		summ_cash INTEGER 
	END RECORD 
	DEFINE l_msg CHAR(70)
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE l_time CHAR(15) 
	DEFINE l_reason CHAR(60) 
	DEFINE l_pay_amt LIKE invoicepay.pay_amt 
	DEFINE l_error_ind SMALLINT 
	DEFINE l_no_records SMALLINT 
	DEFINE l_del_pay SMALLINT 
	DEFINE l_interrupt SMALLINT 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	#------------------------------------------------------------
	#Report for success
	LET l_rpt_idx_1 = rpt_start(getmoduleid(),"ASU_rpt_list",p_where_text,RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx_1 = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	# Report for exceptions
	LET l_rpt_idx_2 = rpt_start(trim(getmoduleid())||".","ASU_rpt_list_purge_exception",p_where_text,RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx_2 = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT ASU_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx_1)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].report_width_num

	START REPORT ASU_rpt_list_purge_exception TO rpt_get_report_file_with_path2(l_rpt_idx_2)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx_2].report_width_num
	#------------------------------------------------------------

	LET modu_ret_year = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].ref1_code
	LET modu_date_stop = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].ref1_date 
	LET modu_time_char = glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].ref2_code 

	LET modu_rpt_total = 0 
	
	LET l_query_text = 
	"SELECT * FROM customer ", 
	" WHERE customer.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND ",p_where_text CLIPPED," ",
	"ORDER BY customer.cust_code" 
 
	PREPARE s_customer FROM l_query_text 
	DECLARE c_customer CURSOR WITH HOLD FOR s_customer 

	LET l_msg = "AR Transaction Purge started by ",glob_rec_kandoouser.sign_on_code 
	CALL errorlog(l_msg) 
	LET modu_counter = 0 
	LET modu_err_counter = 0 
	LET l_interrupt = false 

	WHENEVER ERROR GOTO recovery 
	
	FOREACH c_customer INTO l_rec_customer.* 
		#--------------------
		DELETE FROM t_summary 
		WHERE 1=1 
		
		INITIALIZE l_rec_rpt_info.* TO NULL 

		LET l_rec_rpt_info.invhead = 0 
		LET l_rec_rpt_info.invdetl = 0 
		LET l_rec_rpt_info.invrates = 0 
		LET l_rec_rpt_info.credhead = 0 
		LET l_rec_rpt_info.creddetl = 0 
		LET l_rec_rpt_info.creditrates = 0 
		LET l_rec_rpt_info.cashrcpt = 0 
		LET l_rec_rpt_info.araudit = 0 
		LET l_rec_rpt_info.invoicepay = 0 
		LET l_rec_rpt_info.invheadext = 0 
		LET l_rec_rpt_info.credheadaddr = 0 
		LET l_rec_rpt_info.creditheadext = 0 
		LET l_time = time 

		IF modu_time_char <= l_time	AND modu_date_stop <= TODAY THEN 
			LET l_msg = "Purge terminated by time limit. Customers Processed: ", 
			modu_counter USING "<<<<<<&", " Errors: ", 
			modu_err_counter USING "<<<<<<&" 
			LET l_interrupt = 1 
			EXIT FOREACH 
		END IF 
		IF NOT rpt_int_flag_handler2("Customer:",l_rec_customer.cust_code,l_rec_customer.name_text,l_rpt_idx_1) THEN
			EXIT FOREACH 
		END IF 

		LET l_no_records = true 

		SELECT unique 1 FROM invoicehead 
		WHERE invoicehead.cust_code = l_rec_customer.cust_code 
		AND invoicehead.year_num < modu_ret_year 
		AND invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status != NOTFOUND THEN 
			LET l_no_records = false 
		END IF 

		SELECT unique 1 FROM credithead 
		WHERE credithead.cust_code = l_rec_customer.cust_code 
		AND credithead.year_num < modu_ret_year 
		AND credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status != NOTFOUND THEN 
			LET l_no_records = false 
		END IF 

		SELECT unique 1 FROM cashreceipt 
		WHERE cashreceipt.cust_code = l_rec_customer.cust_code 
		AND cashreceipt.year_num < modu_ret_year 
		AND cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF status != NOTFOUND THEN 
			LET l_no_records = false 
		END IF 

		IF l_no_records THEN 
			CONTINUE FOREACH 
		END IF 
		GOTO bypass 
		LABEL recovery: 

		CASE 
			WHEN status = -107 {record IS locked} 
				OR status = -113 {the file IS locked} 
				OR status = -115 {cannot CREATE LOCK file} 
				OR status = -134 {no more locks} 
				OR status = -143 {deadlock detected} 
				OR status = -144 {key value locked} 
				OR status = -154 {deadlock timeout expired} 
				OR status = -78 {deadlock situation detected/avoided} 
				OR status = -79 {no RECORD locks available} 
				OR status = -233 {record loced BY another user} 
				OR status = -250 {cannot read RECORD FROM file FOR update} 
				OR status = -263 {cannot LOCK ROW FOR update} 
				OR status = -288 {table NOT locked BY CURRENT user} 
				OR status = -289 {cannot LOCK TABLE in requested mode} 
				OR status = -291 {cannot change LOCK MODE OF table} 
				OR status = -327 {cannot UNLOCK TABLE within a transaction.} 
				OR status = -378 {record currently locked BY another user.} 
				OR status = -503 {too many tables locked.} 
				OR status = -504 {cannot LOCK a view.} 
				OR status = -521 {cannot LOCK system catalog.} 
				OR status = -563 {cannot acquire ex LOCK FOR db conversion} 
				OR status = -621 {unable TO UPDATE new LOCK level.} 
				OR status = -3011 {a TABLE IS locked no reading OR writing} 
				OR status = -3460 {this ROW has been locked BY another user} 

				LET l_msg = "Database Lock Error. Rows Deleted: ",	modu_counter USING "<<<<<<&", " Errors: ",	modu_err_counter USING "<<<<<<&" 
				LET l_interrupt = 3 
				EXIT FOREACH 
				
			WHEN status = -104 
				LET l_msg = "Too many files OPEN under unix. Rows Deleted: ",	modu_counter USING "<<<<<<&", " Errors: ",	modu_err_counter USING "<<<<<<&" 
				LET l_interrupt = 3 
				EXIT FOREACH 
				
			WHEN status = -349 
				OR status = -457 
				LET l_msg = "Informix Online Terminated. Rows Deleted: ",	modu_counter USING "<<<<<<&", " Errors: ",	modu_err_counter USING "<<<<<<&" 
				LET l_interrupt = 3 
				EXIT FOREACH 
				
			OTHERWISE 
				LET l_reason = "Database Error Occured. Status: ",STATUS
				
				#---------------------------------------------------------
				OUTPUT TO REPORT ASU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_customer.cust_code,l_reason) 
				#--------------------------------------------------------- 
				
				ROLLBACK WORK 
				CONTINUE FOREACH 
		END CASE
		 
		LABEL bypass: 
		BEGIN WORK 
			EXECUTE IMMEDIATE "SET CONSTRAINTS ALL DEFERRED"
			LOCK TABLE invoicehead in exclusive MODE 
			LOCK TABLE invoicedetl in exclusive MODE 
			LOCK TABLE invrates in exclusive MODE 
			LOCK TABLE credithead in exclusive MODE 
			LOCK TABLE creditdetl in exclusive MODE 
			LOCK TABLE creditrates in exclusive MODE 
			LOCK TABLE cashreceipt in exclusive MODE 
			LOCK TABLE araudit in exclusive MODE 
			LOCK TABLE invoicepay in exclusive MODE 
			LOCK TABLE customer in exclusive MODE 
			LOCK TABLE period in exclusive MODE 

			##################### INVOICES  INVOICES INVOICES #######################

			DECLARE c_invoicehead CURSOR FOR 
			SELECT * FROM invoicehead 
			WHERE invoicehead.cust_code = l_rec_customer.cust_code 
			AND invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND invoicehead.year_num < modu_ret_year 
			
			DECLARE c_invoicepay CURSOR FOR 
			SELECT * FROM invoicepay 
			WHERE invoicepay.cust_code = l_rec_customer.cust_code 
			AND invoicepay.inv_num = glob_rec_invoicehead.inv_num 
			AND invoicepay.cmpy_code = glob_rec_kandoouser.cmpy_code 
			
			LET l_error_ind = 0 
			
			FOREACH c_invoicehead INTO glob_rec_invoicehead.* 
				IF modu_time_char <= l_time	AND modu_date_stop <= TODAY THEN 
					LET l_msg = "Purge terminated by time limit. ",		"Customers Processed: ",	modu_counter USING "<<<<<<&", " Errors: ",	modu_err_counter USING "<<<<<<&" 
					LET l_interrupt = 1 
					LET l_error_ind = 2 
					ROLLBACK WORK 
					EXIT FOREACH 
				END IF 
				
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET l_msg = "Purge terminated by CANCEL key. ",	"Customers Processed: ",	modu_counter USING "<<<<<<&", " Errors: ", modu_err_counter USING "<<<<<<&" 
					LET l_interrupt = 2 
					LET l_error_ind = 2 
					ROLLBACK WORK 
					EXIT FOREACH 
				END IF 
				
				IF glob_rec_invoicehead.total_amt != glob_rec_invoicehead.paid_amt THEN 
					LET l_reason = "Open invoices exist FOR the purge period." 
				
					#---------------------------------------------------------
					OUTPUT TO REPORT ASU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_customer.cust_code,l_reason) 
					#--------------------------------------------------------- 
				
					ROLLBACK WORK 
				
					LET l_error_ind = 1 
					EXIT FOREACH 
				END IF 
				
				IF glob_rec_invoicehead.total_amt IS NULL	OR glob_rec_invoicehead.paid_amt IS NULL	OR glob_rec_invoicehead.period_num IS NULL THEN 
					LET l_reason = "Null value in total, paid OR period " 
					
					#---------------------------------------------------------
					OUTPUT TO REPORT ASU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_customer.cust_code,l_reason) 
					#--------------------------------------------------------- 
					
					ROLLBACK WORK 
					LET l_error_ind = 1 
					EXIT FOREACH 
				END IF 
				
				IF glob_rec_invoicehead.posted_flag != "Y" THEN 
					LET l_reason = "Unposted invoices exist FOR the purge period." 
					
					#---------------------------------------------------------
					OUTPUT TO REPORT ASU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_customer.cust_code,l_reason) 
					#---------------------------------------------------------
					
					ROLLBACK WORK 
					LET l_error_ind = 1 
					EXIT FOREACH 
				END IF 
				
				SELECT unique 1 FROM araudit 
				WHERE araudit.source_num = glob_rec_invoicehead.inv_num 
				AND araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
				AND araudit.cust_code = l_rec_customer.cust_code 
				AND araudit.year_num >= modu_ret_year 
				AND araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status != NOTFOUND THEN 
					LET l_reason = "Outstanding araudits exist FOR the purge period." 
					
					#---------------------------------------------------------
					OUTPUT TO REPORT ASU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_customer.cust_code,l_reason) 
					#---------------------------------------------------------
					
					ROLLBACK WORK 
					LET l_error_ind = 1 
					EXIT FOREACH 
				END IF 
				
				FOREACH c_invoicepay INTO l_rec_invoicepay.* 
					LET l_del_pay = 1 
					IF l_rec_invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA THEN 
						SELECT * INTO l_rec_cashreceipt.* FROM cashreceipt 
						WHERE cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND cashreceipt.cash_num = l_rec_invoicepay.ref_num 
						IF l_rec_cashreceipt.year_num >= modu_ret_year THEN 
							LET l_del_pay = 0 
							LET l_pay_amt = l_rec_invoicepay.pay_amt + l_rec_invoicepay.disc_amt 
							
							INSERT INTO t_summary VALUES (
								TRAN_TYPE_INVOICE_IN, 
								l_rec_invoicepay.inv_num, 
								l_pay_amt, 
								l_rec_invoicepay.ref_num, 
								l_rec_invoicepay.pay_type_ind 
								) 
						END IF 
					ELSE 
						IF l_rec_invoicepay.pay_type_ind = TRAN_TYPE_CREDIT_CR THEN 
							SELECT * INTO l_rec_credithead.* FROM credithead 
							WHERE credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND credithead.cred_num = l_rec_invoicepay.ref_num 
							IF l_rec_credithead.year_num >= modu_ret_year THEN 
								LET l_del_pay = 0 
								LET l_pay_amt = l_rec_invoicepay.pay_amt + l_rec_invoicepay.disc_amt 
								INSERT INTO t_summary VALUES (
									TRAN_TYPE_INVOICE_IN, 
									l_rec_invoicepay.inv_num, 
									l_pay_amt, 
									l_rec_invoicepay.ref_num, 
									l_rec_invoicepay.pay_type_ind 
								) 
							END IF 
						END IF 
					END IF 
					
					IF l_del_pay THEN 
						DELETE FROM invoicepay 
						WHERE invoicepay.inv_num = l_rec_invoicepay.inv_num 
						AND invoicepay.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND invoicepay.ref_num = l_rec_invoicepay.ref_num 
						AND invoicepay.pay_type_ind = l_rec_invoicepay.pay_type_ind 
						AND invoicepay.cust_code = l_rec_customer.cust_code 

						LET l_rec_rpt_info.invoicepay = l_rec_rpt_info.invoicepay + 1 
					END IF 
				END FOREACH
				 
				DELETE FROM invoicedetl 
				WHERE invoicedetl.inv_num = glob_rec_invoicehead.inv_num 
				AND invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				
				LET l_rec_rpt_info.invdetl = l_rec_rpt_info.invdetl + sqlca.sqlerrd[3] 
				
				IF glob_rec_company.module_text[23] = "W" THEN 
					DELETE FROM invrates 
					WHERE invrates.inv_num = glob_rec_invoicehead.inv_num 
					AND invrates.cmpy_code = glob_rec_kandoouser.cmpy_code 

					LET l_rec_rpt_info.invrates = l_rec_rpt_info.invrates	+ sqlca.sqlerrd[3] 
				END IF 
				
				DELETE FROM invheadext 
				WHERE invheadext.inv_num = glob_rec_invoicehead.inv_num 
				AND invheadext.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND invheadext.cust_code = l_rec_customer.cust_code 
		
				LET l_rec_rpt_info.invheadext = l_rec_rpt_info.invheadext	+ sqlca.sqlerrd[3] 
				
				DELETE FROM araudit 
				WHERE araudit.source_num = glob_rec_invoicehead.inv_num 
				AND araudit.cust_code = l_rec_customer.cust_code 
				AND araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
				AND araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				
				LET l_rec_rpt_info.araudit = l_rec_rpt_info.araudit + sqlca.sqlerrd[3] 
				
				DELETE FROM invoicehead 
				WHERE invoicehead.inv_num = glob_rec_invoicehead.inv_num 
				AND invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_rpt_info.invhead = l_rec_rpt_info.invhead + 1 
			
			END FOREACH
			#-------------------------------------------------------------------
 
			IF l_error_ind = 1 THEN 
				CONTINUE FOREACH 
			ELSE 
				IF l_error_ind = 2 THEN 
					EXIT FOREACH 
				END IF 
			END IF 

			####################### CREDITS CREDITS CREDITS ########################

			INITIALIZE glob_rec_invoicehead.* TO NULL 
			INITIALIZE l_rec_invoicepay.* TO NULL 
			
			DECLARE c_credithead CURSOR FOR 
			SELECT * FROM credithead 
			WHERE credithead.cust_code = l_rec_customer.cust_code 
			AND credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND credithead.year_num < modu_ret_year 
			
			DECLARE c2_invoicepay CURSOR FOR 
			SELECT * FROM invoicepay 
			WHERE invoicepay.cust_code = l_rec_customer.cust_code 
			AND invoicepay.ref_num = l_rec_credithead.cred_num 
			AND invoicepay.pay_type_ind = TRAN_TYPE_CREDIT_CR 
			AND invoicepay.cmpy_code = glob_rec_kandoouser.cmpy_code 
			
			#-----------------------------------------------------
			FOREACH c_credithead INTO l_rec_credithead.* 
				IF modu_time_char <= l_time AND modu_date_stop <= TODAY THEN 
					LET l_msg = "Purge terminated by time limit. ",	"Customers Processed: ",	modu_counter USING "<<<<<<&", " Errors: ",	modu_err_counter USING "<<<<<<&" 
					LET l_interrupt = 1 
					LET l_error_ind = 2 

					ROLLBACK WORK 
					EXIT FOREACH 
				END IF 

				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET l_msg = "Purge terminated by CANCEL key. ",	"Customers Processed: ",	modu_counter USING "<<<<<<&", " Errors: ",	modu_err_counter USING "<<<<<<&" 
					LET l_interrupt = 2 
					LET l_error_ind = 2 
					
					ROLLBACK WORK 
					EXIT FOREACH 
				END IF
				 
				IF l_rec_credithead.total_amt != l_rec_credithead.appl_amt THEN 
					LET l_reason = "Open credits exist FOR the purge period." 
					
					#---------------------------------------------------------
					OUTPUT TO REPORT ASU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_customer.cust_code,l_reason) 
					#---------------------------------------------------------
					
					ROLLBACK WORK 
					LET l_error_ind = 1 
					EXIT FOREACH 
				END IF 
				
				IF l_rec_credithead.posted_flag != "Y" THEN 
					LET l_reason = "Unposted credits exist FOR the purge period." 
					#---------------------------------------------------------
					OUTPUT TO REPORT ASU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_customer.cust_code,l_reason) 
					#---------------------------------------------------------
					ROLLBACK WORK 
					LET l_error_ind = 1 
					EXIT FOREACH 
				END IF 
				
				SELECT unique 1 FROM araudit 
				WHERE araudit.source_num = l_rec_credithead.cred_num 
				AND araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
				AND araudit.cust_code = l_rec_customer.cust_code 
				AND araudit.year_num >= modu_ret_year 
				AND araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status != NOTFOUND THEN 
					LET l_reason = "Outstanding araudits exist FOR the purge period." 
					
					#---------------------------------------------------------
					OUTPUT TO REPORT ASU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_customer.cust_code,l_reason) 
					#---------------------------------------------------------
					
					ROLLBACK WORK 
					LET l_error_ind = 1 
					EXIT FOREACH 
				END IF 
				
				FOREACH c2_invoicepay INTO l_rec_invoicepay.* 
					LET l_del_pay = 1 
					INITIALIZE glob_rec_invoicehead.* TO NULL
					SELECT * INTO glob_rec_invoicehead.* FROM invoicehead 
					WHERE invoicehead.inv_num = l_rec_invoicepay.inv_num 
					AND invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
					
					IF glob_rec_invoicehead.year_num >= modu_ret_year THEN 
						LET l_pay_amt = l_rec_invoicepay.pay_amt + l_rec_invoicepay.disc_amt 
						INSERT INTO t_summary VALUES (
							TRAN_TYPE_CREDIT_CR, 
							l_rec_invoicepay.inv_num, 
							l_pay_amt, 
							l_rec_invoicepay.ref_num, 
							l_rec_invoicepay.pay_type_ind) 
					END IF 
				END FOREACH 
	
				DELETE FROM creditheadext 
				WHERE creditheadext.credit_num = l_rec_credithead.cred_num 
				AND creditheadext.cmpy_code = glob_rec_kandoouser.cmpy_code 

				LET l_rec_rpt_info.creditheadext = l_rec_rpt_info.creditheadext	+ sqlca.sqlerrd[3]
				 
				DELETE FROM credheadaddr 
				WHERE credheadaddr.cred_num = l_rec_credithead.cred_num 
				AND credheadaddr.cmpy_code = glob_rec_kandoouser.cmpy_code 
		
				LET l_rec_rpt_info.credheadaddr = l_rec_rpt_info.credheadaddr	+ sqlca.sqlerrd[3] 

				DELETE FROM creditdetl 
				WHERE creditdetl.cred_num = l_rec_credithead.cred_num 
				AND creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
				
				LET l_rec_rpt_info.creddetl = l_rec_rpt_info.creddetl + sqlca.sqlerrd[3] 
				
				IF glob_rec_company.module_text[23] = "W" THEN 
					DELETE FROM creditrates 
					WHERE creditrates.cred_num = l_rec_credithead.cred_num 
					AND creditrates.cmpy_code = glob_rec_kandoouser.cmpy_code 

					LET l_rec_rpt_info.creditrates = l_rec_rpt_info.creditrates 
					+ sqlca.sqlerrd[3] 
				END IF 
				
				DELETE FROM araudit 
				WHERE araudit.source_num = l_rec_credithead.cred_num 
				AND araudit.cust_code = l_rec_customer.cust_code 
				AND araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
				AND araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				
				LET l_rec_rpt_info.araudit = l_rec_rpt_info.araudit + sqlca.sqlerrd[3] 
				
				DELETE FROM credithead 
				WHERE credithead.cred_num = l_rec_credithead.cred_num 
				AND credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 

				LET l_rec_rpt_info.credhead = l_rec_rpt_info.credhead + 1 
			END FOREACH
			#----------------------------------------------
 
			IF l_error_ind = 1 THEN 
				CONTINUE FOREACH 
			ELSE 
				IF l_error_ind = 2 THEN 
					EXIT FOREACH 
				END IF 
			END IF 

			################# CASHRECEIPT  CASHRECEIPT CASHRECEIPT ##################

			INITIALIZE glob_rec_invoicehead.* TO NULL 
			INITIALIZE l_rec_invoicepay.* TO NULL 
			
			DECLARE c_cashreceipt CURSOR FOR 
			SELECT * FROM cashreceipt 
			WHERE cashreceipt.cust_code = l_rec_customer.cust_code 
			AND cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cashreceipt.year_num < modu_ret_year 
			
			DECLARE c3_invoicepay CURSOR FOR 
			SELECT * FROM invoicepay 
			WHERE invoicepay.cust_code = l_rec_customer.cust_code 
			AND invoicepay.ref_num = l_rec_cashreceipt.cash_num 
			AND invoicepay.pay_type_ind = TRAN_TYPE_RECEIPT_CA 
			AND invoicepay.cmpy_code = glob_rec_kandoouser.cmpy_code 
			
			FOREACH c_cashreceipt INTO l_rec_cashreceipt.* 
				IF modu_time_char <= l_time	AND modu_date_stop <= TODAY THEN 
					LET l_msg = "Purge terminated by time limit. ",	"Customers Processed: ",	modu_counter USING "<<<<<<&", " Errors: ",	modu_err_counter USING "<<<<<<&" 
					LET l_interrupt = 1 
					LET l_error_ind = 2 
					ROLLBACK WORK 
					EXIT FOREACH 
				END IF 
				
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET l_msg = "Purge terminated by CANCEL key. ",	"Customers Processed: ",	modu_counter USING "<<<<<<&", " Errors: ",	modu_err_counter USING "<<<<<<&" 
					LET l_interrupt = 2 
					LET l_error_ind = 2 
					ROLLBACK WORK 
					EXIT FOREACH 
				END IF 
				
				IF l_rec_cashreceipt.cash_amt != l_rec_cashreceipt.applied_amt THEN 
					LET l_reason = "Open receipts exist FOR the purge period." 
					
					#---------------------------------------------------------
					OUTPUT TO REPORT ASU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_customer.cust_code,l_reason) 
					#---------------------------------------------------------
					
					ROLLBACK WORK 
					LET l_error_ind = 1 
					EXIT FOREACH 
				END IF 
				
				IF l_rec_cashreceipt.posted_flag != CASHRECEIPT_POST_FLAG_STATUS_POSTED_Y THEN 
					LET l_reason = "Unposted receipts exist FOR the purge period." 
					
					#---------------------------------------------------------
					OUTPUT TO REPORT ASU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_customer.cust_code,l_reason) 
					#---------------------------------------------------------
					
					ROLLBACK WORK 
					LET l_error_ind = 1 
					EXIT FOREACH 
				END IF 
				IF l_rec_cashreceipt.banked_flag != "Y" THEN 
					LET l_reason = "Unbanked receipts exist FOR the purge period." 
					#---------------------------------------------------------
					OUTPUT TO REPORT ASU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_customer.cust_code,l_reason) 
					#---------------------------------------------------------
					ROLLBACK WORK 
					LET l_error_ind = 1 
					EXIT FOREACH 
				END IF 
				
				SELECT unique 1 FROM araudit 
				WHERE araudit.source_num = l_rec_cashreceipt.cash_num 
				AND araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
				AND araudit.cust_code = l_rec_customer.cust_code 
				AND araudit.year_num >= modu_ret_year 
				AND araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				
				IF status != NOTFOUND THEN 
					LET l_reason = "Outstanding araudits exist FOR the purge period." 
					
					#---------------------------------------------------------
					OUTPUT TO REPORT ASU_rpt_list_purge_exception(l_rpt_idx_2,l_rec_customer.cust_code,l_reason) 
					#---------------------------------------------------------
					
					ROLLBACK WORK 
					LET l_error_ind = 1 
					EXIT FOREACH 
				END IF 

				FOREACH c3_invoicepay INTO l_rec_invoicepay.*
					INITIALIZE glob_rec_invoicehead.* TO NULL
					SELECT * INTO glob_rec_invoicehead.* FROM invoicehead 
					WHERE invoicehead.inv_num = l_rec_invoicepay.inv_num 
					AND invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
					
					IF glob_rec_invoicehead.year_num >= modu_ret_year THEN 
						LET l_pay_amt = l_rec_invoicepay.pay_amt	+ l_rec_invoicepay.disc_amt 
						INSERT INTO t_summary VALUES (
							TRAN_TYPE_RECEIPT_CA, 
							l_rec_invoicepay.inv_num, 
							l_pay_amt, 
							l_rec_invoicepay.ref_num, 
							l_rec_invoicepay.pay_type_ind	) 
					END IF 
				END FOREACH 
				
				DELETE FROM araudit 
				WHERE araudit.source_num = l_rec_cashreceipt.cash_num 
				AND araudit.cust_code = l_rec_customer.cust_code 
				AND araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
				AND araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
				
				LET l_rec_rpt_info.araudit = l_rec_rpt_info.araudit + sqlca.sqlerrd[3] 
				
				DELETE FROM cashreceipt 
				WHERE cashreceipt.cash_num = l_rec_cashreceipt.cash_num 
				AND cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
			
				LET l_rec_rpt_info.cashrcpt = l_rec_rpt_info.cashrcpt + sqlca.sqlerrd[3] 
			
			END FOREACH
			 
			IF l_error_ind = 1 THEN 
				CONTINUE FOREACH 
			ELSE 
				IF l_error_ind = 2 THEN 
					EXIT FOREACH 
				END IF 
			END IF 

			###########################################################################

			SELECT unique 1 FROM t_summary 
			IF status != NOTFOUND THEN 
				SELECT max(period_num) INTO modu_period_num FROM period 
				WHERE period.year_num = modu_ret_year - 1 
				AND period.cmpy_code = glob_rec_kandoouser.cmpy_code 
				
				IF modu_period_num IS NULL THEN 
					LET l_msg = "Year/Period are NOT setup FOR Year: ", 
					modu_ret_year - 1 
					ROLLBACK WORK 
					LET l_interrupt = 4 
					EXIT FOREACH 
				END IF 
				
				CALL create_summary(l_rec_customer.*) 
				RETURNING 
					l_rec_rpt_info.summ_invc, 
					l_rec_rpt_info.summ_cred, 
					l_rec_rpt_info.summ_cash 
			END IF 
			
			IF l_rec_rpt_info.summ_invc = -1 
			AND l_rec_rpt_info.summ_cred = -1 
			AND l_rec_rpt_info.summ_cash = -1 THEN 
				LET l_msg = "Database Lock Error. Customers Processed: ",	modu_counter USING "<<<<<<&", " Errors: ",modu_err_counter USING "<<<<<<&" 
				LET l_interrupt = 3 
				
				ROLLBACK WORK 
				EXIT FOREACH 
			END IF 
			# Actual REPORT (not the error/exception listing report)
			#---------------------------------------------------------
			OUTPUT TO REPORT ASU_rpt_list(l_rpt_idx_1,l_rec_rpt_info.*,l_rec_customer.*) 
			#---------------------------------------------------------
		COMMIT WORK 


		SELECT unique 1 FROM t_summary 
		IF status != NOTFOUND THEN 
			CALL rollup_balance(l_rec_customer.*) 
		END IF 
		LET l_msg = "Purge Succesfully Completed. Customers Processed: ", 
		modu_counter USING "<<<<<<&", " Errors: ", 
		modu_err_counter USING "<<<<<<&" 
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	END FOREACH 

	CALL errorlog(l_msg) 
	
	#------------------------------------------------------------
	# Actual (positive) report
	FINISH REPORT ASU_rpt_list
	CALL rpt_finish("ASU_rpt_list")
	# ERROR/Exception Report
	FINISH REPORT ASU_rpt_list_purge_exception
	CALL rpt_finish("ASU_rpt_list_purge_exception")
	#------------------------------------------------------------

	IF glob_arr_rec_rpt_rmsreps[l_rpt_idx_1].exec_ind = "1" THEN
		CASE l_interrupt 
			WHEN 0 
				IF modu_err_counter THEN 
					LET l_msg = kandoomsg2("A",7006,modu_err_counter)	#7024 Purge completed with exceptions
				ELSE 
					LET l_msg = kandoomsg2("U",7023,modu_rpt_total)		#7023 Purge Succesfully Completed.
				END IF 
			WHEN 1 
				LET l_msg = kandoomsg2("U",7024,modu_rpt_total)  		#7024 Purge terminated by time limit.
			WHEN 2 
				LET l_msg = kandoomsg2("U",7025,modu_rpt_total) 			#7025 Purge terminated by Cancel Key.
			WHEN 3 
				LET l_msg = kandoomsg2("U",7009,modu_rpt_total) 			#7009 Purge terminated by database lock.
			WHEN 4 
				LET l_msg = kandoomsg2("U",7026,modu_ret_year-1)			#7026 Year/Period NOT SET up.
		END CASE 
		CALL fgl_winmessage("Error",l_msg,"ERROR")
	END IF 
END FUNCTION 
####################################################################
# END FUNCTION ASU_rpt_process(p_where_text) 
####################################################################
 

####################################################################
# FUNCTION create_summary(p_rec_customer)
#
#
####################################################################
FUNCTION create_summary(p_rec_customer) 
	DEFINE p_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_summary RECORD 
		summary_type CHAR(2), 
		inv_num INTEGER, 
		pay_amt DECIMAL(16,4), 
		ref_num INTEGER, 
		pay_type_ind CHAR(2) 
	END RECORD 
	DEFINE l_inv_amt DECIMAL(16,4) 
	DEFINE l_cred_amt DECIMAL(16,4) 
	DEFINE l_cash_amt DECIMAL(16,4) 

	DEFINE l_err_message CHAR(60) 
	DEFINE l_rec_invoicehead RECORD LIKE invoicehead.* 
	DEFINE l_rec_invoicedetl RECORD LIKE invoicedetl.* 
	DEFINE l_rec_credithead RECORD LIKE credithead.* 
	DEFINE l_rec_creditdetl RECORD LIKE creditdetl.* 
	DEFINE l_rec_cashreceipt RECORD LIKE cashreceipt.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_end_date LIKE period.end_date 
	DEFINE l_rec_invoicepay RECORD LIKE invoicepay.* 

	INITIALIZE l_rec_summary.* TO NULL 
	INITIALIZE glob_rec_invoicehead.* TO NULL 
	INITIALIZE l_rec_invoicedetl.* TO NULL 
	INITIALIZE l_rec_credithead.* TO NULL 
	INITIALIZE l_rec_creditdetl.* TO NULL 
	INITIALIZE l_rec_cashreceipt.* TO NULL 
	INITIALIZE l_rec_araudit.* TO NULL 
	INITIALIZE l_inv_amt TO NULL 
	INITIALIZE l_cred_amt TO NULL 
	INITIALIZE l_cash_amt TO NULL 

	SELECT period.end_date INTO l_end_date FROM period 
	WHERE period.year_num = modu_ret_year - 1 
	AND period.period_num = modu_period_num 
	AND period.cmpy_code = glob_rec_kandoouser.cmpy_code 

	WHENEVER ERROR GOTO recovery 
	GOTO bypass 
	LABEL recovery: 
	RETURN -1,-1,-1 
	#################### INVOICE INVOICE INVOICE ###################
	LABEL bypass: 
	SELECT unique 1 FROM t_summary 
	WHERE summary_type = TRAN_TYPE_INVOICE_IN 
	IF status != NOTFOUND THEN 
		LET l_inv_amt = 0 
		LET glob_rec_invoicehead.inv_num = next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_INVOICE_IN,"") 
		
		IF glob_rec_invoicehead.inv_num < 0 THEN 
			LET status = glob_rec_invoicehead.inv_num 
			GOTO recovery 
		END IF 
		
		DECLARE c_summary CURSOR FOR 
		SELECT * FROM t_summary 
		WHERE summary_type = TRAN_TYPE_INVOICE_IN 
		
		FOREACH c_summary INTO l_rec_summary.* 
			LET l_inv_amt = l_inv_amt + l_rec_summary.pay_amt
			 
			#--------------------------------------
			UPDATE invoicepay 
			SET invoicepay.inv_num = glob_rec_invoicehead.inv_num 
			WHERE invoicepay.inv_num = l_rec_summary.inv_num 
			AND invoicepay.ref_num = l_rec_summary.ref_num 
			AND invoicepay.pay_type_ind = l_rec_summary.pay_type_ind 

		END FOREACH 
		
		LET glob_rec_invoicehead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET glob_rec_invoicehead.cust_code = p_rec_customer.cust_code 
		LET glob_rec_invoicehead.ord_num = NULL 
		LET glob_rec_invoicehead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET glob_rec_invoicehead.entry_date = l_end_date 
		LET glob_rec_invoicehead.sale_code = p_rec_customer.sale_code 
		LET glob_rec_invoicehead.term_code = p_rec_customer.term_code 
		LET glob_rec_invoicehead.tax_code = p_rec_customer.tax_code 
		LET glob_rec_invoicehead.inv_date = l_end_date 
		LET glob_rec_invoicehead.year_num = modu_ret_year - 1 
		LET glob_rec_invoicehead.period_num = modu_period_num 
		LET glob_rec_invoicehead.entry_date = TODAY 
		LET glob_rec_invoicehead.disc_per = 0 
		LET glob_rec_invoicehead.tax_per = 0 
		LET glob_rec_invoicehead.hand_amt = 0 
		LET glob_rec_invoicehead.hand_tax_amt = 0 
		LET glob_rec_invoicehead.freight_amt = 0 
		LET glob_rec_invoicehead.freight_tax_amt = 0 
		LET glob_rec_invoicehead.goods_amt = l_inv_amt 
		LET glob_rec_invoicehead.total_amt = l_inv_amt 
		LET glob_rec_invoicehead.tax_amt = 0 
		LET glob_rec_invoicehead.disc_amt = 0 
		LET glob_rec_invoicehead.cost_amt = 0 
		LET glob_rec_invoicehead.paid_amt = l_inv_amt 
		LET glob_rec_invoicehead.paid_date = l_end_date 
		LET glob_rec_invoicehead.disc_taken_amt = 0 
		
		CALL db_term_get_rec(UI_OFF,glob_rec_invoicehead.term_code ) RETURNING l_rec_term.*
		
		CALL get_due_and_discount_date(l_rec_term.*,glob_rec_invoicehead.inv_date) 
		RETURNING 
			glob_rec_invoicehead.due_date, 
			glob_rec_invoicehead.disc_date 
		
		LET glob_rec_invoicehead.disc_date = NULL 
		LET glob_rec_invoicehead.expected_date = NULL 
		LET glob_rec_invoicehead.on_state_flag = "Y" 
		LET glob_rec_invoicehead.posted_flag = "Y" 
		LET glob_rec_invoicehead.seq_num = 0 
		LET glob_rec_invoicehead.line_num = 1 
		LET glob_rec_invoicehead.printed_num = 1 
		LET glob_rec_invoicehead.manifest_num = NULL 
		LET glob_rec_invoicehead.rev_date = TODAY 
		LET glob_rec_invoicehead.ship_date = TODAY 
		LET glob_rec_invoicehead.currency_code = p_rec_customer.currency_code 
		LET glob_rec_invoicehead.conv_qty = 1 
		LET glob_rec_invoicehead.inv_ind = "4" 
		LET glob_rec_invoicehead.com1_text = "AR Purge Summary Invoice" 
		LET glob_rec_invoicehead.com2_text = "Purge Date: ",TODAY 
		LET glob_rec_invoicehead.name_text = p_rec_customer.name_text 
		LET glob_rec_invoicehead.addr1_text = p_rec_customer.addr1_text 
		LET glob_rec_invoicehead.addr2_text = p_rec_customer.addr2_text 
		LET glob_rec_invoicehead.city_text = p_rec_customer.city_text 
		LET glob_rec_invoicehead.state_code = p_rec_customer.state_code 
		LET glob_rec_invoicehead.post_code = p_rec_customer.post_code 
		LET glob_rec_invoicehead.prev_paid_amt = 0 
		LET glob_rec_invoicehead.invoice_to_ind = p_rec_customer.invoice_to_ind 
		LET glob_rec_invoicehead.territory_code = p_rec_customer.territory_code 
		LET glob_rec_invoicehead.mgr_code = NULL 
		LET glob_rec_invoicehead.area_code = NULL 
		LET glob_rec_invoicehead.cond_code = p_rec_customer.cond_code 
		LET glob_rec_invoicehead.cost_ind = NULL 
		LET glob_rec_invoicehead.jour_num = NULL 
		LET glob_rec_invoicehead.post_date = NULL 
		LET glob_rec_invoicehead.stat_date = NULL 
		
		LET l_err_message = "ASU - Invoicehead Row Insert" 

		#----------------------------
		#INSERT invoicehead Record
		IF db_invoicehead_rec_validation(UI_ON,MODE_INSERT,glob_rec_invoicehead.*) THEN
			
			# INSERT INTO invoicehead ------------------------------------
			INSERT INTO invoicehead VALUES (glob_rec_invoicehead.*)			
		ELSE
			DISPLAY glob_rec_invoicehead.*
			CALL fgl_winmessage("Error","Could not insert new invoicehead record","ERROR")
		END IF 
		
		LET l_rec_invoicedetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_invoicedetl.cust_code = glob_rec_invoicehead.cust_code 
		LET l_rec_invoicedetl.inv_num = glob_rec_invoicehead.inv_num 
		LET l_rec_invoicedetl.line_num = 1 
		LET l_rec_invoicedetl.line_text = "AR Purge Summary Invoice" 
		LET l_rec_invoicedetl.unit_sale_amt = l_inv_amt 
		LET l_rec_invoicedetl.ext_sale_amt = l_inv_amt 
		LET l_rec_invoicedetl.ship_qty = 1 
		LET l_rec_invoicedetl.line_total_amt = l_inv_amt 
		LET l_rec_invoicedetl.tax_code = p_rec_customer.tax_code 
		LET l_rec_invoicedetl.order_num = NULL
		 
		SELECT customertype.ar_acct_code INTO l_rec_invoicedetl.line_acct_code FROM customertype		
		WHERE customertype.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND customertype.type_code = p_rec_customer.type_code 
		
		LET l_rec_invoicedetl.sold_qty = 1 
		LET l_rec_invoicedetl.part_code = NULL 
		LET l_rec_invoicedetl.ware_code = NULL 
		LET l_rec_invoicedetl.cat_code = NULL 
		LET l_rec_invoicedetl.ord_qty = 0 
		LET l_rec_invoicedetl.prev_qty = 0 
		LET l_rec_invoicedetl.back_qty = 0 
		LET l_rec_invoicedetl.ser_flag = NULL 
		LET l_rec_invoicedetl.ser_qty = 0 
		LET l_rec_invoicedetl.uom_code = NULL 
		LET l_rec_invoicedetl.unit_cost_amt = 0 
		LET l_rec_invoicedetl.ext_cost_amt = 0 
		LET l_rec_invoicedetl.disc_amt = 0 
		LET l_rec_invoicedetl.unit_tax_amt = 0 
		LET l_rec_invoicedetl.ext_tax_amt = 0 
		LET l_rec_invoicedetl.seq_num = 0 
		LET l_rec_invoicedetl.level_code = NULL 
		LET l_rec_invoicedetl.comm_amt = 0 
		LET l_rec_invoicedetl.comp_per = 0 
		LET l_rec_invoicedetl.order_line_num = 0 
		LET l_rec_invoicedetl.disc_per = 0 
		LET l_rec_invoicedetl.offer_code = NULL 
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

		LET l_err_message = "ASU - Invoicedetl Row Insert" 

		#----------------------------
		#INSERT invoiceDetl Record
		IF db_invoicedetl_rec_validation(UI_ON,MODE_INSERT,l_rec_invoicedetl.*) THEN
			INSERT INTO invoicedetl VALUES (l_rec_invoicedetl.*)		
		ELSE
			DISPLAY l_rec_invoicedetl.*
			CALL fgl_winmessage("Error","Could not insert new invoiceDetl record","ERROR")
		END IF 
		
		#------------------------------------
		#  Insert ARAUDIT entry
		#
		LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_araudit.tran_date = glob_rec_invoicehead.inv_date 
		LET l_rec_araudit.cust_code = glob_rec_invoicehead.cust_code 
		
		SELECT (min(araudit.seq_num) - 1) INTO l_rec_araudit.seq_num FROM araudit 
		WHERE araudit.cust_code = p_rec_customer.cust_code 
		AND araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		
		IF l_rec_araudit.seq_num IS NULL THEN 
			LET l_rec_araudit.seq_num = -1 
		END IF 
		
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_INVOICE_IN 
		LET l_rec_araudit.source_num = glob_rec_invoicehead.inv_num 
		LET l_rec_araudit.tran_text = "AR Purge IN" 
		LET l_rec_araudit.tran_amt = l_inv_amt 
		LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_araudit.sales_code = p_rec_customer.sale_code 
		LET l_rec_araudit.year_num = glob_rec_invoicehead.year_num 
		LET l_rec_araudit.period_num = glob_rec_invoicehead.period_num 
		LET l_rec_araudit.bal_amt = l_inv_amt 
		LET l_rec_araudit.currency_code = p_rec_customer.currency_code 
		LET l_rec_araudit.conv_qty = glob_rec_invoicehead.conv_qty 
		LET l_rec_araudit.entry_date = l_end_date 
		LET l_err_message = "ASU - Summary Invoice Araudit Entry" 
		
		#-------------------------------------------
		INSERT INTO araudit VALUES (l_rec_araudit.*) 
	END IF 

	###################### CREDIT CREDIT CREDIT ####################

	INITIALIZE l_rec_araudit.* TO NULL 
	SELECT unique 1 FROM t_summary 
	WHERE summary_type = TRAN_TYPE_CREDIT_CR 
	IF status != NOTFOUND THEN 
		LET l_cred_amt = 0 
		LET l_rec_credithead.cred_num = next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_CREDIT_CR,"") 
		IF l_rec_credithead.cred_num < 0 THEN 
			LET status = l_rec_credithead.cred_num 
			GOTO recovery 
		END IF 
		
		DECLARE c2_summary CURSOR FOR 
		SELECT * FROM t_summary 
		WHERE summary_type = TRAN_TYPE_CREDIT_CR 
		
		FOREACH c2_summary INTO l_rec_summary.* 
			LET l_cred_amt = l_cred_amt + l_rec_summary.pay_amt 

			UPDATE invoicepay 
			SET invoicepay.ref_num = l_rec_credithead.cred_num 
			WHERE invoicepay.inv_num = l_rec_summary.inv_num 
			AND invoicepay.ref_num = l_rec_summary.ref_num 
			AND invoicepay.pay_type_ind = l_rec_summary.pay_type_ind 

		END FOREACH 
		
		LET l_rec_credithead.rma_num = NULL 
		LET l_rec_credithead.cust_code = p_rec_customer.cust_code 
		LET l_rec_credithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_credithead.cred_text = NULL 
		LET l_rec_credithead.job_code = NULL 
		LET l_rec_credithead.com1_text = "AR Purge Summary Credit" 
		LET l_rec_credithead.com2_text = "Purge Date: ",TODAY 
		LET l_rec_credithead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_credithead.entry_date = l_end_date 
		LET l_rec_credithead.cred_date = l_end_date 
		LET l_rec_credithead.sale_code = p_rec_customer.sale_code 
		LET l_rec_credithead.tax_code = p_rec_customer.tax_code 
		LET l_rec_credithead.tax_per = 0 
		LET l_rec_credithead.hand_amt = 0 
		LET l_rec_credithead.hand_tax_code = p_rec_customer.tax_code 
		LET l_rec_credithead.hand_tax_amt = 0 
		LET l_rec_credithead.freight_tax_code = p_rec_customer.tax_code 
		LET l_rec_credithead.freight_tax_amt = 0 
		LET l_rec_credithead.freight_amt = 0 
		LET l_rec_credithead.total_amt = l_cred_amt 
		LET l_rec_credithead.goods_amt = l_cred_amt 
		LET l_rec_credithead.appl_amt = l_cred_amt 
		LET l_rec_credithead.tax_amt = 0 
		LET l_rec_credithead.cost_amt = 0 
		LET l_rec_credithead.disc_amt = 0 
		LET l_rec_credithead.year_num = modu_ret_year -1 
		LET l_rec_credithead.period_num = modu_period_num 
		LET l_rec_credithead.on_state_flag = "Y" 
		LET l_rec_credithead.posted_flag = "Y" 
		LET l_rec_credithead.next_num = 0 
		LET l_rec_credithead.line_num = 1 
		LET l_rec_credithead.rev_num = 1 
		LET l_rec_credithead.rev_date = l_end_date 
		LET l_rec_credithead.cost_ind = NULL 
		LET l_rec_credithead.currency_code = p_rec_customer.currency_code 
		LET l_rec_credithead.conv_qty = 1 
		LET l_rec_credithead.cred_ind = 4 
		
		SELECT customertype.ar_acct_code INTO l_rec_credithead.acct_override_code 
		FROM customertype 
		WHERE customertype.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND customertype.type_code = p_rec_customer.type_code 
		
		LET l_rec_credithead.address_to_ind = p_rec_customer.invoice_to_ind 
		LET l_rec_credithead.territory_code = p_rec_customer.territory_code 
		LET l_rec_credithead.mgr_code = NULL 
		LET l_rec_credithead.area_code = NULL 
		LET l_rec_credithead.cond_code = p_rec_customer.cond_code 
		LET l_rec_credithead.printed_num = 1 
		
		#------------------------------------------------------
		INSERT INTO credithead VALUES (l_rec_credithead.*) 
		LET l_rec_creditdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_creditdetl.cred_num = l_rec_credithead.cred_num 
		LET l_rec_creditdetl.cust_code = l_rec_credithead.cust_code 
		LET l_rec_creditdetl.line_num = 1 
		LET l_rec_creditdetl.part_code = NULL 
		LET l_rec_creditdetl.ware_code = NULL 
		LET l_rec_creditdetl.cat_code = NULL 
		LET l_rec_creditdetl.ship_qty = 1 
		LET l_rec_creditdetl.ser_ind = NULL 
		LET l_rec_creditdetl.line_text = "AR Purge Credit (ASU)" 
		LET l_rec_creditdetl.uom_code = NULL 
		LET l_rec_creditdetl.disc_amt = 0 
		LET l_rec_creditdetl.unit_cost_amt = 0 
		LET l_rec_creditdetl.unit_sales_amt = l_cred_amt 
		LET l_rec_creditdetl.unit_tax_amt = 0 
		LET l_rec_creditdetl.ext_cost_amt = 0 
		LET l_rec_creditdetl.ext_sales_amt = l_cred_amt 
		LET l_rec_creditdetl.ext_tax_amt = 0 
		LET l_rec_creditdetl.line_total_amt = l_cred_amt 
		LET l_rec_creditdetl.seq_num = 1 
		
		SELECT customertype.ar_acct_code INTO l_rec_creditdetl.line_acct_code 
		FROM customertype 
		WHERE customertype.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND customertype.type_code = p_rec_customer.type_code 
		
		LET l_rec_creditdetl.job_code = l_rec_credithead.job_code 
		LET l_rec_creditdetl.level_code = NULL 
		LET l_rec_creditdetl.comm_amt = 0 
		LET l_rec_creditdetl.tax_code = p_rec_customer.tax_code 
		LET l_rec_creditdetl.reason_code = NULL 
		LET l_rec_creditdetl.invoice_num = 0 
		LET l_rec_creditdetl.inv_line_num = 0 
		LET l_rec_creditdetl.price_uom_code = NULL 
		LET l_rec_creditdetl.km_qty = NULL 
		LET l_err_message = "Creditdetl Insert (ASU)" 
		
		#--------------------------------------------------
		INSERT INTO creditdetl VALUES (l_rec_creditdetl.*) 
		#-----------------------
		#  Insert ARAUDIT entry
		#-----------------------
		LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_araudit.tran_date = l_end_date 
		LET l_rec_araudit.cust_code = p_rec_customer.cust_code 
		
		SELECT (min(araudit.seq_num) - 1) INTO l_rec_araudit.seq_num FROM araudit 
		WHERE araudit.cust_code = p_rec_customer.cust_code 
		AND araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF l_rec_araudit.seq_num IS NULL THEN 
			LET l_rec_araudit.seq_num = -2 
		END IF 
		
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_CREDIT_CR 
		LET l_rec_araudit.tran_text = "AR Purge CR" 
		LET l_rec_araudit.source_num = l_rec_credithead.cred_num 
		LET l_rec_araudit.tran_amt = l_cred_amt * -1 
		LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_araudit.entry_date = l_end_date 
		LET l_rec_araudit.sales_code = p_rec_customer.sale_code 
		LET l_rec_araudit.year_num = l_rec_credithead.year_num 
		LET l_rec_araudit.period_num = l_rec_credithead.period_num 
		LET l_rec_araudit.currency_code = l_rec_credithead.currency_code 
		LET l_rec_araudit.conv_qty = l_rec_credithead.conv_qty 
		LET l_rec_araudit.bal_amt = 0 
		LET l_err_message = "ASU - Summary Credit Araudit Insert" 
		
		#---------------------------------------------------------
		INSERT INTO araudit VALUES (l_rec_araudit.*) 
	END IF 

	###################### CASHRECEIPT CASHRECEIPT ####################

	INITIALIZE l_rec_araudit.* TO NULL 
	SELECT unique 1 FROM t_summary 
	WHERE summary_type = TRAN_TYPE_RECEIPT_CA 
	IF status != NOTFOUND THEN 
		LET l_cash_amt = 0 
		LET l_rec_cashreceipt.cash_num = next_trans_num(glob_rec_kandoouser.cmpy_code,TRAN_TYPE_RECEIPT_CA,"") 
		IF l_rec_cashreceipt.cash_num < 0 THEN 
			LET status = l_rec_cashreceipt.cash_num 
			GOTO recovery 
		END IF 
		
		DECLARE c3_summary CURSOR FOR 
		SELECT * FROM t_summary 
		WHERE summary_type = TRAN_TYPE_RECEIPT_CA 
		
		FOREACH c3_summary INTO l_rec_summary.* 
			LET l_cash_amt = l_cash_amt + l_rec_summary.pay_amt 

			UPDATE invoicepay 
			SET invoicepay.ref_num = l_rec_cashreceipt.cash_num 
			WHERE invoicepay.inv_num = l_rec_summary.inv_num 
			AND invoicepay.ref_num = l_rec_summary.ref_num 
			AND invoicepay.pay_type_ind = l_rec_summary.pay_type_ind 

		END FOREACH 
		
		LET l_rec_cashreceipt.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_cashreceipt.cust_code = p_rec_customer.cust_code 
		
		SELECT customertype.ar_acct_code INTO l_rec_cashreceipt.cash_acct_code 
		FROM customertype 
		WHERE customertype.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND customertype.type_code = p_rec_customer.type_code 
		
		LET l_rec_cashreceipt.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_cashreceipt.entry_date = l_end_date 
		LET l_rec_cashreceipt.cash_date = l_end_date 
		LET l_rec_cashreceipt.year_num = modu_ret_year - 1 
		LET l_rec_cashreceipt.period_num = modu_period_num 
		LET l_rec_cashreceipt.cash_amt = l_cash_amt 
		LET l_rec_cashreceipt.applied_amt = l_cash_amt 
		LET l_rec_cashreceipt.disc_amt = 0 
		LET l_rec_cashreceipt.on_state_flag = "Y" 
		LET l_rec_cashreceipt.posted_flag = CASHRECEIPT_POST_FLAG_STATUS_POSTED_Y 
		LET l_rec_cashreceipt.next_num = 0 
		LET l_rec_cashreceipt.com1_text = "AR Purge Summary Cashreceipt" 
		LET l_rec_cashreceipt.com2_text = "Purge Date: ",TODAY 
		LET l_rec_cashreceipt.banked_flag = "Y" 
		LET l_rec_cashreceipt.currency_code = p_rec_customer.currency_code 
		LET l_rec_cashreceipt.conv_qty = 1 
		LET l_err_message = "Cashreceipt Insert (ASU)" 
		
		#------------------------------------------------------------
		INSERT INTO cashreceipt VALUES (l_rec_cashreceipt.*) 
		#----------------------------
		#  Insert ARAUDIT entry
		#------------------------------
		LET l_rec_araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_araudit.tran_date = l_end_date 
		LET l_rec_araudit.cust_code = p_rec_customer.cust_code 
		
		SELECT (min(araudit.seq_num) - 1) INTO l_rec_araudit.seq_num FROM araudit 
		WHERE araudit.cust_code = p_rec_customer.cust_code 
		AND araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		
		IF l_rec_araudit.seq_num IS NULL THEN 
			LET l_rec_araudit.seq_num = -3 
		END IF 
		
		LET l_rec_araudit.tran_type_ind = TRAN_TYPE_RECEIPT_CA 
		LET l_rec_araudit.tran_text = "AR Purge CA" 
		LET l_rec_araudit.source_num = l_rec_cashreceipt.cash_num 
		LET l_rec_araudit.tran_amt = l_cash_amt * -1 
		LET l_rec_araudit.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_araudit.entry_date = l_end_date 
		LET l_rec_araudit.sales_code = p_rec_customer.sale_code 
		LET l_rec_araudit.year_num = l_rec_cashreceipt.year_num 
		LET l_rec_araudit.period_num = l_rec_cashreceipt.period_num 
		LET l_rec_araudit.currency_code = l_rec_cashreceipt.currency_code 
		LET l_rec_araudit.conv_qty = l_rec_cashreceipt.conv_qty 
		LET l_rec_araudit.bal_amt = 0 
		LET l_err_message = "ASU - Summary Cashreceipt Araudit Insert" 
		
		#-------------------------------------------
		INSERT INTO araudit VALUES (l_rec_araudit.*) 
	END IF 
	
	RETURN 
		glob_rec_invoicehead.inv_num, 
		l_rec_credithead.cred_num, 
		l_rec_cashreceipt.cash_num 

END FUNCTION 
####################################################################
# END FUNCTION create_summary(p_rec_customer)
####################################################################


####################################################################
# FUNCTION rollup_balance(p_rec_customer)
#
#
####################################################################
FUNCTION rollup_balance(p_rec_customer) 
	DEFINE p_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_araudit RECORD LIKE araudit.* 
	DEFINE l_bal_amt LIKE customer.bal_amt 
	DEFINE l_rowid INTEGER 
	DEFINE l_seq_num INTEGER 
	DEFINE l_comp_per FLOAT 
	DEFINE l_query_text STRING 
	DEFINE l_msg CHAR(1000) 

	LET l_query_text = 
		"SELECT rowid, * FROM araudit ", 
		" WHERE araudit.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND araudit.cust_code = \"",p_rec_customer.cust_code,"\" ", 
		" ORDER BY araudit.entry_date, araudit.seq_num" 
	
	PREPARE s_araudit FROM l_query_text 
	DECLARE c_araudit CURSOR with HOLD FOR s_araudit 
	
	BEGIN WORK 
		EXECUTE IMMEDIATE "SET CONSTRAINTS ALL DEFERRED"
		WHENEVER ERROR GOTO recovery 
		OPEN c_araudit 
		LET l_bal_amt = 0 
		LET l_seq_num = 0 
		
		#-----------------------------------------------------
		## This line included TO move seq_num's out of range WHERE
		## duplicating will occur.
		#

		UPDATE araudit 
		SET araudit.seq_num = araudit.seq_num + 20000 
		WHERE araudit.cust_code = p_rec_customer.cust_code 
		AND araudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		
		FOREACH c_araudit INTO l_rowid, l_rec_araudit.* 
			IF l_rec_araudit.tran_amt IS NULL THEN 
				LET l_rec_araudit.tran_amt = 0 
			END IF 
		
			LET l_bal_amt = l_bal_amt + l_rec_araudit.tran_amt 
			LET l_seq_num = l_seq_num + 1 

			UPDATE araudit 
			SET araudit.seq_num = l_seq_num, 
			araudit.bal_amt = l_bal_amt 
			WHERE araudit.rowid = l_rowid 

		END FOREACH 
		
		CLOSE c_araudit 
		
		IF l_bal_amt != p_rec_customer.bal_amt OR l_seq_num != p_rec_customer.next_seq_num THEN 

			UPDATE customer 
			SET customer.next_seq_num = l_seq_num 
			WHERE customer.cmpy_code = p_rec_customer.cmpy_code 
			AND customer.cust_code = p_rec_customer.cust_code 
		
			LET l_msg = "### ASU Update Cust:",p_rec_customer.cust_code, 
			" Balances:",p_rec_customer.bal_amt," ", 
			" Audit:",l_bal_amt," ", 
			" Sequence:",p_rec_customer.next_seq_num," ", 
			" Audit:",l_seq_num 
			CALL errorlog(l_msg) 
		END IF 
		
		WHENEVER ERROR stop 
		WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	COMMIT WORK 
	
	RETURN 
	LABEL recovery: 
	LET l_msg = 
		"### ASU Error Updating Cust:",p_rec_customer.cust_code, 
		" Balances:",p_rec_customer.bal_amt," ", 
		" Audit:",l_bal_amt," ", 
		" Sequence:",p_rec_customer.next_seq_num," ", 
		" Audit:",l_seq_num," " 
	
	CALL errorlog(l_msg) 
	
	ROLLBACK WORK 
	
END FUNCTION
####################################################################
# FUNCTION rollup_balance(p_rec_customer)
####################################################################

####################################################################
# REPORT ASU_rpt_list(p_rpt_info, p_rec_customer)
#
#
####################################################################
REPORT ASU_rpt_list(p_rpt_idx,p_rpt_info, p_rec_customer) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rpt_info RECORD 
		invhead INTEGER, 
		invdetl INTEGER, 
		invrates INTEGER, 
		credhead INTEGER, 
		creddetl INTEGER, 
		creditrates INTEGER, 
		cashrcpt INTEGER, 
		araudit INTEGER, 
		invoicepay INTEGER, 
		invheadext INTEGER, 
		credheadaddr INTEGER, 
		creditheadext INTEGER, 
		summ_invc INTEGER, 
		summ_cred INTEGER, 
		summ_cash INTEGER 
	END RECORD 
	DEFINE p_rec_customer RECORD LIKE customer.* 
	DEFINE l_inv INTEGER 
	DEFINE l_cred INTEGER 
	DEFINE l_rpt_sub_total INTEGER 
	DEFINE l_arr_line array[4] OF CHAR(132) 

	ORDER EXTERNAL BY p_rec_customer.cust_code 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line3_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
		
		ON EVERY ROW 
			LET modu_counter = modu_counter + 1 
			
			LET l_inv = p_rpt_info.invhead + p_rpt_info.invdetl 
			+ p_rpt_info.invoicepay + p_rpt_info.invheadext 
			+ p_rpt_info.invrates 
			
			LET l_cred = p_rpt_info.credhead + p_rpt_info.creddetl 
			+ p_rpt_info.creditheadext + p_rpt_info.credheadaddr 
			+ p_rpt_info.creditrates 
			
			LET l_rpt_sub_total = p_rpt_info.invhead + p_rpt_info.invdetl 
			+ p_rpt_info.credhead + p_rpt_info.creddetl 
			+ p_rpt_info.cashrcpt + p_rpt_info.araudit 
			+ p_rpt_info.invoicepay + p_rpt_info.invheadext 
			+ p_rpt_info.credheadaddr + p_rpt_info.creditrates 
			+ p_rpt_info.creditheadext + p_rpt_info.invrates 
			
			PRINT 
			COLUMN 01, p_rec_customer.cust_code CLIPPED, 
			COLUMN 10, p_rec_customer.name_text CLIPPED, 
			COLUMN 45, l_inv                USING "#######&", 
			COLUMN 55, l_cred               USING "#######&", 
			COLUMN 65, p_rpt_info.cashrcpt  USING "#######&", 
			COLUMN 75, p_rpt_info.araudit   USING "#######&", 
			COLUMN 85, l_rpt_sub_total      USING "#######&", 
			COLUMN 106,p_rpt_info.summ_invc USING "#######&", 
			COLUMN 116,p_rpt_info.summ_cred USING "#######&", 
			COLUMN 125,p_rpt_info.summ_cash USING "#######&" 
			LET modu_rpt_total = modu_rpt_total + l_rpt_sub_total 
		
		ON LAST ROW 
			SKIP 1 LINE 
			PRINT COLUMN 84,"---------" 
			PRINT COLUMN 51,"Total number of deleted records: ",	modu_rpt_total USING "########&" 
			SKIP 1 LINE 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
####################################################################
# END REPORT ASU_rpt_list(p_rpt_info, p_rec_customer)
####################################################################

####################################################################
# REPORT ASU_rpt_list_purge_exception(p_cust_code,p_reason)
#
#
####################################################################
REPORT ASU_rpt_list_purge_exception(p_rpt_idx,p_cust_code,p_reason) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_cust_code LIKE customer.cust_code 
	DEFINE l_rec_customer RECORD LIKE customer.*
	DEFINE p_reason CHAR(60) 

	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]

	ON EVERY ROW 
		SELECT * INTO l_rec_customer.* FROM customer 
		WHERE customer.cust_code = p_cust_code 
		AND customer.cmpy_code = glob_rec_kandoouser.cmpy_code 
		PRINT 
		COLUMN 01,l_rec_customer.cust_code CLIPPED, 
		COLUMN 10,l_rec_customer.name_text CLIPPED, 
		COLUMN 50,p_reason CLIPPED 
		LET modu_err_counter = modu_err_counter + 1 

	ON LAST ROW 
		SKIP 1 LINE 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 
####################################################################
# END REPORT ASU_rpt_list_purge_exception(p_cust_code,p_reason)
####################################################################
