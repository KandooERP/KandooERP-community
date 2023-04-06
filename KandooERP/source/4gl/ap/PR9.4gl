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
# \brief module - PR9.4gl
# Purpose - Creditors snapshot as AT a given year/period.
#           Prints all vendors, even WHEN balance IS zero, but does
#           NOT PRINT zero balance vouchers.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl"
GLOBALS "../common/glob_GLOBALS_report.4gl"  
GLOBALS 
	DEFINE glob_year_num SMALLINT 
	DEFINE glob_period_num SMALLINT
END GLOBALS 

############################################################
# MAIN
#
#
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("PR9") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	CASE rpt_init_url_get_operation_method_exec_ind() #url-arg 1=menu 2=batch 3=construct 4=query
		WHEN RPT_OP_MENU #UI/MENU Mode 	

			OPEN WINDOW P181 with FORM "P181" 
			CALL windecoration_p("P181") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
		
			MENU " AP Snapshot" 
		
				BEFORE MENU 
					CALL publish_toolbar("kandoo","PR9","menu-ap_snapshot-1") 
		
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
		
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
		
				ON ACTION "Report" 				#COMMAND "Report" " SELECT criteria AND PRINT REPORT"
					CALL rpt_rmsreps_reset(NULL)
					CALL PR9_rpt_process(PR9_rpt_query())
		
				ON ACTION "Print Manager"				#COMMAND KEY ("P",f11) "Print" " Print OR view using RMS"
					CALL run_prog("URS","","","","") 
		
				ON ACTION "CANCEL" 		#COMMAND KEY(interrupt,"E")"Exit" " Exit TO menus"
					EXIT MENU 
		
			END MENU 
		
			CLOSE WINDOW P181 


		WHEN RPT_OP_BATCH #Background Process with rmsreps.report_code
			CALL PR9_rpt_process(NULL)  

		WHEN RPT_OP_CONSTRUCT #Only create query-where-part
			OPEN WINDOW P181 with FORM "P181" 
			CALL windecoration_p("P181") 
			CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
			CALL set_url_sel_text(PR9_rpt_query()) #save where clause in env 
			CLOSE WINDOW P181 
			
		WHEN RPT_OP_QUERY #Background Process with SQL WHERE ARGUMENT
			CALL PR9_rpt_process(get_url_sel_text())
	END CASE 

END MAIN 



############################################################
# FUNCTION PR9_rpt_query()
#
#
############################################################
FUNCTION PR9_rpt_query() 

	CLEAR FORM 

	INPUT 
		glob_year_num, 
		glob_period_num WITHOUT DEFAULTS
	FROM 
		year_num, 
		period_num ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PR9","inp-period-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN NULL
	ELSE
		LET glob_rec_rpt_selector.ref1_num = glob_year_num
		LET glob_rec_rpt_selector.ref2_num = glob_period_num		
		RETURN "N/A" 
	END IF 
END FUNCTION 


############################################################
# FUNCTION PR9_rpt_process(p_where_text)
#
#
############################################################
FUNCTION PR9_rpt_process(p_where_text)
	DEFINE p_where_text STRING 
	DEFINE l_rpt_idx SMALLINT  #report array index
	DEFINE l_tmp_str STRING
	DEFINE l_rec_voucher RECORD LIKE voucher.*
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.*
	DEFINE l_output_flag CHAR(1)
	DEFINE l_query_str CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag
 	DEFINE l_cnt5 SMALLINT
	
	SELECT unique 1 FROM period 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = glob_year_num 
	AND period_num = glob_period_num 
	
	IF status = NOTFOUND THEN 
		CALL fgl_winmessage("ERROR","This year AND period NOT SET up in the General Ledger","ERROR") 
		RETURN false 
	END IF 
 
	LET l_output_flag = "N" 

	#------------------------------------------------------------
	#User pressed CANCEL = p_where_text IS NULL 
	IF (p_where_text IS NULL AND (get_url_report_code() IS NULL OR get_url_report_code() = 0)) OR int_flag = TRUE THEN
		LET int_flag = FALSE 
		LET quit_flag = FALSE

		RETURN FALSE
	END IF

	LET l_rpt_idx = rpt_start(getmoduleid(),"PR9_rpt_list_snap",p_where_text, RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT PR9_rpt_list_snap TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].top_margin, 
	BOTTOM MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].bottom_margin, 
	LEFT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].left_margin, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	--LET p_where_text = glob_arr_rec_rpt_rmsreps[l_rpt_idx].sel_text
	#------------------------------------------------------------
	#Case specific rems_reps works...
	LET glob_year_num  = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref1_num
	LET glob_period_num  = glob_arr_rec_rpt_rmsreps[l_rpt_idx].ref2_num	

	LET l_tmp_str = glob_year_num USING "####","Period ", glob_period_num USING "###"
	CALL rpt_set_header_footer_line_2_append(l_rpt_idx,NULL, l_tmp_str)
		
	#------------------------------------------------------------


	LET l_query_str = 
	"SELECT * FROM vendor, outer voucher ", 
	"WHERE voucher.cmpy_code = '", glob_rec_kandoouser.cmpy_code CLIPPED , "' ", 
	" AND (year_num < ", trim(glob_year_num), 
	" OR (year_num = ", trim(glob_year_num), 
	" AND period_num <= ", trim(glob_period_num), " ))", 
	" AND vendor.cmpy_code = '", glob_rec_kandoouser.cmpy_code CLIPPED, "' ", 
	" AND vendor.vend_code = voucher.vend_code ", 
	" ORDER BY voucher.vend_code,", 
	" voucher.vouch_code" 

	PREPARE ccc FROM l_query_str 

	DECLARE c_1 CURSOR FOR ccc 

	FOREACH c_1 INTO glob_rec_vendor.*, l_rec_voucher.* 
		IF l_rec_voucher.vouch_code IS NOT NULL THEN 
			LET l_output_flag = "Y" 
			MESSAGE "Vendor:", trim(l_rec_voucher.vend_code), " Voucher: ", trim(l_rec_voucher.vouch_code) 
			LET l_rec_voucher.paid_amt = 0 
			LET l_rec_voucher.taken_disc_amt = 0 

			{accumulate all the POSTED PAYMENTS up TO this date}
			DECLARE c_2 CURSOR FOR 
			SELECT sum(voucherpays.apply_amt), 
			sum(voucherpays.disc_amt) 
			FROM voucherpays, cheque 
			WHERE voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND voucherpays.vend_code = l_rec_voucher.vend_code 
			AND voucherpays.vouch_code = l_rec_voucher.vouch_code 
			AND voucherpays.pay_type_code = "CH" 
			AND cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cheque.vend_code = l_rec_voucher.vend_code 
			AND cheque.cheq_code = voucherpays.pay_num 
			AND cheque.pay_meth_ind = voucherpays.pay_meth_ind 
			AND (cheque.year_num < glob_year_num 
			OR (cheque.year_num = glob_year_num 
			AND cheque.period_num <= glob_period_num)) 
			OPEN c_2 
			FETCH c_2 INTO l_rec_voucherpays.apply_amt, l_rec_voucherpays.disc_amt 
			IF l_rec_voucherpays.apply_amt IS NOT NULL AND l_rec_voucherpays.disc_amt IS NOT NULL THEN 
				LET l_rec_voucher.paid_amt = l_rec_voucher.paid_amt + l_rec_voucherpays.apply_amt 
				LET l_rec_voucher.taken_disc_amt = l_rec_voucher.taken_disc_amt + l_rec_voucherpays.disc_amt 
			END IF 
			{Accumulate all POSTED CREDITS up TO this period}
			DECLARE c_3 CURSOR FOR 
			SELECT sum(voucherpays.apply_amt), 
			sum(voucherpays.disc_amt) 
			FROM voucherpays, debithead 
			WHERE voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND voucherpays.vend_code = l_rec_voucher.vend_code 
			AND voucherpays.vouch_code = l_rec_voucher.vouch_code 
			AND voucherpays.pay_type_code = "DB" 
			AND debithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND debithead.vend_code = l_rec_voucher.vend_code 
			AND debithead.debit_num = voucherpays.pay_num 
			AND (debithead.year_num < glob_year_num 
			OR (debithead.year_num = glob_year_num 
			AND debithead.period_num <= glob_period_num)) 
			OPEN c_3 
			FETCH c_3 INTO l_rec_voucherpays.apply_amt,	l_rec_voucherpays.disc_amt 
			IF l_rec_voucherpays.apply_amt IS NOT NULL AND l_rec_voucherpays.disc_amt IS NOT NULL THEN 
				LET l_rec_voucher.paid_amt = l_rec_voucher.paid_amt + l_rec_voucherpays.apply_amt 
				LET l_rec_voucher.taken_disc_amt = l_rec_voucher.taken_disc_amt + l_rec_voucherpays.disc_amt 
			END IF 
			CLOSE c_3 
			
		ELSE
		 
			SELECT count(*) INTO l_cnt5 FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_vendor.vend_code 
			AND (cheque.year_num < glob_year_num 
			OR (cheque.year_num = glob_year_num 
			AND cheque.period_num <= glob_period_num)) 
			AND cheque.apply_amt < cheque.pay_amt 
			IF l_cnt5 > 0 THEN 
				LET l_output_flag = "Y" 
			ELSE 
				SELECT count(*) INTO l_cnt5 FROM debithead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = glob_rec_vendor.vend_code 
				AND (debithead.year_num < glob_year_num 
				OR (debithead.year_num = glob_year_num 
				AND debithead.period_num <= glob_period_num)) 
				AND debithead.apply_amt < debithead.total_amt 
				IF l_cnt5 > 0 THEN 
					LET l_output_flag = "Y" 
				END IF 
			END IF 
		END IF 
		IF l_output_flag = "Y" THEN 
			LET l_output_flag = "N"

			#---------------------------------------------------------
			OUTPUT TO REPORT PR9_rpt_list_snap(l_rpt_idx,
			glob_rec_vendor.*, 
			l_rec_voucher.*, 
			l_rec_voucherpays.*)   
			IF NOT rpt_int_flag_handler2("Vendor:",glob_rec_vendor.vend_code, l_rec_voucher.vouch_code,l_rpt_idx) THEN
				EXIT FOREACH 
			END IF 
			#---------------------------------------------------------

		END IF 

	END FOREACH 

	#------------------------------------------------------------
	FINISH REPORT PR9_rpt_list_snap
	CALL rpt_finish("PR9_rpt_list_snap")
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
# REPORT PR9_rpt_list_snap(p_rpt_idx,p_rec_vendor, p_rec_voucher, p_rec_voucherpays)
#
#
############################################################
REPORT PR9_rpt_list_snap(p_rpt_idx,p_rec_vendor,p_rec_voucher,p_rec_voucherpays) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_rec_vendor RECORD LIKE vendor.* 
	DEFINE p_rec_voucher RECORD LIKE voucher.* 
	DEFINE p_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.*
	DEFINE l_rec_cheque RECORD LIKE cheque.*
	DEFINE l_1_vend_bal_amt DECIMAL(14,2) 
	DEFINE l_2_vend_bal_amt DECIMAL(14,2)
	DEFINE l_3_vend_bal_amt DECIMAL(14,2)
	DEFINE l_bal_amt DECIMAL(14,2)
	DEFINE l_vend_local_bal_amt DECIMAL(14,2) 
	DEFINE l_tot_vend_local_bal_amt DECIMAL(14,2)
	DEFINE l_first_ind SMALLINT

	OUTPUT 
 
	FORMAT 
		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			--PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			--PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line2_text
			 			
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 

			IF pageno = 1 THEN 
				LET l_3_vend_bal_amt = 0 
				LET l_tot_vend_local_bal_amt = 0 
			END IF 
			
		BEFORE GROUP OF p_rec_vendor.vend_code 
			LET l_2_vend_bal_amt = 0 
			LET l_vend_local_bal_amt = 0 
			PRINT "Vendor: ", p_rec_vendor.vend_code, 
			" ", p_rec_vendor.name_text, 
			"Currency :", p_rec_vendor.currency_code 
			IF p_rec_voucher.vouch_code IS NOT NULL THEN 
				PRINT "Voucher", 
				COLUMN 11, "Date", 
				COLUMN 23, "Voucher Amt", 
				COLUMN 42, "Disc. Amt", 
				COLUMN 58, "Paid Amt", 
				COLUMN 75, "Balance", 
				COLUMN 90, "Balance in Base" 
			END IF 

		ON EVERY ROW 
			IF p_rec_voucher.vouch_code IS NOT NULL THEN 
				LET l_1_vend_bal_amt = p_rec_voucher.total_amt - 
				(p_rec_voucher.paid_amt + p_rec_voucher.taken_disc_amt) 
				IF l_1_vend_bal_amt IS NULL THEN 
					LET l_1_vend_bal_amt = 0 
				END IF 
				LET l_2_vend_bal_amt = l_2_vend_bal_amt + l_1_vend_bal_amt 
				IF l_1_vend_bal_amt <> 0 THEN 
					LET l_bal_amt = l_1_vend_bal_amt / p_rec_voucher.conv_qty 
					LET l_vend_local_bal_amt = l_vend_local_bal_amt + l_bal_amt 
					PRINT p_rec_voucher.vouch_code USING "#######", 
					COLUMN 10, p_rec_voucher.vouch_date USING "dd/mm/yy", 
					COLUMN 21, p_rec_voucher.total_amt USING "----------.--", 
					COLUMN 38, p_rec_voucher.taken_disc_amt USING "----------.--", 
					COLUMN 53, p_rec_voucher.paid_amt USING "----------.--", 
					COLUMN 69, l_1_vend_bal_amt USING "----------.--", 
					COLUMN 90, l_bal_amt USING "----------.--" 
				END IF 
			END IF 

		AFTER GROUP OF p_rec_vendor.vend_code 
			DECLARE c_4 CURSOR FOR 
			SELECT * FROM cheque 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_vendor.vend_code 
			AND (cheque.year_num < glob_year_num 
			OR (cheque.year_num = glob_year_num 
			AND cheque.period_num <= glob_period_num)) 
			AND apply_amt < pay_amt 
			LET l_first_ind = true 
			
			FOREACH c_4 INTO l_rec_cheque.* 
				IF l_first_ind THEN 
					LET l_first_ind = false 
					PRINT "Unapplied Cheques " 
					PRINT "Cheque", 
					COLUMN 11, "Date", 
					COLUMN 24, "Paid Amt", 
					COLUMN 39, "Applied Amt" 
				END IF 
				LET l_1_vend_bal_amt = l_rec_cheque.pay_amt - l_rec_cheque.apply_amt 
				IF l_1_vend_bal_amt IS NULL THEN 
					LET l_1_vend_bal_amt = 0 
				END IF 
				LET l_bal_amt = l_1_vend_bal_amt / l_rec_cheque.conv_qty 
				LET l_vend_local_bal_amt = l_vend_local_bal_amt - l_bal_amt 
				PRINT l_rec_cheque.cheq_code USING "#########", 
				COLUMN 11, l_rec_cheque.cheq_date USING "dd/mm/yy", 
				COLUMN 21, l_rec_cheque.pay_amt USING "----------.--", 
				COLUMN 38, l_rec_cheque.apply_amt USING "----------.--", 
				COLUMN 69, l_1_vend_bal_amt USING "----------.--", 
				COLUMN 90, l_bal_amt USING "----------.--" 
				LET l_2_vend_bal_amt = l_2_vend_bal_amt - l_1_vend_bal_amt 
			END FOREACH 
			
			# Now get the un un-applied DEBITS posted
			# before the nominated period
			DECLARE c_5 CURSOR FOR 
			SELECT * FROM debithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = p_rec_vendor.vend_code 
			AND (debithead.year_num < glob_year_num 
			OR (debithead.year_num = glob_year_num 
			AND debithead.period_num <= glob_period_num)) 
			AND apply_amt < total_amt 
			LET l_first_ind = true 
			FOREACH c_5 INTO l_rec_debithead.* 
				IF l_first_ind THEN 
					LET l_first_ind = false 
					PRINT "Unapplied Debits " 
					PRINT "Debit", 
					COLUMN 11, "Date", 
					COLUMN 24, "Debit Amt", 
					COLUMN 39, "Applied Amt" 
				END IF 
				LET l_1_vend_bal_amt = l_rec_debithead.total_amt - l_rec_debithead.apply_amt 
				IF l_1_vend_bal_amt IS NULL THEN 
					LET l_1_vend_bal_amt = 0 
				END IF 
				LET l_bal_amt = l_1_vend_bal_amt / l_rec_debithead.conv_qty 
				LET l_vend_local_bal_amt = l_vend_local_bal_amt - l_bal_amt 
				PRINT l_rec_debithead.total_amt USING "#######", 
				COLUMN 11, l_rec_debithead.debit_date USING "dd/mm/yy", 
				COLUMN 21, l_rec_debithead. total_amt USING "----------.--", 
				COLUMN 38, l_rec_debithead. apply_amt USING "----------.--", 
				COLUMN 69, l_1_vend_bal_amt USING "----------.--", 
				COLUMN 90, l_bal_amt USING "----------.--" 
				LET l_2_vend_bal_amt = l_2_vend_bal_amt - l_1_vend_bal_amt 
			END FOREACH
			 
			# now get the payments applied TO later invoices
			DECLARE t_4 CURSOR FOR 
			SELECT cheque.cheq_code, 
			cheque.cheq_date, 
			cheque.pay_amt, 
			cheque.conv_qty, 
			sum(voucherpays.apply_amt) 
			FROM cheque, voucherpays, voucher 
			WHERE cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cheque.vend_code = p_rec_vendor.vend_code 
			AND (cheque.year_num < glob_year_num 
			OR (cheque.year_num = glob_year_num 
			AND cheque.period_num <= glob_period_num)) 
			AND voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND voucherpays.vend_code = p_rec_vendor.vend_code 
			AND voucherpays.pay_type_code = "CH" 
			AND voucherpays.pay_num = cheque.cheq_code 
			AND voucherpays.pay_meth_ind = cheque.pay_meth_ind 
			AND voucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND voucher.vend_code = p_rec_vendor.vend_code 
			AND voucher.vouch_code = voucherpays.vouch_code 
			AND (voucher.year_num > glob_year_num 
			OR (voucher.year_num = glob_year_num 
			AND voucher.period_num > glob_period_num)) 
			GROUP BY 1,2,3,4 
			LET l_first_ind = true 

			FOREACH t_4 INTO l_rec_cheque.cheq_code, l_rec_cheque.cheq_date, 
				l_rec_cheque.pay_amt, l_rec_cheque.conv_qty, 
				l_1_vend_bal_amt 
				IF l_first_ind THEN 
					LET l_first_ind = false 
					PRINT "Forward Applied Cheques " 
					PRINT "Cheque", 
					COLUMN 11, "Date", 
					COLUMN 24, "Paid Amt", 
					COLUMN 39, "Future Applied Amt" 
				END IF 
				LET l_rec_cheque.apply_amt = l_rec_cheque.pay_amt - l_1_vend_bal_amt 
				LET l_bal_amt = l_1_vend_bal_amt / l_rec_cheque.conv_qty 
				LET l_vend_local_bal_amt = l_vend_local_bal_amt - l_bal_amt 
				PRINT l_rec_cheque.cheq_code USING "#########", 
				COLUMN 11, l_rec_cheque.cheq_date USING "dd/mm/yy", 
				COLUMN 21, l_rec_cheque.pay_amt USING "----------.--", 
				COLUMN 38, l_1_vend_bal_amt USING "----------.--", 
				COLUMN 69, l_1_vend_bal_amt USING "----------.--", 
				COLUMN 90, l_bal_amt USING "----------.--" 
				LET l_2_vend_bal_amt = l_2_vend_bal_amt - l_1_vend_bal_amt 
			END FOREACH 
			DECLARE t_d CURSOR FOR 
			SELECT debithead.debit_num, 
			debithead.debit_date, 
			debithead.total_amt, 
			debithead.conv_qty, 
			sum(voucherpays.apply_amt) 
			FROM voucherpays, debithead, voucher 
			WHERE debithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND debithead.vend_code = p_rec_vendor.vend_code 
			AND (debithead.year_num < glob_year_num 
			OR (debithead.year_num = glob_year_num 
			AND debithead.period_num <= glob_period_num)) 
			AND voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND voucherpays.vend_code = p_rec_vendor.vend_code 
			AND voucherpays.pay_type_code = "DB" 
			AND voucherpays.pay_num = debithead.debit_num 
			AND voucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND voucher.vend_code = p_rec_vendor.vend_code 
			AND voucher.vouch_code = voucherpays.vouch_code 
			AND (voucher.year_num > glob_year_num 
			OR (voucher.year_num = glob_year_num 
			AND voucher.period_num > glob_period_num)) 
			GROUP BY 1,2,3,4 
			LET l_first_ind = true 
			
			FOREACH t_d INTO l_rec_debithead.debit_num, l_rec_debithead.debit_date, 
				l_rec_debithead.total_amt, l_rec_debithead.conv_qty, 
				l_1_vend_bal_amt 
				IF l_first_ind THEN 
					LET l_first_ind = false 
					PRINT "Forward Applied Debits " 
					PRINT "Debit", 
					COLUMN 11, "Date", 
					COLUMN 24, "Debit Amt", 
					COLUMN 39, "Future Applied Amt" 
				END IF 
				LET l_rec_debithead.apply_amt = l_rec_debithead.total_amt - l_1_vend_bal_amt 
				LET l_bal_amt = l_1_vend_bal_amt / l_rec_debithead.conv_qty 
				LET l_vend_local_bal_amt = l_vend_local_bal_amt - l_bal_amt 
				PRINT l_rec_debithead.debit_num USING "#######", 
				COLUMN 11, l_rec_debithead.debit_date USING "dd/mm/yy", 
				COLUMN 21, l_rec_debithead.total_amt USING "----------.--", 
				COLUMN 38, l_1_vend_bal_amt USING "----------.--", 
				COLUMN 69, l_1_vend_bal_amt USING "----------.--", 
				COLUMN 90, l_bal_amt USING "----------.--" 
				LET l_2_vend_bal_amt = l_2_vend_bal_amt - l_1_vend_bal_amt 
			END FOREACH 
			PRINT COLUMN 69, "=============", 
			COLUMN 90, "=============" 
			PRINT "Vendor Total", 
			COLUMN 68, l_2_vend_bal_amt USING "-----------.--", 
			COLUMN 89, l_vend_local_bal_amt USING "-----------.--" 
			LET l_tot_vend_local_bal_amt = l_tot_vend_local_bal_amt 
			+ l_vend_local_bal_amt 
			LET l_3_vend_bal_amt = l_3_vend_bal_amt + l_2_vend_bal_amt 
			SKIP 1 line 

		ON LAST ROW 
			NEED 10 LINES 
			SKIP 2 LINES 
			PRINT "AP Ledger Balance (vendor currency)", 
			COLUMN 68, l_3_vend_bal_amt USING "-----------.--" 
			PRINT "AP Ledger Balance (local currency)", 
			COLUMN 89, l_tot_vend_local_bal_amt USING "-----------.--"
			 
			SKIP 2 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
		
			PRINT COLUMN 50, "***** END OF REPORT PR9 *****" 
END REPORT