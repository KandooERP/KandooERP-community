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
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/../ap/P_AP_P3_GLOBALS.4gl" 


GLOBALS 
	DEFINE glob_tot_pay_amt LIKE cheque.net_pay_amt 
	DEFINE glob_tot_tax_amt LIKE cheque.net_pay_amt 
	DEFINE glob_tot_contra_amt LIKE cheque.net_pay_amt 
	DEFINE glob_query_text STRING -- CHAR(1200) 
	DEFINE glob_where_part STRING -- CHAR(1200) 
	DEFINE glob_report_ord_flag LIKE apparms.report_ord_flag 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module P32  Payments Register FOR Accounts Payable
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	#Initial UI Init
	CALL setModuleId("P32") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	SELECT report_ord_flag INTO glob_report_ord_flag FROM apparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("U",5116,"")	#5116 AP Parameters NOT SET up; Refer Menu PZP.
		EXIT PROGRAM 
	END IF 

	OPEN WINDOW p111 with FORM "P111" 
	CALL windecoration_p("P111") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	MENU " Payment Register" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","P32","menu-payment-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		COMMAND "Report" " SELECT criteria AND PRINT REPORT" 
			CALL P32_query() 

		ON ACTION "Print" 		#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
			CALL run_prog("URS","","","","") 
		COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 
	CLOSE WINDOW P111 
END MAIN 
############################################################
# END MAIN
############################################################


############################################################
# FUNCTION P32_query()
#
#
############################################################
FUNCTION p32_query() 
	DEFINE p_where_text STRING 
	DEFINE l_query_text STRING
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE l_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_name_text LIKE vendor.name_text 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("U",1001,"") #1001 Enter Selection Criteria - ESC TO Continue"
	CONSTRUCT BY NAME glob_where_part ON 
		tentpays.vend_code, 
		tentpays.vouch_code, 
		tentpays.due_date, 
		tentpays.vouch_amt, 
		tentpays.disc_date, 
		tentpays.taken_disc_amt, 
		tentpays.withhold_tax_ind, 
		tentpays.pay_meth_ind 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P32","construct-tentpays-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL
	IF (glob_where_part IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = false 
		LET quit_flag = false

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"P32_rpt_list",glob_where_part, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT AC1_rpt_list TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	LET glob_where_part = glob_arr_rec_rpt_rmsreps[rpt_rmsreps_idx_get_idx("AC1_rpt_list")].sel_text
	#------------------------------------------------------------


	LET glob_tot_contra_amt = 0 
	LET glob_tot_tax_amt = 0 
	LET glob_tot_pay_amt = 0 
	IF glob_report_ord_flag = "C" THEN 
		LET glob_query_text = 
		"SELECT tentpays.* ", 
		"FROM tentpays ", 
		"WHERE tentpays.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND ", glob_where_part clipped," ", 
		"ORDER BY pay_meth_ind, ", 
		"vend_code, ", 
		"source_ind, ", 
		"source_text, ", 
		"withhold_tax_ind, ", 
		"inv_text" 
	ELSE 
		LET glob_query_text = 
		"SELECT tentpays.*, name_text ", 
		"FROM tentpays, vendor ", 
		"WHERE tentpays.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND vendor.vend_code = tentpays.vend_code ", 
		"AND ", glob_where_part clipped," ", 
		"ORDER BY pay_meth_ind, ", 
		"name_text, ", 
		"source_ind, ", 
		"source_text, ", 
		"vend_code, ", 
		"withhold_tax_ind, ", 
		"inv_text" 
	END IF 
	PREPARE choice FROM glob_query_text 
	DECLARE selcurs CURSOR FOR choice 
 
	FOREACH selcurs INTO l_rec_tentpays.*, l_name_text 
		#---------------------------------------------------------
		OUTPUT TO REPORT P32_rpt_list(l_rpt_idx,
		l_rec_tentpays.*)  
		IF NOT rpt_int_flag_handler2("Vendor:",l_name_text,NULL,l_rpt_idx) THEN
			EXIT FOREACH 
		END IF 
		#---------------------------------------------------------	

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT P32_rpt_list
	CALL rpt_finish("P32_rpt_list")
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
# END FUNCTION P32_query()
############################################################


############################################################
# REPORT P32_rpt_list(p_rpt_idx,p_rec_tentpays)
#
#
############################################################
REPORT P32_rpt_list(p_rpt_idx,p_rec_tentpays) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
	DEFINE p_rec_tentpays RECORD LIKE tentpays.* 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	#DEFINE l_cmpy_head CHAR(80), NOT used
	DEFINE l_rr_count SMALLINT 
	DEFINE l_wtax_chq_amt, l_wtax_tax_amt LIKE cheque.net_pay_amt 
	DEFINE l_tot_vend_pay,l_tot_vend_tax LIKE cheque.net_pay_amt 
	DEFINE l_tot_vend_disc_amt LIKE tentpays.taken_disc_amt 
	DEFINE l_tot_vend_contra,l_tot_ind_contra LIKE cheque.net_pay_amt 
	DEFINE l_tot_ind_pay, l_ind_tax LIKE cheque.net_pay_amt 
	DEFINE l_cust_name, l_contra_cust_name LIKE customer.name_text 
	DEFINE l_com1_text LIKE voucher.com1_text 
	DEFINE l_total_amt LIKE voucher.total_amt 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_contra_adjust, l_valid_payment SMALLINT 
	DEFINE l_contra_amt LIKE customer.bal_amt 
	DEFINE l_arr_char_line array[4] OF CHAR(132) 
	DEFINE l_sundry_vend_flag CHAR(1) 
	DEFINE l_name_text LIKE vouchpayee.name_text 
	DEFINE l_bank_acct_code LIKE vouchpayee.bank_acct_code 
	DEFINE l_credits_exist CHAR(1) 
	DEFINE l_last_page SMALLINT
	DEFINE i, col2, col SMALLINT

	OUTPUT 
 
	ORDER external BY p_rec_tentpays.pay_meth_ind, 
	p_rec_tentpays.vend_code, 
	p_rec_tentpays.source_ind, 
	p_rec_tentpays.source_text, 
	p_rec_tentpays.withhold_tax_ind, 
	p_rec_tentpays.inv_text 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  

			PRINT COLUMN 01, " Voucher Voucher Due/Cr Voucher/Cr Payment Discount Discount Invoice/Cr Voucher/Cr" 
			PRINT COLUMN 01, " Number Date Date Amount Amount Date Amount Number Comments" 

--			UPDATE kandooreport SET * = glob_rec_kandooreport.* 
--			WHERE report_code = glob_rec_kandooreport.report_code 

			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]

			IF NOT l_last_page THEN 
				SELECT currency.* INTO l_rec_currency.* FROM currency, vendor 
				WHERE vendor.cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND currency.currency_code = vendor.currency_code 
				AND vendor.vend_code = p_rec_tentpays.vend_code 
				PRINT COLUMN 01, "Currency: ", 
				COLUMN 11, l_rec_currency.currency_code, 
				COLUMN 17, l_rec_currency.desc_text 
				IF p_rec_tentpays.pay_meth_ind = "1" THEN 
					PRINT COLUMN 01, "Payments by Cheque" 
				ELSE 
					PRINT COLUMN 01, "Payments by EFT" 
				END IF 
			ELSE 
				PRINT 
				PRINT 
			END IF 

		BEFORE GROUP OF p_rec_tentpays.pay_meth_ind 
			LET l_rr_count = 0 
			LET l_tot_ind_pay = 0 
			LET l_ind_tax = 0 
			LET l_tot_ind_contra = 0 
			LET l_last_page = false 
			SKIP TO top OF PAGE 

		BEFORE GROUP OF p_rec_tentpays.vend_code 
			SELECT * INTO l_rec_vendor.* FROM vendor 
			WHERE vend_code = p_rec_tentpays.vend_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			# Need TO determine IF vendor IS a sundry vendor.  IF so, will PRINT
			# payee details on REPORT.
			SELECT unique(1) FROM bank 
			WHERE bank_code = p_rec_tentpays.vend_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_sundry_vend_flag = false 
			ELSE 
				LET l_sundry_vend_flag = true 
			END IF 
			LET l_tot_vend_pay = 0 
			LET l_tot_vend_disc_amt = 0 
			LET l_tot_vend_tax = 0 
			LET l_tot_vend_contra = 0 
			LET l_valid_payment = true 
			NEED 4 LINES 
			PRINT 
			PRINT COLUMN 02, "Vendor: ", 
			COLUMN 12, p_rec_tentpays.vend_code, 
			COLUMN 21, l_rec_vendor.name_text 

		BEFORE GROUP OF p_rec_tentpays.source_text 
			IF p_rec_tentpays.source_ind = "8" THEN #refund voucher 
				SELECT name_text INTO l_cust_name 
				FROM customer 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND cust_code = p_rec_tentpays.source_text 
				PRINT 
				PRINT COLUMN 06, "Customer: ", 
				COLUMN 16, p_rec_tentpays.source_text, 
				COLUMN 25, l_cust_name, 
				COLUMN 79, "** Refund **" 
			END IF 

		BEFORE GROUP OF p_rec_tentpays.withhold_tax_ind 
			PRINT 

		ON EVERY ROW 
			NEED 2 LINES 
			SELECT com1_text, total_amt INTO l_com1_text, l_total_amt 
			FROM voucher 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vouch_code = p_rec_tentpays.vouch_code 
			IF l_sundry_vend_flag THEN 
				SELECT name_text, bank_acct_code 
				INTO l_name_text, l_bank_acct_code 
				FROM vouchpayee 
				WHERE vend_code = p_rec_tentpays.vend_code 
				AND vouch_code = p_rec_tentpays.vouch_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF status != NOTFOUND THEN 
					PRINT COLUMN 02, "Payee: ", 
					l_name_text, 
					COLUMN 43, "Bank Account: ", 
					l_bank_acct_code 
				END IF 
			END IF 
			PRINT COLUMN 14, p_rec_tentpays.vouch_code USING "########" , 
			COLUMN 25, p_rec_tentpays.vouch_date USING "dd/mm/yy", 
			COLUMN 34, p_rec_tentpays.due_date USING "dd/mm/yy", 
			COLUMN 43, l_total_amt USING "----,---,--&.&&", 
			COLUMN 59, p_rec_tentpays.vouch_amt USING "----,---,--&.&&", 
			COLUMN 79, p_rec_tentpays.disc_date USING "dd/mm/yy", 
			COLUMN 88, p_rec_tentpays.taken_disc_amt USING "------&.&&", 
			COLUMN 100, p_rec_tentpays.inv_text, 
			COLUMN 124, l_com1_text 

			LET l_credits_exist = "N" 
			DECLARE c_debit CURSOR FOR 
			SELECT d.* FROM voucherpays v, debithead d 
			WHERE v.cmpy_code = p_rec_tentpays.cmpy_code 
			AND v.vend_code = p_rec_tentpays.vend_code 
			AND v.vouch_code = p_rec_tentpays.vouch_code 
			AND v.pay_type_code = "DB" 
			AND d.cmpy_code = v.cmpy_code 
			AND d.vend_code = v.vend_code 
			AND d.debit_num = v.pay_num 
			FOREACH c_debit INTO l_rec_debithead.* 
				LET l_rec_debithead.apply_amt = l_rec_debithead.apply_amt * -1 
				PRINT COLUMN 27, "Credit", 
				COLUMN 34, l_rec_debithead.debit_date USING "dd/mm/yy", 
				COLUMN 45, l_rec_debithead.apply_amt USING "--,---,--&.&&", 
				COLUMN 100, l_rec_debithead.debit_num USING "<<<<<<<<", 
				COLUMN 124, l_rec_debithead.debit_text 
				LET l_credits_exist = "Y" 
			END FOREACH 

			IF l_credits_exist = "Y" THEN 
				SKIP 1 line 
			END IF 

		AFTER GROUP OF p_rec_tentpays.withhold_tax_ind 
			#
			#  Check FOR a contra balance in the AR ledger AND adjust the net
			#  payment amount accordingly, AFTER creating the balancing AR
			#  transactions.
			#  Rules FOR applying the contra amount are:
			#     0 - no contra adjustments allowed
			#     1 - adjust taxed payments only
			#     2 - adjust non-taxed payments only
			#
			INITIALIZE l_contra_amt TO NULL 
			CASE 
				WHEN (l_rec_vendor.contra_meth_ind = "1" AND 
					p_rec_tentpays.withhold_tax_ind <> "0") 
					LET l_contra_adjust = true 
				WHEN (l_rec_vendor.contra_meth_ind = "2" AND 
					p_rec_tentpays.withhold_tax_ind = "0") 
					LET l_contra_adjust = true 
				OTHERWISE 
					LET l_contra_adjust = false 
			END CASE 
			IF l_contra_adjust THEN 
				SELECT name_text, bal_amt INTO l_contra_cust_name, l_contra_amt 
				FROM customer 
				WHERE cust_code = l_rec_vendor.contra_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 
			IF l_contra_amt IS NULL THEN 
				LET l_contra_amt = 0 
			END IF 
			LET l_wtax_chq_amt = GROUP sum(p_rec_tentpays.vouch_amt) 
			NEED 5 LINES 
			IF p_rec_tentpays.withhold_tax_ind = "0" THEN 
				PRINT COLUMN 59, "---------------" 
				IF l_contra_amt <> 0 THEN 
					PRINT COLUMN 30, "Less Contra:", 
					COLUMN 59, (0 - l_contra_amt) USING "----,---,--&.&&", 
					COLUMN 79, "Contra Customer: ", 
					COLUMN 96, l_rec_vendor.contra_cust_code, 
					COLUMN 85, l_contra_cust_name 
					LET l_wtax_chq_amt = l_wtax_chq_amt - l_contra_amt 
				END IF 
				IF p_rec_tentpays.pay_meth_ind = "1" THEN 
					PRINT COLUMN 28, "Cheque Amount: "; 
				ELSE 
					PRINT COLUMN 28, " EFT Amount: "; 
				END IF 
				PRINT COLUMN 59, l_wtax_chq_amt USING "----,---,--&.&&"; 
				IF l_wtax_chq_amt < 0 THEN 
					PRINT COLUMN 79, "* No payment will be created *" 
					LET l_valid_payment = false 
				END IF 
			ELSE 
				CALL wtaxcalc(l_wtax_chq_amt, 
				p_rec_tentpays.tax_per, 
				p_rec_tentpays.withhold_tax_ind, 
				glob_rec_kandoouser.cmpy_code) 
				RETURNING l_wtax_chq_amt, l_wtax_tax_amt 
				PRINT COLUMN 59, "---------------" 
				PRINT COLUMN 27, "Taxable Amount: ", 
				COLUMN 59, GROUP sum(p_rec_tentpays.vouch_amt) 
				USING "----,---,--&.&&", 
				COLUMN 88, GROUP sum(p_rec_tentpays.taken_disc_amt) 
				USING "------&.&&" 
				PRINT COLUMN 33, "Less tax:", 
				COLUMN 59, (0 - l_wtax_tax_amt) USING "----,---,--&.&&" 
				IF l_contra_amt <> 0 THEN 
					PRINT COLUMN 30, "Less Contra:", 
					COLUMN 59, (0 - l_contra_amt) USING "----,---,--&.&&", 
					COLUMN 79, "Contra Customer: ", 
					COLUMN 96, l_rec_vendor.contra_cust_code, 
					COLUMN 105, l_contra_cust_name 
					LET l_wtax_chq_amt = l_wtax_chq_amt - l_contra_amt 
				END IF 
				IF p_rec_tentpays.pay_meth_ind = "1" THEN 
					PRINT COLUMN 28, "Cheque Amount: "; 
				ELSE 
					PRINT COLUMN 28, " EFT Amount: "; 
				END IF 
				PRINT COLUMN 59, l_wtax_chq_amt USING "----,---,--&.&&"; 
				IF l_wtax_chq_amt < 0 THEN 
					PRINT COLUMN 79, "* No payment will be created *" 
					LET l_valid_payment = false 
				END IF 
				IF l_valid_payment THEN 
					LET l_tot_vend_tax = l_tot_vend_tax + l_wtax_tax_amt 
				END IF 
			END IF 
			LET l_rr_count = l_rr_count + 1 
			IF l_valid_payment THEN 
				LET l_tot_vend_pay = l_tot_vend_pay + l_wtax_chq_amt 
				LET l_tot_vend_disc_amt = 
				l_tot_vend_disc_amt + GROUP sum(p_rec_tentpays.taken_disc_amt) 
				LET l_tot_vend_contra = l_tot_vend_contra + l_contra_amt 
			END IF 
			LET l_valid_payment = true 
			PRINT 

		AFTER GROUP OF p_rec_tentpays.vend_code 
			NEED 5 LINES 
			PRINT 
			PRINT COLUMN 14, "Total:", 
			COLUMN 22, "Current Balance: ", 
			COLUMN 39, l_rec_vendor.bal_amt USING "-<<<,<<<,<<&.&&", 
			COLUMN 49, "Payments: ", 
			COLUMN 64, l_tot_vend_pay USING "-<<<,<<<,<<&.&&", 
			COLUMN 81, "Deductions: ", 
			COLUMN 93, (l_tot_vend_tax + l_tot_vend_contra + l_tot_vend_disc_amt) 
			USING "-<<<,<<<,<<&.&&", 
			COLUMN 109, "New Bal: ", 
			COLUMN 118, (l_rec_vendor.bal_amt - l_tot_vend_pay 
			- l_tot_vend_tax - l_tot_vend_contra - l_tot_vend_disc_amt) 
			USING "-<<<,<<<,<<&.&&" 
			LET l_tot_ind_pay = l_tot_ind_pay + l_tot_vend_pay 
			LET l_ind_tax = l_ind_tax + l_tot_vend_tax 
			LET l_tot_ind_contra = l_tot_ind_contra + l_tot_vend_contra 

		AFTER GROUP OF p_rec_tentpays.pay_meth_ind 
			LET glob_tot_pay_amt = glob_tot_pay_amt + l_tot_ind_pay 
			LET glob_tot_tax_amt = glob_tot_tax_amt + l_ind_tax 
			LET glob_tot_contra_amt = glob_tot_contra_amt + l_tot_ind_contra 
			NEED 5 LINES 
			PRINT 
			PRINT 
			PRINT COLUMN 59, "===============" 
			IF p_rec_tentpays.pay_meth_ind = "1" THEN 
				PRINT COLUMN 01, " Total Payments by Cheque: "; 
			ELSE 
				PRINT COLUMN 01, " Total Payments by EFT: "; 
			END IF 
			PRINT COLUMN 30, "Count: ", l_rr_count USING "####"; 
			PRINT COLUMN 59, l_tot_ind_pay USING "----,---,--&.&&", 
			COLUMN 88, GROUP sum(p_rec_tentpays.taken_disc_amt) 
			USING "------&.&&" 

		ON LAST ROW 
			LET l_last_page = true 
			SKIP TO top OF PAGE 
			PRINT COLUMN 1, "Total Vouchers: ",count(*) using "####", 
			COLUMN 58, glob_tot_pay_amt + glob_tot_tax_amt + glob_tot_contra_amt 
			USING "-----,---,--&.&&", 
			COLUMN 88, sum(p_rec_tentpays.taken_disc_amt) USING "------&.&&" 
			IF glob_tot_tax_amt != 0 THEN 
				PRINT COLUMN 18, "Less total tax:", 
				COLUMN 58, (0 - glob_tot_tax_amt) USING "-----,---,--&.&&" 
			END IF 
			IF glob_tot_contra_amt != 0 THEN 
				PRINT COLUMN 15, "Less total contra:", 
				COLUMN 58, (0 - glob_tot_contra_amt) USING "-----,---,--&.&&" 
			END IF 
			IF (glob_tot_tax_amt != 0 OR glob_tot_contra_amt != 0) THEN 
				PRINT COLUMN 58, "----------------" 
				PRINT COLUMN 58, glob_tot_pay_amt USING "-----,---,--&.&&" 
			END IF 
			PRINT 
			PRINT 

			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	
			
			
END REPORT 
############################################################
# END REPORT P32_rpt_list(p_rpt_idx,p_rec_tentpays)
############################################################