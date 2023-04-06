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

	Source code beautified by beautify.pl on 2020-01-03 13:41:50	$Id: $
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
DEFINE modu_tenthead RECORD LIKE tenthead.* 

############################################################
# MAIN
#
# \brief module PX1  Standard Remittance Print Routine
############################################################
MAIN 
	DEFINE l_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_cycle_num LIKE tentpays.cycle_num
	DEFINE l_comment CHAR(60) 
	DEFINE l_count INTEGER 
	DEFINE l_done INTEGER 
	DEFINE l_complete INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]

	#Initial UI Init
	CALL setModuleId("PX1") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	LET l_cycle_num = get_url_cycle_num() #arg_val(1) 

	OPEN WINDOW P236 with FORM "P236" 
	CALL windecoration_p("P236") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	SELECT * INTO glob_rec_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("P",5000,"") 	#5000 - Company Not Found"
		CLOSE WINDOW p236 
		EXIT PROGRAM 
	END IF 

	SELECT * INTO modu_tenthead.* FROM tenthead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = l_cycle_num 
	IF status <> 0 THEN 
		LET l_msgresp=kandoomsg("P","7070",l_cycle_num) 	#P7070 The Automatic Payment Cycle VALUE does NOT exist
		CLOSE WINDOW p236 
		EXIT PROGRAM 
	END IF 

	WHENEVER ERROR CONTINUE 

	SELECT unique 1 FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = l_cycle_num 
	AND pay_meth_ind = "1" 
	AND status_ind = "4" 
	AND (page_num != 0 AND page_num IS NOT null) 
	IF status != NOTFOUND THEN 
		UPDATE tentpays 
		SET page_num = 0 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND cycle_num = l_cycle_num 
		AND pay_meth_ind = "1" 
		IF status != 0 THEN 
			CLOSE WINDOW p236 
			EXIT PROGRAM 
		END IF 
	END IF 

	WHENEVER ERROR stop 

	SELECT count(*) INTO l_count FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = l_cycle_num 
	AND pay_meth_ind = "1" 
	AND status_ind = "4" 
	IF l_count IS NULL OR 
	l_count = 0 
	THEN 
		LET l_msgresp=kandoomsg("P","7069",l_cycle_num) 
		#P7069 There are no Automatic Payments TO process...
		CLOSE WINDOW p236 
		EXIT PROGRAM 
	END IF 
	LET l_msgresp=kandoomsg("U",1002,"") 
	#U1002 Searching database - please wait
	DECLARE c_tentpays CURSOR FOR 
	SELECT * FROM tentpays 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND cycle_num = l_cycle_num 
	AND status_ind = "4" 
	AND pay_meth_ind = "1" 
	ORDER BY tentpays.pay_doc_num, 
	tentpays.vouch_date, 
	tentpays.inv_text 
	
	#------------------------------------------------------------

	LET l_rpt_idx = rpt_start(getmoduleid(),"PX3_rpt_list_cheque_remit_report","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PX3_rpt_list_cheque_remit_report TO rpt_get_report_file_with_path2(l_rpt_idx)
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
		IF l_complete mod 10 = 0 THEN 
			LET l_comment = "Processing in Progress..", 
			l_complete USING "##&", "% Complete" 
			DISPLAY l_comment TO comments1 

		END IF 
		#---------------------------------------------------------
		OUTPUT TO REPORT PX3_rpt_list_cheque_remit_report(l_rpt_idx,l_rec_tentpays.*)   
		IF NOT rpt_int_flag_handler2("Company:",l_rec_tentpays.cmpy_code, NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------		 


	END FOREACH 

 
	#------------------------------------------------------------
	FINISH REPORT PX3_rpt_list_cheque_remit_report
	CALL rpt_finish("PX3_rpt_list_cheque_remit_report")
	#------------------------------------------------------------
	CLOSE WINDOW p236	 
	IF int_flag THEN 
		LET int_flag = false 
		ERROR " Printing was aborted" 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END MAIN 


############################################################
# REPORT PX3_rpt_list_cheque_remit_report(p_rpt_idx,p_rec_tentpays) 
#
#
############################################################
REPORT PX3_rpt_list_cheque_remit_report(p_rpt_idx,p_rec_tentpays) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_3_cheque RECORD LIKE cheque.* 
	DEFINE l_pay_doc_num LIKE voucherpays.pay_doc_num
	DEFINE l_page_num LIKE rmsreps.page_num 
	DEFINE l_pay_num LIKE voucherpays.pay_num 
	DEFINE l_pay_type_code LIKE voucherpays.pay_type_code 
	DEFINE l_apply_amt DECIMAL(16,2) 
	DEFINE l_disc_amt DECIMAL(16,2) 
	DEFINE l_disp_tax DECIMAL(16,2) 
	DEFINE l_disp_amt DECIMAL(16,2) 
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
	DEFINE l_last_pay_doc_num LIKE tentpays.pay_doc_num 
	DEFINE l_line_count SMALLINT 
	DEFINE l_printchq_ind SMALLINT
	DEFINE l_disp_cheq_date LIKE cheque.cheq_date 
	DEFINE l_arr_line_text ARRAY[3] OF 
	RECORD offset SMALLINT, 
		ret_text CHAR(69) 
	END RECORD 
	DEFINE l_cents DECIMAL(16,2) 

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
			PRINT COLUMN 16, l_arr_address[2] 
			PRINT COLUMN 16, l_arr_address[3], 
			COLUMN 60, modu_tenthead.cheq_date USING "mmm dd yyyy" 
			PRINT COLUMN 16, l_arr_address[4] 
			PRINT COLUMN 16, l_arr_address[5], 
			COLUMN 60, l_rec_vendor.vend_code clipped 
			PRINT COLUMN 16, l_arr_address[6] 
			SKIP 4 LINES 


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
			SELECT * INTO l_rec_3_cheque.* FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND doc_num = p_rec_tentpays.pay_doc_num 

		ON EVERY ROW 
			NEED 3 LINES 
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
				NEED 3 LINES 
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
					INITIALIZE l_disp_cheq_date TO NULL 
					SELECT * INTO l_rec_cheque.* FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND doc_num = l_pay_doc_num 
					LET l_disp_cheq_date = l_rec_cheque.cheq_date 
					IF l_rec_cheque.withhold_tax_ind != 0 THEN 
						CALL wtaxcalc(l_apply_amt, 
						l_rec_cheque.tax_per, 
						"1", ### hardcoded as per p34m.4gl ### 
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
			LET l_cents = 0 
			LET l_printchq_ind = true 
			LET l_last_pay_doc_num = p_rec_tentpays.pay_doc_num 
			LET l_page_num = pageno 
			IF l_tax_total <> 0 THEN 
				LET l_tax2_total = l_rec_3_cheque.tax_amt 
				LET l_cheque_amt = l_rec_3_cheque.net_pay_amt 
				IF l_tax2_total <> l_tax_total THEN 
					LET l_cents = l_tax2_total - l_tax_total 
				END IF 
				LET l_tax_total = l_tax2_total 
				### Ensure the total tax found IS also adjusted before displaying ###
				LET l_tax3_total = l_tax3_total + l_cents 
			END IF 
			UPDATE tentpays 
			SET page_num = l_page_num 
			WHERE pay_doc_num = p_rec_tentpays.pay_doc_num 
			PAGE TRAILER 
				SKIP 1 line 
				IF l_printchq_ind THEN 
					PRINT COLUMN 048, "TOTAL REMITTED: ", 
					COLUMN 064, l_cheque_amt USING "-------&.&&" 
					IF l_cheque_amt < 1000000 THEN 
						SKIP 7 LINES 
						PRINT COLUMN 013, l_rec_vendor.name_text, 
						COLUMN 069, modu_tenthead.cheq_date USING "mmm dd yyyy" 
						SKIP 2 LINES 

--						INITIALIZE l_arr_line_text[1].* TO NULL 
--						INITIALIZE l_arr_line_text[2].* TO NULL 

						CALL numto(l_cheque_amt,69) 
						RETURNING l_line_count, 
						l_arr_line_text[1].offset, 
						l_arr_line_text[1].ret_text, 
						l_arr_line_text[2].offset, 
						l_arr_line_text[2].ret_text, 
						l_arr_line_text[3].offset, 
						l_arr_line_text[3].ret_text 

						PRINT COLUMN 010, l_arr_line_text[1].ret_text 
						PRINT COLUMN 010, l_arr_line_text[2].ret_text 
						PRINT COLUMN 066, l_rec_3_cheque.net_pay_amt USING "$******.**" 
						SKIP 6 LINES 
					ELSE 
						SKIP 7 LINES 
						PRINT COLUMN 013, "***VOID***", 
						COLUMN 069, "********" 
						SKIP 2 LINES 
						PRINT COLUMN 009, "VOID", # 100,000's COLUMN 
						COLUMN 017, "VOID", # 10,000's COLUMN 
						COLUMN 025, "VOID", # 1,000's COLUMN 
						COLUMN 033, "VOID", # 100's COLUMN 
						COLUMN 040, "VOID", # 10's COLUMN 
						COLUMN 049, "VOID", # units COLUMN 
						COLUMN 060, "**" # cents COLUMN 
						PRINT COLUMN 068, "**********" # amount in numbers 
						SKIP 6 LINES 
						PRINT COLUMN 004, "XXXXXXXXXXXXXXXXXXXXXXXXXXX", 
						COLUMN 050, "XXXXXXXXXXXXXXXXXXXXXXXXXXX" 
					END IF 
				ELSE 
					PRINT COLUMN 052, "BALANCE B/F", 
					COLUMN 068, l_cheque_amt USING "------&.&&" 
					SKIP 7 LINES 
					PRINT COLUMN 013, "***VOID***", 
					COLUMN 069, "********" 
					SKIP 2 LINES 
					PRINT COLUMN 009, "VOID", # 100,000's COLUMN 
					COLUMN 017, "VOID", # 10,000's COLUMN 
					COLUMN 025, "VOID", # 1,000's COLUMN 
					COLUMN 033, "VOID", # 100's COLUMN 
					COLUMN 040, "VOID", # 10's COLUMN 
					COLUMN 049, "VOID", # units COLUMN 
					COLUMN 060, "**" # cents COLUMN 
					PRINT COLUMN 068, "**********" # amount in numbers 
					SKIP 6 LINES 
					PRINT COLUMN 004, "XXXXXXXXXXXXXXXXXXXXXXXXXXX", 
					COLUMN 050, "XXXXXXXXXXXXXXXXXXXXXXXXXXX" 
				END IF 

END REPORT 