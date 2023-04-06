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
# must NOT alter allocation
# of cheques AFTER this has been sent up , ELSE run them all
# again.
# Once the REPORT IS produced a cheque may be un-allocated, AND THEN
# allocated TO another voucher...potential FOR confusion eh?
# IF there IS cheque allocation TO a voucher which pays off a PO, AND
# the value of the allocation overpays the value of goods received on
# that PO, THEN we cannot dissect the amount TO an account, an error
# row IS written on the REPORT AND the cheque allocation details are printed.
# only works on fully paid vouchers
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/PC_GROUP_GLOBALS.4gl"
GLOBALS 
	-- DEFINE glob_where_part STRING -- CHAR(2048)
	DEFINE glob_rec_voucherdist RECORD 
		cmpy_code LIKE voucherdist.cmpy_code, 
		vend_code LIKE voucherdist.vend_code, 
		vouch_code LIKE voucherdist.vouch_code, 
		line_num LIKE voucherdist.line_num, 
		acct_code LIKE voucherdist.acct_code, 
		desc_text LIKE voucherdist.desc_text, 
		dist_amt LIKE voucherdist.dist_amt, 
		chart3 CHAR(18) 
	END RECORD
	DEFINE glob_rec_puparms RECORD LIKE puparms.*
	DEFINE glob_rec_voucherpays RECORD LIKE voucherpays.*
	DEFINE glob_rec_voucher RECORD LIKE voucher.*
	DEFINE glob_rec_bank RECORD LIKE bank.*
	DEFINE glob_starter SMALLINT
	DEFINE glob_pos3 SMALLINT
	DEFINE glob_ender SMALLINT
	DEFINE glob_err_ind SMALLINT 
	DEFINE glob_cheq_total_amt LIKE voucherdist.dist_amt 
	DEFINE glob_cheq_cnt INTEGER 
	DEFINE glob_dist_offset MONEY(15,2) 
	DEFINE glob_rem_paid MONEY(15,2)
	DEFINE glob_first_flag CHAR(1) 
	DEFINE glob_rec_print RECORD 
		cheq_code LIKE cheque.cheq_code, 
		cheq_amt LIKE cheque.pay_amt, 
		vouch_code LIKE voucherpays.vouch_code, 
		vouch_amt LIKE voucher.total_amt, 
		prev_paid DECIMAL(10,2), 
		order_num LIKE poaudit.po_num, 
		acct_code CHAR(18), 
		desc_text CHAR(40), 
		alloc_amt LIKE voucherdist.dist_amt, 
		rem_amt LIKE voucherdist.dist_amt, 
		vouch_rem_amt LIKE voucherdist.dist_amt, 
		apply_amt LIKE voucherpays.apply_amt, 
		purch_gl_flag CHAR(1), # p purchase/delivery, g gl/distribution 
		prev_this_flag CHAR(1), # p(revious paid) t(his cheque) 
		del_date DATE, 
		received_qty LIKE poaudit.received_qty, 
		dist_amt LIKE voucherdist.dist_amt 
	END RECORD 
	DEFINE l_rec_structure RECORD LIKE structure.*
END GLOBALS 
############################################################
# FUNCTION PC8_main()
# RETURN VOID
#
# PC8 - Treasury REPORT
############################################################
FUNCTION PC8_main()

	CALL setModuleId("PC8") 

	LET glob_err_ind = false 
	LET glob_cheq_total_amt = 0 
	LET glob_cheq_cnt = 0 
	-- LET glob_rpt_date = today 
	-- CALL rpt_rmsreps_set_page_size(132,NULL) 
	-- LET glob_rpt_note = NULL 

	-- SELECT * 
	-- INTO glob_rec_company.* 
	-- FROM company 
	-- WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 


	-- CALL init_r_pu() #init r/pu module  
	-- glob_rec_puparms should be initialized by init_r_pu function
	DECLARE pu_c CURSOR FOR 
		SELECT * 
		INTO glob_rec_puparms.* 
		FROM puparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	OPEN pu_c 
	FETCH pu_c 

	IF sqlca.sqlcode = NOTFOUND THEN 
		INITIALIZE glob_rec_puparms.* TO NULL 
	END IF 
	CLOSE pu_c 

	SELECT * 
		INTO l_rec_structure.* 
		FROM structure 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_ind = "C"
	
	LET glob_starter = l_rec_structure.start_num 
	LET glob_pos3 = glob_starter + 2 
	LET glob_ender = l_rec_structure.start_num + l_rec_structure.length_num - 1 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query 
		WHEN RPT_OP_MENU #UI/MENU Mode

			OPEN WINDOW P160 with FORM "P160" 
			CALL windecoration_p("P160") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

			MENU " Treasury Report" 

				BEFORE MENU 
					CALL publish_toolbar("kandoo","PC8","menu-treasury_rep-1") 
					CALL PC8_rpt_process(PC8_rpt_query())

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Report" #COMMAND "Run Report" " SELECT criteria AND PRINT REPORT"
					CALL PC8_rpt_process(PC8_rpt_query())

				ON ACTION "Print Manager" #COMMAND KEY ("P",f11) "Print" "Print OR view using RMS"
					CALL run_prog("URS","","","","") 

				ON ACTION "Exit" #COMMAND "Exit" " Exit TO menus"
					EXIT MENU 

			END MENU 
			CLOSE WINDOW P160 

		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PC8_rpt_process(NULL) # (NULL query-where-part will read report_code from URL

		WHEN RPT_OP_CONSTRUCT 
			OPEN WINDOW P160 with FORM "P160" 
			CALL windecoration_p("P160") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL PC8_rpt_query()
			CALL set_url_sel_text(PC8_rpt_query()) #save where clause in env 
			CLOSE WINDOW P160

		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PC8_rpt_process(get_url_sel_text())
	END CASE 

END FUNCTION 
############################################################
# END FUNCTION PC8_main()
############################################################


############################################################
# FUNCTION PC8_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PC8_rpt_query() 
	DEFINE l_where_text STRING

	-- DEFINE l_rec_cheque RECORD 
	-- 	vend_code LIKE cheque.vend_code, 
	-- 	name_text LIKE vendor.name_text, 
	-- 	cheq_code LIKE cheque.cheq_code, 
	-- 	entry_code LIKE cheque.entry_code, 
	-- 	entry_date LIKE cheque.entry_date, 
	-- 	bank_acct_code LIKE cheque.bank_acct_code, 
	-- 	com3_text LIKE cheque.com3_text, 
	-- 	cheq_date LIKE cheque.cheq_date, 
	-- 	pay_amt LIKE cheque.pay_amt, 
	-- 	year_num LIKE cheque.year_num, 
	-- 	period_num LIKE cheque.period_num, 
	-- 	post_flag LIKE cheque.post_flag, 
	-- 	apply_amt LIKE cheque.apply_amt, 
	-- 	disc_amt LIKE cheque.disc_amt, 
	-- 	rec_state_num LIKE cheque.rec_state_num, 
	-- 	rec_line_num LIKE cheque.rec_line_num, 
	-- 	com1_text LIKE cheque.com1_text, 
	-- 	com2_text LIKE cheque.com2_text 
	-- END RECORD 
	-- DEFINE l_query_text CHAR(2200)
	-- DEFINE l_pr_output CHAR(60)
	-- DEFINE l_pr_output_b CHAR(60)
	-- DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	DISPLAY BY NAME glob_rec_bank.bank_code 

	INPUT BY NAME glob_rec_bank.bank_code 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PC8","inp-bank_code-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD bank_code 
			DISPLAY BY NAME glob_rec_bank.bank_code 

			SELECT * 
				INTO glob_rec_bank.* 
				FROM bank 
				WHERE bank_code = glob_rec_bank.bank_code 
					AND bank.cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF sqlca.sqlcode = NOTFOUND THEN 
				ERROR "Invalid banking account - try window" 
				NEXT FIELD bank_code 
			END IF 

			DISPLAY BY NAME glob_rec_bank.name_acct_text 

		ON KEY (control-b) 
			IF infield (bank_code) THEN 

				CALL show_bank(glob_rec_kandoouser.cmpy_code) RETURNING glob_rec_bank.bank_code, glob_rec_bank.acct_code 
				DISPLAY BY NAME glob_rec_bank.name_acct_text 
				DISPLAY BY NAME glob_rec_bank.bank_code 

				NEXT FIELD bank_code 
			END IF 

	END INPUT 

	IF int_flag THEN
		RETURN NULL
	END IF

	MESSAGE " Enter Selection Criteria - ESC TO Continue" attribute(yellow) 

	CONSTRUCT BY NAME l_where_text ON cheque.cheq_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","PC8","construct-cheque-1") 

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
		LET glob_rec_rpt_selector.ref1_code = glob_rec_bank.bank_code
		RETURN l_where_text
	END IF 

END FUNCTION

############################################################
# FUNCTION PC8_rpt_query()
# RETURN l_ret_sql_sel_text #WHERE part also stored in rmsreps.sel_text
# 
# DataSource for the report driver with CONSTRUCT
############################################################
FUNCTION PC8_rpt_process(p_where_text)
	DEFINE p_where_text STRING
	DEFINE l_rpt_idx SMALLINT #report array index
	DEFINE l_query_text STRING

	DEFINE l_rec_cheque RECORD 
		vend_code LIKE cheque.vend_code, 
		name_text LIKE vendor.name_text, 
		cheq_code LIKE cheque.cheq_code, 
		entry_code LIKE cheque.entry_code, 
		entry_date LIKE cheque.entry_date, 
		bank_acct_code LIKE cheque.bank_acct_code, 
		com3_text LIKE cheque.com3_text, 
		cheq_date LIKE cheque.cheq_date, 
		pay_amt LIKE cheque.pay_amt, 
		year_num LIKE cheque.year_num, 
		period_num LIKE cheque.period_num, 
		post_flag LIKE cheque.post_flag, 
		apply_amt LIKE cheque.apply_amt, 
		disc_amt LIKE cheque.disc_amt, 
		rec_state_num LIKE cheque.rec_state_num, 
		rec_line_num LIKE cheque.rec_line_num, 
		com1_text LIKE cheque.com1_text, 
		com2_text LIKE cheque.com2_text 
	END RECORD 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false
		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PC8_rpt_list",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PC8_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
	LET p_where_text = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PC8_rpt_list")].sel_text
	#------------------------------------------------------------

	LET glob_rec_bank.bank_code = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PC8_rpt_list")].ref1_code

	LET l_query_text = 
		"SELECT cheque.vend_code, vendor.name_text, cheque.cheq_code, ", 
		"cheque.entry_code, cheque.entry_date, cheque.bank_acct_code, ", 
		"cheque.com3_text, cheque.cheq_date, cheque.pay_amt, ", 
		"cheque.year_num, cheque.period_num, cheque.post_flag, ", 
		"cheque.apply_amt, cheque.disc_amt, cheque.rec_state_num, ", 
		"cheque.rec_line_num, cheque.com1_text, cheque.com2_text ", 
		"FROM cheque, vendor ", 
		"WHERE cheque.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND vendor.vend_code = cheque.vend_code AND vendor.cmpy_code = ", 
		"cheque.cmpy_code AND cheque.bank_acct_code = '", glob_rec_bank.acct_code, "' ",
		"AND ", glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("PC8_rpt_list")].sel_text CLIPPED," ",
		" ORDER BY cheque.cheq_code" 

	PREPARE choice FROM l_query_text 
	DECLARE selcurs CURSOR FOR choice 

#	DISPLAY " Reporting on Cheque...." at 1,1 
	FOREACH selcurs INTO l_rec_cheque.* 

		#------------------------------------------------------------
		OUTPUT TO REPORT PC8_rpt_list(rpt_rmsreps_idx_get_idx("PC8_rpt_list"), l_rec_cheque.*) 
		IF NOT rpt_int_flag_handler2("Cheque no: ",l_rec_cheque.cheq_code, NULL ,rpt_rmsreps_idx_get_idx("PC8_rpt_list")) THEN
			EXIT FOREACH 
		END IF 
		#--------------------------------------------------------8

	END FOREACH 
--		CLEAR WINDOW p160 -- albo 

	#------------------------------------------------------------
	FINISH REPORT PC8_rpt_list
	CALL rpt_finish("PC8_rpt_list")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN NULL 
	END IF 

	OPEN selcurs 

		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start("PC8-A","PC8_rpt_list_a",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT PC8_rpt_list_a TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		#------------------------------------------------------------
		#------------------------------------------------------------
		LET l_rpt_idx = rpt_start("PC8-B","PC8_rpt_list_b",p_where_text, RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT PC8_rpt_list_b TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , TOP MARGIN = 0, BOTTOM MARGIN = 0, LEFT MARGIN = 0, RIGHT MARGIN = 0
		#------------------------------------------------------------
	BEGIN WORK 
		FOREACH selcurs INTO l_rec_cheque.* 
			# there IS a known bug here. IF there are duplicate cheque numbers
			# (FROM different banks) FOR the same vendor, pretty unlikely eh?,
			# THEN because voucherpays only records
			# the cheque number (in pay_num) AND no bank a/c ref (bank_code OR
			# account_code) THEN this SELECT will snare all the cheques with
			# the given cheque number FOR that vendor.
			# SET up some lines in the detail REPORT

			LET glob_rec_print.cheq_code = l_rec_cheque.cheq_code 
			LET glob_rec_print.cheq_amt = l_rec_cheque.pay_amt 

			DECLARE vos_curs CURSOR FOR 
				SELECT voucherpays.*, voucher.* 
				INTO glob_rec_voucherpays.*, glob_rec_voucher.* 
				FROM voucherpays, voucher 
				WHERE voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
					voucherpays.pay_type_code = "CH" AND 
					voucherpays.pay_num = l_rec_cheque.cheq_code AND 
					voucher.cmpy_code = voucherpays.cmpy_code AND 
					voucher.vend_code = voucherpays.vend_code AND 
					voucher.vouch_code = voucherpays.vouch_code 
				ORDER BY voucherpays.vend_code, 
					voucherpays.vouch_code, voucherpays.apply_num 

			FOREACH vos_curs 
				LET glob_first_flag = "Y" 
				LET glob_rem_paid = glob_rec_voucherpays.apply_amt 
				# we accumulate all previous payments (distributions)
				#  TO this voucher

				SELECT sum(apply_amt) 
					INTO glob_dist_offset 
					FROM voucherpays 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
						vend_code = glob_rec_voucherpays.vend_code AND 
						vouch_code = glob_rec_voucherpays.vouch_code AND 
						apply_num < glob_rec_voucherpays.apply_num 

				IF glob_dist_offset IS NULL THEN 
					LET glob_dist_offset = 0 
				END IF 

				LET glob_rec_print.prev_paid = glob_dist_offset 
				LET glob_rec_print.vouch_code = glob_rec_voucherpays.vouch_code 
				LET glob_rec_print.vouch_amt = glob_rec_voucher.total_amt 
				LET glob_rec_print.vouch_rem_amt = glob_rec_voucher.total_amt - glob_rec_print.prev_paid 

				# We now go searching FOR distributions TO make up
				#   this cheque amount.
				# IF a later cheque, THEN we ignore distributed amounts up
				#   TO the value
				# of the previous cheques. This amount IS in **glob_dist_offset** .

				DECLARE vd_curs CURSOR FOR 
				SELECT cmpy_code, 
						vend_code, 
						vouch_code, 
						line_num, 
						acct_code a, 
						desc_text, 
						dist_amt, 
						acct_code b 
					INTO glob_rec_voucherdist.* 
					FROM voucherdist 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND vend_code = glob_rec_voucherpays.vend_code 
						AND vouch_code = glob_rec_voucherpays.vouch_code 
					ORDER BY vend_code, 
						vouch_code, 
						line_num 

				FOREACH vd_curs 

					IF glob_rec_voucherdist.acct_code <> glob_rec_puparms.clear_acct_code AND 
					glob_rec_voucherdist.acct_code <> glob_rec_puparms.commit_acct_code THEN 
						CALL check_dists() 
					ELSE 
						CALL check_poinvs() 
					END IF 

					IF glob_rem_paid = 0 THEN 
						EXIT FOREACH 
					END IF 

				END FOREACH 

				IF glob_rem_paid != 0 THEN 
					CALL err_list() 
				END IF 

				-- DISPLAY glob_rec_voucherpays.vouch_code at 1,25 

				-- IF int_flag OR quit_flag THEN 
				-- 	#8503 Continue Report(Y/N)
				-- 	IF kandoomsg("U",8503,"") = "N" THEN 
				-- 		#9501 Report Terminated
				-- 		LET l_msgresp=kandoomsg("U",9501,"") 
				-- 		ROLLBACK WORK 

				-- 		RETURN false 
				-- 	END IF 
				-- END IF 

				IF NOT rpt_int_flag_handler2("Voucher no: ",glob_rec_voucherpays.vouch_code, NULL ,rpt_rmsreps_idx_get_idx("PC8_rpt_list_a")) THEN
					ROLLBACK WORK 
					RETURN NULL
				END IF 

			END FOREACH #next unique voucherpays FOR this cheque 
		END FOREACH #next cheque 

		#------------------------------------------------------------
		FINISH REPORT PC8_rpt_list_a
		CALL rpt_finish("PC8_rpt_list_a")
		#------------------------------------------------------------
		#------------------------------------------------------------
		FINISH REPORT PC8_rpt_list_b
		CALL rpt_finish("PC8_rpt_list_b")
		#------------------------------------------------------------

	COMMIT WORK 
	RETURN true 
END FUNCTION 



############################################################
# FUNCTION check_dists()
#
#
############################################################
FUNCTION check_dists() 
	# glob_rem_paid holds the amount remaining FROM the current
	# voucherpays.apply_amt which gets whittled away as it IS allocated
	# TO a voucherdist.
	#------------
	#  LET int_amt = glob_rec_voucherdist.dist_amt - glob_dist_offset
	# Set up the detail PRINT line
	LET glob_rec_print.purch_gl_flag = "G" 
	LET glob_rec_print.del_date = NULL 
	LET glob_rec_print.received_qty = NULL 
	LET glob_rec_print.order_num = 0 
	LET glob_rec_print.desc_text = glob_rec_voucherdist.desc_text 
	LET glob_rec_print.acct_code = glob_rec_voucherdist.acct_code 
	LET glob_rec_print.dist_amt = glob_rec_voucherdist.dist_amt 

	IF glob_dist_offset > 0 THEN 
		IF glob_dist_offset > glob_rec_voucherdist.dist_amt THEN 
			# this voucherdist IS less than the dist_amt,
			LET glob_dist_offset = glob_dist_offset - glob_rec_voucherdist.dist_amt 
			LET glob_rec_voucherdist.dist_amt = 0 
			RETURN # no more WORK ON this voucherdist 
		ELSE 
			# this voucherdist IS more than the dist_amt,
			LET glob_rec_voucherdist.dist_amt = glob_rec_voucherdist.dist_amt - glob_dist_offset 
			LET glob_dist_offset = 0 
		END IF 
	END IF 
	# check that the previous distribution does leave something
	# on the voucher TO be paid FOR with this cheque
	IF glob_rec_voucherdist.dist_amt > 0 THEN 

		IF glob_rec_voucherdist.dist_amt > glob_rem_paid THEN 
			# this voucherdist amt IS more than left on the chq.
			LET glob_rec_print.alloc_amt = glob_rem_paid 
			LET glob_rec_voucherdist.dist_amt = glob_rem_paid 
			LET glob_rec_print.rem_amt = 0 
			LET glob_rec_print.dist_amt = glob_rec_voucherdist.dist_amt 
			LET glob_rem_paid = 0 
		ELSE 
			# this voucherdist amt IS less than left on the chq.
			LET glob_rec_print.alloc_amt = glob_rec_voucherdist.dist_amt 
			LET glob_rec_print.rem_amt = glob_rem_paid - glob_rec_voucherdist.dist_amt 
			LET glob_rem_paid = glob_rec_print.rem_amt 
		END IF 

		LET glob_rec_print.vouch_rem_amt = glob_rec_print.vouch_rem_amt - glob_rec_print.alloc_amt 

		IF glob_first_flag = "Y" AND glob_rec_print.prev_paid > 0 THEN 
			LET glob_first_flag = "N" 
			LET glob_rec_print.prev_this_flag = "P" 
		ELSE 
			LET glob_rec_print.prev_this_flag = "T" 
		END IF 

		#------------------------------------------------------------
		OUTPUT TO REPORT PC8_rpt_list_b(rpt_rmsreps_idx_get_idx("PC8_rpt_list_b"), glob_rec_print.*) 
		#------------------------------------------------------------
		
		LET glob_rec_voucherdist.chart3 = glob_rec_voucherdist.acct_code[glob_starter,glob_pos3] 
		LET glob_rec_voucherdist.acct_code = glob_rec_voucherdist.acct_code[glob_starter,glob_ender] 

		IF glob_rec_voucherdist.dist_amt <> 0 THEN 

			#------------------------------------------------------------
			OUTPUT TO REPORT PC8_rpt_list_a(rpt_rmsreps_idx_get_idx("PC8_rpt_list_a"), glob_rec_voucherdist.*)
			#------------------------------------------------------------

		END IF 
	END IF 
	IF glob_rem_paid = 0 THEN 
		RETURN 
	END IF 
END FUNCTION 



############################################################
# FUNCTION check_poinvs()
#
#
############################################################
FUNCTION check_poinvs() 
	# IF the voucher has a non_null po_number, THEN rather
	# than examining the voucherdists, we look AT the purchase ORDER
	# receipts TO get the expense account code. The distributions
	# FOR vouchers with such PO numbers will always be TO the
	# Clearing account. That's the way purchasing works.
	# we have TO go searching in a similar manner FOR the
	# goods receipt in **purchdetl** FOR the appropriate account
	# dissection.  need TO tally any previous payments (FROM voucherpays)
	# FOR vouchers on same purchase ORDER. There could be multiple
	# vouchers FOR the same PO, AND multiple voucherpays FOR the
	# same voucher. The voucherpays.seq_num should sort them out.
	# However, now (1/91) we are allowing a PO voucher TO over
	# charge a PO FOR (say) freight, so there may be non-commitment
	# account distributions on a PO voucher.
	# now work through all the poaudit receipts in ORDER of
	# receipt number FOR the PO until the previous payments
	# have been accounted FOR.
	DEFINE l_rec_poaudit RECORD LIKE poaudit.*
	DEFINE l_rec_purchdetl RECORD LIKE purchdetl.*
	DEFINE l_received_amt MONEY(15,2)
	DEFINE l_held_dist_amt LIKE voucherdist.dist_amt	

	DECLARE pudl_c CURSOR FOR 
	SELECT poaudit.*, poaudit.tran_date 
		INTO l_rec_poaudit.*, glob_rec_print.del_date 
		FROM poaudit 
		WHERE poaudit.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			poaudit.vend_code = glob_rec_voucherpays.vend_code AND 
			poaudit.tran_code = "VO" AND 
			poaudit.tran_num = glob_rec_voucher.vouch_code 
		ORDER BY poaudit.vend_code, 
			poaudit.po_num, poaudit.seq_num 

	FOREACH pudl_c 

		# glob_rem_paid holds the amount remaining FROM the current
		# voucherpays.apply_amt which gets whittled away as it
		# IS allocated TO a poaudit
		#------------
		# get the acct_code FROM purchdetl
		SELECT * 
			INTO l_rec_purchdetl.* 
			FROM purchdetl 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND order_num = l_rec_poaudit.po_num 
				AND vend_code = l_rec_poaudit.vend_code 
				AND line_num = l_rec_poaudit.line_num 

		LET l_received_amt = l_rec_poaudit.line_total_amt 
		LET glob_rec_print.purch_gl_flag = "P" 
		LET glob_rec_print.apply_amt = glob_rec_voucherpays.apply_amt 
		LET glob_rec_print.order_num = l_rec_poaudit.po_num 
		#SET up above  LET glob_rec_print.del_date
		LET glob_rec_print.desc_text = l_rec_poaudit.desc_text 
		LET glob_rec_print.acct_code = l_rec_purchdetl.acct_code 
		LET glob_rec_print.received_qty = l_rec_poaudit.voucher_qty 
		LET glob_rec_print.dist_amt = l_rec_poaudit.line_total_amt 

		IF glob_dist_offset > 0 THEN 
			IF glob_dist_offset > l_received_amt THEN 
				LET glob_dist_offset = glob_dist_offset - l_received_amt 
				LET glob_rec_voucherdist.dist_amt = glob_rec_voucherdist.dist_amt - l_received_amt 
				CONTINUE FOREACH 
			ELSE 
				# this goods receipt IS more than the dist_amt,
				LET l_received_amt = l_received_amt - glob_dist_offset 
				LET glob_rec_voucherdist.dist_amt = glob_rec_voucherdist.dist_amt - glob_dist_offset 
				LET glob_dist_offset = 0 
			END IF 
		END IF 

		IF l_received_amt > 0 THEN 

			IF l_received_amt > glob_rem_paid THEN 
				LET glob_rec_print.alloc_amt = glob_rem_paid 
				LET l_received_amt = glob_rem_paid 
				LET glob_rec_print.rem_amt = 0 
				LET glob_rem_paid = 0 
			ELSE 
				LET glob_rec_print.alloc_amt = l_received_amt 
				LET glob_rec_print.rem_amt = glob_rem_paid - l_received_amt 
				LET glob_rem_paid = glob_rec_print.rem_amt 
			END IF 

			IF glob_first_flag = "Y" AND glob_rec_print.prev_paid > 0 THEN 
				LET glob_first_flag = "N" 
				LET glob_rec_print.prev_this_flag = "P" 
			ELSE 
				LET glob_rec_print.prev_this_flag = "T" 
			END IF 

			LET glob_rec_print.vouch_rem_amt = glob_rec_print.vouch_rem_amt - glob_rec_print.alloc_amt 

			#------------------------------------------------------------
			OUTPUT TO REPORT PC8_rpt_list_b(rpt_rmsreps_idx_get_idx("PC8_rpt_list_b"), glob_rec_print.*) 
			#------------------------------------------------------------

			LET glob_rec_voucherdist.chart3 = l_rec_purchdetl.acct_code[glob_starter,glob_pos3] 
			LET glob_rec_voucherdist.acct_code = l_rec_purchdetl.acct_code[glob_starter,glob_ender] 
			LET l_held_dist_amt = glob_rec_voucherdist.dist_amt 
			LET glob_rec_voucherdist.dist_amt = l_received_amt 
	
			IF glob_rec_voucherdist.dist_amt <> 0 THEN 
				#------------------------------------------------------------
				OUTPUT TO REPORT PC8_rpt_list_a(rpt_rmsreps_idx_get_idx("PC8_rpt_list_a"), glob_rec_voucherdist.*)
				#------------------------------------------------------------
			END IF 

			LET glob_rec_voucherdist.dist_amt = l_held_dist_amt 
		ELSE 
			LET glob_dist_offset = glob_dist_offset - l_received_amt 
			LET glob_rec_voucherdist.dist_amt = glob_rec_voucherdist.dist_amt - l_received_amt 
		END IF 

		IF glob_rem_paid = 0 THEN 
			EXIT FOREACH 
		END IF 

	END FOREACH 
END FUNCTION 



############################################################
# FUNCTION err_list()
#
#
############################################################
FUNCTION err_list() 
	LET glob_rec_print.purch_gl_flag = "E" 
	LET glob_rec_print.acct_code = glob_rec_voucherdist.acct_code 
	LET glob_rec_print.desc_text = glob_rec_voucherdist.desc_text 
	LET glob_rec_print.alloc_amt = glob_rem_paid 

	#------------------------------------------------------------
	OUTPUT TO REPORT PC8_rpt_list_b(rpt_rmsreps_idx_get_idx("PC8_rpt_list_b"), glob_rec_print.*) 
	#------------------------------------------------------------

	IF NOT glob_err_ind THEN 
		CREATE temp TABLE err_vpays ( 
			vouch_code INTEGER, 
			pay_num INTEGER, 
			apply_amt money(10,2), 
			glob_rem_paid money(10,2) 
		) with no LOG 

		DELETE FROM err_vpays WHERE 1 = 1 

		LET glob_err_ind = true 

	END IF 

	LET glob_rec_voucherdist.dist_amt = glob_rem_paid 
	LET glob_rec_voucherdist.acct_code = "See Error Report " 
	LET glob_rec_voucherdist.chart3 = glob_rec_voucherdist.acct_code 

	#------------------------------------------------------------
	OUTPUT TO REPORT PC8_rpt_list_a(rpt_rmsreps_idx_get_idx("PC8_rpt_list_a"), glob_rec_voucherdist.*)
	#------------------------------------------------------------

	INSERT INTO err_vpays VALUES ( 
		glob_rec_voucherpays.vouch_code, 
		glob_rec_voucherpays.pay_num, 
		glob_rec_voucherpays.apply_amt, 
		glob_rem_paid ) 

END FUNCTION 



############################################################
# REPORT PC8_rpt_list(p_rec_cheque)
#
#
############################################################
REPORT PC8_rpt_list(p_rpt_idx, p_rec_cheque) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_cheque RECORD 
		vend_code LIKE cheque.vend_code, 
		name_text LIKE vendor.name_text, 
		cheq_code LIKE cheque.cheq_code, 
		entry_code LIKE cheque.entry_code, 
		entry_date LIKE cheque.entry_date, 
		bank_acct_code LIKE cheque.bank_acct_code, 
		com3_text LIKE cheque.com3_text, 
		cheq_date LIKE cheque.cheq_date, 
		pay_amt LIKE cheque.pay_amt, 
		year_num LIKE cheque.year_num, 
		period_num LIKE cheque.period_num, 
		post_flag LIKE cheque.post_flag, 
		apply_amt LIKE cheque.apply_amt, 
		disc_amt LIKE cheque.disc_amt, 
		rec_state_num LIKE cheque.rec_state_num, 
		rec_line_num LIKE cheque.rec_line_num, 
		com1_text LIKE cheque.com1_text, 
		com2_text LIKE cheque.com2_text 
	END RECORD 
	-- DEFINE l_line1, l_line2 CHAR(80) 
	-- DEFINE l_offset1, l_offset2 SMALLINT

	OUTPUT 
	-- left margin 0 
		ORDER external BY p_rec_cheque.cheq_code 

	FORMAT 
		PAGE HEADER 
			-- LET l_line1 = glob_rpt_date clipped, 10 spaces, 
			-- glob_rec_company.cmpy_code,2 spaces, 
			-- glob_rec_company.name_text clipped, 10 spaces, 
			-- "Page :", pageno USING "####" 
			-- IF glob_rpt_note IS NULL THEN 
			-- 	LET glob_rpt_note=" Treasury Report I - Cheque Allocation (Menu-PC8)" 
			-- END IF 
			-- LET l_line2 = glob_rpt_note clipped 
			-- LET l_offset1 = (glob_rpt_width - length(l_line1))/2 
			-- LET l_offset2 = (glob_rpt_width - length(l_line2))/2 
			-- PRINT COLUMN l_offset1, l_line1 clipped 
			-- PRINT COLUMN l_offset2, l_line2 clipped 
			-- LET glob_rpt_note = NULL 
			-- SKIP 1 line 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 1,"Date", 
			COLUMN 9, "Description", 
			COLUMN 41, "GL Code", 
			COLUMN 65, "Quantity", 
			COLUMN 78, "Amount", 
			COLUMN 89, "Allocated", 
			COLUMN 105, "Remaining" 
			-- PRINT COLUMN 1,"--------------------------------------------", 
			-- "--------------------------------------------", 
			-- "--------------------------------------------" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]
			PRINT COLUMN 1, "Cheque", 
			COLUMN 10, "Cheque ", 
			COLUMN 35, "Date", 
			COLUMN 45, "Period", 
			COLUMN 60, "Amount", 
			COLUMN 75, "Amount", 
			COLUMN 85, "Posted", 
			COLUMN 95, " Vendor " 
			PRINT COLUMN 1, "Number", 
			COLUMN 10, "Reference", 
			COLUMN 75, "Applied" 
			-- PRINT COLUMN 1,"--------------------------------------------", 
			-- "--------------------------------------------", 
			-- "--------------------------------------------" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		ON EVERY ROW 
			PRINT COLUMN 1,p_rec_cheque.cheq_code USING "#######", 
			COLUMN 10, p_rec_cheque.com3_text, 
			COLUMN 35, p_rec_cheque.cheq_date USING "dd/mm/yy", 
			COLUMN 45, p_rec_cheque.period_num USING "###", 
			COLUMN 55, p_rec_cheque.pay_amt USING "---,---,--$.&&", 
			COLUMN 70, p_rec_cheque.apply_amt USING "---,---,--$.&&", 
			COLUMN 88, p_rec_cheque.post_flag, 
			COLUMN 90, p_rec_cheque.vend_code, 
			COLUMN 100,p_rec_cheque.name_text 

		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 1, "Cheques: ", count(*) USING "####", 
			COLUMN 20,"Avg: ",avg(p_rec_cheque.pay_amt) 
			USING "---,---,--$.&&", 
			COLUMN 55, sum(p_rec_cheque.pay_amt) USING "---,---,--$.&&", 
			COLUMN 70, sum(p_rec_cheque.apply_amt) USING "---,---,--$.&&" 
			-- SKIP 1 line 
			-- PRINT COLUMN 30, "***** END OF REPORT PC8 *****" 

			SKIP 2 LINES 

			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			


END REPORT 



############################################################
# REPORT PC8_lista(p_rec_voucherdist)
#
#
############################################################
REPORT PC8_rpt_list_a (p_rpt_idx,p_rec_voucherdist) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_voucherdist RECORD 
		cmpy_code LIKE voucherdist.cmpy_code, 
		vend_code LIKE voucherdist.vend_code, 
		vouch_code LIKE voucherdist.vouch_code, 
		line_num LIKE voucherdist.line_num, 
		acct_code LIKE voucherdist.acct_code, 
		desc_text LIKE voucherdist.desc_text, 
		dist_amt LIKE voucherdist.dist_amt, 
		chart3 CHAR(18) 
	END RECORD
	DEFINE l_tot_rem_paid MONEY(10,2) 
	-- DEFINE l_line1, l_line2 CHAR(80) 
	-- DEFINE l_offset1, l_offset2 SMALLINT	
	
	OUTPUT 
	-- left margin 0 
		ORDER BY p_rec_voucherdist.chart3,p_rec_voucherdist.acct_code 

	FORMAT 
		PAGE HEADER 
			-- LET l_line1 = glob_rpt_date clipped, 10 spaces, glob_rec_company.cmpy_code, 
			-- 2 spaces, glob_rec_company.name_text clipped, 10 spaces, 
			-- "Page:", pageno USING "####" 
			-- IF glob_rpt_note IS NULL THEN 
			-- 	LET glob_rpt_note = " Treasury Report II - Distribution by Account (Menu-PC8)" 
			-- END IF 
			-- LET l_line2 = glob_rpt_note clipped 
			-- LET l_offset1 = (glob_rpt_width - length(l_line1))/2 
			-- LET l_offset2 = (glob_rpt_width - length(l_line2))/2 
			-- PRINT COLUMN l_offset1, l_line1 clipped 
			-- PRINT COLUMN l_offset2, l_line2 clipped 
			-- LET glob_rpt_note = NULL 
			-- PRINT COLUMN 1,"--------------------------------------------", 
			-- "--------------------------------------------", 
			-- "--------------------------------------------" 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 1, "", 
			COLUMN 15, "Account", 
			COLUMN 90, "Amount" 
			-- PRINT COLUMN 1,"--------------------------------------------", 
			-- "--------------------------------------------", 
			-- "--------------------------------------------" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

		AFTER GROUP OF p_rec_voucherdist.acct_code 
			PRINT COLUMN 1, "Account: ", 
			p_rec_voucherdist.acct_code , 
			COLUMN 83, GROUP sum(p_rec_voucherdist.dist_amt) USING "----,---,--$.&&" 

		AFTER GROUP OF p_rec_voucherdist.chart3 
			PRINT COLUMN 83, "---------------" 
			PRINT COLUMN 1, "Sub Total:", 
			COLUMN 83, GROUP sum(p_rec_voucherdist.dist_amt) USING "----,---,--$.&&" 
			SKIP 1 LINES 

		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 82, sum(p_rec_voucherdist.dist_amt) USING "-----,---,--$.&&" 
			SKIP 1 line 
			IF glob_err_ind THEN 
				PRINT "Cheque allocations TO purchase ORDER vouchers WHERE the value of goods " 
				PRINT "received IS less THEN the cheque allocation" 
					DECLARE err_c CURSOR FOR 
					SELECT * 
					FROM err_vpays 
					PRINT "Cheque No. ", 
					"Voucher No.", 
					"Applied Amount ", 
					"Excess Amount " 
					LET l_tot_rem_paid = 0 
					FOREACH err_c INTO 
						glob_rec_voucherpays.vouch_code, 
						glob_rec_voucherpays.pay_num, 
						glob_rec_voucherpays.apply_amt, 
						glob_rem_paid 
						PRINT 
						glob_rec_voucherpays.pay_num USING "########", 
						glob_rec_voucherpays.vouch_code USING "########", 
						glob_rec_voucherpays.apply_amt USING "---,---,---.--", 
						glob_rem_paid USING "---,---,---.--" 
						LET l_tot_rem_paid = l_tot_rem_paid + glob_rem_paid 
					END FOREACH 
					PRINT "Total over-allocations", 
					COLUMN 30, l_tot_rem_paid 
				END IF 
				-- PRINT COLUMN 30, "***** END OF REPORT PC8 *****" 

			SKIP 2 LINES 

			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			

END REPORT 



############################################################
# REPORT PC8_listb (p_rec_print)
#
#
############################################################
REPORT PC8_rpt_list_b (p_rpt_idx,p_rec_print) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_print RECORD 
		cheq_code LIKE cheque.cheq_code, 
		cheq_amt LIKE cheque.pay_amt, 
		vouch_code LIKE voucherpays.vouch_code, 
		vouch_amt LIKE voucherdist.dist_amt, 
		prev_paid DECIMAL(10,2), 
		order_num LIKE poaudit.po_num, 
		acct_code CHAR(18), 
		desc_text CHAR(40), 
		alloc_amt LIKE voucherdist.dist_amt, 
		rem_amt LIKE voucherdist.dist_amt, 
		vouch_rem_amt LIKE voucherdist.dist_amt, 
		apply_amt LIKE voucherpays.apply_amt, 
		purch_gl_flag CHAR(1), # p purchase/delivery, g gl/distribution 
		prev_this_flag CHAR(1), # p(revious paid) t(his cheque) 
		del_date DATE, 
		received_qty LIKE poaudit.received_qty, 
		dist_amt LIKE voucherdist.dist_amt 
	END RECORD 
	-- DEFINE l_line1, l_line2 CHAR(80) 
	-- DEFINE l_offset1, l_offset2 SMALLINT

	OUTPUT 
	-- left margin 0 
		ORDER external BY p_rec_print.cheq_code, p_rec_print.vouch_code,p_rec_print.order_num, 
			p_rec_print.purch_gl_flag, p_rec_print.prev_this_flag 

	FORMAT 
		PAGE HEADER 
			-- LET l_line1 = glob_rpt_date clipped, 10 spaces, glob_rec_company.cmpy_code, 
			-- 2 spaces, glob_rec_company.name_text clipped, 10 spaces, 
			-- "Page:", pageno USING "####" 
			-- IF glob_rpt_note IS NULL THEN 
			-- 	LET glob_rpt_note = " Treasury Report III - Detail (Menu-PC8)" 
			-- END IF 
			-- LET l_line2 = glob_rpt_note clipped 
			-- LET l_offset1 = (glob_rpt_width - length(l_line1))/2 
			-- LET l_offset2 = (glob_rpt_width - length(l_line2))/2 
			-- PRINT COLUMN l_offset1, l_line1 
			-- PRINT COLUMN l_offset2, l_line2 
			-- LET glob_rpt_note = NULL 
			-- PRINT "---------------------------------------------------------------", 
			-- "----------------------------------------------------------------" 
			CALL rpt_set_page_num(p_rpt_idx,pageno)  #update page number
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 1, "Voucher", 
			COLUMN 8, " Voucher", 
			COLUMN 23, " Previously", 
			COLUMN 38, " Order", 
			COLUMN 45, "GL Account", 
			COLUMN 64, "Description", 
			COLUMN 86, "Cheque Amt", 
			COLUMN 101, " Payment", 
			COLUMN 116, "Voucher Amt" 
			PRINT COLUMN 1, "Number", 
			COLUMN 8, " Total", 
			COLUMN 23, " Paid", 
			COLUMN 38, "Number", 
			COLUMN 45, " Code ", 
			COLUMN 86, "Allocated ", 
			COLUMN 101, "Unallocated", 
			COLUMN 116, " Unpaid" 
			-- PRINT "---------------------------------------------------------------", 
			-- "----------------------------------------------------------------" 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			PRINT COLUMN 1, "Bank ID: ", glob_rec_bank.bank_code clipped, 
			" - ", glob_rec_bank.name_acct_text 
			PRINT "------------------------------------------" 
			PRINT 

		BEFORE GROUP OF p_rec_print.cheq_code 
			PRINT "Cheque Number: ", p_rec_print.cheq_code USING "########", " FOR ", 
			COLUMN 29, p_rec_print.cheq_amt USING "$$$$$$$$$$$.$$" 
			PRINT "------------------------------------------" 

		BEFORE GROUP OF p_rec_print.vouch_code 
			PRINT COLUMN 1, p_rec_print.vouch_code USING "######", 
			COLUMN 8, p_rec_print.vouch_amt USING "$$$$$$$$$.$$"; 
			IF p_rec_print.prev_this_flag = "P" THEN 
				PRINT COLUMN 23, p_rec_print.prev_paid USING "$$$$$$$$$.$$"; 
			END IF
 
		ON EVERY ROW 
			PRINT COLUMN 38, p_rec_print.order_num USING "######", 
			COLUMN 45, p_rec_print.acct_code, 
			COLUMN 64, p_rec_print.desc_text[1,20], 
			COLUMN 86, p_rec_print.alloc_amt USING "--------$.$$"; 
			IF p_rec_print.purch_gl_flag = "E" THEN 
				PRINT COLUMN 101, "****ALLOCATION ERROR****" 
			ELSE 
				PRINT COLUMN 101, p_rec_print.rem_amt USING "--------$.$$", 
				COLUMN 116, p_rec_print.vouch_rem_amt USING "--------$.$$" 
			END IF 

		AFTER GROUP OF p_rec_print.vouch_code 
			PRINT COLUMN 55, "Voucher Allocation Total: ", 
			COLUMN 86, GROUP sum( p_rec_print.alloc_amt) USING "--------$.$$" 
			SKIP 1 LINES 

		AFTER GROUP OF p_rec_print.cheq_code 
			IF p_rec_print.rem_amt <> 0 THEN 
				PRINT "Balance unallocated, insufficent distributions OR deliveries ", 
				COLUMN 118, p_rec_print.rem_amt USING "--------$.$$" 
			ELSE 
				PRINT COLUMN 86, "------------" 
				PRINT COLUMN 55," Total Cheque Allocation: ", 
				COLUMN 86, GROUP sum( p_rec_print.alloc_amt) USING "--------$.$$" 
			END IF 
			LET glob_cheq_total_amt = glob_cheq_total_amt + p_rec_print.cheq_amt 
			LET glob_cheq_cnt = glob_cheq_cnt + 1 
			PRINT 

		ON LAST ROW 
			PRINT "Number of cheques processed: ", glob_cheq_cnt USING "####" 
			PRINT "Total Cheque Amount:", 
			COLUMN 29, glob_cheq_total_amt USING "--------$.$$" 
			-- PRINT 
			-- PRINT "Cheque number selection criteria: ", glob_where_part clipped 
			-- PRINT 
			-- PRINT COLUMN 30, "***** END OF REPORT PC8 *****" 

			SKIP 2 LINES 

			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN #Optional Query Where part print
				PRINT COLUMN 01,"Selection Criteria:"
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100
			END IF
			#End Of Report
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #Let's use the same END of report line whenever it's required/possible			

			LET glob_cheq_total_amt = 0 
			LET glob_cheq_cnt = 0 
END REPORT 


