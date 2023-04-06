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

#	Source code beautified by beautify.pl on 2020-01-03 09:12:31	$Id: $

#KandooERP runs on Querix Lycia www.querix.com
#Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../gl/GC_GROUP_GLOBALS.4gl" 
GLOBALS "../gl/GC9_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################
DEFINE modu_rec_bank RECORD LIKE bank.* 
DEFINE modu_clo_bal_amt MONEY(12,2) 
DEFINE modu_op_bal_amt MONEY(12,2) 
DEFINE modu_dr_tot_amt MONEY(12,2) 
DEFINE modu_cr_tot_amt MONEY(12,2) 
DEFINE modu_start_sheet_num SMALLINT 
DEFINE modu_end_sheet_num SMALLINT 

###########################################################################
# FUNCTION GC9_main()
#
# Purpose - Bank Statement Report
###########################################################################
FUNCTION GC9_main() 
	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("GC9") 

	IF get_gl_setup_cash_book_installed() != "Y" THEN 
		CALL msgcontinue("",kandoomsg2("G",9502,""))
		EXIT PROGRAM 
	END IF 

	CREATE TEMP TABLE t_recon ( 
	re_rowid INTEGER, 
	re_seq_no SMALLINT, 
	re_date DATE, 
	re_type NCHAR(2), 
	re_ref INTEGER, 
	re_desc NCHAR(30), 
	re_debit MONEY(12,2), 
	re_cred MONEY(12,2), 
	re_bank_code NCHAR(9), 
	re_name_acct_text NCHAR(40), 
	re_acct_code NCHAR(18), 
	re_iban NCHAR(40), 
	re_currency_code NCHAR(3), 
	re_sheet_num SMALLINT 
	) with no LOG 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 
			OPEN WINDOW G182 with FORM "G182" 
			CALL windecoration_g("G182")
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU "Bank statements" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","GC9","menu-bank-statements") 
					CALL rpt_rmsreps_reset(NULL)
					CALL GC9_rpt_process(GC9_rpt_query())
					
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "REPORT" #COMMAND "Run" " Enter selection criteria AND begin purge" 
					CALL rpt_rmsreps_reset(NULL)
					CALL GC9_rpt_process(GC9_rpt_query())

				ON ACTION "Print Manager"			#COMMAND KEY ("P",f11) "Print" " Print purge reports"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" #COMMAND KEY(interrupt,"E") "Exit" " RETURN TO Menus" 
					EXIT MENU 

			END MENU 
			CLOSE WINDOW G182 
	 
		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL GC9_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW G182 with FORM "G182" 
			CALL windecoration_g("G182") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(GC9_rpt_query()) #save where clause in env 
			CLOSE WINDOW G182 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL GC9_rpt_process(get_url_sel_text())
	END CASE 	

END FUNCTION


############################################################
# FUNCTION GC9_rpt_query()
#
#
############################################################
FUNCTION GC9_rpt_query() 
	DEFINE r_where_text STRING
	DEFINE l_cnt INTEGER
	DEFINE start_sheet_num UI.ComboBox
	DEFINE end_sheet_num UI.ComboBox
	DEFINE i INTEGER

	MESSAGE kandoomsg2("P",1051,"") 

	CLEAR FORM
	INPUT 
		modu_rec_bank.bank_code, 
		modu_start_sheet_num, 
		modu_end_sheet_num 
	FROM 
		bank_code, 
		start_sheet_num, 
		end_sheet_num ATTRIBUTE(UNBUFFERED)

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","GC9","inp-bank-sheet") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) RETURNING modu_rec_bank.bank_code, 
			modu_rec_bank.acct_code 
			DISPLAY modu_rec_bank.bank_code TO bank_code 
			NEXT FIELD bank_code 

		ON CHANGE bank_code
			CALL ui.combobox.forname("start_sheet_num").clear()
			CALL ui.combobox.forname("end_sheet_num").clear()

			SELECT bank.* 
			INTO modu_rec_bank.* 
			FROM bank 
			WHERE bank.bank_code = modu_rec_bank.bank_code 
			AND bank.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF STATUS = NOTFOUND THEN 
				ERROR "Bank code not found"
				NEXT FIELD bank_code 
			END IF 

			DISPLAY modu_rec_bank.name_acct_text TO name_acct_text 
			DISPLAY modu_rec_bank.iban TO iban 
			DISPLAY modu_rec_bank.bic_code TO bic_code
			DISPLAY modu_rec_bank.sheet_num TO sheet_num 

			IF modu_rec_bank.sheet_num IS NULL OR modu_rec_bank.sheet_num <= 0 THEN
				ERROR "No valid statements exist for this bank (may be bank.sheet_num IS NULL or bank.sheet_num = 0)"
				NEXT FIELD bank_code
			END IF

			# Needs to be done dynamically after require values of 'bank' table are entered
			LET modu_start_sheet_num = modu_rec_bank.sheet_num
			LET modu_end_sheet_num  = modu_rec_bank.sheet_num
			FOR i = 1 TO modu_rec_bank.sheet_num 			
   			CALL ui.ComboBox.ForName("start_sheet_num").addItem(i,i)
   			CALL ui.ComboBox.ForName("end_sheet_num").addItem(i,i)
			END FOR 

		AFTER INPUT
			IF modu_start_sheet_num > modu_end_sheet_num THEN
				ERROR "Invalid value entered."
				NEXT FIELD start_sheet_num
			END IF 

	END INPUT 

	IF int_flag = 1 OR quit_flag = 1 THEN 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_code = modu_rec_bank.bank_code 
		LET glob_rec_rpt_selector.ref1_num  = modu_start_sheet_num   
		LET glob_rec_rpt_selector.ref2_num  = modu_end_sheet_num 
		LET r_where_text = " 1=1"
		RETURN r_where_text	
	END IF 

END FUNCTION 
####################################################################
# END FUNCTION GC9_rpt_query()
####################################################################


####################################################################
# FUNCTION GC9_rpt_process(p_where_text) 
#
# The report driver
####################################################################
FUNCTION GC9_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT
	DEFINE l_rec_a_recon 
	RECORD 
		re_rowid INTEGER, 
		re_seq_no SMALLINT, 
		re_date DATE, 
		re_type NCHAR(2), 
		re_ref INTEGER, 
		re_desc NCHAR(30), 
		re_debit MONEY(12,2), 
		re_cred MONEY(12,2), 
		re_bank_code NCHAR(9), 
		re_name_acct_text NCHAR(40), 
		re_acct_code NCHAR(18), 
		re_iban NCHAR(40), 
		re_currency_code NCHAR(3), 
		re_sheet_num SMALLINT 
	END RECORD
	DEFINE l_rec_recon 
	RECORD 
		re_seq_no SMALLINT, 
		re_date DATE, 
		re_type NCHAR(2), 
		re_ref INTEGER, 
		re_desc NCHAR(30), 
		re_debit MONEY(12,2), 
		re_cred MONEY(12,2) 
	END RECORD
	DEFINE l_sql_stmt STRING
	DEFINE l_rowid INTEGER
	DEFINE l_cheque_curr_code LIKE cheque.currency_code
	DEFINE l_cheque_conv_qty LIKE cheque.conv_qty
	DEFINE l_cnt SMALLINT
	DEFINE l_counter SMALLINT

	#------------------------------------------------------------
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"GC9_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	

	START REPORT GC9_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

	LET modu_rec_bank.bank_code = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_code
	LET modu_start_sheet_num    = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num 
	LET modu_end_sheet_num      = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_num

	LET l_sql_stmt = "INSERT INTO t_recon VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?,?)" 

	PREPARE pp_sql_line FROM l_sql_stmt 
	DECLARE ins_rec_curs CURSOR FOR pp_sql_line 

	LET modu_clo_bal_amt = 0 

	BEGIN WORK 

		DELETE FROM t_recon 
		FOR l_counter = modu_start_sheet_num TO modu_end_sheet_num 
			# first load cheques FROM cheque accounts payable AP
			OPEN ins_rec_curs 

			LET l_query_text = 
         "SELECT ",
         "C.rowid,",
         "C.rec_line_num,",
         "C.cheq_date,",
         "C.cheq_code,",
         "V.name_text,",
         "C.net_pay_amt,",
         "C.currency_code,",
         "C.conv_qty ",
			"FROM cheque C, OUTER vendor V ", 
			"WHERE C.cmpy_code = '", trim(glob_rec_kandoouser.cmpy_code),"' " , 
			"AND C.bank_acct_code = '", trim(modu_rec_bank.acct_code),"' ", 
			"AND C.rec_state_num = ", trim(l_counter)," ", 
			"AND C.part_recon_flag IS NULL ", 
			"AND V.cmpy_code = C.cmpy_code ", 
			"AND V.vend_code = C.vend_code "

			PREPARE eeq FROM l_query_text 
			DECLARE cb_2 CURSOR FOR eeq 

			LET l_cnt = 0 
			INITIALIZE l_rec_recon.* TO NULL 
			FOREACH cb_2 INTO l_rowid, 
				l_rec_recon.re_seq_no, 
				l_rec_recon.re_date, 
				l_rec_recon.re_ref, 
				l_rec_recon.re_desc, 
				l_rec_recon.re_debit, 
				l_cheque_curr_code, 
				l_cheque_conv_qty 
				IF l_cheque_curr_code != modu_rec_bank.currency_code THEN 
					LET l_rec_recon.re_debit = 
					l_rec_recon.re_debit / l_cheque_conv_qty 
				END IF 
				LET l_cnt = l_cnt + 1 
				LET l_rec_recon.re_type = "AP" 
				PUT ins_rec_curs FROM l_rowid, l_rec_recon.*,modu_rec_bank.bank_code, 
				modu_rec_bank.name_acct_text, modu_rec_bank.acct_code, 
				modu_rec_bank.iban, 
				modu_rec_bank.currency_code,l_counter 
			END FOREACH 

			# now load banking details FROM banking, CD deposits credit, BC Bank Charges debit
			DECLARE cb_3 CURSOR FOR 
			SELECT banking.rowid, banking.bk_seq_no, banking.bk_bankdt, banking.bk_type, 
			banking.bk_desc, banking.bk_debit, banking.bk_cred 
			FROM banking 
			WHERE banking.bk_cmpy = glob_rec_kandoouser.cmpy_code 
			AND banking.bk_acct = modu_rec_bank.acct_code 
			AND banking.bk_sh_no = l_counter 
			AND banking.bk_rec_part IS NULL 
 
			INITIALIZE l_rec_recon.* TO NULL 
			FOREACH cb_3 INTO l_rowid, l_rec_recon.re_seq_no, l_rec_recon.re_date, 
				l_rec_recon.re_type, l_rec_recon.re_desc, l_rec_recon.re_debit, 
				l_rec_recon.re_cred 
				LET l_cnt = l_cnt + 1 
				PUT ins_rec_curs FROM l_rowid, l_rec_recon.*,modu_rec_bank.bank_code, 
				modu_rec_bank.name_acct_text, modu_rec_bank.acct_code, 
				modu_rec_bank.iban, 
				modu_rec_bank.currency_code,l_counter 
			END FOREACH 
			CLOSE ins_rec_curs 
		END FOR 

	COMMIT WORK 

	DECLARE cb_4 CURSOR FOR 
	SELECT * 
	INTO l_rec_a_recon.* 
	FROM t_recon 
	ORDER BY t_recon.re_bank_code, t_recon.re_sheet_num, t_recon.re_seq_no, t_recon.re_type, t_recon.re_date 

	LET modu_op_bal_amt = 0 
	LET modu_clo_bal_amt = 0 
	FOREACH cb_4 
		#---------------------------------------------------------
		OUTPUT TO REPORT GC9_rpt_list(l_rpt_idx,l_rec_a_recon.*) 
		IF NOT rpt_int_flag_handler2("Statment Number:",l_rec_a_recon.re_sheet_num, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		
	END FOREACH 
	 
	#------------------------------------------------------------
	FINISH REPORT GC9_rpt_list
	RETURN rpt_finish("GC9_rpt_list")
	#------------------------------------------------------------

END FUNCTION 
####################################################################
# END FUNCTION GC9_rpt_process() 
####################################################################

############################################################
# REPORT GC9_rpt_list(p_rec_recon)
#
#
############################################################
REPORT GC9_rpt_list(p_rpt_idx,p_rec_recon) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_recon 
	RECORD 
		re_rowid INTEGER, 
		re_seq_no SMALLINT, 
		re_date DATE, 
		re_type NCHAR(2), 
		re_ref INTEGER, 
		re_desc NCHAR(30), 
		re_debit MONEY(12,2), 
		re_cred MONEY(12,2), 
		re_bank_code NCHAR(9), 
		re_name_acct_text NCHAR(40), 
		re_acct_code NCHAR(18), 
		re_iban NCHAR(40), 
		re_currency_code NCHAR(3), 
		re_sheet_num SMALLINT 
	END RECORD 
	DEFINE l_action_flag INTEGER 
	DEFINE l_rowid INTEGER 
	DEFINE l_bal_amt MONEY(12,2)

	ORDER EXTERNAL BY p_rec_recon.re_bank_code,p_rec_recon.re_sheet_num 

	FORMAT 
		PAGE HEADER 
			IF PAGENO = 1 THEN 
				LET l_action_flag = 0 
				LET modu_dr_tot_amt = 0 
				LET modu_cr_tot_amt = 0 
				LET l_bal_amt = 0 
			END IF 

			CALL rpt_set_page_num(p_rpt_idx,PAGENO) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 CLIPPED #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 CLIPPED #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 CLIPPED #wasl_arr_line[3]  

			PRINT COLUMN 01, "Bank Code: ",p_rec_recon.re_bank_code CLIPPED, 
			COLUMN 32,"Name: ",p_rec_recon.re_name_acct_text CLIPPED 
			PRINT COLUMN 01, "Bank Account: ",p_rec_recon.re_iban CLIPPED 
			PRINT COLUMN 01, "GL Account: ", p_rec_recon.re_acct_code CLIPPED, 
			COLUMN 32,"Currency: ", p_rec_recon.re_currency_code CLIPPED 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3  CLIPPED #wasl_arr_line[3] 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text CLIPPED 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3  CLIPPED #wasl_arr_line[3] 

	BEFORE GROUP OF p_rec_recon.re_bank_code 
		SELECT t_recon.re_cred 
		INTO modu_op_bal_amt 
		FROM t_recon 
		WHERE t_recon.re_sheet_num = p_rec_recon.re_sheet_num
		AND t_recon.re_type = "XO" 
		LET l_bal_amt = modu_op_bal_amt 

	BEFORE GROUP OF p_rec_recon.re_sheet_num 
		LET l_action_flag = 0 
		PRINT COLUMN 1, "Sheet Number: ", p_rec_recon.re_sheet_num 
		LET modu_dr_tot_amt = 0 
		LET modu_cr_tot_amt = 0 

		SELECT t_recon.re_cred 
		INTO modu_op_bal_amt 
		FROM t_recon 
		WHERE t_recon.re_sheet_num = p_rec_recon.re_sheet_num 
		AND t_recon.re_type = "XO" 
		PRINT COLUMN 1, "Opening Balance: ",modu_op_bal_amt   USING "----,---,--&.&&" 

	ON EVERY ROW 
		# opening balance row, don't put it INTO the array
		LET l_action_flag = 1 
		IF p_rec_recon.re_type = "XO" THEN 
		ELSE 
			# closing balance row, don't put it INTO the array
			IF p_rec_recon.re_type = "XC" THEN 
			ELSE 
				PRINT 
				COLUMN 01, p_rec_recon.re_seq_no                USING "####", 
				COLUMN 06, p_rec_recon.re_date                  USING "dd/mm/yy", 
				COLUMN 15, p_rec_recon.re_type CLIPPED, 
				COLUMN 21, p_rec_recon.re_ref                   USING "######", 
				COLUMN 28, p_rec_recon.re_desc CLIPPED; 
				IF p_rec_recon.re_debit IS NOT NULL THEN 
					PRINT COLUMN 61, p_rec_recon.re_debit        USING "----,---,--&.&&"; 
					LET modu_dr_tot_amt = modu_dr_tot_amt + p_rec_recon.re_debit 
					LET l_bal_amt = l_bal_amt - p_rec_recon.re_debit 
				ELSE 
					PRINT COLUMN 77, p_rec_recon.re_cred         USING "----,---,--&.&&"; 
					LET modu_cr_tot_amt = modu_cr_tot_amt + p_rec_recon.re_cred 
					LET l_bal_amt = l_bal_amt + p_rec_recon.re_cred 
				END IF 
				PRINT COLUMN 93,l_bal_amt                       USING "----,---,--&.&&" 
			END IF 
		END IF 

	AFTER GROUP OF p_rec_recon.re_sheet_num 
		IF l_action_flag = 0 THEN 
			PRINT COLUMN 05, "No transactions on this statement" 
		ELSE 
			PRINT COLUMN 61,"---------------", 
			COLUMN 77,"---------------", 
			COLUMN 93,"---------------" 
			PRINT COLUMN 1, "Totals: ", 
			COLUMN 61, modu_dr_tot_amt                         USING "----,---,--&.&&", 
			COLUMN 77, modu_cr_tot_amt                         USING "----,---,--&.&&", 
			COLUMN 93,l_bal_amt                                USING "----,---,--&.&&" 
		END IF 
		SELECT t_recon.re_debit 
		INTO modu_clo_bal_amt 
		FROM t_recon 
		WHERE t_recon.re_sheet_num = p_rec_recon.re_sheet_num 
		AND t_recon.re_type = "XC" 
		PRINT 
		PRINT COLUMN 01, "Closing Balance: ",modu_clo_bal_amt USING "----,---,--&.&&" 
		SKIP 2 LINES 

	ON LAST ROW 
		#End Of Report
		IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
			PRINT COLUMN 01,"Selection Criteria:" 
			PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
		END IF 
		PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
END REPORT 
