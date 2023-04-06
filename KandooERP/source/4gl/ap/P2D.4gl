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
	Source code beautified by beautify.pl on 2020-01-03 13:41:22	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P2_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_voucher RECORD LIKE voucher.* 
	DEFINE glob_rec_voucher2 RECORD LIKE voucher.* 
	DEFINE glob_arr_rec_voucher array[200] 
	OF RECORD 
		vouch_code LIKE voucher.vouch_code, 
		vend_code LIKE voucher.vend_code, 
		vouch_date LIKE voucher.vouch_date, 
		year_num LIKE voucher.year_num, 
		period_num LIKE voucher.period_num, 
		total_amt LIKE voucher.total_amt, 
		dist_amt LIKE voucher.dist_amt, 
		post_flag LIKE voucher.post_flag 
	END RECORD 
	DEFINE glob_counter INTEGER 
	DEFINE glob_idx SMALLINT 
	DEFINE glob_num_selected SMALLINT 
END GLOBALS 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module P2D looks FOR all unpaid vouchers that match the selection
#             criteria THEN allows the user TO transfer them TO another
#             vendor
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P2D") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW wp129 with FORM "P129" 
	CALL winDecoration_p("P129") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE select_vouchers() 
		IF glob_num_selected != 0 THEN 
			CALL select_xfer() 
		END IF 
	END WHILE 
	CLOSE WINDOW wp129 
END MAIN 


FUNCTION select_vouchers() 
	DEFINE l_where_text CHAR(2048)
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("P",1001,"") 
	#1001 Enter Selection Criteria - ESC TO Continue "
	CONSTRUCT BY NAME l_where_text ON vouch_code, 
	vend_code, 
	vouch_date, 
	year_num, 
	period_num, 
	total_amt, 
	dist_amt, 
	post_flag 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P2D","construct-voucher-1") 

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
	LET l_query_text = 
	"SELECT * FROM voucher", 
	" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
	" AND ", l_where_text clipped, 
	" AND paid_amt = 0", 
	" AND approved_code = 'Y'", 
	" AND (source_ind IS NULL OR source_ind != '4')", 
	" ORDER BY vouch_code " 
	PREPARE vouch_query FROM l_query_text 
	DECLARE c_vouch CURSOR FOR vouch_query 

	LET glob_idx = 0 
	FOREACH c_vouch INTO glob_rec_voucher.* 
		LET glob_idx = glob_idx + 1 
		CALL fill_array_line() 
		IF glob_idx = 200 THEN 
			LET l_msgresp = kandoomsg("P", 9042, glob_idx) 
			#9042 First 200 entries selected "
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count (glob_idx) 
	IF glob_idx = 0 THEN 
		LET l_msgresp = kandoomsg("P", 9044, "") 
		#9044 No entries satisfied selection criteria
	END IF 
	LET glob_num_selected = glob_idx 
	RETURN true 
END FUNCTION 


############################################################
# FUNCTION select_xfer()
#
#
############################################################
FUNCTION select_xfer() 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_scrn SMALLINT

	LET l_msgresp = kandoomsg("P",1061,"") 
	#1061 RETURN on line TO transfer voucher"
	OPTIONS INSERT KEY f36 
	OPTIONS DELETE KEY f36 
	INPUT ARRAY glob_arr_rec_voucher WITHOUT DEFAULTS FROM sr_voucher.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P2D","inp-arr-voucher-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET glob_idx = arr_curr() 
			LET l_scrn = scr_line() 
			IF glob_idx > glob_num_selected THEN 
				LET l_msgresp = kandoomsg("P",9001,"") 
				#9001 " There are no more rows in this direction "
			ELSE 
				DISPLAY glob_arr_rec_voucher[glob_idx].* TO sr_voucher[l_scrn].* 

			END IF 

		ON ACTION "EDIT" 
			SELECT * INTO glob_rec_voucher.* FROM voucher 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_arr_rec_voucher[glob_idx].vend_code 
			AND vouch_code = glob_arr_rec_voucher[glob_idx].vouch_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P",9122,"") 
				#9122 " Voucher NOT found"
				NEXT FIELD vouch_code 
			END IF 
			IF glob_rec_voucher.paid_amt != 0 THEN 
				LET l_msgresp = kandoomsg("P",9538,"") 
				#9538 " Voucher has been paid OR transferred already"
				NEXT FIELD vouch_code 
			END IF 
			SELECT count(*) 
			INTO glob_counter 
			FROM voucherdist 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_voucher.vend_code 
			AND vouch_code = glob_rec_voucher.vouch_code 
			AND type_ind = "P" 
			IF glob_counter > 0 THEN 
				LET l_msgresp = kandoomsg("P",9539,"") 
				#9539 " Voucher distributed TO Purchsae Order - remove..."
				NEXT FIELD vouch_code 
			END IF 
			CALL transfer_vouch() 
			CALL fill_array_line() 
			NEXT FIELD vouch_code 



		BEFORE FIELD vend_code 
			#
			# Vouchers cannot be transferred IF any payment has been made OR IF any
			# of the distributions are automatic distributions FROM Purchase Orders
			#
			SELECT * INTO glob_rec_voucher.* FROM voucher 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_arr_rec_voucher[glob_idx].vend_code 
			AND vouch_code = glob_arr_rec_voucher[glob_idx].vouch_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P",9122,"") 
				#9122 " Voucher NOT found"
				NEXT FIELD vouch_code 
			END IF 
			IF glob_rec_voucher.paid_amt != 0 THEN 
				LET l_msgresp = kandoomsg("P",9538,"") 
				#9538 " Voucher has been paid OR transferred already"
				NEXT FIELD vouch_code 
			END IF 
			SELECT count(*) 
			INTO glob_counter 
			FROM voucherdist 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_voucher.vend_code 
			AND vouch_code = glob_rec_voucher.vouch_code 
			AND type_ind = "P" 
			IF glob_counter > 0 THEN 
				LET l_msgresp = kandoomsg("P",9539,"") 
				#9539 " Voucher distributed TO Purchsae Order - remove..."
				NEXT FIELD vouch_code 
			END IF 
			CALL transfer_vouch() 
			CALL fill_array_line() 
			NEXT FIELD vouch_code 

		AFTER ROW 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 
			IF glob_idx <= glob_num_selected THEN 
				DISPLAY glob_arr_rec_voucher[glob_idx].* TO sr_voucher[l_scrn].* 

			END IF 

	END INPUT 
	OPTIONS INSERT KEY f1 
	OPTIONS DELETE KEY f2 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 


############################################################
# FUNCTION transfer_vouch()
#
#
############################################################
FUNCTION transfer_vouch() 
	DEFINE l_vendor_code LIKE vendor.vend_code 
	DEFINE l_vendor_name LIKE vendor.name_text 
	DEFINE l_save_due DATE 
	DEFINE l_save_disc DATE
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_period RECORD LIKE period.* 
	DEFINE l_rec_holdpay RECORD LIKE holdpay.* 
	DEFINE l_debit_num LIKE debithead.debit_num 
	DEFINE l_xfer_text CHAR(80) 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW p177 with FORM "P177" 
	CALL winDecoration_p("P177") 


	LET l_msgresp = kandoomsg("I",1302,"") 
	#1001 Enter Transfer Details - ESC TO Continue "
	SELECT vend_code, 
	name_text 
	INTO l_vendor_code, 
	l_vendor_name 
	FROM vendor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vend_code = glob_arr_rec_voucher[glob_idx].vend_code 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("P",9501,"") 
		#9501 " Vendor NOT found"
		SLEEP 3 
		CLOSE WINDOW p177 
		RETURN 
	END IF 

	SELECT * 
	INTO l_rec_tax.* 
	FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = glob_rec_voucher.tax_code 
	IF status = NOTFOUND THEN 
		LET l_rec_tax.desc_text = " " 
	END IF 

	SELECT * 
	INTO l_rec_term.* 
	FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = glob_rec_voucher.term_code 
	IF status = NOTFOUND THEN 
		LET l_rec_term.disc_day_num = 0 
	END IF 

	SELECT * 
	INTO l_rec_holdpay.* 
	FROM holdpay 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = glob_rec_voucher.hold_code 
	IF status = NOTFOUND THEN 
		LET l_rec_holdpay.hold_text = " " 
	END IF 

	DISPLAY BY NAME glob_rec_voucher.vouch_code, 
	glob_rec_voucher.total_amt, 
	glob_rec_voucher.currency_code, 
	glob_rec_voucher.dist_amt, 
	glob_rec_voucher.inv_text, 
	glob_rec_voucher.tax_code, 
	l_rec_tax.desc_text, 
	glob_rec_voucher.vouch_date, 
	glob_rec_voucher.disc_date, 
	glob_rec_voucher.term_code, 
	glob_rec_voucher.poss_disc_amt, 
	glob_rec_voucher.hold_code, 
	l_rec_holdpay.hold_text, 
	glob_rec_voucher.due_date, 
	glob_rec_voucher.year_num, 
	glob_rec_voucher.period_num 

	DISPLAY l_vendor_code,l_vendor_name TO vendor_code,vendor_name 

	LET glob_rec_voucher2.* = glob_rec_voucher.* 
	LET glob_rec_voucher2.vend_code = NULL 
	LET glob_rec_voucher2.post_flag = "N" 
	LET glob_rec_voucher2.post_date = NULL 
	LET glob_rec_voucher2.jour_num = NULL 
	LET glob_rec_voucher2.entry_code = glob_rec_kandoouser.sign_on_code 
	LET glob_rec_voucher2.entry_date = today 
	DISPLAY BY NAME glob_rec_voucher2.entry_code, 
	glob_rec_voucher2.entry_date 

	INPUT BY NAME glob_rec_voucher2.vend_code, 
	glob_rec_voucher2.vouch_date, 
	glob_rec_voucher2.term_code, 
	glob_rec_voucher2.hold_code, 
	glob_rec_voucher2.due_date, 
	glob_rec_voucher2.disc_date, 
	glob_rec_voucher2.poss_disc_amt, 
	glob_rec_voucher2.year_num, 
	glob_rec_voucher2.period_num, 
	glob_rec_voucher2.com1_text, 
	glob_rec_voucher2.com2_text 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P2D","inp-voucher-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (vend_code) 
			LET glob_rec_voucher2.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,glob_rec_voucher2.vend_code) 
			DISPLAY BY NAME glob_rec_voucher2.vend_code 

			NEXT FIELD vend_code 

		ON ACTION "LOOKUP" infield (term_code) 
			LET glob_rec_voucher2.term_code = show_term(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME glob_rec_voucher2.term_code 

			NEXT FIELD term_code 

		ON ACTION "LOOKUP" infield (hold_code) 
			LET glob_rec_voucher2.hold_code = show_hold(glob_rec_kandoouser.cmpy_code) 
			DISPLAY BY NAME glob_rec_voucher2.hold_code 

			NEXT FIELD hold_code 



		AFTER FIELD vend_code 
			SELECT * 
			INTO l_rec_vendor.* 
			FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_voucher2.vend_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P",9043,"") 
				#9043 " Vendor NOT found - try window"
				NEXT FIELD vend_code 
			END IF 

			DISPLAY BY NAME l_rec_vendor.name_text 

			IF l_rec_vendor.currency_code != glob_rec_voucher2.currency_code THEN 
				LET l_msgresp = kandoomsg("P",9540,"") 
				#9540 " Must transfer voucher TO vendor with same currency code."
				NEXT FIELD vend_code 
			END IF 
			IF l_rec_vendor.vend_code = glob_rec_voucher.vend_code THEN 
				LET l_msgresp = kandoomsg("P",9541,"") 
				#9541 " Cannot transfer voucher TO same vendor.
				NEXT FIELD vend_code 
			END IF 

			SELECT count(*) 
			INTO glob_counter 
			FROM vendorinvs 
			WHERE vendorinvs.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vendorinvs.vend_code = glob_rec_voucher2.vend_code 
			AND vendorinvs.inv_text = glob_rec_voucher2.inv_text 
			IF glob_counter != 0 THEN 
				LET l_msgresp = kandoomsg("P",9023,"") 
				#9023 " Vendor invoice number already exists.
				NEXT FIELD vend_code 
			END IF 

		AFTER FIELD vouch_date 
			IF glob_rec_voucher2.vouch_date IS NULL THEN 
				LET glob_rec_voucher2.vouch_date = today 
			END IF 
			CALL db_period_what_period(glob_rec_kandoouser.cmpy_code, 
			glob_rec_voucher2.vouch_date) 
			RETURNING glob_rec_voucher2.year_num, 
			glob_rec_voucher2.period_num 
			CALL get_due_and_discount_date(l_rec_term.*, 
			glob_rec_voucher2.vouch_date) 
			RETURNING glob_rec_voucher2.due_date, 
			glob_rec_voucher2.disc_date 
			IF l_rec_term.disc_day_num > 0 THEN 
				LET glob_rec_voucher2.poss_disc_amt = glob_rec_voucher2.total_amt * 
				l_rec_term.disc_per / 100 
				DISPLAY glob_rec_voucher2.poss_disc_amt TO poss_disc_amt 

			END IF 

			DISPLAY BY NAME glob_rec_voucher2.period_num, 
			glob_rec_voucher2.vouch_date, 
			glob_rec_voucher2.year_num, 
			glob_rec_voucher2.due_date, 
			glob_rec_voucher2.disc_date 


		AFTER FIELD term_code 
			SELECT * 
			INTO l_rec_term.* 
			FROM term 
			WHERE term.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND term.term_code = glob_rec_voucher2.term_code 
			IF (status = NOTFOUND) THEN 
				LET l_msgresp = kandoomsg("P",9025,"") 
				#9025 " Payment terms code NOT found; Try window"
				NEXT FIELD term_code 
			ELSE 
				CALL get_due_and_discount_date(l_rec_term.*, 
				glob_rec_voucher2.vouch_date) 
				RETURNING glob_rec_voucher2.due_date, 
				glob_rec_voucher2.disc_date 
				IF l_rec_term.disc_day_num > 0 THEN 
					LET glob_rec_voucher2.poss_disc_amt = glob_rec_voucher2.total_amt * 
					l_rec_term.disc_per / 100 
					DISPLAY glob_rec_voucher2.poss_disc_amt TO poss_disc_amt 

				END IF 
				DISPLAY BY NAME glob_rec_voucher2.due_date, 
				glob_rec_voucher2.disc_date 

			END IF 

		AFTER FIELD hold_code 
			SELECT * 
			INTO l_rec_holdpay.* 
			FROM holdpay 
			WHERE holdpay.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND holdpay.hold_code = glob_rec_voucher2.hold_code 
			IF (status = NOTFOUND) THEN 
				LET l_msgresp = kandoomsg("P",9026,"") 
				#9026 " Hold payment code does NOT exist; Try window"
				NEXT FIELD hold_code 
			ELSE 
				DISPLAY l_rec_holdpay.hold_text TO holdpay.hold_text 

			END IF 

		BEFORE FIELD due_date 
			LET l_save_due = glob_rec_voucher2.due_date 

		AFTER FIELD due_date 
			IF glob_rec_voucher2.due_date IS NULL THEN 
				LET glob_rec_voucher2.due_date = l_save_due 
			END IF 

			CALL check_date_range(glob_rec_voucher2.due_date) 

		BEFORE FIELD disc_date 
			LET l_save_disc = glob_rec_voucher2.disc_date 

		AFTER FIELD disc_date 
			IF glob_rec_voucher2.disc_date IS NULL THEN 
				LET glob_rec_voucher2.disc_date = l_save_disc 
			END IF 

			CALL check_date_range(glob_rec_voucher2.disc_date) 

		AFTER FIELD period_num 
			SELECT * 
			INTO l_rec_period.* 
			FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = glob_rec_voucher2.year_num 
			AND period_num = glob_rec_voucher2.period_num 
			AND ap_flag = "Y" 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P",9024,"") 
				#9024 " Accounting period IS closed OR NOT SET up "
				NEXT FIELD year_num 
			END IF 


		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			SELECT * 
			INTO l_rec_term.* 
			FROM term 
			WHERE term.term_code = glob_rec_voucher2.term_code 
			AND term.cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF (status = NOTFOUND) THEN 
				LET l_msgresp = kandoomsg("P",9025,"") 
				#9025 " Payment terms code NOT found; Try window"
				NEXT FIELD term_code 
			END IF 

			SELECT * 
			INTO l_rec_holdpay.* 
			FROM holdpay 
			WHERE holdpay.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND holdpay.hold_code = glob_rec_voucher2.hold_code 
			IF (status = NOTFOUND) THEN 
				LET l_msgresp = kandoomsg("P",9026,"") 
				#9026 " Hold payment code does NOT exist; Try window"
				NEXT FIELD hold_code 
			END IF 

			SELECT * 
			INTO l_rec_period.* 
			FROM period 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = glob_rec_voucher2.year_num 
			AND period_num = glob_rec_voucher2.period_num 
			AND ap_flag = "Y" 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P",9024,"") 
				#9024 " Accounting period IS closed OR NOT SET up "
				NEXT FIELD year_num 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		CLOSE WINDOW p177 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 
	END IF 

	LET l_msgresp = kandoomsg("U",1005,"") 
	# 1005 Updating database please wait
	CALL create_xfers() 
	RETURNING l_debit_num 

	IF l_debit_num < 0 THEN 
		LET l_xfer_text = " Transfer unsuccessful - refer error MESSAGE" 
	ELSE 
		LET l_xfer_text = " Transferred TO Voucher ", 
		glob_rec_voucher2.vouch_code USING "<<<<<<<<" clipped, 
		" , Debit entry ", l_debit_num USING "<<<<<<<<", 
		" created " 
	END IF 
	#DISPLAY l_xfer_text AT 1,1
	MESSAGE l_xfer_text 
	CALL donePrompt(NULL,NULL,"ACCEPT") 

	LET int_flag = false 
	LET quit_flag = false 
	CLOSE WINDOW p177 
	RETURN 
END FUNCTION 


############################################################
# FUNCTION fill_array_line()
#
#
############################################################
FUNCTION fill_array_line() 
	LET glob_arr_rec_voucher[glob_idx].vouch_code = glob_rec_voucher.vouch_code 
	LET glob_arr_rec_voucher[glob_idx].vend_code = glob_rec_voucher.vend_code 
	LET glob_arr_rec_voucher[glob_idx].vouch_date = glob_rec_voucher.vouch_date 
	LET glob_arr_rec_voucher[glob_idx].year_num = glob_rec_voucher.year_num 
	LET glob_arr_rec_voucher[glob_idx].period_num = glob_rec_voucher.period_num 
	LET glob_arr_rec_voucher[glob_idx].total_amt = glob_rec_voucher.total_amt 
	LET glob_arr_rec_voucher[glob_idx].dist_amt = glob_rec_voucher.dist_amt 
	LET glob_arr_rec_voucher[glob_idx].post_flag = glob_rec_voucher.post_flag 
END FUNCTION 


############################################################
# FUNCTION check_date_range(date_entered)
#
#
############################################################
FUNCTION check_date_range(p_date_entered) 
	DEFINE p_date_entered DATE 
	DEFINE l_strmessage STRING 

	IF p_date_entered > (today + 366) OR p_date_entered < (today - 366) THEN 

		LET l_strmessage = "WARNING: Date entered ", #huho 
		p_date_entered USING "dd/mm/yyyy", 
		" out of range" 
		ERROR l_strmessage 
		CALL fgl_winmessage("Warning - Date Range",l_strMessage,"info") 


	END IF 
END FUNCTION 

############################################################
# FUNCTION create_xfers()
#
#
############################################################
FUNCTION create_xfers() 
	DEFINE l_rec_voucher1 RECORD LIKE voucher.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_vendorinvs RECORD LIKE vendorinvs.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_debithead2 RECORD LIKE debithead.* 
	DEFINE l_rec_debitdist RECORD LIKE debitdist.* 
	DEFINE l_rec_voucherdist RECORD LIKE voucherdist.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_jobledger RECORD LIKE jobledger.* 
	DEFINE l_seq_num LIKE activity.seq_num 
	DEFINE l_trans_amt_tot LIKE jobledger.trans_amt 
	DEFINE l_trans_qty_tot LIKE jobledger.trans_qty 
	DEFINE l_charge_amt_tot LIKE jobledger.charge_amt 
	DEFINE l_err_message CHAR(80) 
	DEFINE l_try_again CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 

	# Create a debit FOR the old Vendor, a voucher FOR the new Vendor
	# AND reverse out any jobledger distributions AND re-enter FOR new
	# voucher

	GOTO bypass 
	LABEL recovery: 
	LET l_try_again = error_recover(l_err_message, status) 
	IF l_try_again != "Y" THEN 
		EXIT PROGRAM 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 

		INITIALIZE l_rec_debithead.* TO NULL 

		# Retrieve next voucher/debit numbers FROM parameters AND UPDATE

		LET l_err_message = "P2D - AP parameters UPDATE" 
		DECLARE ap_curs CURSOR FOR 
		SELECT * INTO glob_rec_apparms.* FROM apparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND parm_code = "1" 
		FOR UPDATE 
		FOREACH ap_curs 
			IF glob_rec_apparms.next_vouch_num IS NULL 
			OR glob_rec_apparms.next_deb_num IS NULL THEN 
				LET l_msgresp = kandoomsg("P",5016,"") 
				#5016 Accounts Payable Parameters NOT SET up ...
				ROLLBACK WORK 
				EXIT PROGRAM 
			END IF 
			LET glob_rec_voucher2.vouch_code = glob_rec_apparms.next_vouch_num 
			LET glob_rec_apparms.next_vouch_num = glob_rec_apparms.next_vouch_num + 1 
			LET l_rec_debithead.debit_num = glob_rec_apparms.next_deb_num 
			LET glob_rec_apparms.next_deb_num = glob_rec_apparms.next_deb_num + 1 
			UPDATE apparms 
			SET next_vouch_num = glob_rec_apparms.next_vouch_num, 
			next_deb_num = glob_rec_apparms.next_deb_num 
			WHERE CURRENT OF ap_curs 
		END FOREACH 

		# Fetch AND lock the old voucher record.  Check that the amount
		# hasn't changed AND that the voucher hasn't been paid.
		INITIALIZE l_rec_voucher1.* TO NULL 
		DECLARE c1_voucher CURSOR FOR 
		SELECT * 
		FROM voucher 
		WHERE vouch_code = glob_rec_voucher.vouch_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		OPEN c1_voucher 
		FETCH c1_voucher INTO l_rec_voucher1.* 
		IF status = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("P",9122,"") 
			#9122 " Voucher NOT found"
			ROLLBACK WORK 
			RETURN -1 
		END IF 
		IF l_rec_voucher1.paid_amt <> 0 OR 
		l_rec_voucher1.total_amt <> glob_rec_voucher.total_amt OR 
		l_rec_voucher1.dist_amt <> glob_rec_voucher.dist_amt THEN 
			LET l_msgresp = kandoomsg("P",9542,"") 
			#9542 Voucher has been edited - cannot proceed with transfer
			ROLLBACK WORK 
			RETURN -1 
		END IF 
		# Create the vendorinvs, apaudit AND voucher entries FOR the new
		# voucher (held in glob_rec_voucher2) AND UPDATE the new Vendor's balance
		# accordingly

		IF glob_rec_voucher.inv_text IS NOT NULL THEN 
			SELECT * INTO l_rec_vendorinvs.* FROM vendorinvs 
			WHERE vendorinvs.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vendorinvs.vend_code = glob_rec_voucher2.vend_code 
			AND vendorinvs.inv_text = glob_rec_voucher2.inv_text 
			IF (status != NOTFOUND) THEN 
				LET l_msgresp = kandoomsg("P",9023,"") 
				#9023 " Vendor invoice number already exists.
				ROLLBACK WORK 
				RETURN -1 
			END IF 

			LET l_err_message = "P2D - Vendor invoice INSERT" 
			INSERT INTO vendorinvs VALUES (glob_rec_kandoouser.cmpy_code, 
			glob_rec_voucher2.vend_code, 
			glob_rec_voucher2.inv_text, 
			glob_rec_voucher2.vouch_code, 
			glob_rec_voucher2.entry_date) 
		END IF 
		LET l_err_message = "P2D - Vendor main UPDATE" 
		DECLARE curr_amts CURSOR FOR 
		SELECT * INTO l_rec_vendor.* FROM vendor 
		WHERE vendor.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vendor.vend_code = glob_rec_voucher2.vend_code 
		FOR UPDATE 
		FOREACH curr_amts 
			LET l_rec_vendor.bal_amt = 
			l_rec_vendor.bal_amt + glob_rec_voucher2.total_amt 
			LET l_rec_vendor.curr_amt = 
			l_rec_vendor.curr_amt + glob_rec_voucher2.total_amt 
			IF l_rec_vendor.bal_amt > l_rec_vendor.highest_bal_amt THEN 
				LET l_rec_vendor.highest_bal_amt = l_rec_vendor.bal_amt 
			END IF 
			IF glob_rec_voucher2.vouch_date > l_rec_vendor.last_vouc_date 
			OR l_rec_vendor.last_vouc_date IS NULL THEN 
				LET l_rec_vendor.last_vouc_date = glob_rec_voucher2.vouch_date 
			END IF 
			LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 
			UPDATE vendor 
			SET bal_amt = l_rec_vendor.bal_amt, 
			curr_amt = l_rec_vendor.curr_amt, 
			highest_bal_amt = l_rec_vendor.highest_bal_amt, 
			last_vouc_date = l_rec_vendor.last_vouc_date, 
			next_seq_num = l_rec_vendor.next_seq_num 
			WHERE CURRENT OF curr_amts 
		END FOREACH 

		LET l_rec_apaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_apaudit.tran_date = glob_rec_voucher2.vouch_date 
		LET l_rec_apaudit.vend_code = glob_rec_voucher2.vend_code 
		LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
		LET l_rec_apaudit.trantype_ind = "VO" 
		LET l_rec_apaudit.year_num = glob_rec_voucher2.year_num 
		LET l_rec_apaudit.period_num = glob_rec_voucher2.period_num 
		LET l_rec_apaudit.source_num = glob_rec_voucher2.vouch_code 
		LET l_rec_apaudit.tran_text = "Enter Voucher" 
		LET l_rec_apaudit.tran_amt = glob_rec_voucher2.total_amt 
		LET l_rec_apaudit.entry_code = glob_rec_voucher2.entry_code 
		LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
		LET l_rec_apaudit.currency_code = glob_rec_voucher2.currency_code 
		LET l_rec_apaudit.conv_qty = glob_rec_voucher2.conv_qty 
		LET l_rec_apaudit.entry_date = today 
		LET l_err_message = "P2D - Vendor daily log INSERT" 
		INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
		LET glob_rec_voucher2.pay_seq_num = 0 
		SELECT withhold_tax_ind INTO glob_rec_voucher2.withhold_tax_ind FROM vendortype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = l_rec_vendor.type_code 
		IF status = NOTFOUND THEN 
			LET glob_rec_voucher.withhold_tax_ind = "0" 
		END IF 
		LET l_err_message = "P2D - Voucher header INSERT" 
		IF glob_rec_apparms.vouch_approve_flag = "Y" THEN 
			LET glob_rec_voucher2.approved_code = 'N' 
		ELSE 
			LET glob_rec_voucher2.approved_code = 'Y' 
		END IF 
		LET glob_rec_voucher2.approved_by_code = NULL 
		LET glob_rec_voucher2.approved_date = NULL 
		INSERT INTO voucher VALUES (glob_rec_voucher2.*) 

		# Create the apaudit AND debithead entries with the same amount as
		# the old voucher (held in glob_rec_voucher) AND UPDATE the old Vendor's
		# balance accordingly.  Note that the debit IS distributed as per the
		# old voucher AND fully applied AND discounts/exchange variances
		# do NOT apply. Date AND period are as per new voucher.

		LET l_rec_debithead.cmpy_code = glob_rec_voucher.cmpy_code 
		LET l_rec_debithead.vend_code = glob_rec_voucher.vend_code 
		LET l_rec_debithead.debit_text = glob_rec_voucher2.vouch_code 
		LET l_rec_debithead.debit_date = glob_rec_voucher2.vouch_date 
		LET l_rec_debithead.year_num = glob_rec_voucher2.year_num 
		LET l_rec_debithead.period_num = glob_rec_voucher2.period_num 
		LET l_rec_debithead.entry_code = glob_rec_kandoouser.sign_on_code 
		LET l_rec_debithead.entry_date = today 
		LET l_rec_debithead.tax_code = glob_rec_voucher.tax_code 
		LET l_rec_debithead.total_amt = glob_rec_voucher.total_amt 
		LET l_rec_debithead.apply_amt = l_rec_debithead.total_amt 
		LET l_rec_debithead.disc_amt = 0 
		LET l_rec_debithead.dist_amt = glob_rec_voucher.dist_amt 
		LET l_rec_debithead.dist_qty = glob_rec_voucher.dist_qty 
		LET l_rec_debithead.currency_code = glob_rec_voucher.currency_code 
		LET l_rec_debithead.conv_qty = glob_rec_voucher.conv_qty 
		LET l_rec_debithead.post_flag = "N" 
		LET l_rec_debithead.appl_seq_num = 1 
		LET l_rec_debithead.tax_amt = 0 
		LET l_rec_debithead.goods_amt = l_rec_debithead.total_amt 
		LET l_rec_debithead.com1_text = 
		"Transfer of voucher ", 
		glob_rec_voucher.vouch_code USING "<<<<<<<<<<" clipped 

		LET l_err_message = "P2D - Vendmain debit UPDATE" 
		DECLARE c2_curr_amts CURSOR FOR 
		SELECT * INTO l_rec_vendor.* FROM vendor 
		WHERE vendor.cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vendor.vend_code = l_rec_debithead.vend_code 
		FOR UPDATE 

		FOREACH c2_curr_amts 
			LET l_rec_vendor.bal_amt = 
			l_rec_vendor.bal_amt - l_rec_debithead.total_amt 
			LET l_rec_vendor.curr_amt = 
			l_rec_vendor.curr_amt - l_rec_debithead.total_amt 
			IF l_rec_vendor.bal_amt > l_rec_vendor.highest_bal_amt THEN 
				LET l_rec_vendor.highest_bal_amt = l_rec_vendor.bal_amt 
			END IF 
			LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num + 1 

			UPDATE vendor 
			SET bal_amt = l_rec_vendor.bal_amt, 
			curr_amt = l_rec_vendor.curr_amt, 
			highest_bal_amt = l_rec_vendor.highest_bal_amt, 
			next_seq_num = l_rec_vendor.next_seq_num 
			WHERE CURRENT OF c2_curr_amts 
		END FOREACH 

		LET l_rec_apaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_apaudit.tran_date = l_rec_debithead.debit_date 
		LET l_rec_apaudit.vend_code = l_rec_debithead.vend_code 
		LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
		LET l_rec_apaudit.trantype_ind = "DB" 
		LET l_rec_apaudit.year_num = l_rec_debithead.year_num 
		LET l_rec_apaudit.period_num = l_rec_debithead.period_num 
		LET l_rec_apaudit.source_num = l_rec_debithead.debit_num 
		LET l_rec_apaudit.tran_text = "Enter Debit" 
		LET l_rec_apaudit.tran_amt = 0 - l_rec_debithead.total_amt 
		LET l_rec_apaudit.entry_code = l_rec_debithead.entry_code 
		LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
		LET l_rec_apaudit.currency_code = l_rec_debithead.currency_code 
		LET l_rec_apaudit.conv_qty = l_rec_debithead.conv_qty 
		LET l_rec_apaudit.entry_date = today 
		LET l_err_message = "P2D - Debit Apdlog INSERT" 

		INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
		LET l_err_message = "P2D - Debhead INSERT" 
		INSERT INTO debithead VALUES (l_rec_debithead.*) 

		# Apply the debit by updating the payment details in the old voucher
		# AND creating the corresponding voucherpays entry

		LET l_err_message = "P2D - Old Vouchead UPDATE" 
		UPDATE voucher 
		SET paid_amt = l_rec_debithead.total_amt, 
		pay_seq_num = glob_rec_voucher.pay_seq_num + 1, 
		taken_disc_amt = 0, 
		paid_date = l_rec_debithead.debit_date 
		WHERE cmpy_code = glob_rec_voucher.cmpy_code 
		AND vend_code = glob_rec_voucher.vend_code 
		AND vouch_code = glob_rec_voucher.vouch_code 

		LET l_rec_voucherpays.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_voucherpays.vend_code = l_rec_debithead.vend_code 
		LET l_rec_voucherpays.vouch_code = glob_rec_voucher.vouch_code 
		LET l_rec_voucherpays.seq_num = 0 
		LET l_rec_voucherpays.pay_num = l_rec_debithead.debit_num 
		LET l_rec_voucherpays.apply_num = glob_rec_voucher.pay_seq_num 
		LET l_rec_voucherpays.pay_type_code = "DB" 
		LET l_rec_voucherpays.pay_date = today 
		LET l_rec_voucherpays.apply_amt = l_rec_debithead.total_amt 
		LET l_rec_voucherpays.disc_amt = 0 
		LET l_rec_voucherpays.withhold_tax_ind = "0" 
		LET l_rec_voucherpays.tax_code = NULL 
		LET l_rec_voucherpays.tax_per = 0 
		LET l_rec_voucherpays.pay_meth_ind = NULL 
		LET l_rec_voucherpays.rev_flag = NULL 
		LET l_rec_voucherpays.pay_doc_num = 0 
		LET l_rec_voucherpays.remit_doc_num = 0 
		LET l_err_message = "P2D - Voucpay INSERT" 
		INSERT INTO voucherpays VALUES (l_rec_voucherpays.*) 

		# FOR each distribution on the old voucher, create a corresponding
		# distribution on the new voucher AND a reversed sign distribution
		# on the debit
		DECLARE c_dist CURSOR FOR 
		SELECT * INTO l_rec_voucherdist.* FROM voucherdist 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = glob_rec_voucher.vend_code 
		AND vouch_code = glob_rec_voucher.vouch_code 

		FOREACH c_dist 
			LET l_err_message = "P2D - debitdist INSERT" 
			LET l_rec_debitdist.cmpy_code = l_rec_voucherdist.cmpy_code 
			LET l_rec_debitdist.vend_code = l_rec_voucherdist.vend_code 
			LET l_rec_debitdist.debit_code = l_rec_debithead.debit_num 
			LET l_rec_debitdist.line_num = l_rec_voucherdist.line_num 
			LET l_rec_debitdist.acct_code = l_rec_voucherdist.acct_code 
			LET l_rec_debitdist.desc_text = l_rec_voucherdist.desc_text 
			LET l_rec_debitdist.dist_qty = l_rec_voucherdist.dist_qty 
			LET l_rec_debitdist.dist_amt = l_rec_voucherdist.dist_amt 
			LET l_rec_debitdist.analysis_text = l_rec_voucherdist.analysis_text 
			INSERT INTO debitdist VALUES (l_rec_debitdist.*) 
			LET l_err_message = "P2D - voucherdist INSERT" 
			LET l_rec_voucherdist.vend_code = glob_rec_voucher2.vend_code 
			LET l_rec_voucherdist.vouch_code = glob_rec_voucher2.vouch_code 
			INSERT INTO voucherdist VALUES (l_rec_voucherdist.*) 
		END FOREACH 

		# Now back out any "VO" jobledger rows FOR this voucher AND INSERT
		# new ones with the new Voucher number.  TO cater FOR previous
		# reversals, a reverse jobledger row IS inserted FOR the sum of
		# all jobledgers FOR each job/variation/activity/source_text (resource)
		# combination FOR this voucher.  No reversal IS required IF the
		# selected sum IS zero.


		DECLARE c_jobled CURSOR FOR 
		SELECT job_code, 
		var_code, 
		activity_code, 
		trans_source_text, 
		sum(trans_qty), 
		sum(trans_amt), 
		sum(charge_amt) 
		INTO l_rec_jobledger.job_code, 
		l_rec_jobledger.var_code, 
		l_rec_jobledger.activity_code, 
		l_rec_jobledger.trans_source_text, 
		l_trans_qty_tot, 
		l_trans_amt_tot, 
		l_charge_amt_tot 
		FROM jobledger 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND trans_source_num = glob_rec_voucher.vouch_code 
		AND trans_type_ind = "VO" 
		GROUP BY job_code, var_code, activity_code, trans_source_text 

		FOREACH c_jobled 
			DECLARE c_act CURSOR FOR 
			SELECT seq_num 
			FROM activity 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND job_code = l_rec_jobledger.job_code 
			AND var_code = l_rec_jobledger.var_code 
			AND activity_code = l_rec_jobledger.activity_code 
			FOR UPDATE 
			OPEN c_act 
			FETCH c_act INTO l_seq_num 
			IF status = NOTFOUND THEN 
				LET l_err_message = "Activity NOT found " 
				LET l_try_again = error_recover(l_err_message, status) 
				ROLLBACK WORK 
				EXIT PROGRAM 
			END IF 
			LET l_seq_num = l_seq_num + 1 

			IF l_trans_amt_tot IS NULL THEN 
				LET l_trans_amt_tot = 0 
			END IF 

			IF l_trans_qty_tot IS NULL THEN 
				LET l_trans_amt_tot = 0 
				LET l_trans_qty_tot = 0 
			END IF 

			IF l_charge_amt_tot IS NULL THEN 
				LET l_charge_amt_tot = 0 
			END IF 

			# First the reverse jobledger, THEN the new with new voucher code

			IF l_trans_qty_tot != 0 OR 
			l_trans_amt_tot != 0 OR 
			l_charge_amt_tot != 0 THEN 
				LET l_rec_jobledger.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_jobledger.trans_date = today 
				LET l_rec_jobledger.year_num = glob_rec_voucher.year_num 
				LET l_rec_jobledger.period_num = glob_rec_voucher.period_num 
				LET l_rec_jobledger.seq_num = l_seq_num 
				LET l_rec_jobledger.trans_type_ind = "VO" 
				LET l_rec_jobledger.trans_source_num = glob_rec_voucher.vouch_code 
				LET l_rec_jobledger.trans_amt = 0 - l_trans_amt_tot 
				LET l_rec_jobledger.trans_qty = 0 - l_trans_qty_tot 
				LET l_rec_jobledger.charge_amt = 0 - l_charge_amt_tot 
				LET l_rec_jobledger.posted_flag = "N" 
				LET l_rec_jobledger.desc_text = "Voucher transfer " 
				LET l_err_message = " Jobledger INSERT " 
				INSERT INTO jobledger VALUES (l_rec_jobledger.*) 
				LET l_seq_num = l_seq_num + 1 
				LET l_rec_jobledger.year_num = glob_rec_voucher2.year_num 
				LET l_rec_jobledger.period_num = glob_rec_voucher2.period_num 
				LET l_rec_jobledger.trans_source_num = glob_rec_voucher2.vouch_code 
				LET l_rec_jobledger.seq_num = l_seq_num 
				LET l_rec_jobledger.trans_amt = l_trans_amt_tot 
				LET l_rec_jobledger.trans_qty = l_trans_qty_tot 
				LET l_rec_jobledger.charge_amt = l_charge_amt_tot 
				LET l_err_message = " Jobledger INSERT " 
				INSERT INTO jobledger VALUES (l_rec_jobledger.*) 
				LET l_err_message = "Activity UPDATE" 
				UPDATE activity 
				SET seq_num = l_seq_num 
				WHERE CURRENT OF c_act 
			END IF 
		END FOREACH 
	COMMIT WORK 
	WHENEVER ERROR stop 

	RETURN l_rec_debithead.debit_num 
END FUNCTION 

