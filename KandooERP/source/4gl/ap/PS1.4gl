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

	Source code beautified by beautify.pl on 2020-01-03 13:41:48	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module PS1  Accounts Payable Aging Process
#

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 

#Module Scope Variables
DEFINE modu_agedate LIKE apparms.last_aging_date
DEFINE modu_days_late INTEGER 
DEFINE modu_overdue_amt DECIMAL(16,2) 
DEFINE modu_where_text CHAR(2048) 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_last_age_date LIKE apparms.last_aging_date
	DEFINE l_runner CHAR(30)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arg1 STRING
	
	#Initial UI Init
	CALL setModuleId("PS1") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	SELECT last_aging_date INTO l_last_age_date FROM apparms 
	WHERE parm_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("P", 5016, "") 
		#5016 "  Accounts Payable Parameters NOT SET up, see PZP"
		SLEEP 3 
		EXIT PROGRAM 
	END IF 
	LET modu_agedate = today 

	OPEN WINDOW p100 with FORM "P100" 
	CALL windecoration_p("P100") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	MENU " Vendor Aging" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","PS1","menu-vendor_aging-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Report" 
			#COMMAND "Run" " Run vendor aging"
			IF modu_where_text IS NULL THEN 
				LET l_msgresp=kandoomsg("P",9171,"") 
				# WARNING: No Selection Criteria entered
				#          Enter Selection Criteria (Y/N) ?
				IF l_msgresp='Y' THEN 
					IF enter_params() THEN 
						NEXT option "Run" 
					END IF 
				ELSE 
					CALL vend_ageing() 
					NEXT option "Exit" 
				END IF 
			ELSE 
				LET l_msgresp=kandoomsg("U",8015,"") 
				## Begin Aging Process. (Y/N)?
				IF l_msgresp="Y" THEN 
					CALL vend_ageing() 
					NEXT option "Exit" 
				END IF 
			END IF 

		ON ACTION "Change" 
			#COMMAND "Change" " Change aging parameters"
			IF enter_params() THEN 
				NEXT option "Run" 
			END IF 

		ON ACTION "CANCEL" 
			#COMMAND KEY(interrupt,"E")"Exit" " EXIT PROGRAM"
			EXIT MENU 



	END MENU 

	UPDATE apparms 
	SET last_aging_date = modu_agedate 
	WHERE parm_code = "1" 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_msgresp = kandoomsg("P", 8016, "") 
	#8016 Run Vendor Credit Aging Report (Y/N) ?
	IF l_msgresp = "Y" THEN 
		# was: pass "A" TO PA6 so the MESSAGE about running PS1 IS NOT displayed
		# NOW: using url switch on/off
		LET l_arg1 = "SWITCH=ON"
		CALL run_prog("PA6",l_arg1,"","","")  #switch=on -> so the MESSAGE about running PS1 IS NOT displayed
		RUN l_runner 
	END IF 
	CLOSE WINDOW p100 
END MAIN 


############################################################
# FUNCTION enter_params()
#
#
############################################################
FUNCTION enter_params() 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 " Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT BY NAME modu_where_text ON vendor.vend_code, 
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
			CALL publish_toolbar("kandoo","PS1","construct-vendor-1") 

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
	OPEN WINDOW p508 at 10,25 with FORM "P508" 
	CALL windecoration_p("P508") 

	LET modu_agedate = today 

	INPUT modu_agedate WITHOUT DEFAULTS FROM agedate 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PS1","inp-agedate-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF modu_agedate IS NULL THEN 
					LET l_msgresp = kandoomsg("P",9513,"") 
					#9513 Aging Date must be entered
					LET modu_agedate = today 
					NEXT FIELD agedate 
				END IF 
			END IF 


	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW p508 
		RETURN false 
	END IF 
	CLOSE WINDOW p508 

	RETURN true 
END FUNCTION 



############################################################
# FUNCTION vend_ageing()
#
#
############################################################
FUNCTION vend_ageing() 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_purchhead RECORD LIKE purchhead.* 
	DEFINE l_rec_poaudit 
	RECORD 
		order_total DECIMAL(16,2), 
		receipt_total DECIMAL(16,2), 
		voucher_total DECIMAL(16,2), 
		tax_total DECIMAL(16,2) 
	END RECORD 
	DEFINE l_total_days_late INTEGER
	DEFINE l_total_vouchers INTEGER
	DEFINE l_year_num LIKE voucher.year_num
	DEFINE l_period_num LIKE voucher.period_num
	DEFINE l_voucher_amt DECIMAL(16,2) 
	DEFINE l_debit_amt DECIMAL(16,2) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_err_message CHAR(40)	

	IF get_kandoooption_feature_state('AP','VY') = 1 THEN 
		CALL db_period_what_period(glob_rec_kandoouser.cmpy_code,modu_agedate) 
		RETURNING l_year_num, l_period_num 
		IF status = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("P",5016,"") 
			#5016 " Accounts Payable Parameters NOT SET up, see PZP"
		END IF 
	END IF 
	LET l_query_text = "SELECT * FROM vendor ", 
	"WHERE vendor.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" " 
	IF modu_where_text IS NOT NULL THEN 
		LET l_query_text = l_query_text clipped, " AND ",modu_where_text clipped 
	END IF 
	PREPARE s_vendor FROM l_query_text 
	DECLARE c_vendor CURSOR with HOLD FOR s_vendor 

	LET l_msgresp = kandoomsg("P", 1005, "") 
	#1005 Updating database please wait
	FOREACH c_vendor INTO glob_rec_vendor.* 
		DISPLAY glob_rec_vendor.vend_code, " ", glob_rec_vendor.name_text at 2,3 

		LET l_err_message = "Updating vendor ", glob_rec_vendor.vend_code clipped 
		GOTO bypass 
		LABEL recovery: 
		LET l_msgresp = error_recover(l_err_message, status) 
		IF l_msgresp != "Y" THEN 
			EXIT PROGRAM 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 

		BEGIN WORK 

			DECLARE c2_vendor CURSOR FOR 
			SELECT * FROM vendor 
			WHERE vend_code = glob_rec_vendor.vend_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			FOR UPDATE 
			OPEN c2_vendor 
			FETCH c2_vendor INTO glob_rec_vendor.* 
			LET l_total_vouchers = 0 
			LET l_total_days_late = 0 
			LET l_voucher_amt = 0 
			LET l_debit_amt = 0 
			LET glob_rec_vendor.bal_amt = 0 

			DECLARE c_purchhead CURSOR FOR 
			SELECT * FROM purchhead 
			WHERE vend_code = glob_rec_vendor.vend_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			LET glob_rec_vendor.onorder_amt = 0 

			FOREACH c_purchhead INTO l_rec_purchhead.* 
				CALL po_head_info(glob_rec_kandoouser.cmpy_code,l_rec_purchhead.order_num) 
				RETURNING l_rec_poaudit.order_total, 
				l_rec_poaudit.receipt_total, 
				l_rec_poaudit.voucher_total, 
				l_rec_poaudit.tax_total 
				IF l_rec_poaudit.voucher_total = l_rec_poaudit.order_total THEN 
					CONTINUE FOREACH 
				ELSE 
					LET glob_rec_vendor.onorder_amt = glob_rec_vendor.onorder_amt 
					+ l_rec_poaudit.order_total 
					- l_rec_poaudit.voucher_total 
				END IF 
			END FOREACH 

			LET glob_rec_vendor.curr_amt = 0 
			LET glob_rec_vendor.over1_amt = 0 
			LET glob_rec_vendor.over30_amt = 0 
			LET glob_rec_vendor.over60_amt = 0 
			LET glob_rec_vendor.over90_amt = 0 
			LET glob_rec_vendor.ytd_amt = 0 

			DECLARE c_voucher CURSOR FOR 

			SELECT * INTO l_rec_voucher.* FROM voucher 
			WHERE voucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND voucher.vend_code = glob_rec_vendor.vend_code 
			AND voucher.total_amt <> paid_amt 
			AND voucher.post_flag <> "V" 

			FOREACH c_voucher 
				LET l_total_vouchers = l_total_vouchers + 1 
				LET modu_days_late = modu_agedate - l_rec_voucher.due_date 
				LET l_total_days_late = l_total_days_late + modu_days_late 
				LET modu_overdue_amt = l_rec_voucher.total_amt - l_rec_voucher.paid_amt 
				CALL age() 
			END FOREACH 

			DECLARE c_debithead CURSOR FOR 
			SELECT * INTO l_rec_debithead.* FROM debithead 
			WHERE debithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND debithead.vend_code = glob_rec_vendor.vend_code 
			AND debithead.total_amt <> debithead.apply_amt 
			AND debithead.post_flag <> "V" 
			FOREACH c_debithead 
				LET modu_days_late = modu_agedate - l_rec_debithead.debit_date 
				LET modu_overdue_amt=0-(l_rec_debithead.total_amt - l_rec_debithead.apply_amt) 
				CALL age() 
			END FOREACH 


			DECLARE c_cheque CURSOR FOR 
			SELECT * INTO l_rec_cheque.* FROM cheque 
			WHERE cheque.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND cheque.vend_code = glob_rec_vendor.vend_code 
			AND cheque.pay_amt <> cheque.apply_amt 
			AND cheque.post_flag <> "V" 

			FOREACH c_cheque 
				LET modu_days_late = modu_agedate - l_rec_cheque.cheq_date 
				LET modu_overdue_amt = 0 - (l_rec_cheque.pay_amt - l_rec_cheque.apply_amt) 
				CALL age() 
			END FOREACH 

			IF l_total_days_late > 32676 THEN 
				LET l_total_days_late = 32000 
			END IF 
			IF l_total_vouchers > 0 THEN 
				LET glob_rec_vendor.avg_day_paid_num = l_total_days_late/l_total_vouchers 
			END IF 

			CASE 
				WHEN get_kandoooption_feature_state('AP','VY') = 1 
					SELECT sum(voucher.total_amt) INTO l_voucher_amt FROM voucher 
					WHERE voucher.year_num = l_year_num 
					AND voucher.vend_code = glob_rec_vendor.vend_code 
					AND voucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF l_voucher_amt IS NULL THEN 
						LET l_voucher_amt = 0 
					END IF 
					SELECT sum(debithead.total_amt) INTO l_debit_amt FROM debithead 
					WHERE debithead.year_num = l_year_num 
					AND debithead.vend_code = glob_rec_vendor.vend_code 
					AND debithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF l_debit_amt IS NULL THEN 
						LET l_debit_amt = 0 
					END IF 
					LET glob_rec_vendor.ytd_amt = l_voucher_amt - l_debit_amt 

				WHEN get_kandoooption_feature_state('AP','VY') = 2 
					SELECT sum(voucher.total_amt) INTO l_voucher_amt FROM voucher 
					WHERE year(voucher.vouch_date) = year(modu_agedate) 
					AND voucher.vend_code = glob_rec_vendor.vend_code 
					AND voucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF l_voucher_amt IS NULL THEN 
						LET l_voucher_amt = 0 
					END IF 
					SELECT sum(debithead.total_amt) INTO l_debit_amt FROM debithead 
					WHERE year(debithead.debit_date) = year(modu_agedate) 
					AND debithead.vend_code = glob_rec_vendor.vend_code 
					AND debithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF l_debit_amt IS NULL THEN 
						LET l_debit_amt = 0 
					END IF 
					LET glob_rec_vendor.ytd_amt = l_voucher_amt - l_debit_amt 

			END CASE 

			IF glob_rec_vendor.ytd_amt IS NULL THEN 
				LET glob_rec_vendor.ytd_amt = 0 
			END IF 

			UPDATE vendor 
			SET bal_amt = glob_rec_vendor.bal_amt, 
			curr_amt = glob_rec_vendor.curr_amt, 
			over1_amt = glob_rec_vendor.over1_amt, 
			over30_amt = glob_rec_vendor.over30_amt, 
			over60_amt = glob_rec_vendor.over60_amt, 
			over90_amt = glob_rec_vendor.over90_amt, 
			onorder_amt = glob_rec_vendor.onorder_amt, 
			avg_day_paid_num = glob_rec_vendor.avg_day_paid_num, 
			ytd_amt = glob_rec_vendor.ytd_amt 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_vendor.vend_code 

		COMMIT WORK 

	END FOREACH 

	WHENEVER ERROR stop 

END FUNCTION 



############################################################
# FUNCTION age()
#
#
############################################################
FUNCTION age() 
	LET glob_rec_vendor.bal_amt = glob_rec_vendor.bal_amt + modu_overdue_amt 
	CASE 
		WHEN (modu_days_late > 90) 
			LET glob_rec_vendor.over90_amt = glob_rec_vendor.over90_amt + modu_overdue_amt 
		WHEN (modu_days_late > 60) 
			LET glob_rec_vendor.over60_amt = glob_rec_vendor.over60_amt + modu_overdue_amt 
		WHEN (modu_days_late > 30) 
			LET glob_rec_vendor.over30_amt = glob_rec_vendor.over30_amt + modu_overdue_amt 
		WHEN (modu_days_late > 0) 
			LET glob_rec_vendor.over1_amt = glob_rec_vendor.over1_amt + modu_overdue_amt 
		OTHERWISE 
			LET glob_rec_vendor.curr_amt = glob_rec_vendor.curr_amt + modu_overdue_amt 
	END CASE 
END FUNCTION 


