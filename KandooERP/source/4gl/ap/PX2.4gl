{
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

	Source code beautified by beautify.pl on 2020-01-03 13:41:51	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl" 
############################################################
# Module Scope Variables
############################################################
DEFINE modu_rec_tenthead RECORD LIKE tenthead.* 
DEFINE modu_cycle_num LIKE tentpays.cycle_num 
DEFINE modu_where_text CHAR(2048) 

############################################################
# MAIN
#
# \brief module PX2 Standard Remittance Advice Print Routine
############################################################
MAIN 
	DEFINE l_prog_call CHAR(10) 
	DEFINE l_msgresp LIKE language.yes_flag 

	#Initial UI Init
	CALL setModuleId("PX2") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL fgl_winmessage("??? Module","undocumented module - needs 2 arguments\nsomething with bank transactions","info") 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	SELECT * INTO glob_rec_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("P",5000,"") 
		#5000 - Company Not Found"
		EXIT PROGRAM 
	END IF 
	LET modu_cycle_num = get_url_cycle_num() #arg_val(1) 
	LET l_prog_call = get_url_prog_child() #arg_val(2) 
	LET modu_where_text = get_url_query_where_text()  #arg_val(3) 

	IF l_prog_call IS NOT NULL THEN 
		IF l_prog_call = "P3A" THEN 
			CALL print_tentpays_remittance() 
		ELSE 
			CALL print_other_remittance() 
		END IF 
	END IF 
END MAIN 


############################################################
# FUNCTION print_tentpays_remittance()
#
#
############################################################
FUNCTION print_tentpays_remittance() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_comment CHAR(60) 
	DEFINE l_done INTEGER 
	DEFINE l_count INTEGER 
	DEFINE l_complete FLOAT 
	DEFINE l_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW p237 with FORM "P237" 
	CALL windecoration_p("P237") 

	LET l_msgresp=kandoomsg("U",1002,"") 
	#U1002 Searching database - please wait
	SELECT * INTO modu_rec_tenthead.* FROM tenthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = modu_cycle_num 
	IF status <> 0 THEN 
		LET l_msgresp=kandoomsg("P","7070",modu_cycle_num) 
		#P7070 The Automatic Payment Cycle VALUE does NOT exist
		EXIT PROGRAM 
	END IF 

	SELECT count(*) INTO l_count FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = modu_cycle_num 
	AND pay_meth_ind = "3" 
	AND status_ind = "4" 

	IF l_count = 0 
	OR l_count IS NULL THEN 
		LET l_msgresp=kandoomsg("P","7069",modu_cycle_num) 
		#P7069 There are NO Automatic Payments TO process...
		EXIT PROGRAM 
	END IF 

	DECLARE c_tentpays CURSOR FOR 
	SELECT * FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = modu_cycle_num 
	AND pay_meth_ind = "3" 
	AND status_ind = "4" 
	ORDER BY pay_doc_num, 
	vouch_date, 
	inv_text 

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"PX2_rpt_remittance_report","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PX2_rpt_remittance_report TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------


	LET l_done = 0 
	FOREACH c_tentpays INTO l_rec_tentpays.* 
		LET l_done = l_done + 1 
		LET l_complete = ((l_done/l_count) * 100) 
		IF l_complete mod 50 = 0 THEN 
			LET l_comment = "Processing in Progress..", 
			l_complete USING "##&", "% Complete" 
			DISPLAY l_comment TO comments1 

		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT PX2_rpt_remittance_report(l_rpt_idx,l_rec_tentpays.*)
		IF NOT rpt_int_flag_handler2("Remittance:",l_comment, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	

	END FOREACH 

	CLOSE WINDOW p237 
	
	#------------------------------------------------------------
	FINISH REPORT PX2_rpt_remittance_report
	CALL rpt_finish("PX2_rpt_remittance_report")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF  
END FUNCTION 


############################################################
# FUNCTION print_other_remittance()
#
#
############################################################
FUNCTION print_other_remittance() 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_rec_2_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_2_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_comment CHAR(60) 
	DEFINE l_done INTEGER 
	DEFINE l_count INTEGER 
	DEFINE l_complete FLOAT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW p236 with FORM "P236" 
	CALL windecoration_p("P236") 

	LET l_msgresp=kandoomsg("U",1002,"") 
	#U1002 Searching database - please wait
	SELECT * FROM tentpays WHERE 1!=1 INTO temp t_tentpays 
	LET l_query_text = "SELECT * FROM cheque ", 
	"WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND ",modu_where_text clipped 

	PREPARE s_cheque FROM l_query_text 
	DECLARE c5_cheque CURSOR FOR s_cheque 
	DISPLAY "Selecting Information FOR Remittance..." TO comments1 

	FOREACH c5_cheque INTO l_rec_cheque.* 
		### Collect the voucherpays that were created as payments ###
		### FOR the current cheque.                               ###
		DECLARE c5_voucherpays CURSOR FOR 
		SELECT * FROM voucherpays 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND pay_type_code = "CH" 
		AND vend_code = l_rec_cheque.vend_code 
		AND pay_doc_num = l_rec_cheque.doc_num 
		AND remit_doc_num = l_rec_cheque.doc_num 

		FOREACH c5_voucherpays INTO l_rec_voucherpays.* 
			IF int_flag OR quit_flag THEN 
				#8503 Continue Report(Y/N)
				IF kandoomsg("U",8503,"") = "N" THEN 
					#9501 Report Terminated
					LET l_msgresp=kandoomsg("U",9501,"") 
					CLOSE WINDOW p236 
					EXIT PROGRAM 
				END IF 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 

			SELECT * INTO l_rec_voucher.* FROM voucher 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vouch_code = l_rec_voucherpays.vouch_code 
			AND vend_code = l_rec_voucherpays.vend_code 
			IF status = 0 THEN 
				INSERT INTO t_tentpays 
				VALUES (l_rec_voucher.cmpy_code, 
				"", 
				l_rec_voucherpays.vend_code, 
				l_rec_voucherpays.vouch_code, 
				l_rec_cheque.cheq_date, 
				l_rec_voucherpays.apply_amt, 
				"", 
				l_rec_voucherpays.disc_amt, 
				l_rec_voucherpays.withhold_tax_ind, 
				l_rec_voucherpays.tax_code, 
				l_rec_voucherpays.tax_per, 
				l_rec_cheque.pay_meth_ind, 
				l_rec_voucher.source_ind, 
				l_rec_voucher.source_text, 
				"5", 
				l_rec_cheque.doc_num, 
				0, 
				l_rec_cheque.cheq_code, 
				l_rec_voucher.vouch_date, 
				l_rec_voucher.inv_text, 
				l_rec_voucher.total_amt) 
			END IF 

		END FOREACH 


		### FOR this cheque.doc_num find any pay_doc_num != remit_doc_num ###
		### applications that must appear here FOR current cheque. IF the ###
		### voucher appears in the t_tentpays THEN no need TO add it.     ###
		DECLARE c6_voucherpays CURSOR FOR 
		SELECT * FROM voucherpays 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND pay_doc_num != l_rec_cheque.doc_num 
		AND remit_doc_num = l_rec_cheque.doc_num 

		FOREACH c6_voucherpays INTO l_rec_2_voucherpays.* 
			IF int_flag OR quit_flag THEN 
				#8503 Continue Report(Y/N)
				IF kandoomsg("U",8503,"") = "N" THEN 
					#9501 Report Terminated
					LET l_msgresp=kandoomsg("U",9501,"") 
					CLOSE WINDOW p236 
					EXIT PROGRAM 
				END IF 
				LET int_flag = false 
				LET quit_flag = false 
			END IF 
			### IF the vendor/voucher combination exists in the ###
			### t_tentpays THEN do NOT add it again.            ###
			SELECT unique 1 FROM t_tentpays 
			WHERE vend_code = l_rec_2_voucherpays.vend_code 
			AND vouch_code = l_rec_2_voucherpays.vouch_code 
			IF status = NOTFOUND THEN 
				SELECT * INTO l_rec_2_voucher.* FROM voucher 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vouch_code = l_rec_2_voucherpays.vouch_code 
				AND vend_code = l_rec_2_voucherpays.vend_code 
				IF status = 0 THEN 
					INSERT INTO t_tentpays 
					VALUES (l_rec_2_voucher.cmpy_code, 
					"", 
					l_rec_2_voucherpays.vend_code, 
					l_rec_2_voucherpays.vouch_code, 
					l_rec_cheque.cheq_date, 
					0, 
					"", 
					0, 
					l_rec_2_voucherpays.withhold_tax_ind, 
					l_rec_2_voucherpays.tax_code, 
					l_rec_2_voucherpays.tax_per, 
					l_rec_cheque.pay_meth_ind, 
					l_rec_2_voucher.source_ind, 
					l_rec_2_voucher.source_text, 
					"5", 
					l_rec_cheque.doc_num, 
					0, 
					l_rec_cheque.cheq_code, 
					l_rec_2_voucher.vouch_date, 
					l_rec_2_voucher.inv_text, 
					l_rec_2_voucher.total_amt) 
				END IF 
			END IF 

		END FOREACH 

	END FOREACH 

	SELECT count(*) INTO l_count FROM t_tentpays 
	WHERE 1=1 

	DECLARE c5_tentpays CURSOR FOR 
	SELECT * FROM t_tentpays 
	ORDER BY pay_doc_num, 
	vouch_date, 
	inv_text 
	
	
	#------------------------------------------------------------

	LET l_rpt_idx = rpt_start(getmoduleid(),"PX2_rpt_remittance_report","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PX2_rpt_remittance_report TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------
		
	LET l_done = 0 

	FOREACH c5_tentpays INTO l_rec_tentpays.* 
		LET l_done = l_done + 1 
		LET l_complete = ((l_done/l_count) * 100) 
		IF l_complete mod 50 = 0 THEN 
			LET l_comment = "Processing in Progress..", 
			l_complete USING "##&", "% Complete" 
			DISPLAY l_comment TO comments1 

		END IF 


		#---------------------------------------------------------
		OUTPUT TO REPORT PX2_rpt_remittance_report(l_rpt_idx,l_rec_tentpays.*)
		IF NOT rpt_int_flag_handler2("Remittance:",l_comment, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		 

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PX2_rpt_remittance_report
	CALL rpt_finish("PX2_rpt_remittance_report")
	#------------------------------------------------------------
	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF  
END FUNCTION 


############################################################
# REPORT PX2_rpt_remittance_report(p_rec_tentpays)
#
#
############################################################
REPORT PX2_rpt_remittance_report(p_rpt_idx,p_rec_tentpays) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_3_cheque RECORD LIKE cheque.* 
	DEFINE l_pay_doc_num LIKE voucherpays.pay_doc_num 
	DEFINE l_pay_num LIKE voucherpays.pay_num 
	DEFINE l_pay_type_code LIKE voucherpays.pay_type_code 
	DEFINE l_apply_amt DECIMAL(16,2) 
	DEFINE l_disc_amt DECIMAL(16,2) 
	DEFINE l_cheque_amt LIKE vendor.bal_amt 
	DEFINE l_credit_total LIKE vendor.bal_amt 
	DEFINE l_invoice_total LIKE vendor.bal_amt 
	DEFINE l_voucher_total LIKE vendor.bal_amt 
	DEFINE l_voucher2_total LIKE vendor.bal_amt 
	DEFINE l_disc_total LIKE vendor.bal_amt 
	DEFINE l_tax_amt LIKE cheque.net_pay_amt 
	DEFINE l_tax3_total LIKE cheque.net_pay_amt 
	DEFINE l_tax2_total LIKE cheque.net_pay_amt 
	DEFINE l_tax_total LIKE cheque.net_pay_amt 
	DEFINE l_arr_address ARRAY[6] OF CHAR(32) 
	DEFINE l_printchq_ind SMALLINT 
	DEFINE l_disp_amt DECIMAL(16,2) 
	DEFINE l_disp_tax DECIMAL(16,2) 
	DEFINE l_cents DECIMAL(16,2) 
	DEFINE l_textline CHAR(40) 
	DEFINE l_last_cheq_code LIKE cheque.cheq_code 
	DEFINE l_last_vend_code LIKE vendor.vend_code 
	DEFINE l_last_meth_ind LIKE tentpays.pay_meth_ind 
	DEFINE l_last_source_ind LIKE tentpays.source_ind 
	DEFINE l_disp_cheq_date LIKE cheque.cheq_date 

	OUTPUT 
--	PAGE length 66 
--	left margin 0 
--	top margin 5 
--	bottom margin 5 
	ORDER external BY p_rec_tentpays.pay_doc_num, 
	p_rec_tentpays.vouch_date, 
	p_rec_tentpays.inv_text 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
		
			IF p_rec_tentpays.source_ind = "8" THEN 
				INITIALIZE l_rec_customer.* TO NULL 
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cust_code = p_rec_tentpays.source_text 
				AND cmpy_code = p_rec_tentpays.cmpy_code 
				LET l_rec_vendor.vend_code = l_rec_customer.cust_code 
				LET l_rec_vendor.name_text = l_rec_customer.name_text 
				LET l_rec_vendor.addr1_text = l_rec_customer.addr1_text 
				LET l_rec_vendor.addr2_text = l_rec_customer.addr2_text 
				LET l_rec_vendor.addr3_text = NULL 
				LET l_rec_vendor.city_text = l_rec_customer.city_text 
				LET l_rec_vendor.state_code = l_rec_customer.state_code 
				LET l_rec_vendor.post_code = l_rec_customer.post_code 
				LET l_rec_vendor.country_code = l_rec_customer.country_code --@db-patch_2020_10_04-- 
			ELSE 
				IF p_rec_tentpays.source_ind = "S" THEN 
					SELECT * INTO l_rec_vouchpayee.* FROM vouchpayee 
					WHERE vend_code = p_rec_tentpays.vend_code 
					AND vouch_code = p_rec_tentpays.vouch_code 
					AND cmpy_code = cmpy_code 
					LET l_rec_vendor.vend_code = "SUNDRY" 
					LET l_rec_vendor.name_text = l_rec_vouchpayee.name_text 
					LET l_rec_vendor.addr1_text = l_rec_vouchpayee.addr1_text 
					LET l_rec_vendor.addr2_text = l_rec_vouchpayee.addr2_text 
					LET l_rec_vendor.addr3_text = l_rec_vouchpayee.addr3_text 
					LET l_rec_vendor.city_text = l_rec_vouchpayee.city_text 
					LET l_rec_vendor.state_code = l_rec_vouchpayee.state_code 
					LET l_rec_vendor.post_code = l_rec_vouchpayee.post_code  
					LET l_rec_vendor.country_code = l_rec_vouchpayee.country_code --@db-patch_2020_10_04--
				ELSE 
					INITIALIZE l_rec_vendor.* TO NULL 
					SELECT * INTO l_rec_vendor.* FROM vendor 
					WHERE cmpy_code = p_rec_tentpays.cmpy_code 
					AND vend_code = p_rec_tentpays.vend_code 
				END IF 
			END IF 
			CALL pack_vend_address(l_rec_vendor.name_text, 
			l_rec_vendor.addr1_text, 
			l_rec_vendor.addr2_text, 
			l_rec_vendor.addr3_text, 
			l_rec_vendor.city_text, 
			l_rec_vendor.state_code, 
			l_rec_vendor.post_code, 
			l_rec_vendor.country_code) --@db-patch_2020_10_04--
			RETURNING l_arr_address[1], 
			l_arr_address[2], 
			l_arr_address[3], 
			l_arr_address[4], 
			l_arr_address[5], 
			l_arr_address[6] 
			LET l_printchq_ind = false 
			PRINT COLUMN 16, l_arr_address[1] 
			PRINT COLUMN 11, "TO: ", 
			COLUMN 16, l_arr_address[2] 
			PRINT COLUMN 16, l_arr_address[3]; 
			IF modu_rec_tenthead.cheq_date IS NULL THEN 
				PRINT COLUMN 60, modu_rec_tenthead.cheq_date USING "ddmmmyyyy" 
			ELSE 
				### WHEN re-printing remittance the t_tentpays table   ###
				### contains details of past payments.  Therefore the  ###
				### actual cheq_date will be inserted INTO the due_date###
				### so that it can be printed in the PAGE HEADER.      ###
				PRINT COLUMN 60, p_rec_tentpays.due_date USING "ddmmmyyyy" 
			END IF 
			PRINT COLUMN 16, l_arr_address[4] 
			PRINT COLUMN 16, l_arr_address[5], 
			COLUMN 60, l_rec_vendor.vend_code clipped 
			PRINT COLUMN 16, l_arr_address[6] 
			SKIP 1 LINES 
			PRINT COLUMN 07, "DATE", 
			COLUMN 19, "DOC", 
			COLUMN 24, "REFERENCE", 
			COLUMN 42, "TOTAL", 
			COLUMN 54, "WITHHELD", 
			COLUMN 68, "REMITTED" 
			SKIP 1 LINES 
			IF p_rec_tentpays.source_ind = "8" THEN 
				INITIALIZE l_rec_vendor.* TO NULL 
				SELECT * INTO l_rec_vendor.* FROM vendor 
				WHERE cmpy_code = p_rec_tentpays.cmpy_code 
				AND vend_code = p_rec_tentpays.vend_code 
			END IF 
		BEFORE GROUP OF p_rec_tentpays.pay_doc_num 
			SKIP TO top OF PAGE 
			LET l_voucher_total = 0 
			LET l_voucher2_total = 0 
			LET l_disc_total = 0 
			LET l_cheque_amt = 0 
			LET l_invoice_total = 0 
			LET l_credit_total = 0 
			LET l_tax_total = 0 
			LET l_tax3_total = 0 
		ON EVERY ROW 
			NEED 2 LINES 
			LET l_tax_amt = 0 
			LET l_voucher_total = 0 
			IF p_rec_tentpays.withhold_tax_ind != "0" THEN 
				CALL wtaxcalc(p_rec_tentpays.vouch_amt, 
				p_rec_tentpays.tax_per, 
				'1', 
				p_rec_tentpays.cmpy_code) 
				RETURNING l_voucher_total, 
				l_tax_amt 
				LET l_voucher2_total = l_voucher2_total + p_rec_tentpays.vouch_amt 
			ELSE 
				LET l_voucher_total = p_rec_tentpays.vouch_amt 
			END IF 
			LET l_invoice_total = l_invoice_total + p_rec_tentpays.total_amt 
			LET l_disc_total = l_disc_total + p_rec_tentpays.taken_disc_amt 
			LET l_tax_total = l_tax_total + l_tax_amt 
			LET l_tax3_total = l_tax3_total + l_tax_amt 
			LET l_cheque_amt = l_cheque_amt + l_voucher_total 
			IF p_rec_tentpays.taken_disc_amt = 0 THEN 
				LET p_rec_tentpays.taken_disc_amt = NULL 
			END IF 
			IF l_tax_amt = 0 THEN 
				LET l_tax_amt = NULL 
			END IF 
			IF l_voucher_total = 0 THEN 
				LET l_voucher_total = NULL 
			END IF 
			PRINT COLUMN 005, p_rec_tentpays.vouch_date USING "dd/mm/yy", 
			COLUMN 019, "INV", 
			COLUMN 024, p_rec_tentpays.inv_text[1,13], 
			COLUMN 037, p_rec_tentpays.total_amt USING "-------&.&&", 
			COLUMN 051, (0-p_rec_tentpays.taken_disc_amt) USING "-------&.&&", 
			COLUMN 065, l_voucher_total USING "-------&.&&" 
			DECLARE c_otherpays CURSOR FOR 
			SELECT pay_doc_num, 
			pay_num, 
			pay_type_code, 
			sum(apply_amt), 
			sum(disc_amt) 
			FROM voucherpays 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_tentpays.vend_code 
			AND vouch_code = p_rec_tentpays.vouch_code 
			AND pay_doc_num != p_rec_tentpays.pay_doc_num 
			AND remit_doc_num = p_rec_tentpays.pay_doc_num 
			AND (rev_flag != "Y" OR rev_flag IS null) 
			GROUP BY 1,2,3 
			having sum(apply_amt+disc_amt) != 0 
			FOREACH c_otherpays INTO l_pay_doc_num, 
				l_pay_num, l_pay_type_code, 
				l_apply_amt, l_disc_amt 
				NEED 2 LINES 
				IF l_pay_type_code = "DB" THEN 
					INITIALIZE l_rec_debithead.* TO NULL 
					SELECT * INTO l_rec_debithead.* FROM debithead 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND debit_num = l_pay_num 
					AND vend_code = p_rec_tentpays.vend_code 
					LET l_credit_total = l_credit_total + l_apply_amt 
					IF l_apply_amt = 0 THEN 
						LET l_apply_amt = NULL 
					END IF 
					PRINT COLUMN 005, l_rec_debithead.debit_date USING "dd/mm/yy", 
					COLUMN 019, "DEB", 
					COLUMN 024, l_rec_debithead.debit_text[1,13], 
					COLUMN 051, (0-l_apply_amt) USING "-------&.&&" 
				ELSE 
					INITIALIZE l_rec_cheque.* TO NULL 
					SELECT * INTO l_rec_cheque.* FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND doc_num = l_pay_doc_num 
					LET l_disp_cheq_date = l_rec_cheque.cheq_date 
					IF l_rec_cheque.withhold_tax_ind != 0 THEN 
						CALL wtaxcalc(l_apply_amt, 
						l_rec_cheque.tax_per, 
						"1", 
						l_rec_cheque.cmpy_code) 
						RETURNING l_disp_amt, 
						l_disp_tax 
						LET l_disc_total = l_disc_total + l_disc_amt 
						LET l_tax3_total = l_tax3_total + l_disp_tax 
						LET l_credit_total = l_credit_total + l_disp_amt 
						IF l_disp_amt = 0 THEN 
							LET l_disp_amt = NULL 
						END IF 
						IF l_disp_tax = 0 THEN 
							LET l_disp_tax = NULL 
						END IF 
						IF l_disc_amt = 0 THEN 
							LET l_disc_amt = NULL 
						END IF 
						PRINT COLUMN 005, l_disp_cheq_date USING "dd/mm/yy", 
						COLUMN 019, "PAY", 
						COLUMN 024, l_pay_num USING "<<<<<<<<<<", 
						COLUMN 051, (0-l_disp_amt) USING "-------&.&&" 
					ELSE 
						LET l_disc_total = l_disc_total + l_disc_amt 
						LET l_credit_total = l_credit_total + l_apply_amt 
						IF l_apply_amt = 0 THEN 
							LET l_apply_amt = NULL 
						END IF 
						IF l_disc_amt = 0 THEN 
							LET l_disc_amt = NULL 
						END IF 
						PRINT COLUMN 005, l_disp_cheq_date USING "dd/mm/yy", 
						COLUMN 019, "PAY", 
						COLUMN 024, l_pay_num USING "<<<<<<<<<<", 
						COLUMN 051, (0-l_apply_amt) USING "-------&.&&" 
					END IF 
				END IF 
			END FOREACH 
		AFTER GROUP OF p_rec_tentpays.pay_doc_num 
			LET l_cents = 0.00 
			LET l_printchq_ind = true 

			IF l_tax_total <> 0 THEN 
				SELECT * INTO l_rec_3_cheque.* 
				FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND doc_num = p_rec_tentpays.pay_doc_num 
				LET l_tax2_total = l_rec_3_cheque.tax_amt 
				LET l_cheque_amt = l_rec_3_cheque.net_pay_amt 
				IF l_tax2_total <> l_tax_total THEN 
					LET l_cents = l_tax2_total - l_tax_total 
				END IF 
				LET l_tax_total = l_tax2_total 
				### Ensure the total tax found IS also adjusted before displaying ###
				LET l_tax3_total = l_tax3_total + l_cents 
			END IF 
			### IF in UPDATE mode THEN ensure the page_no IS SET TO 1 ###
			### 1 represents the EFT tentpays has been processed AND  ###
			### IS used back in source program P3A as confirmation    ###
			### that EFT have been printed.                           ###
			IF p_rec_tentpays.status_ind = "4" THEN 
				UPDATE tentpays 
				SET page_num = 1 
				WHERE pay_doc_num = p_rec_tentpays.pay_doc_num 
			END IF 
			LET l_last_vend_code = p_rec_tentpays.vend_code 
			LET l_last_cheq_code = p_rec_tentpays.cheq_code 
			LET l_last_meth_ind = p_rec_tentpays.pay_meth_ind 
			LET l_last_source_ind = p_rec_tentpays.source_ind 
			PAGE TRAILER 
				IF l_printchq_ind THEN 
					CASE l_last_meth_ind 
						WHEN "1" LET l_textline = "Payment by Cheque Number :", 
							l_last_cheq_code USING "<<<<<<<<<<" 
							WHEN "3" IF l_last_source_ind = "S" THEN 
								LET l_textline = "Payment by EFT TO Account :", 
								l_rec_vouchpayee.bank_acct_code 
							ELSE 
								SELECT * INTO l_rec_vendor.* FROM vendor 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND vend_code = l_last_vend_code 
								LET l_textline = "Payment by EFT TO Account :", 
								l_rec_vendor.bank_acct_code 
							END IF 
						WHEN "4" LET l_textline = "Payment by Direct Debit :", 
							l_last_cheq_code USING "<<<<<<<<<<" 
					END CASE 
					PRINT COLUMN 002, l_textline clipped 
					SKIP 1 line 
					PRINT COLUMN 048, "TOTAL REMITTED: ", 
					COLUMN 064, l_cheque_amt USING "-------&.&&" 
				ELSE 
					CASE l_last_meth_ind 
						WHEN "1" LET l_textline = "Payment by Cheque Number :", 
							l_last_cheq_code USING "<<<<<<<<<<" 
							WHEN "3" IF p_rec_tentpays.source_ind = "S" THEN 
								LET l_textline = "Payment by EFT TO Account :", 
								l_rec_vouchpayee.bank_acct_code 
							ELSE 
								SELECT * INTO l_rec_vendor.* FROM vendor 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND vend_code = l_last_vend_code 
								LET l_textline = "Payment by EFT TO Account :", 
								l_rec_vendor.bank_acct_code 
							END IF 
						WHEN "4" LET l_textline = "Payment by Direct Debit :", 
							l_last_cheq_code USING "<<<<<<<<<<" 
					END CASE 
					PRINT COLUMN 002, l_textline clipped 
					SKIP 1 line 
					PRINT COLUMN 52, "BALANCE B/F", 
					COLUMN 64, l_cheque_amt USING "------&.&&" 
				END IF 
END REPORT 


