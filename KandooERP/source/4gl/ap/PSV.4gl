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



# Verify the AP system, check all possibilities.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 

############################################################
# Module Scope Variables
############################################################
DEFINE modu_rec_voucher RECORD LIKE voucher.* 
DEFINE modu_problem SMALLINT 
DEFINE modu_rpt_wid CHAR(3) 

############################################################
# MAIN
#
#
############################################################
MAIN 
 
	#Initial UI Init
	CALL setModuleId("PSV") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	CALL fgl_settitle("Verify Accounts Payable System") 
	--LET argurlstr = get_url_str1()
	IF get_url_switch() THEN 
	--IF arg_val(1) = "Y" OR argurlstr = "Y" THEN 

		MENU " Reset A/P " 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","PSV","menu-verify_a_p-2") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "Reset" 
				#COMMAND "Reset"   " Reset Accounts Payable"
				CALL do_verify() 
				NEXT option "Print Manager" 

			ON ACTION "Print Manager" 
				#COMMAND KEY ("P",f11) "Print"  " Print OR view using RMS"
				CALL run_prog("URS","","","","") 
				NEXT option "Exit" 

			ON ACTION "Exit" 
				#COMMAND "Exit" " Exit TO Menu"
				EXIT MENU 


		END MENU 


	ELSE -------------------------------------------------------- 

		MENU " Verify A/P " 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","PSV","menu-verify_a_p-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "Verify" 				#COMMAND "Verify"   " Verify Accounts Payable"
				CALL do_verify() 

			ON ACTION "Print Manager" 				#COMMAND KEY ("P",f11) "Print"  " Print OR view using RMS"
				CALL run_prog("URS","","","","") 

			ON ACTION "CANCEL" 				#COMMAND "Exit" " Exit TO Menu"
				EXIT MENU 
		END MENU 
	END IF 
END MAIN 


############################################################
# FUNCTION do_verify()
#
#
############################################################
FUNCTION do_verify() 
	DEFINE l_rec_cheque RECORD LIKE cheque.*
	DEFINE l_rec_debithead RECORD LIKE debithead.*
	DEFINE l_rec_vendor RECORD LIKE vendor.*
	DEFINE l_sum_amt MONEY(12,2)
	DEFINE l_sum_paid MONEY(12,2) 
	DEFINE l_sum_dist MONEY(12,2) 
	DEFINE l_sum_app MONEY(12,2) 
	DEFINE l_sum_cash MONEY(12,2) 
	DEFINE l_sum_cred MONEY(12,2) 
	DEFINE l_line_info CHAR(132)
	DEFINE l_last_num INTEGER
	DEFINE l_last_vend CHAR(8)
	DEFINE l_prob_sw SMALLINT

	CALL authenticate("PSV") 
	LET modu_rpt_wid = "132" 
	LET modu_problem = 0 
	LET l_last_num = 0 

	DISPLAY "VERIFY OF ACCOUNTS PAYABLE SYSTEM TAKING PLACE" at 8,10 
	DECLARE vo_curs 
	CURSOR FOR 
	SELECT * 
	INTO modu_rec_voucher.* 
	FROM voucher 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vouch_code > l_last_num 
	ORDER BY vouch_code 

	LET l_prob_sw = 0 
	FOREACH vo_curs 
		DISPLAY "Voucher Number: " , modu_rec_voucher.vouch_code at 10,10 
		LET l_last_num = modu_rec_voucher.vouch_code 

		# check that daily log file correct
		# note that sum takes care of edit situations

		SELECT sum(tran_amt) 
		INTO l_sum_amt 
		FROM apaudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trantype_ind = "VO" 
		AND vend_code = modu_rec_voucher.vend_code 
		AND source_num = modu_rec_voucher.vouch_code 

		IF l_sum_amt IS NULL THEN 
			LET l_sum_amt = 0 
		END IF 

		IF l_sum_amt != modu_rec_voucher.total_amt 
		THEN 
			LET l_line_info = "Voucher Amount NOT equal TO daily log ", 
			modu_rec_voucher.vouch_code, " Header amt", modu_rec_voucher.total_amt, 
			" Log amt" ,l_sum_amt 
			CALL prob(l_line_info) 
			# OPEN vo_curs
		END IF 

		# check that applied amount IS correct

		SELECT sum(apply_amt) 
		INTO l_sum_amt 
		FROM voucherpays 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = modu_rec_voucher.vend_code 
		AND vouch_code = modu_rec_voucher.vouch_code 

		IF l_sum_amt IS NULL THEN 
			LET l_sum_amt = 0 
		END IF 

		IF l_sum_amt != modu_rec_voucher.paid_amt 
		THEN 
			LET l_line_info = "Voucher Paid NOT equal TO voucher payments", 
			modu_rec_voucher.vouch_code, " Voucher Paid amt", 
			modu_rec_voucher.paid_amt, " Vou Payments" ,l_sum_amt 
			CALL prob(l_line_info) 
			IF arg_val(1) = "Y" THEN 
				CALL del_pays() 
			END IF 
			# OPEN vo_curs
		END IF 

		# check that distributed amount IS correct

		SELECT sum(dist_amt) 
		INTO l_sum_amt 
		FROM voucherdist 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = modu_rec_voucher.vend_code 
		AND vouch_code = modu_rec_voucher.vouch_code 

		IF l_sum_amt IS NULL THEN 
			LET l_sum_amt = 0 
		END IF 

		IF l_sum_amt != modu_rec_voucher.dist_amt 
		THEN 
			LET l_line_info = "Voucher Dist NOT equal TO voucher distributes", modu_rec_voucher.vouch_code, " Voucher Dist amt", modu_rec_voucher.dist_amt, " Vou Distributes" ,l_sum_amt 
			CALL prob(l_line_info) 
			LET l_prob_sw = 1 
		END IF 

	END FOREACH 

	LET l_last_num = 0 
	LET l_last_vend = " " 
	# Now check the cheques

	DECLARE cred_curs 
	CURSOR FOR 
	SELECT * 
	INTO l_rec_cheque.* 
	FROM cheque 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND (cheq_code > l_last_num OR 
	(cheq_code = l_last_num AND vend_code > l_last_vend)) 
	ORDER BY cheq_code, vend_code 

	FOREACH cred_curs 
		DISPLAY "Cheque Number: " , l_rec_cheque.cheq_code at 10,10 

		LET l_last_num = l_rec_cheque.cheq_code 
		LET l_last_vend = l_rec_cheque.vend_code 

		# check that line totals = invoice total

		SELECT sum(apply_amt) 
		INTO l_sum_amt 
		FROM voucherpays 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_cheque.vend_code 
		AND pay_type_code = "CH" 
		AND pay_num = l_rec_cheque.cheq_code 

		IF l_sum_amt IS NULL THEN 
			LET l_sum_amt = 0 
		END IF 

		IF l_sum_amt != l_rec_cheque.apply_amt 
		THEN 
			LET l_line_info = "Cheque applied NOT equal TO applied ", 
			l_rec_cheque.cheq_code, " Header amt", l_rec_cheque.pay_amt, 
			" Line amt" ,l_sum_amt 
			CALL prob(l_line_info) 
			OPEN cred_curs 
		END IF 


		# check that daily log file correct
		# note that sum takes care of edit situations

		SELECT sum(tran_amt) 
		INTO l_sum_amt 
		FROM apaudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trantype_ind = "CH" 
		AND vend_code = l_rec_cheque.vend_code 
		AND source_num = l_rec_cheque.cheq_code 

		IF l_sum_amt IS NULL THEN 
			LET l_sum_amt = 0 
		END IF 

		LET l_sum_amt = 0 - l_sum_amt + 0 
		IF l_sum_amt != l_rec_cheque.pay_amt 
		THEN 
			LET l_line_info = "Check Amount NOT equal TO daily log ", 
			l_rec_cheque.cheq_code, " Header amt", l_rec_cheque.pay_amt, 
			" Log amt" ,l_sum_amt 
			CALL prob(l_line_info) 
			OPEN cred_curs 
		END IF 

	END FOREACH 

	LET l_last_num = 0 
	# Now check the debitheads

	DECLARE dm_curs 
	CURSOR FOR 
	SELECT * 
	INTO l_rec_debithead.* 
	FROM debithead 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND debit_num > l_last_num 
	ORDER BY debit_num 

	FOREACH dm_curs 
		DISPLAY "Debit Number: " , l_rec_debithead.debit_num at 10,10 

		LET l_last_num = l_rec_debithead.debit_num 
		# check that line totals = debit total

		# check that line totals = invoice total

		SELECT sum(apply_amt) 
		INTO l_sum_amt 
		FROM voucherpays 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_debithead.vend_code 
		AND pay_type_code = "DB" 
		AND pay_num = l_rec_debithead.debit_num 

		IF l_sum_amt IS NULL THEN 
			LET l_sum_amt = 0 
		END IF 

		IF l_sum_amt != l_rec_debithead.apply_amt 
		THEN 
			LET l_line_info = "Debit appl NOT equal TO vp_ applied ", 
			l_rec_debithead.debit_num, " Header amt", l_rec_debithead.total_amt, 
			" Line amt" ,l_sum_amt 
			CALL prob(l_line_info) 
			OPEN dm_curs 
		END IF 

		# check that distributed = sum distributed

		SELECT sum(dist_amt) 
		INTO l_sum_amt 
		FROM debitdist 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_debithead.vend_code 
		AND debit_code = l_rec_debithead.debit_num 

		IF l_sum_amt IS NULL THEN 
			LET l_sum_amt = 0 
		END IF 

		IF l_sum_amt != l_rec_debithead.dist_amt 
		THEN 
			LET l_line_info = "Debit dist NOT equal TO dd_ applied ", 
			l_rec_debithead.debit_num, " Header amt", l_rec_debithead.total_amt, 
			" Line amt" ,l_sum_amt 
			CALL prob(l_line_info) 
			OPEN dm_curs 
		END IF 

		# check that daily log file correct
		# note that sum takes care of edit situations

		SELECT sum(tran_amt) 
		INTO l_sum_amt 
		FROM apaudit 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trantype_ind = "DB" 
		AND vend_code = l_rec_debithead.vend_code 
		AND source_num = l_rec_debithead.debit_num 

		IF l_sum_amt IS NULL THEN 
			LET l_sum_amt = 0 
		END IF 

		LET l_sum_amt = 0 - l_sum_amt + 0 
		IF l_sum_amt != l_rec_debithead.total_amt 
		THEN 
			LET l_line_info = "Debit Amount NOT equal TO daily log ", 
			l_rec_debithead.debit_num, " Header amt", l_rec_debithead.total_amt, 
			" Log amt" ,l_sum_amt 
			CALL prob(l_line_info) 
			OPEN dm_curs 
		END IF 

	END FOREACH 

	# Now check the vendor balance IS OK

	LET l_last_vend = " " 
	DECLARE vend_curs 
	CURSOR FOR 
	SELECT * 
	INTO l_rec_vendor.* 
	FROM vendor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vend_code > l_last_vend 
	ORDER BY vend_code 

	FOREACH vend_curs 
		DISPLAY "Vendor: " , l_rec_vendor.name_text at 10,10 
		LET l_last_vend = l_rec_vendor.vend_code 

		# get the sum of the vouchers outstanding

		SELECT sum(total_amt), sum(paid_amt) 
		INTO l_sum_amt , l_sum_paid 
		FROM voucher 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND total_amt != paid_amt 
		AND vend_code = l_rec_vendor.vend_code 

		# now get the sum of the cheques outstanding

		SELECT sum(pay_amt), sum(apply_amt) 
		INTO l_sum_cred, l_sum_dist 
		FROM cheque 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_vendor.vend_code 
		AND pay_amt != apply_amt 

		# now get the sum of the debits outstanding

		SELECT sum(total_amt), sum(apply_amt) 
		INTO l_sum_cash, l_sum_app 
		FROM debithead 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = l_rec_vendor.vend_code 
		AND total_amt != apply_amt 

		IF l_sum_amt IS NULL THEN 
			LET l_sum_amt = 0 
		END IF 

		IF l_sum_paid IS NULL THEN 
			LET l_sum_paid = 0 
		END IF 

		IF l_sum_cred IS NULL THEN 
			LET l_sum_cred = 0 
		END IF 

		IF l_sum_dist IS NULL THEN 
			LET l_sum_dist = 0 
		END IF 

		IF l_sum_cash IS NULL THEN 
			LET l_sum_cash = 0 
		END IF 

		IF l_sum_app IS NULL THEN 
			LET l_sum_app = 0 
		END IF 

		LET l_sum_amt = (l_sum_amt - l_sum_paid) 
		- ((l_sum_cred - l_sum_dist) 
		+ (l_sum_cash - l_sum_app)) 
		IF l_rec_vendor.bal_amt != l_sum_amt 
		THEN 
			LET l_line_info = "Vendor bal NOT equal TO parts- run aging ", 
			l_rec_vendor.vend_code, " Vend bal", l_rec_vendor.bal_amt, " Parts amt" 
			,l_sum_amt 
			CALL prob(l_line_info) 
			OPEN vend_curs 
		END IF 

	END FOREACH 

	CLEAR screen 


	IF modu_problem = 1 
	THEN 
		FINISH REPORT PSV_rpt_list_ver 
		CALL fgl_winmessage("AP Database verified - Problems Exist","error") 
		#      DISPLAY " AP DATABASE VERIFIED - PROBLEMS EXIST" AT 16,10
		#      attribute (magenta)
		#      sleep 15
	ELSE 
		CALL fgl_winmessage("AP Database verified - No problems found","info") 
		#      DISPLAY " AP DATABASE VERIFIED - ALL OK" AT 16,10
		#      attribute (magenta)
		#      sleep 15
	END IF 

END FUNCTION 



############################################################
# FUNCTION prob(p_rpt_line1)
#
#
############################################################
FUNCTION prob(p_rpt_line1) 
	DEFINE p_rpt_line1 CHAR(132)
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]
 
	IF modu_problem = 0 THEN 
		LET l_rpt_idx = rpt_start(getmoduleid(),"PSV_rpt_list_ver","N/A", RPT_SHOW_RMS_DIALOG)
		IF l_rpt_idx = 0 THEN #User pressed CANCEL
			RETURN FALSE
		END IF	
		START REPORT PSV_rpt_list_ver TO rpt_get_report_file_with_path2(l_rpt_idx)
		WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
		TOP MARGIN = 0, 
		BOTTOM MARGIN = 0, 
		LEFT MARGIN = 0, 
		RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
		#------------------------------------------------------------
	 
		OPEN vo_curs 

		LET modu_problem = 1 
	END IF 
	OUTPUT TO REPORT PSV_rpt_list_ver(l_rpt_idx,p_rpt_line1) 
END FUNCTION 

############################################################
# REPORT PSV_rpt_list_ver(p_line_info)
#
#
############################################################
REPORT PSV_rpt_list_ver(p_rpt_idx,p_line_info) 
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
	DEFINE p_line_info CHAR(132) 
	DEFINE l_rpt_note CHAR(30) 
	DEFINE l_rpt_date DATE 
	DEFINE l_rpt_offset1 SMALLINT 
	DEFINE l_rpt_offset2 SMALLINT 
	DEFINE l_rpt_line1 CHAR(80) 
	DEFINE l_rpt_line2 CHAR(80) 

	OUTPUT 
--	left margin 0 

	FORMAT 

		PAGE HEADER 
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		ON EVERY ROW 
			PRINT COLUMN 1, p_line_info 
		ON LAST ROW 
			SKIP 1 line 
			PRINT COLUMN 20, "Total Problems: ", count(*) USING "###" 
			SKIP 1 line 
			 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 			
			
END REPORT 



############################################################
# FUNCTION del_pays()
#
# This IS called WHEN the applied amounts of the cheques OR debits do
# NOT tally with the total paid of a voucher. It zeroes the vendor paid amount,
# cheque AND debit applied amount AND it deletes the voucherpays rows FOR this
# VENDOR. You THEN have TO go through AND re-apply ALL the cheques AND debits
# FOR this VENDOR.
# Discounts on the voucher are left untouched.
# Written 12/90 by Al. FROM a spec FROM Tim. as a result of inconsistencies
# that crept in with a wee nastie around version 2.35
############################################################
FUNCTION del_pays() 
	DEFINE l_try_again CHAR(1) 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_line_info CHAR(132)

	GOTO bypass 
	LABEL recovery: 
	LET l_try_again = error_recover(l_err_message, status) 
	IF l_try_again != "Y" 
	THEN 
		CALL errorlog(l_err_message) 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	BEGIN WORK 
		WHENEVER ERROR GOTO recovery 

		LET l_err_message = "DELETE FROM voucherpays" 
		DELETE FROM voucherpays 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = modu_rec_voucher.vend_code 

		LET l_err_message = "Update cheque" 
		UPDATE cheque 
		SET apply_amt = 0 WHERE 
		cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = modu_rec_voucher.vend_code 

		LET l_err_message = "Update voucher" 
		UPDATE voucher 
		SET paid_amt = 0 WHERE 
		cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = modu_rec_voucher.vend_code 

		LET l_err_message = "Update debithead" 
		UPDATE debithead 
		SET apply_amt = 0 WHERE 
		cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = modu_rec_voucher.vend_code 
	COMMIT WORK 
	LET l_line_info = "All cheques AND debits FOR ", modu_rec_voucher.vouch_code clipped, 
	" will need re-allocating " 

	OUTPUT TO REPORT PSV_rpt_list_ver(l_line_info) 

	OPEN vo_curs 

	WHENEVER ERROR stop 

END FUNCTION 




