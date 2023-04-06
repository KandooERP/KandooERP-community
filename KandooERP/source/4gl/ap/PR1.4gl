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
# Purpose : Detailed Account Aging

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PR1_GLOBALS.4gl"

############################################################
# Module Scope Variables
############################################################


############################################################
# Module Scope Variables
############################################################
DEFINE modu_agedate DATE 
DEFINE modu_conv_ind CHAR(1) 
DEFINE modu_tot_unpaid DECIMAL(16,2) 
DEFINE modu_tot_curr DECIMAL(16,2) 
DEFINE modu_tot_o30 DECIMAL(16,2) 
DEFINE modu_tot_o60 DECIMAL(16,2) 
DEFINE modu_tot_o90 DECIMAL(16,2) 
DEFINE modu_tot_plus DECIMAL(16,2) 
DEFINE modu_notes_flag CHAR(1) 

############################################################
# FUNCTION ap_pr0(p_mode) 
#
#
############################################################
FUNCTION ap_pr0(p_mode) 
	DEFINE p_mode int -- 1=via ar MENU 0=direct CALL 

	IF p_mode <> 1 THEN 
		CALL authenticate("PR1") 
		CALL init_p_ap() #init a/ap module 
	END IF
	
	SELECT * INTO glob_rec_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 
	LET modu_agedate = today 
	LET modu_conv_ind = "1" 
	LET modu_notes_flag = "N" 

	#######################################################################
	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW P100 with FORM "P100" 
			CALL windecoration_p("P100") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Aging Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","PR1","menu-aging_rep-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "REPORT" 					#COMMAND "Run" " Enter selection criteria AND generate report"
					CALL rpt_rmsreps_reset(NULL)
					CALL PR1_rpt_process(PR1_rpt_query()) 

				ON ACTION "Aging Defaults"					#COMMAND "Aging Defaults" " Enter Date TO age TO"
					OPEN WINDOW U511 with FORM "U511" 
					CALL winDecoration_u("U511") 

					INPUT 
						modu_agedate, 
						modu_conv_ind, 
						modu_notes_flag WITHOUT DEFAULTS 
					FROM 
						age_date, 
						conv_ind, 
						notes_flag ATTRIBUTE(UNBUFFERED) 

						BEFORE INPUT 
							CALL publish_toolbar("kandoo","PR1","inp-aging_defaults-1") 

						ON ACTION "WEB-HELP" 
							CALL onlinehelp(getmoduleid(),null) 

						ON ACTION "actToolbarManager" 
							CALL setuptoolbar() 

						AFTER FIELD pr_date 
							IF modu_agedate IS NULL THEN 
								NEXT FIELD pr_date 
							END IF 

					END INPUT 

					CLOSE WINDOW U511 
					NEXT option "Run" 

				ON ACTION "Print Manager" 				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "CANCEL" 				#COMMAND KEY("E",interrupt)"CANCEL" " Exit TO menus"
					EXIT MENU 

			END MENU 

			CLOSE WINDOW P100 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PR1_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P100 with FORM "P100" 
			CALL windecoration_p("P100") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PR1_rpt_query()) #save where clause in env 
			CLOSE WINDOW P100 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PR1_rpt_process(get_url_sel_text())
	END CASE 
	
END FUNCTION 


############################################################
# FUNCTION PR1_rpt_query()
#
#
############################################################
FUNCTION PR1_rpt_query() 
	DEFINE l_where_text STRING

	MESSAGE kandoomsg2("U",1001,"") #1001 Enter criteria FOR selection - press ESC TO begin REPORT"
	CONSTRUCT BY NAME l_where_text ON vendor.vend_code, 
	vendor.name_text, 
	vendor.addr1_text, 
	vendor.addr2_text, 
	vendor.addr3_text, 
	vendor.city_text, 
	vendor.state_code, 
	vendor.post_code, 
	vendor.country_code, 
--@db-patch_2020_10_04--	vendor.country_text, 
	vendor.our_acct_code, 
	vendor.contact_text, 
	vendor.tele_text, 
	vendor.extension_text, 
	vendor.fax_text, 
	vendor.type_code, 
	vendor.term_code, 
	vendor.tax_code, 
	vendor.currency_code, 
	vendor.tax_text, 
	vendor.bank_acct_code, 
	vendor.drop_flag, 
	vendor.language_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PR1","construct-vendor-1") 

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
		LET glob_rec_rpt_selector.ref1_date = modu_agedate
		RETURN l_where_text 
	END IF 
END FUNCTION 


############################################################
# FUNCTION PR1_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PR1_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_tmp_str STRING	
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_tempdoc
	 
	RECORD 
		tm_vend LIKE vendor.vend_code, 
		tm_name LIKE vendor.name_text, 
		tm_cury LIKE vendor.currency_code, 
		tm_tele LIKE vendor.tele_text, 
		tm_date LIKE vendor.setup_date, 
		tm_type CHAR(2), 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_late INTEGER, 
		tm_conv_qty FLOAT, 
		tm_amount DECIMAL(16,2), 
		tm_unpaid DECIMAL(16,2), 
		tm_curr DECIMAL(16,2), 
		tm_o30 DECIMAL(16,2), 
		tm_o60 DECIMAL(16,2), 
		tm_o90 DECIMAL(16,2), 
		tm_plus DECIMAL(16,2) 
	END RECORD 
	DEFINE l_rec_voucher 
	RECORD 
		vend_code LIKE voucher.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		tele_text LIKE vendor.tele_text, 
		vouch_code LIKE voucher.vouch_code, 
		vouch_date LIKE voucher.vouch_date, 
		due_date LIKE voucher.due_date, 
		inv_text LIKE voucher.inv_text, 
		total_amt LIKE voucher.total_amt, 
		paid_amt LIKE voucher.paid_amt, 
		conv_qty LIKE voucher.conv_qty 
	END RECORD 
	DEFINE l_rec_debithead 
	RECORD 
		vend_code LIKE debithead.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		tele_text LIKE vendor.tele_text, 
		debit_num LIKE debithead.debit_num, 
		debit_date LIKE debithead.debit_date, 
		debit_text LIKE debithead.debit_text, 
		total_amt LIKE debithead.total_amt, 
		apply_amt LIKE debithead.apply_amt, 
		conv_qty LIKE debithead.conv_qty 
	END RECORD 
	DEFINE l_rec_cheque RECORD 
		vend_code LIKE cheque.vend_code, 
		name_text LIKE vendor.name_text, 
		currency_code LIKE vendor.currency_code, 
		tele_text LIKE vendor.tele_text, 
		cheq_code LIKE cheque.cheq_code, 
		cheq_date LIKE cheque.cheq_date, 
		com3_text LIKE cheque.com3_text, 
		pay_amt LIKE cheque.pay_amt, 
		apply_amt LIKE cheque.apply_amt, 
		conv_qty LIKE cheque.conv_qty 
	END RECORD 
	DEFINE l_continue_flag SMALLINT 
	DEFINE l_query_text STRING

	LET modu_tot_unpaid = 0 
	LET modu_tot_curr = 0 
	LET modu_tot_o30 = 0 
	LET modu_tot_o60 = 0 
	LET modu_tot_o90 = 0 
	LET modu_tot_plus = 0 
	LET l_continue_flag = true 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PR1_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PR1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#Case specific rems_reps works...
	LET modu_agedate  = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_date
	LET l_tmp_str = "Aging FROM: ", modu_agedate USING "dd/mm/yy"
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, l_tmp_str)
	#------------------------------------------------------------


	LET l_query_text = "SELECT voucher.vend_code,", 
	"vendor.name_text,", 
	"vendor.currency_code,", 
	"vendor.tele_text,", 
	"voucher.vouch_code,", 
	"voucher.vouch_date,", 
	"voucher.due_date,", 
	"voucher.inv_text, ", 
	"voucher.total_amt,", 
	"voucher.paid_amt, ", 
	"voucher.conv_qty ", 
	"FROM voucher,", 
	"vendor ", 
	"WHERE vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND voucher.vend_code = vendor.vend_code ", 
	"AND voucher.cmpy_code = vendor.cmpy_code ", 
	"AND voucher.total_amt != voucher.paid_amt ", 
	"AND voucher.post_flag != 'V' ", 
	"AND voucher.vouch_date <= '",modu_agedate,"' ", 
	"AND ",p_where_text clipped 
	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR FOR s_voucher
	 
	FOREACH c_voucher INTO l_rec_voucher.* 
		LET l_rec_tempdoc.tm_vend = l_rec_voucher.vend_code 
		LET l_rec_tempdoc.tm_name = l_rec_voucher.name_text 
		LET l_rec_tempdoc.tm_cury = l_rec_voucher.currency_code 
		LET l_rec_tempdoc.tm_tele = l_rec_voucher.tele_text 
		LET l_rec_tempdoc.tm_date = l_rec_voucher.vouch_date 
		LET l_rec_tempdoc.tm_type = "VO" 
		LET l_rec_tempdoc.tm_doc = l_rec_voucher.vouch_code 
		LET l_rec_tempdoc.tm_refer = l_rec_voucher.inv_text 
		LET l_rec_tempdoc.tm_late = modu_agedate - l_rec_voucher.due_date 
		LET l_rec_tempdoc.tm_conv_qty = l_rec_voucher.conv_qty 
		LET l_rec_tempdoc.tm_amount = l_rec_voucher.total_amt 
		LET l_rec_tempdoc.tm_unpaid = l_rec_voucher.total_amt - l_rec_voucher.paid_amt 
		LET l_rec_tempdoc.tm_plus = 0 
		LET l_rec_tempdoc.tm_o90 = 0 
		LET l_rec_tempdoc.tm_o60 = 0 
		LET l_rec_tempdoc.tm_o30 = 0 
		LET l_rec_tempdoc.tm_curr = 0 
		CASE 
			WHEN l_rec_tempdoc.tm_late > 90 
				LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
			WHEN l_rec_tempdoc.tm_late > 60 
				LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
			WHEN l_rec_tempdoc.tm_late > 30 
				LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
			WHEN l_rec_tempdoc.tm_late > 0 
				LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
			OTHERWISE 
				LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
		END CASE
		 
		INSERT INTO shuffle VALUES (l_rec_tempdoc.*)

		#---------------------------------------------------------
		# Cancel ?
		IF NOT rpt_int_flag_handler2("Voucher:",l_rec_voucher.name_text,l_rec_voucher.vouch_code,l_rpt_idx) THEN
			LET l_continue_flag = false 
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------
		 
	END FOREACH 

	IF l_continue_flag THEN 
		LET l_query_text = "SELECT debithead.vend_code,", 
		"vendor.name_text,", 
		"vendor.currency_code,", 
		"vendor.tele_text,", 
		"debithead.debit_num,", 
		"debithead.debit_date,", 
		"debithead.debit_text,", 
		"debithead.total_amt,", 
		"debithead.apply_amt, ", 
		"debithead.conv_qty ", 
		"FROM debithead,", 
		"vendor ", 
		"WHERE vendor.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND debithead.cmpy_code = vendor.cmpy_code ", 
		"AND debithead.vend_code = vendor.vend_code ", 
		"AND debithead.total_amt != debithead.apply_amt ", 
		"AND debithead.post_flag != 'V' ", 
		"AND debithead.debit_date <= '",modu_agedate,"' ", 
		"AND ",p_where_text clipped 
		PREPARE creditor FROM l_query_text 
		DECLARE credcurs CURSOR FOR creditor 

		FOREACH credcurs INTO l_rec_debithead.* 
			LET l_rec_tempdoc.tm_vend = l_rec_debithead.vend_code 
			LET l_rec_tempdoc.tm_name = l_rec_debithead.name_text 
			LET l_rec_tempdoc.tm_cury = l_rec_debithead.currency_code 
			LET l_rec_tempdoc.tm_tele = l_rec_debithead.tele_text 
			LET l_rec_tempdoc.tm_date = l_rec_debithead.debit_date 
			LET l_rec_tempdoc.tm_type = "DB" 
			LET l_rec_tempdoc.tm_doc = l_rec_debithead.debit_num 
			LET l_rec_tempdoc.tm_refer = l_rec_debithead.debit_text 
			LET l_rec_tempdoc.tm_late = 0 
			LET l_rec_tempdoc.tm_conv_qty = l_rec_debithead.conv_qty 
			LET l_rec_tempdoc.tm_amount = 0 
			LET l_rec_tempdoc.tm_amount = l_rec_tempdoc.tm_amount - 
			l_rec_debithead.total_amt 
			LET l_rec_tempdoc.tm_unpaid = l_rec_debithead.apply_amt - 
			l_rec_debithead.total_amt 
			LET l_rec_tempdoc.tm_plus = 0 
			LET l_rec_tempdoc.tm_o90 = 0 
			LET l_rec_tempdoc.tm_o60 = 0 
			LET l_rec_tempdoc.tm_o30= 0 
			LET l_rec_tempdoc.tm_curr = 0 
			CASE 
				WHEN l_rec_tempdoc.tm_late > 90 
					LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_late > 60 
					LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_late > 30 
					LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_late > 0 
					LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
				OTHERWISE 
					LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
			END CASE 

			INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 

			#---------------------------------------------------------
			# Cancel ?
			IF NOT rpt_int_flag_handler2("Debit:",l_rec_debithead.name_text,l_rec_debithead.debit_num,l_rpt_idx) THEN
				LET l_continue_flag = false 
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

		END FOREACH 

	END IF 

	IF l_continue_flag THEN 
		LET l_query_text = "SELECT cheque.vend_code,", 
		"vendor.name_text,", 
		"vendor.currency_code,", 
		"vendor.tele_text,", 
		"cheque.cheq_code,", 
		"cheque.cheq_date,", 
		"cheque.com3_text,", 
		"cheque.pay_amt,", 
		"cheque.apply_amt, ", 
		"cheque.conv_qty ", 
		"FROM cheque,", 
		"vendor ", 
		"WHERE vendor.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND cheque.cmpy_code = vendor.cmpy_code ", 
		"AND cheque.vend_code = vendor.vend_code ", 
		"AND cheque.pay_amt != cheque.apply_amt ", 
		"AND cheque.cheq_date <= '",modu_agedate,"' ", 
		"AND cheque.post_flag != 'V' ", 
		"AND ",p_where_text clipped 
		PREPARE casher FROM l_query_text 
		DECLARE cashcurs CURSOR FOR casher 

		FOREACH cashcurs INTO l_rec_cheque.* 
			LET l_rec_tempdoc.tm_vend = l_rec_cheque.vend_code 
			LET l_rec_tempdoc.tm_name = l_rec_cheque.name_text 
			LET l_rec_tempdoc.tm_cury = l_rec_cheque.currency_code 
			LET l_rec_tempdoc.tm_tele = l_rec_cheque.tele_text 
			LET l_rec_tempdoc.tm_date = l_rec_cheque.cheq_date 
			LET l_rec_tempdoc.tm_type = "CH" 
			LET l_rec_tempdoc.tm_doc = l_rec_cheque.cheq_code 
			LET l_rec_tempdoc.tm_refer = l_rec_cheque.com3_text 
			LET l_rec_tempdoc.tm_late = 0 
			LET l_rec_tempdoc.tm_conv_qty = l_rec_cheque.conv_qty 
			LET l_rec_tempdoc.tm_amount = 0 
			LET l_rec_tempdoc.tm_amount = l_rec_tempdoc.tm_amount - l_rec_cheque.pay_amt 
			LET l_rec_tempdoc.tm_unpaid = l_rec_cheque.apply_amt - l_rec_cheque.pay_amt 
			LET l_rec_tempdoc.tm_plus = 0 
			LET l_rec_tempdoc.tm_o90 = 0 
			LET l_rec_tempdoc.tm_o60 = 0 
			LET l_rec_tempdoc.tm_o30= 0 
			LET l_rec_tempdoc.tm_curr = 0 
			CASE 
				WHEN l_rec_tempdoc.tm_late > 90 
					LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_late > 60 
					LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_late > 30 
					LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_late > 0 
					LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
				OTHERWISE 
					LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
			END CASE 

			INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 

			#---------------------------------------------------------
			# Cancel ?
			IF NOT rpt_int_flag_handler2("Cheque:",l_rec_cheque.name_text,l_rec_cheque.cheq_code,l_rpt_idx) THEN
				LET l_continue_flag = false 
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

		END FOREACH 

	END IF 

	################################
	#   VOUCHERPAYS
	################################
	# Now we need TO reopen anything closed since the cutoff date
	#################################################################
	LET l_query_text = 
	"SELECT voucherpays.* FROM voucherpays,vendor ", 
	" WHERE voucherpays.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	"AND voucherpays.pay_date > '",modu_agedate,"' ", 
	"AND voucherpays.cmpy_code = vendor.cmpy_code ", 
	"AND voucherpays.vend_code = vendor.vend_code ", 
	"AND ", p_where_text clipped 
	PREPARE s_voucherpays FROM l_query_text 
	DECLARE c_voucherpays CURSOR FOR s_voucherpays 

	FOREACH c_voucherpays INTO l_rec_voucherpays.* 
		#################################################################
		# The voucher should already be in the temporary table IF it
		# was entered before the cutoff date AND paid later
		#################################################################
		SELECT * INTO l_rec_tempdoc.* 
		FROM shuffle 
		WHERE tm_doc = l_rec_voucherpays.vouch_code 
		AND tm_type = "VO" 
		IF status = 0 THEN 
			LET l_rec_tempdoc.tm_unpaid = l_rec_tempdoc.tm_unpaid + 
			l_rec_voucherpays.apply_amt + 
			l_rec_voucherpays.disc_amt 
			CASE 
				WHEN l_rec_tempdoc.tm_late > 90 
					LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_late > 60 
					LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_late > 30 
					LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
				WHEN l_rec_tempdoc.tm_late > 0 
					LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
				OTHERWISE 
					LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
			END CASE 
			UPDATE shuffle SET tm_unpaid = l_rec_tempdoc.tm_unpaid, 
			tm_plus = l_rec_tempdoc.tm_plus, 
			tm_o90 = l_rec_tempdoc.tm_o90, 
			tm_o60 = l_rec_tempdoc.tm_o60, 
			tm_o30 = l_rec_tempdoc.tm_o30, 
			tm_cur = l_rec_tempdoc.tm_curr 
			WHERE tm_doc = l_rec_voucherpays.vouch_code 
			AND tm_type = "VO" 
		ELSE 
			###################################################################
			# But paid date IS NOT always applied date so check Invoice if
			# it IS NOT in temporary table AND add it IF it was entered
			# before the cutoff date
			###################################################################
			SELECT voucher.vend_code, 
			vendor.name_text, 
			vendor.currency_code, 
			vendor.tele_text, 
			voucher.vouch_code, 
			voucher.vouch_date, 
			voucher.due_date, 
			voucher.inv_text, 
			voucher.total_amt, 
			voucher.paid_amt, 
			voucher.conv_qty 
			INTO l_rec_voucher.* 
			FROM voucher, vendor 
			WHERE voucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND voucher.vouch_code = l_rec_voucherpays.vouch_code 
			AND voucher.vend_code = l_rec_voucherpays.vend_code 
			AND voucher.vouch_date <= modu_agedate 
			AND vendor.cmpy_code = voucher.cmpy_code 
			AND vendor.vend_code = voucher.vend_code 
			IF status = 0 THEN 
				LET l_rec_tempdoc.tm_vend = l_rec_voucher.vend_code 
				LET l_rec_tempdoc.tm_name = l_rec_voucher.name_text 
				LET l_rec_tempdoc.tm_cury = l_rec_voucher.currency_code 
				LET l_rec_tempdoc.tm_tele = l_rec_voucher.tele_text 
				LET l_rec_tempdoc.tm_date = l_rec_voucher.vouch_date 
				LET l_rec_tempdoc.tm_type = "VO" 
				LET l_rec_tempdoc.tm_doc = l_rec_voucher.vouch_code 
				LET l_rec_tempdoc.tm_refer = l_rec_voucher.inv_text 
				LET l_rec_tempdoc.tm_late = modu_agedate - l_rec_voucher.due_date 
				LET l_rec_tempdoc.tm_conv_qty = l_rec_voucher.conv_qty 
				LET l_rec_tempdoc.tm_amount = l_rec_voucher.total_amt 
				LET l_rec_tempdoc.tm_unpaid = l_rec_voucher.total_amt 
				- l_rec_voucher.paid_amt 
				+ l_rec_voucherpays.apply_amt 
				+ l_rec_voucherpays.disc_amt 
				LET l_rec_tempdoc.tm_plus = 0 
				LET l_rec_tempdoc.tm_o90 = 0 
				LET l_rec_tempdoc.tm_o60 = 0 
				LET l_rec_tempdoc.tm_o30 = 0 
				LET l_rec_tempdoc.tm_curr = 0 
				CASE 
					WHEN l_rec_tempdoc.tm_late > 90 
						LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 60 
						LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 30 
						LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 0 
						LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
					OTHERWISE 
						LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
				END CASE 
				INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
			END IF 
		END IF 
		#################################################################
		# Need TO check temp table FOR cheque first. IF it IS there
		# THEN UPDATE it
		#################################################################
		IF l_rec_voucherpays.pay_type_code = "CH" THEN 
			SELECT * INTO l_rec_tempdoc.* 
			FROM shuffle 
			WHERE tm_doc = l_rec_voucherpays.pay_num 
			AND tm_type = "CH" 
			IF status = 0 THEN 
				LET l_rec_tempdoc.tm_unpaid = l_rec_tempdoc.tm_unpaid - 
				l_rec_voucherpays.apply_amt 
				CASE 
					WHEN l_rec_tempdoc.tm_late > 90 
						LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 60 
						LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 30 
						LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 0 
						LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
					OTHERWISE 
						LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
				END CASE 
				UPDATE shuffle SET tm_unpaid = l_rec_tempdoc.tm_unpaid, 
				tm_plus = l_rec_tempdoc.tm_plus, 
				tm_o90 = l_rec_tempdoc.tm_o90, 
				tm_o60 = l_rec_tempdoc.tm_o60, 
				tm_o30 = l_rec_tempdoc.tm_o30, 
				tm_cur = l_rec_tempdoc.tm_curr 
				WHERE tm_doc = l_rec_voucherpays.pay_num 
				AND tm_type = "CH" 
			ELSE 
				#################################################################
				# IF cheque IS NOT in temp table THEN SELECT it AND INSERT
				# it IF it was entered before cutoff date
				#################################################################
				SELECT cheque.vend_code, 
				vendor.name_text, 
				vendor.currency_code, 
				vendor.tele_text, 
				cheque.cheq_code, 
				cheque.cheq_date, 
				cheque.com3_text, 
				cheque.pay_amt, 
				cheque.apply_amt, 
				cheque.conv_qty 
				INTO l_rec_cheque.* 
				FROM cheque, vendor 
				WHERE cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cheque.cheq_code = l_rec_voucherpays.pay_num 
				AND cheque.doc_num = l_rec_voucherpays.pay_doc_num 
				AND cheque.cheq_date <= modu_agedate 
				AND vendor.cmpy_code = cheque.cmpy_code 
				AND vendor.vend_code = cheque.vend_code 
				IF status = 0 THEN 
					LET l_rec_tempdoc.tm_vend = l_rec_cheque.vend_code 
					LET l_rec_tempdoc.tm_name = l_rec_cheque.name_text 
					LET l_rec_tempdoc.tm_cury = l_rec_cheque.currency_code 
					LET l_rec_tempdoc.tm_tele = l_rec_cheque.tele_text 
					LET l_rec_tempdoc.tm_date = l_rec_cheque.cheq_date 
					LET l_rec_tempdoc.tm_type = "CH" 
					LET l_rec_tempdoc.tm_doc = l_rec_cheque.cheq_code 
					LET l_rec_tempdoc.tm_refer = l_rec_cheque.com3_text 
					LET l_rec_tempdoc.tm_late = 0 
					LET l_rec_tempdoc.tm_conv_qty = l_rec_cheque.conv_qty 
					LET l_rec_tempdoc.tm_amount = 0 
					LET l_rec_tempdoc.tm_amount = l_rec_tempdoc.tm_amount - l_rec_cheque.pay_amt 
					LET l_rec_tempdoc.tm_unpaid = (l_rec_cheque.apply_amt - 
					l_rec_voucherpays.apply_amt) 
					- l_rec_cheque.pay_amt 
					LET l_rec_tempdoc.tm_plus = 0 
					LET l_rec_tempdoc.tm_o90 = 0 
					LET l_rec_tempdoc.tm_o60 = 0 
					LET l_rec_tempdoc.tm_o30= 0 
					LET l_rec_tempdoc.tm_curr = 0 
					CASE 
						WHEN l_rec_tempdoc.tm_late > 90 
							LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
						WHEN l_rec_tempdoc.tm_late > 60 
							LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
						WHEN l_rec_tempdoc.tm_late > 30 
							LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
						WHEN l_rec_tempdoc.tm_late > 0 
							LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
						OTHERWISE 
							LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
					END CASE 
					INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
				END IF 
			END IF 
		ELSE 
			# Must be a debit
			SELECT * INTO l_rec_tempdoc.* 
			FROM shuffle 
			WHERE tm_doc = l_rec_voucherpays.pay_num 
			AND tm_type = "DB" 
			IF status = 0 THEN 
				LET l_rec_tempdoc.tm_unpaid = l_rec_tempdoc.tm_unpaid - 
				l_rec_voucherpays.apply_amt 
				CASE 
					WHEN l_rec_tempdoc.tm_late > 90 
						LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 60 
						LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 30 
						LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
					WHEN l_rec_tempdoc.tm_late > 0 
						LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
					OTHERWISE 
						LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
				END CASE 
				UPDATE shuffle SET tm_unpaid = l_rec_tempdoc.tm_unpaid, 
				tm_plus = l_rec_tempdoc.tm_plus, 
				tm_o90 = l_rec_tempdoc.tm_o90, 
				tm_o60 = l_rec_tempdoc.tm_o60, 
				tm_o30 = l_rec_tempdoc.tm_o30, 
				tm_cur = l_rec_tempdoc.tm_curr 
				WHERE tm_doc = l_rec_voucherpays.pay_num 
				AND tm_type = "DB" 
			ELSE 
				#################################################################
				# IF debit IS NOT in temp table THEN SELECT it AND INSERT
				# it IF it was entered before cutoff date
				#################################################################
				SELECT debithead.vend_code, 
				vendor.name_text, 
				vendor.currency_code, 
				vendor.tele_text, 
				debithead.debit_num, 
				debithead.debit_date, 
				debithead.debit_text, 
				debithead.total_amt, 
				debithead.apply_amt, 
				debithead.conv_qty 
				INTO l_rec_debithead.* 
				FROM debithead,vendor 
				WHERE debithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND debithead.debit_num = l_rec_voucherpays.pay_num 
				AND debithead.debit_date <= modu_agedate 
				AND vendor.cmpy_code = debithead.cmpy_code 
				AND vendor.vend_code = debithead.vend_code 
				IF status = 0 THEN 
					LET l_rec_tempdoc.tm_vend = l_rec_debithead.vend_code 
					LET l_rec_tempdoc.tm_name = l_rec_debithead.name_text 
					LET l_rec_tempdoc.tm_cury = l_rec_debithead.currency_code 
					LET l_rec_tempdoc.tm_tele = l_rec_debithead.tele_text 
					LET l_rec_tempdoc.tm_date = l_rec_debithead.debit_date 
					LET l_rec_tempdoc.tm_type = "DB" 
					LET l_rec_tempdoc.tm_doc = l_rec_debithead.debit_num 
					LET l_rec_tempdoc.tm_refer = l_rec_debithead.debit_text 
					LET l_rec_tempdoc.tm_late = 0 
					LET l_rec_tempdoc.tm_conv_qty = l_rec_debithead.conv_qty 
					LET l_rec_tempdoc.tm_amount = 0 
					LET l_rec_tempdoc.tm_amount = l_rec_tempdoc.tm_amount - 
					l_rec_debithead.total_amt 
					LET l_rec_tempdoc.tm_unpaid = (l_rec_debithead.apply_amt - 
					l_rec_voucherpays.apply_amt ) 
					- l_rec_debithead.total_amt 
					LET l_rec_tempdoc.tm_plus = 0 
					LET l_rec_tempdoc.tm_o90 = 0 
					LET l_rec_tempdoc.tm_o60 = 0 
					LET l_rec_tempdoc.tm_o30= 0 
					LET l_rec_tempdoc.tm_curr = 0 
					CASE 
						WHEN l_rec_tempdoc.tm_late > 90 
							LET l_rec_tempdoc.tm_plus = l_rec_tempdoc.tm_unpaid 
						WHEN l_rec_tempdoc.tm_late > 60 
							LET l_rec_tempdoc.tm_o90 = l_rec_tempdoc.tm_unpaid 
						WHEN l_rec_tempdoc.tm_late > 30 
							LET l_rec_tempdoc.tm_o60 = l_rec_tempdoc.tm_unpaid 
						WHEN l_rec_tempdoc.tm_late > 0 
							LET l_rec_tempdoc.tm_o30 = l_rec_tempdoc.tm_unpaid 
						OTHERWISE 
							LET l_rec_tempdoc.tm_curr = l_rec_tempdoc.tm_unpaid 
					END CASE 
					INSERT INTO shuffle VALUES (l_rec_tempdoc.*) 
				END IF 
			END IF 
		END IF 
	END FOREACH 
	##############################
	# END VOUCHERPAYS PROCESSING :)
	###############################

	IF l_continue_flag THEN 
		DECLARE selcurs CURSOR FOR 
		SELECT * FROM shuffle 
		ORDER BY tm_vend, 
		tm_date, 
		tm_doc 

		FOREACH selcurs INTO l_rec_tempdoc.* 

			#---------------------------------------------------------
			OUTPUT TO REPORT PR1_rpt_list(l_rpt_idx,
			l_rec_tempdoc.*)  
			IF NOT rpt_int_flag_handler2("Vendor:",l_rec_tempdoc.tm_vend, l_rec_tempdoc.tm_name,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

		END FOREACH 
	END IF 

	IF fgl_find_table("shuffle") THEN
		DELETE FROM shuffle 
		WHERE 1=1
	END IF
	
	#------------------------------------------------------------
	FINISH REPORT PR1_rpt_list
	CALL rpt_finish("PR1_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = FALSE 
		ERROR " Printing was aborted" 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 	
END FUNCTION 


############################################################
# REPORT PR1_rpt_list(p_rec_tempdoc)
#
############################################################
REPORT PR1_rpt_list(p_rpt_idx,p_rec_tempdoc)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	 
	DEFINE p_rec_tempdoc 
	RECORD 
		tm_vend CHAR(8), 
		tm_name CHAR(30), 
		tm_cury CHAR(3), 
		tm_tele CHAR(12), 
		tm_date DATE, 
		tm_type CHAR(2), 
		tm_doc INTEGER, 
		tm_refer CHAR(20), 
		tm_late INTEGER, 
		tm_conv_qty FLOAT, 
		tm_amount DECIMAL(16,2), 
		tm_unpaid DECIMAL(16,2), 
		tm_curr DECIMAL(16,2), 
		tm_o30 DECIMAL(16,2), 
		tm_o60 DECIMAL(16,2), 
		tm_o90 DECIMAL(16,2), 
		tm_plus DECIMAL(16,2) 
	END RECORD 
	DEFINE l_vendor_curr_code LIKE vendor.currency_code 
	DEFINE l_conv_date DATE 
	DEFINE l_conv_unpaid DECIMAL(16,2) 
	DEFINE l_conv_amount DECIMAL(16,2) 
	DEFINE l_vend_unpaid DECIMAL(16,2) 
	DEFINE l_arr_line array[4] OF CHAR(132) 
	DEFINE l_rec_vendornote RECORD LIKE vendornote.* 
	DEFINE l_fv_notes CHAR(6) 
	DEFINE l_query_text CHAR(2200) 

	OUTPUT 

	ORDER external BY p_rec_tempdoc.tm_vend, 
	p_rec_tempdoc.tm_date, 
	p_rec_tempdoc.tm_doc 
	
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			 			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 


		BEFORE GROUP OF p_rec_tempdoc.tm_date 
			SKIP 1 LINES 
			PRINT COLUMN 001, "Date: ", p_rec_tempdoc.tm_date
			 
		BEFORE GROUP OF p_rec_tempdoc.tm_vend 
			SKIP 2 LINES 
			LET l_vend_unpaid = 0 
			PRINT COLUMN 001, "Vendor: ", p_rec_tempdoc.tm_vend, 2 spaces, 
			p_rec_tempdoc.tm_tele, 2 spaces, 
			COLUMN 025, p_rec_tempdoc.tm_name 
			PRINT COLUMN 001, "Currency Code: ", p_rec_tempdoc.tm_cury 
			LET l_vendor_curr_code = p_rec_tempdoc.tm_cury 


			IF modu_notes_flag = "Y" THEN 
				LET l_fv_notes = "Notes:" 
				LET l_query_text = 
				"SELECT *", 
				" FROM vendornote", 
				" WHERE vendornote.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
				" AND vendornote.vend_code = \"",p_rec_tempdoc.tm_vend,"\" " 
				PREPARE s_vendornote FROM l_query_text 
				DECLARE c_vendornote CURSOR FOR s_vendornote 
				SKIP 1 LINES 
				FOREACH c_vendornote INTO l_rec_vendornote.* 
					PRINT COLUMN 1, l_fv_notes, 
					COLUMN 8, l_rec_vendornote.note_date USING "dd/mm/yy", 
					COLUMN 19, l_rec_vendornote.note_text 
					#COLUMN 19, l_rec_vendornote.note_num using "--&.&&",
					#COLUMN 28, l_rec_vendornote.note_text

					LET l_fv_notes = " " 
				END FOREACH 
				SKIP 1 LINES 
			END IF 


		AFTER GROUP OF p_rec_tempdoc.tm_vend 
			PRINT COLUMN 045, "-----------------------------------------------", 
			"-----------------------------------------" 
			PRINT COLUMN 040, GROUP sum(p_rec_tempdoc.tm_unpaid) USING "----------&.&&", 
			COLUMN 056, GROUP sum(p_rec_tempdoc.tm_curr) USING "----------&.&&", 
			COLUMN 072, GROUP sum(p_rec_tempdoc.tm_o30) USING "----------&.&&", 
			COLUMN 088, GROUP sum(p_rec_tempdoc.tm_o60) USING "----------&.&&", 
			COLUMN 104, GROUP sum(p_rec_tempdoc.tm_o90) USING "----------&.&&", 
			COLUMN 119, GROUP sum(p_rec_tempdoc.tm_plus) USING "----------&.&&" 
			PRINT COLUMN 040, l_vend_unpaid USING "----------&.&&" 
			
		ON EVERY ROW 
			PRINT COLUMN 001, p_rec_tempdoc.tm_type, 
			COLUMN 004, p_rec_tempdoc.tm_doc USING "########", 
			COLUMN 013, p_rec_tempdoc.tm_refer[1,12], 
			COLUMN 026, p_rec_tempdoc.tm_late USING "----", 
			COLUMN 030, p_rec_tempdoc.tm_amount USING "------&.&&", 
			COLUMN 040, p_rec_tempdoc.tm_unpaid USING "----------&.&&", 
			COLUMN 056, p_rec_tempdoc.tm_curr USING "----------&.&&", 
			COLUMN 072, p_rec_tempdoc.tm_o30 USING "----------&.&&", 
			COLUMN 088, p_rec_tempdoc.tm_o60 USING "----------&.&&", 
			COLUMN 104, p_rec_tempdoc.tm_o90 USING "----------&.&&", 
			COLUMN 119, p_rec_tempdoc.tm_plus USING "----------&.&&" 
			CASE 
				WHEN modu_conv_ind = "1" 
					LET l_conv_date = modu_agedate 
				WHEN modu_conv_ind = "2" 
					LET l_conv_date = p_rec_tempdoc.tm_date 
				OTHERWISE 
					LET l_conv_date = today 
			END CASE
			 
			IF l_vendor_curr_code != glob_rec_glparms.base_currency_code THEN 
				LET l_conv_amount = conv_currency(p_rec_tempdoc.tm_amount, glob_rec_kandoouser.cmpy_code, l_vendor_curr_code, "F", l_conv_date, "S") 
				LET l_conv_unpaid = conv_currency(p_rec_tempdoc.tm_unpaid, glob_rec_kandoouser.cmpy_code,	l_vendor_curr_code, "F", l_conv_date, "S") 
				LET l_vend_unpaid = l_vend_unpaid + l_conv_unpaid 
				PRINT COLUMN 030, l_conv_amount USING "------&.&&", 
				COLUMN 040, l_conv_unpaid USING "----------&.&&" 
			END IF 
			
			IF p_rec_tempdoc.tm_unpaid <> 0 THEN 
				LET modu_tot_unpaid = modu_tot_unpaid + conv_currency(p_rec_tempdoc.tm_unpaid, 
				glob_rec_kandoouser.cmpy_code,l_vendor_curr_code, 
				"F", l_conv_date, "S") 
			END IF
			 
			IF p_rec_tempdoc.tm_curr <> 0 THEN 
				LET modu_tot_curr = modu_tot_curr + conv_currency(p_rec_tempdoc.tm_curr, 
				glob_rec_kandoouser.cmpy_code,l_vendor_curr_code, 
				"F", l_conv_date, "S") 
			END IF 
			IF p_rec_tempdoc.tm_o30 <> 0 THEN 
				LET modu_tot_o30 = modu_tot_o30 + conv_currency(p_rec_tempdoc.tm_o30, 
				glob_rec_kandoouser.cmpy_code,l_vendor_curr_code, 
				"F", l_conv_date, "S") 
			END IF 
			IF p_rec_tempdoc.tm_o60 <> 0 THEN 
				LET modu_tot_o60 = modu_tot_o60 + conv_currency(p_rec_tempdoc.tm_o60, 
				glob_rec_kandoouser.cmpy_code,l_vendor_curr_code, 
				"F", l_conv_date, "S") 
			END IF 
			IF p_rec_tempdoc.tm_o90 <> 0 THEN 
				LET modu_tot_o90 = modu_tot_o90 + conv_currency(p_rec_tempdoc.tm_o90, 
				glob_rec_kandoouser.cmpy_code,l_vendor_curr_code, 
				"F", l_conv_date, "S") 
			END IF 
			IF p_rec_tempdoc.tm_plus <> 0 THEN 
				LET modu_tot_plus = modu_tot_plus + conv_currency(p_rec_tempdoc.tm_plus, 
				glob_rec_kandoouser.cmpy_code,l_vendor_curr_code, 
				"F", l_conv_date, "S") 
			END IF 
			
		ON LAST ROW 
			PRINT COLUMN 045,"-----------------------------------------------", 
			"-----------------------------------------" 
			PRINT COLUMN 001, "Totals in base currency", 
			COLUMN 040, modu_tot_unpaid USING "----------&.&&", 
			COLUMN 056, modu_tot_curr USING "----------&.&&", 
			COLUMN 072, modu_tot_o30 USING "----------&.&&", 
			COLUMN 088, modu_tot_o60 USING "----------&.&&", 
			COLUMN 104, modu_tot_o90 USING "----------&.&&", 
			COLUMN 119, modu_tot_plus USING "----------&.&&" 
			SKIP 2 line 
			
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
		
END REPORT