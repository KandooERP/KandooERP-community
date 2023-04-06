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

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../common/postfunc_GLOBALS.4gl"
GLOBALS "../ar/A_AR_GLOBALS.4gl"
GLOBALS "../ar/A6_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/A64_GLOBALS.4gl"

#######################################################################
# FUNCTION A64_main()
#
# Purpose - Generate Bank Deposit
#######################################################################
FUNCTION A64_main() 

	DEFER interrupt 
	DEFER quit 

	CALL setModuleId("A64") 

	OPEN WINDOW A687 with FORM "A687" 
	CALL windecoration_a("A687") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE select_deposit() 
	END WHILE 

	CLOSE WINDOW A687 

END FUNCTION 
#######################################################################
# END FUNCTION A64_main()
#######################################################################


#######################################################################
# FUNCTION select_deposit()
#
#
#######################################################################
FUNCTION select_deposit() 
	DEFINE l_rec_tentbankhead RECORD LIKE tentbankhead.*
	DEFINE l_arr_rec_tentbankhead DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		bank_code LIKE tentbankhead.bank_code, 
		bank_dep_num LIKE tentbankhead.bank_dep_num, 
		desc_text LIKE tentbankhead.desc_text, 
		deposit_amt DECIMAL(16,2), 
		status_flag CHAR(1) 
	END RECORD
	DEFINE l_idx SMALLINT

	MESSAGE kandoomsg2("A",1043,"") 	#1038 "ENTER TO Generate Deposit List; OK TO Continue."

	CALL l_arr_rec_tentbankhead.CLEAR()
	CALL db_tentbankhead_get_datasource(FALSE) RETURNING l_arr_rec_tentbankhead

	DISPLAY ARRAY l_arr_rec_tentbankhead TO sr_tentbankhead.* ATTRIBUTE(UNBUFFERED) 
 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","A64","inp-arr-tentbankhead") 
			CALL dialog.setActionHidden("ACCEPT",TRUE)
			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER"
			CALL l_arr_rec_tentbankhead.CLEAR()
			CALL db_tentbankhead_get_datasource(TRUE) RETURNING l_arr_rec_tentbankhead
			
		ON ACTION ("ACCEPT","DOUBLECLICK","GENERATE")
			LET l_idx = arr_curr() 
			IF l_arr_rec_tentbankhead[l_idx].bank_dep_num IS NOT NULL 
			AND l_arr_rec_tentbankhead[l_idx].bank_dep_num != 0 THEN 
				SELECT * INTO l_rec_tentbankhead.* FROM tentbankhead 
				WHERE tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND tentbankhead.bank_dep_num = l_arr_rec_tentbankhead[l_idx].bank_dep_num 
				AND tentbankhead.bank_code = l_arr_rec_tentbankhead[l_idx].bank_code

				IF l_rec_tentbankhead.status_ind NOT MATCHES "[23]" THEN 
					IF kandoomsg("A",8038,"") = "N" THEN 
						CONTINUE DISPLAY 
					END IF 

					IF l_rec_tentbankhead.status_ind NOT MATCHES"[23]" THEN 
						UPDATE tentbankhead 
						SET tentbankhead.status_ind = "3" 
						WHERE tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND tentbankhead.bank_dep_num = l_arr_rec_tentbankhead[l_idx].bank_dep_num 
						AND tentbankhead.bank_code = l_arr_rec_tentbankhead[l_idx].bank_code
					ELSE 
						ERROR kandoomsg2("A",9523,"") 							#9523 This tentative deposit IS currently being used.
						LET l_arr_rec_tentbankhead[l_idx].status_flag = "*" 
					END IF 

					# Generate Deposit
				 	IF NOT generate_deposit(
				 		l_arr_rec_tentbankhead[l_idx].bank_code, 
						l_arr_rec_tentbankhead[l_idx].bank_dep_num) THEN 
						UPDATE tentbankhead 
						SET tentbankhead.status_ind = "1" 
						WHERE tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND tentbankhead.bank_dep_num = l_arr_rec_tentbankhead[l_idx].bank_dep_num 
						AND tentbankhead.bank_code = l_arr_rec_tentbankhead[l_idx].bank_code
						CALL msgcontinue("","No Bank Deposit has been created.")
					END IF 
				ELSE 
					ERROR kandoomsg2("A",9523,"") 					#9523 This tentative deposit IS currently being used.
				END IF 
			END IF 

			CALL l_arr_rec_tentbankhead.CLEAR()
			CALL db_tentbankhead_get_datasource(FALSE) RETURNING l_arr_rec_tentbankhead

	END DISPLAY

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE 
	ELSE
		RETURN TRUE
	END IF 

END FUNCTION 
#######################################################################
# END FUNCTION select_deposit()
#######################################################################


#######################################################################
# FUNCTION db_tentbankhead_get_datasource(p_filter)
#
#
#######################################################################
FUNCTION db_tentbankhead_get_datasource(p_filter)
	DEFINE p_filter BOOLEAN
	DEFINE l_rec_tentbankhead RECORD LIKE tentbankhead.*
	DEFINE l_arr_rec_tentbankhead DYNAMIC ARRAY OF RECORD 
		scroll_flag CHAR(1), 
		bank_code LIKE tentbankhead.bank_code, 
		bank_dep_num LIKE tentbankhead.bank_dep_num, 
		desc_text LIKE tentbankhead.desc_text, 
		deposit_amt DECIMAL(16,2), 
		status_flag CHAR(1) 
	END RECORD
	DEFINE l_query_text STRING
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT

	IF p_filter THEN
		CLEAR FORM 
		MESSAGE kandoomsg2("U",1001,"") 		#1001 " Enter Selection Criteria - ESC TO Continue"

		CONSTRUCT BY NAME l_where_text ON 
		tentbankhead.bank_code, 
		tentbankhead.bank_dep_num, 
		tentbankhead.desc_text 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","A64","construct-tentbankhead") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
		END CONSTRUCT 
	
		IF int_flag OR quit_flag THEN 
			LET int_flag = FALSE 
			LET quit_flag = FALSE 
			LET l_where_text = " 1=1 "
		END IF 
	ELSE
		LET l_where_text = " 1=1 "
	END IF
	
	MESSAGE kandoomsg2("U",1002,"") #1002 " Searching database - please wait"

	LET l_query_text = 
		"SELECT * FROM tentbankhead ", 
		"WHERE tentbankhead.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ",l_where_text CLIPPED," ", 
		"ORDER BY tentbankhead.bank_code, tentbankhead.bank_dep_num" 

	PREPARE s_tentbankhead FROM l_query_text 
	DECLARE c_tentbankhead CURSOR FOR s_tentbankhead 

	LET l_idx = 0 
	FOREACH c_tentbankhead INTO l_rec_tentbankhead.* 
		LET l_idx = l_idx + 1 
		INITIALIZE l_arr_rec_tentbankhead[l_idx].* TO NULL 

		LET l_arr_rec_tentbankhead[l_idx].bank_code = l_rec_tentbankhead.bank_code 
		LET l_arr_rec_tentbankhead[l_idx].bank_dep_num = l_rec_tentbankhead.bank_dep_num 
		LET l_arr_rec_tentbankhead[l_idx].desc_text = l_rec_tentbankhead.desc_text 

		IF l_rec_tentbankhead.status_ind MATCHES "[23]" THEN 
			LET l_arr_rec_tentbankhead[l_idx].status_flag = "*" 
		END IF 

		SELECT SUM(tentbankdetl.tran_amt) INTO l_arr_rec_tentbankhead[l_idx].deposit_amt 
		FROM tentbankdetl 
		WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tentbankdetl.bank_dep_num = l_rec_tentbankhead.bank_dep_num

	END FOREACH 

	MESSAGE kandoomsg2("U",9113,l_idx)#U9113 l_idx records selected

	RETURN l_arr_rec_tentbankhead

END FUNCTION
#######################################################################
# END FUNCTION db_tentbankhead_get_datasource(p_filter)
#######################################################################


#######################################################################
# FUNCTION generate_deposit(p_bank_code,p_bank_dep_num)
#
#
#######################################################################
FUNCTION generate_deposit(p_bank_code,p_bank_dep_num) 
	DEFINE p_bank_code LIKE bank.bank_code
	DEFINE p_bank_dep_num LIKE tentbankhead.bank_dep_num
	DEFINE l_rpt_idx SMALLINT 	
	DEFINE l_rec_tentbankdetl RECORD LIKE tentbankdetl.*
	DEFINE l_rec_bank RECORD LIKE bank.*
	DEFINE l_rec_banking RECORD LIKE banking.*
	DEFINE l_rec_tentbankhead RECORD LIKE tentbankhead.*
	DEFINE l_cash_amt LIKE tentbankdetl.tran_amt
	DEFINE l_base_cash_amt LIKE tentbankdetl.tran_amt
	DEFINE l_base_currency_code LIKE glparms.base_currency_code 

	MESSAGE kandoomsg2("U",1005,"") 	#1005 Updating Database; Please Wait

	SELECT glparms.base_currency_code 
	INTO l_base_currency_code 
	FROM glparms 
	WHERE glparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND glparms.key_code = "1" 

	SELECT * INTO l_rec_bank.* FROM bank 
	WHERE bank.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank.bank_code = p_bank_code 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"A64_rpt_deposit_slip",p_bank_dep_num, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT A64_rpt_deposit_slip TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	DECLARE c_tentbankdetl CURSOR FOR 
	SELECT * FROM tentbankdetl 
	WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tentbankdetl.bank_dep_num = p_bank_dep_num 
	ORDER BY tentbankdetl.cash_type_ind, tentbankdetl.seq_num 

	LET l_cash_amt = 0 
	LET l_base_cash_amt = 0

	FOREACH c_tentbankdetl INTO l_rec_tentbankdetl.* 
		IF l_rec_tentbankdetl.tran_amt IS NULL THEN 
			LET l_rec_tentbankdetl.tran_amt = 0 
		END IF 
		## Transaction amount IS always in currency of the bank
		## IF bank currency IS NOT base currency, need TO convert
		## transaction TO give base currency total
		LET l_cash_amt = l_cash_amt + l_rec_tentbankdetl.tran_amt 
		IF l_rec_bank.currency_code != l_base_currency_code THEN 
			LET l_base_cash_amt = l_base_cash_amt 
			+ (l_rec_tentbankdetl.tran_amt / l_rec_tentbankdetl.conv_qty) 
		ELSE 
			LET l_base_cash_amt = l_base_cash_amt + l_rec_tentbankdetl.tran_amt 
		END IF 
		#------------------------------------------------------------
		OUTPUT TO REPORT A64_rpt_deposit_slip(l_rpt_idx,p_bank_code,p_bank_dep_num,l_rec_tentbankdetl.*) 
		IF NOT rpt_int_flag_handler2("Bank Deposit Slip",p_bank_code,p_bank_dep_num,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#------------------------------------------------------------
	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT A64_rpt_deposit_slip
	CALL rpt_finish("A64_rpt_deposit_slip")
	#------------------------------------------------------------

	SELECT * INTO l_rec_tentbankhead.* FROM tentbankhead 
	WHERE tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tentbankhead.bank_dep_num = p_bank_dep_num 
	AND tentbankhead.bank_code = p_bank_code

	INITIALIZE l_rec_banking.* TO NULL 

	LET l_rec_banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
	LET l_rec_banking.bk_acct = l_rec_bank.acct_code 
	LET l_rec_banking.bk_type = "CD" 
	LET l_rec_banking.bk_bankdt = today 
	LET l_rec_banking.bk_desc = l_rec_tentbankhead.desc_text 
	LET l_rec_banking.bk_cred = l_cash_amt 
	LET l_rec_banking.base_cred_amt = l_base_cash_amt 
	LET l_rec_banking.bk_enter = glob_rec_kandoouser.sign_on_code 
	LET l_rec_banking.bank_dep_num = p_bank_dep_num 
	LET l_rec_banking.doc_num = 0 

	BEGIN WORK
		INSERT INTO banking VALUES (l_rec_banking.*) 
		DELETE FROM tentbankhead 
		WHERE tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tentbankhead.bank_dep_num = p_bank_dep_num 
		AND tentbankhead.bank_code = p_bank_code
		DELETE FROM tentbankdetl 
		WHERE tentbankdetl.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tentbankdetl.bank_dep_num = p_bank_dep_num 
	COMMIT WORK

	CALL msgcontinue("",kandoomsg2("A",1097,p_bank_dep_num))
  
	RETURN TRUE 

END FUNCTION 
#######################################################################
# END FUNCTION generate_deposit(p_bank_code,p_bank_dep_num)
#
#######################################################################


#######################################################################
# REPORT A64_rpt_deposit_slip(p_rpt_idx,p_bank_code,p_bank_dep_num,p_rec_tentbankdetl)
#
#
#######################################################################
REPORT A64_rpt_deposit_slip(p_rpt_idx,p_bank_code,p_bank_dep_num,p_rec_tentbankdetl) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_bank_code LIKE bank.bank_code
	DEFINE p_bank_dep_num LIKE tentbankhead.bank_dep_num
	DEFINE p_rec_tentbankdetl RECORD LIKE tentbankdetl.*
	DEFINE l_rec_tentbankhead RECORD LIKE tentbankhead.*
	DEFINE l_rec_bank RECORD LIKE bank.*
	DEFINE l_cash_amt LIKE tentbankdetl.tran_amt 
	DEFINE l_type_text CHAR(20)

	ORDER EXTERNAL BY	p_rec_tentbankdetl.cash_type_ind, p_rec_tentbankdetl.seq_num 

	FORMAT 
		FIRST PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]
			
			SELECT * INTO glob_rec_company.* FROM company 
			WHERE company.cmpy_code = glob_rec_kandoouser.cmpy_code

			SELECT * INTO l_rec_bank.* FROM bank 
			WHERE bank.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank.bank_code = p_bank_code

			SELECT * INTO l_rec_tentbankhead.* FROM tentbankhead 
			WHERE tentbankhead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tentbankhead.bank_dep_num = p_bank_dep_num
			AND tentbankhead.bank_code = p_bank_code			
			 
			PRINT COLUMN 01, "Credit of: ",glob_rec_company.name_text CLIPPED;
			PRINT COLUMN 53, "Deposit slip No: ",	p_rec_tentbankdetl.bank_dep_num USING "<<<<<<<<" 
			SKIP 1 LINE
			PRINT COLUMN 01, "Bank: ",l_rec_bank.bank_code CLIPPED," ", 
			"Account: ", l_rec_bank.iban CLIPPED," ",l_rec_bank.name_acct_text CLIPPED," ",
			"Currency: " , l_rec_bank.currency_code CLIPPED
			SKIP 1 LINE
			PRINT COLUMN 1, "Bank Deposit Listing FOR ", l_rec_tentbankhead.tran_date USING "dd mmm, yyyy"
			SKIP 1 LINE 

			SELECT SUM(tran_amt) INTO l_cash_amt FROM tentbankdetl 
			WHERE cash_type_ind = "C" 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_dep_num = p_rec_tentbankdetl.bank_dep_num
			 
			PRINT COLUMN 53, "Cash Total", 
			COLUMN 75, l_cash_amt USING "---,---,--&.&&" 
			SELECT SUM(tran_amt) INTO l_cash_amt FROM tentbankdetl 
			WHERE cash_type_ind = PAYMENT_TYPE_CHEQUE_Q 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_dep_num = p_rec_tentbankdetl.bank_dep_num
			 
			PRINT COLUMN 53, "Cheque Total", 
			COLUMN 75, l_cash_amt USING "---,---,--&.&&" 
			SELECT SUM(tran_amt) INTO l_cash_amt FROM tentbankdetl 
			WHERE cash_type_ind = PAYMENT_TYPE_CC_P 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_dep_num = p_rec_tentbankdetl.bank_dep_num 

			PRINT COLUMN 53, "Credit Card Total", 
			COLUMN 75, l_cash_amt USING "---,---,--&.&&" 
			SELECT SUM(tran_amt) INTO l_cash_amt FROM tentbankdetl 
			WHERE cash_type_ind = "O" 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_dep_num = p_rec_tentbankdetl.bank_dep_num 

			PRINT COLUMN 53, "Other", 
			COLUMN 75, l_cash_amt USING "---,---,--&.&&" 
			SKIP 1 LINE 
			SELECT SUM(tran_amt) INTO l_cash_amt FROM tentbankdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND bank_dep_num = p_rec_tentbankdetl.bank_dep_num 

			PRINT COLUMN 61, "GRAND TOTAL", 
			COLUMN 75, l_cash_amt USING "---,---,--&.&&" 
			SKIP 1 LINE 

	BEFORE GROUP OF p_rec_tentbankdetl.cash_type_ind 
		CASE p_rec_tentbankdetl.cash_type_ind 
			WHEN PAYMENT_TYPE_CASH_C 
				LET l_type_text = NULL 
				
			WHEN PAYMENT_TYPE_CHEQUE_Q 
				LET l_type_text = "CHEQUES" 
				PRINT COLUMN 01, l_type_text CLIPPED 
				PRINT 
				COLUMN 01, "DRAWER", 
				COLUMN 23, "BANK", 
				COLUMN 42, "BRANCH", 
				COLUMN 64, "CHEQUE NO" 
				SKIP 1 LINE 
					
			WHEN PAYMENT_TYPE_CC_P 
				LET l_type_text = "CREDIT CARDS" 
				PRINT COLUMN 01, l_type_text  CLIPPED
				PRINT 
				COLUMN 01, "CARD HOLDER", 
				COLUMN 23, "BANK", 
				COLUMN 42, "CARD NUMBER" 
				SKIP 1 LINE 
				
			OTHERWISE 
				LET l_type_text = "OTHER PAYMENT TYPES" 
				PRINT COLUMN 01, l_type_text CLIPPED
				PRINT 
				COLUMN 01, "DRAWER / SOURCE", 
				COLUMN 23, "BANK", 
				COLUMN 42, "BRANCH", 
				COLUMN 63, "PAYMENT TYPE" 
				SKIP 1 LINE 
		END CASE 

	ON EVERY ROW 
		IF p_rec_tentbankdetl.cash_type_ind != "C" THEN 
			PRINT 
			COLUMN 01, p_rec_tentbankdetl.drawer_text CLIPPED, 
			COLUMN 23, p_rec_tentbankdetl.bank_text CLIPPED, 
			COLUMN 42, p_rec_tentbankdetl.branch_text CLIPPED, 
			COLUMN 63, p_rec_tentbankdetl.cheque_text CLIPPED, 
			COLUMN 75, p_rec_tentbankdetl.tran_amt             USING "---,---,--&.&&" 
		END IF 

	AFTER GROUP OF p_rec_tentbankdetl.cash_type_ind 
		IF p_rec_tentbankdetl.cash_type_ind != "C" THEN 
			PRINT 
			COLUMN 42, "TOTAL FOR ",l_type_text CLIPPED, 
			COLUMN 75, GROUP SUM( p_rec_tentbankdetl.tran_amt) USING "---,---,--&.&&" 
			SKIP 1 LINE 
		END IF 

	ON LAST ROW 
		SKIP 4 LINES 
		PRINT COLUMN 01, "Paid in by: ........................................" 
		SKIP 1 LINE 
		PRINT COLUMN 01, "Deposit : ", l_rec_tentbankhead.desc_text CLIPPED 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text CLIPPED WORDWRAP RIGHT MARGIN 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report 			
		LET glob_arr_rec_rpt_rmsreps[p_rpt_idx].page_num = PAGENO

END REPORT
#######################################################################
# END REPORT A64_rpt_deposit_slip()
#######################################################################