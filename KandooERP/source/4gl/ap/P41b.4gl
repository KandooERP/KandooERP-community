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

	Source code beautified by beautify.pl on 2020-01-03 13:41:28	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - P41b
# Purpose - cheq_appl() applies the cheques TO the outstanding vouchers
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P4_GLOBALS.4gl" 

FUNCTION cheq_appl(p_cmpy,p_cheqnum,p_bank_acct_code,p_pay_meth_ind,p_bank_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_cheqnum LIKE cheque.cheq_code
	DEFINE p_bank_acct_code LIKE cheque.bank_acct_code
	DEFINE p_pay_meth_ind LIKE cheque.pay_meth_ind
	DEFINE p_bank_code LIKE cheque.bank_code
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_voucherpays RECORD LIKE voucherpays.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_arr_cheq ARRAY[500] OF RECORD 
		vouch_code LIKE voucher.vouch_code, 
		inv_text LIKE voucher.inv_text, 
		apply_amt LIKE voucherpays.apply_amt, 
		disc_amt LIKE voucherpays.disc_amt, 
		total_amt LIKE voucher.total_amt, 
		paid_amt LIKE voucher.paid_amt 
	END RECORD 
	DEFINE l_arr_source_ind ARRAY[500] OF RECORD 
		source_ind LIKE voucher.source_ind 
	END RECORD 
	DEFINE l_arr_orig_paid_amt ARRAY[500] OF money(10,2) 
	DEFINE l_before_flag CHAR(1) 
	DEFINE l_err_continue CHAR(1)
	DEFINE l_err_message CHAR(40) 
	DEFINE l_appl_amt DECIMAL(12,2) 
	DEFINE l_discount_amt DECIMAL(12,2)
	DEFINE l_save_dis LIKE voucher.total_amt 
	DEFINE l_save_amt LIKE voucher.total_amt
	DEFINE l_save_num LIKE voucher.vouch_code 
	DEFINE l_arr_size SMALLINT 
 	DEFINE l_withhold_tax_ind LIKE cheque.withhold_tax_ind 
	DEFINE l_base_vouc_apply_amt LIKE voucherpays.apply_amt 
	DEFINE l_base_cheq_apply_amt LIKE voucherpays.apply_amt
	DEFINE l_base_vouc_disc_amt LIKE voucherpays.disc_amt 
	DEFINE l_base_cheq_disc_amt LIKE voucherpays.disc_amt
	DEFINE l_rec_exchangevar RECORD LIKE exchangevar.* 
	DEFINE l_recalc_ind LIKE cheque.source_ind
	DEFINE l_temp_source_ind LIKE cheque.source_ind #used FOR sundry payments 
	DEFINE l_temp_source_text LIKE cheque.source_text 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE i, idx, scrn, cnt SMALLINT

	SELECT * INTO l_rec_cheque.* FROM cheque 
	WHERE cheque.cmpy_code = p_cmpy 
	AND cheque.bank_acct_code = p_bank_acct_code 
	AND cheque.cheq_code = p_cheqnum 
	AND cheque.pay_meth_ind = p_pay_meth_ind 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("P",9570,p_cheqnum) 
		#9570 Cheque number XXXXX NOT found.
		SLEEP 5 
		RETURN 0 
	END IF 
	WHENEVER ERROR CONTINUE 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	WHENEVER ERROR stop 
	OPEN WINDOW p138 with FORM "P138" 
	CALL windecoration_p("P138") 

	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = l_rec_cheque.vend_code 
	IF l_rec_cheque.apply_amt = l_rec_cheque.pay_amt THEN 
		LET l_msgresp = kandoomsg("P",5020,"") 
		#5020 Cheque has been fully applied.
	END IF 
	DISPLAY BY NAME l_rec_vendor.currency_code 
	attribute(green) 
	DISPLAY BY NAME l_rec_cheque.vend_code, 
	l_rec_vendor.name_text, 
	l_rec_cheque.cheq_code, 
	l_rec_cheque.pay_amt, 
	l_rec_cheque.apply_amt, 
	l_rec_cheque.net_pay_amt, 
	l_rec_cheque.cheq_date 

	IF l_rec_cheque.source_ind = "S" 
	AND l_rec_cheque.source_text IS NOT NULL THEN 
		LET l_query_text = "SELECT * FROM voucher ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND vend_code = '",l_rec_cheque.vend_code,"' ", 
		"AND total_amt <> paid_amt ", 
		"AND (hold_code = 'NO' OR hold_code IS NULL) ", 
		"AND approved_code = 'Y' ", 
		"AND withhold_tax_ind = '",l_rec_cheque.withhold_tax_ind,"' ", 
		"AND vouch_code = '",l_rec_cheque.source_text,"'" 
	ELSE 
		LET l_query_text = "SELECT * FROM voucher ", 
		"WHERE cmpy_code = '",p_cmpy,"' ", 
		"AND vend_code = '",l_rec_cheque.vend_code,"' ", 
		"AND total_amt <> paid_amt ", 
		"AND (hold_code = 'NO' OR hold_code IS NULL) ", 
		"AND approved_code = 'Y' ", 
		"AND withhold_tax_ind = '",l_rec_cheque.withhold_tax_ind,"' ", 
		"ORDER BY vouch_code" 
	END IF 
	PREPARE s1_voucher FROM l_query_text 
	DECLARE c1_voucher CURSOR FOR s1_voucher 
	LET idx = 0 
	FOREACH c1_voucher INTO l_rec_voucher.* 
		IF idx = 0 THEN 
			CASE get_kandoooption_feature_state("AP","PT") 
				WHEN '1' 
					LET l_recalc_ind = 'N' 
				WHEN '2' 
					LET l_recalc_ind = 'Y' 
				WHEN '3' 
					LET l_recalc_ind = kandoomsg("P",1503,"") 
					#P1503 Override invoice discount settings (Y/N)
			END CASE 
		END IF 
		LET idx = idx + 1 
		LET l_arr_cheq[idx].vouch_code = l_rec_voucher.vouch_code 
		LET l_arr_cheq[idx].inv_text = l_rec_voucher.inv_text 
		LET l_arr_cheq[idx].apply_amt = 0 
		LET l_arr_cheq[idx].disc_amt = 0 
		IF l_rec_cheque.post_flag != "Y" THEN 
			IF l_recalc_ind = 'Y' THEN 
				LET l_arr_cheq[idx].disc_amt = l_rec_voucher.goods_amt * 
				( show_disc( p_cmpy, 
				l_rec_voucher.term_code, 
				l_rec_cheque.cheq_date, 
				l_rec_voucher.vouch_date ) 
				/ 100 ) 
			ELSE 
				IF l_rec_cheque.cheq_date <= l_rec_voucher.disc_date THEN 
					LET l_arr_cheq[idx].disc_amt = l_rec_voucher.poss_disc_amt 
				END IF 
			END IF 
		END IF 
		LET l_arr_cheq[idx].total_amt = l_rec_voucher.total_amt 
		LET l_arr_cheq[idx].paid_amt = l_rec_voucher.paid_amt 
		LET l_arr_orig_paid_amt[idx] = l_rec_voucher.paid_amt 
		LET l_arr_source_ind[idx].source_ind = l_rec_voucher.source_ind 
		IF idx = 500 THEN 
			LET l_msgresp = kandoomsg("P",9006,idx) 
			#9006 First 500 vouchers selected.
			EXIT FOREACH 
		END IF 
	END FOREACH 
	CALL set_count(idx) 
	IF idx = 0 THEN 
		LET l_msgresp = kandoomsg("P", 9044, "") 
		#9044 No entries satisfied selection criteria
		SLEEP 2 
		CLOSE WINDOW p138 
		RETURN 0 
	END IF 
	LET l_msgresp = kandoomsg("P",1080,"") 
	#1080 TAB TO apply; OK TO continue.
	#OPTIONS INSERT KEY f36, 
	#DELETE KEY f36 
	INPUT ARRAY l_arr_cheq WITHOUT DEFAULTS FROM sr_cheq.* attribute(UNBUFFERED, auto append = false, append ROW = false, DELETE ROW = false, INSERT ROW = false)

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P41B","inp-arr-cheque-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF l_arr_cheq[idx].apply_amt IS NULL THEN 
				LET l_arr_cheq[idx].apply_amt = 0 
			END IF 
			IF l_arr_cheq[idx].disc_amt IS NULL THEN 
				LET l_arr_cheq[idx].disc_amt = 0 
			END IF 
			LET l_before_flag = "Y" 
			LET l_save_amt = l_arr_cheq[idx].apply_amt 
			LET l_save_dis = l_arr_cheq[idx].disc_amt 
			LET l_save_num = l_arr_cheq[idx].vouch_code 
		AFTER ROW 
			IF fgl_lastkey() = fgl_keyval("nextpage") THEN 
				IF l_arr_cheq[idx+8].vouch_code IS NULL 
				OR l_arr_cheq[idx+8].vouch_code = 0 THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					#9001 No more rows in this direction
					NEXT FIELD vouch_code 
				END IF 
			END IF 
			IF ((fgl_lastkey() = fgl_keyval("down")) 
			AND (l_arr_cheq[idx+1].vouch_code IS NULL 
			OR l_arr_cheq[idx+1].vouch_code = 0)) THEN 
				LET l_msgresp = kandoomsg("U",9001,"") 
				#9001 No more Rows in direction
				NEXT FIELD vouch_code 
			END IF 
		AFTER FIELD vouch_code 
			LET l_arr_cheq[idx].vouch_code = l_save_num 
			DISPLAY l_arr_cheq[idx].* 
			TO sr_cheq[scrn].* 

			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() < arr_count() THEN 
				IF l_arr_cheq[idx+1].vouch_code IS NULL THEN 
					LET l_msgresp=kandoomsg("U",9001,"") 
					#9001 No more rows in the direction you are going
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("left") 
			OR fgl_lastkey() = fgl_keyval("tab") 
			OR fgl_lastkey() = fgl_keyval("RETURN") THEN 
				IF l_rec_cheque.source_ind = "S" THEN 
					IF l_rec_cheque.source_text != l_arr_cheq[idx].vouch_code THEN 
						LET l_msgresp = kandoomsg("P",9571,"") 
						#9571 Sundry payments can only be applied TO original sundry
						#     vouchers.
						NEXT FIELD vouch_code 
					END IF 
				END IF 
			END IF 
		AFTER FIELD inv_text 
			NEXT FIELD apply_amt 
		BEFORE FIELD apply_amt 
			IF l_arr_cheq[idx].vouch_code IS NULL 
			OR l_arr_cheq[idx].vouch_code = 0 THEN 
				NEXT FIELD vouch_code 
			END IF 
			SELECT unique 1 FROM tentpays 
			WHERE cmpy_code = p_cmpy 
			AND vouch_code = l_save_num 
			AND vend_code = l_rec_cheque.vend_code 
			IF status != NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P", 7033, "") 
				#7033 WARNING: Tentpays exist - Cycle will stuff up with
				#                               Voucher has changed msgs
				NEXT FIELD vouch_code 
			END IF 
			SELECT withhold_tax_ind INTO l_withhold_tax_ind FROM voucher 
			WHERE cmpy_code = p_cmpy 
			AND vouch_code = l_save_num 
			IF l_withhold_tax_ind != l_rec_cheque.withhold_tax_ind THEN 
				LET l_msgresp = kandoomsg("P",9564,"") 
				#9564 This voucher has a different withholding tax indicator.
				NEXT FIELD vouch_code 
			END IF 
			IF l_rec_cheque.pay_amt = l_rec_cheque.apply_amt THEN 
				LET l_msgresp = kandoomsg("P",1523,"") 
				#1523 Cheque has been fully applied; OK TO continue.
			ELSE 
				IF l_rec_cheque.pay_amt < l_rec_cheque.apply_amt THEN 
					LET l_msgresp = kandoomsg("P",9565,"") 
					#9565 Cheque has been over applied.
				ELSE 
					LET l_msgresp = kandoomsg("P",1080,"") 
					#1080 TAB TO apply; OK TO continue.
				END IF 
			END IF 
			IF l_before_flag = "Y" THEN 
				LET l_before_flag = "N" 
				LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt - l_save_amt 
				IF l_arr_cheq[idx].apply_amt = 0 THEN 
					# LET amount TO apply = available left
					LET l_arr_cheq[idx].apply_amt = l_rec_cheque.pay_amt 
					- l_rec_cheque.apply_amt 
					+ l_save_amt 
					# see IF too much TO apply, IF so adjust
					IF l_arr_cheq[idx].apply_amt > l_arr_cheq[idx].total_amt 
					+ l_save_amt 
					- l_arr_cheq[idx].paid_amt 
					- l_save_dis THEN 
						LET l_arr_cheq[idx].apply_amt = l_arr_cheq[idx].total_amt 
						+ l_save_amt 
						- l_arr_cheq[idx].paid_amt 
						- l_save_dis 
					END IF 
				END IF 
				# cant claim discount IF part paying
				IF l_arr_cheq[idx].apply_amt < l_arr_cheq[idx].total_amt 
				+ l_save_amt 
				- l_arr_cheq[idx].paid_amt - l_save_dis THEN 
					LET l_arr_cheq[idx].disc_amt = 0 
				END IF 
				LET l_arr_cheq[idx].paid_amt = l_arr_cheq[idx].paid_amt - l_save_amt 
				LET l_save_amt = l_arr_cheq[idx].apply_amt 
				LET l_save_dis = l_arr_cheq[idx].disc_amt 
				LET l_save_num = l_arr_cheq[idx].vouch_code 
				LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt + l_save_amt 
				DISPLAY l_arr_cheq[idx].disc_amt, 
				l_arr_cheq[idx].apply_amt, 
				l_arr_cheq[idx].total_amt, 
				l_arr_cheq[idx].paid_amt 
				TO sr_cheq[scrn].disc_amt, 
				sr_cheq[scrn].apply_amt, 
				sr_cheq[scrn].total_amt, 
				sr_cheq[scrn].paid_amt 

			END IF 
			DISPLAY l_arr_orig_paid_amt[idx] 
			TO sr_cheq[scrn].paid_amt 

			LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt - l_save_amt 
		AFTER FIELD apply_amt 
			IF l_arr_cheq[idx].apply_amt IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD apply_amt 
			END IF 
			IF l_arr_cheq[idx].apply_amt >= 0 THEN 
			ELSE 
				# can get the CASE of overapply in which
				# CASE negatives should be allowed
				IF l_arr_cheq[idx].paid_amt > l_arr_cheq[idx].total_amt 
				OR l_arr_cheq[idx].disc_amt > l_arr_cheq[idx].total_amt THEN 
				ELSE 
					LET l_msgresp = kandoomsg("P",9193,"") 
					#9193 Payment amount must be positive OR zero.
					LET l_save_amt = 0 
					NEXT FIELD apply_amt 
				END IF 
			END IF 
			IF l_arr_cheq[idx].total_amt = l_arr_cheq[idx].paid_amt 
			AND (l_arr_cheq[idx].apply_amt + l_arr_cheq[idx].disc_amt + 
			l_arr_orig_paid_amt[idx]) = l_arr_cheq[idx].total_amt THEN 
				NEXT FIELD disc_amt 
			END IF 
			IF l_arr_cheq[idx].apply_amt + l_arr_cheq[idx].disc_amt > 
			l_arr_cheq[idx].total_amt - l_arr_orig_paid_amt[idx] THEN 
				LET l_msgresp = kandoomsg("P",9194,"") 
				#9194 Payment will over apply the voucher.
				LET l_save_amt = 0 
				NEXT FIELD apply_amt 
			END IF 
			IF l_arr_cheq[idx].apply_amt > l_rec_cheque.pay_amt 
			- l_rec_cheque.apply_amt THEN 
				LET l_msgresp = kandoomsg("P",9199,"") 
				#9199 Payment will over apply the cheque.
				LET l_save_amt = 0 
				NEXT FIELD apply_amt 
			END IF 
			IF (int_flag OR quit_flag) 
			AND l_arr_source_ind[idx].source_ind = "S" THEN 
				IF l_arr_cheq[idx].apply_amt > 0 
				AND l_rec_cheque.apply_amt != l_rec_cheque.apply_amt THEN 
					LET l_msgresp = kandoomsg("P",9572,"") 
					#9572 Voucher payment must be complete WHEN applying TO
					#     sundry voucher.
					LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt - l_save_amt 
					LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt 
					+ l_arr_cheq[idx].apply_amt 
					LET l_save_amt = l_arr_cheq[idx].apply_amt 
					LET l_arr_cheq[idx].apply_amt = l_rec_cheque.pay_amt 
					- l_rec_cheque.apply_amt 
					# see IF too much TO apply, IF so adjust
					IF l_arr_cheq[idx].apply_amt > l_arr_cheq[idx].total_amt 
					- l_arr_orig_paid_amt[idx] 
					- l_save_dis THEN 
						LET l_arr_cheq[idx].apply_amt = l_arr_cheq[idx].total_amt 
						- l_arr_orig_paid_amt[idx] 
						- l_save_dis 
					END IF 
					DISPLAY l_arr_cheq[idx].apply_amt 
					TO sr_cheq[scrn].apply_amt 

					NEXT FIELD apply_amt 
				ELSE 
					IF l_arr_cheq[idx].apply_amt = 0 
					AND l_arr_cheq[idx].disc_amt = 0 THEN 
						#Reset VALUES TO original cheque VALUES
						LET l_rec_cheque.source_ind = "1" 
						LET l_rec_cheque.source_text = l_rec_cheque.vend_code 
					END IF 
				END IF 
				IF l_rec_cheque.source_ind != "S" THEN 
					LET l_rec_cheque.source_ind = "S" 
					LET l_rec_cheque.source_text = l_arr_cheq[i].vouch_code 
					USING "&&&&&&&&" 
				END IF 
			END IF 
			NEXT FIELD disc_amt 
		AFTER FIELD disc_amt 
			LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt 
			+ l_arr_cheq[idx].apply_amt 
			LET l_save_amt = l_arr_cheq[idx].apply_amt 
			LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt 
			IF l_arr_cheq[idx].disc_amt IS NULL THEN 
				LET l_arr_cheq[idx].disc_amt = 0 
				DISPLAY l_arr_cheq[idx].disc_amt 
				TO sr_cheq[scrn].disc_amt 

			ELSE 
				IF l_arr_cheq[idx].disc_amt < 0 THEN 
					LET l_msgresp = kandoomsg("G",9084,"") 
					#9084 Amount of discount must be positive OR zero
					NEXT FIELD apply_amt 
				END IF 
			END IF 
			IF l_rec_cheque.apply_amt > l_rec_cheque.pay_amt THEN 
				LET l_msgresp = kandoomsg("P",9566,"") 
				#9566 This entry will over apply the cheque.
				NEXT FIELD apply_amt 
			END IF 
			IF l_arr_cheq[idx].apply_amt + l_arr_cheq[idx].disc_amt 
			> l_arr_cheq[idx].total_amt - l_arr_orig_paid_amt[idx] THEN 
				LET l_msgresp = kandoomsg("P",9567,"") 
				#9567 This entry will over apply the voucher.
				LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt 
				- l_arr_cheq[idx].apply_amt 
				LET l_save_amt = 0 
				LET l_arr_cheq[idx].disc_amt = l_save_dis 
				NEXT FIELD apply_amt 
			END IF 
			IF l_arr_cheq[idx].disc_amt != 0 THEN 
				IF l_rec_cheque.post_flag = "Y" THEN 
					LET l_msgresp = kandoomsg("P",9568,"") 
					#9568 Cheque has been posted, no discounts are allowed.
					NEXT FIELD apply_amt 
				END IF 
				IF l_arr_cheq[idx].disc_amt > l_save_dis THEN 
					LET l_msgresp = kandoomsg("P",9569,"") 
					#9569 Too much discount taken, maximum IS displayed.
					LET l_arr_cheq[idx].disc_amt = l_save_dis 
					DISPLAY l_arr_cheq[idx].disc_amt 
					TO sr_cheq[scrn].disc_amt 

					NEXT FIELD apply_amt 
				END IF 
				IF (l_arr_cheq[idx].apply_amt < l_arr_cheq[idx].total_amt 
				- l_arr_cheq[idx].paid_amt 
				- l_save_dis) 
				OR (l_arr_cheq[idx].apply_amt + l_arr_cheq[idx].disc_amt 
				+ l_arr_orig_paid_amt[idx] 
				<> l_arr_cheq[idx].total_amt) THEN 
					LET l_msgresp = kandoomsg("G",9083,"") 
					#9083 Must fully pay voucher TO claim discount.
					LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt - l_save_amt 
					LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt 
					+ l_arr_cheq[idx].apply_amt 
					LET l_save_amt = l_arr_cheq[idx].apply_amt 
					LET l_arr_cheq[idx].apply_amt = l_rec_cheque.pay_amt 
					- l_rec_cheque.apply_amt 
					# see IF too much TO apply, IF so adjust
					IF l_arr_cheq[idx].apply_amt > l_arr_cheq[idx].total_amt 
					- l_arr_orig_paid_amt[idx] 
					- l_save_dis THEN 
						LET l_arr_cheq[idx].apply_amt = l_arr_cheq[idx].total_amt 
						- l_arr_orig_paid_amt[idx] 
						- l_save_dis 
					END IF 
					DISPLAY l_arr_cheq[idx].apply_amt 
					TO sr_cheq[scrn].apply_amt 

					NEXT FIELD apply_amt 
				END IF 
			END IF 
			LET l_arr_cheq[idx].paid_amt = l_arr_orig_paid_amt[idx] 
			+ l_arr_cheq[idx].apply_amt 
			+ l_arr_cheq[idx].disc_amt 
			LET l_arr_cheq[idx].vouch_code = l_save_num 
			DISPLAY l_rec_cheque.apply_amt, 
			l_arr_cheq[idx].paid_amt 
			TO apply_amt, 
			sr_cheq[scrn].paid_amt 

			# just in CASE they changed the voucher number
			DISPLAY l_arr_cheq[idx].vouch_code 
			TO sr_cheq[scrn].vouch_code 

			IF l_rec_cheque.pay_amt = l_rec_cheque.apply_amt THEN 
				LET l_msgresp = kandoomsg("P",1523,"") 
				#1523 Cheque has been fully applied; OK TO continue.
			ELSE 
				LET l_msgresp = kandoomsg("P",1080,"") 
				#1080 TAB TO apply; OK TO continue.
			END IF 
			IF l_arr_source_ind[idx].source_ind = "S" 
			AND l_arr_cheq[idx].apply_amt > 0 THEN 
				IF l_rec_cheque.apply_amt != l_arr_cheq[idx].apply_amt THEN 
					LET l_msgresp = kandoomsg("P",9572,"") 
					#9572 Voucher payment must be complete WHEN applying TO
					#     sundry voucher.
					LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt - l_save_amt 
					LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt 
					+ l_arr_cheq[idx].apply_amt 
					LET l_save_amt = l_arr_cheq[idx].apply_amt 
					LET l_arr_cheq[idx].apply_amt = l_rec_cheque.pay_amt 
					- l_rec_cheque.apply_amt 
					# see IF too much TO apply, IF so adjust
					IF l_arr_cheq[idx].apply_amt > l_arr_cheq[idx].total_amt 
					- l_arr_orig_paid_amt[idx] 
					- l_save_dis THEN 
						LET l_arr_cheq[idx].apply_amt = l_arr_cheq[idx].total_amt 
						- l_arr_orig_paid_amt[idx] 
						- l_save_dis 
					END IF 
					DISPLAY l_arr_cheq[idx].apply_amt 
					TO sr_cheq[scrn].apply_amt 

					NEXT FIELD apply_amt 
				END IF 
				LET l_rec_cheque.source_ind = "S" 
				LET l_rec_cheque.source_text = l_arr_cheq[idx].vouch_code 
				USING "&&&&&&&&" 
			ELSE 
				IF l_rec_cheque.source_ind = "S" 
				AND l_arr_cheq[idx].apply_amt = 0 
				AND l_arr_cheq[idx].disc_amt = 0 THEN 
					#Reset VALUES TO original cheque VALUES
					LET l_rec_cheque.source_ind = "1" 
					LET l_rec_cheque.source_text = l_rec_cheque.vend_code 
				END IF 
			END IF 
			NEXT FIELD vouch_code 
		AFTER INPUT 
			LET l_arr_size = arr_count() 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_rec_cheque.cheq_code = 0 
	ELSE 
		GOTO bypass 
		LABEL recovery: 
		LET l_err_continue = error_recover(l_err_message, status) 
		IF l_err_continue != "Y" THEN 
			EXIT PROGRAM 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 
		BEGIN WORK 
			LET l_err_message = "P41 - Chechead UPDATE" 
			IF l_rec_cheque.source_ind = "S" THEN 
				#Need TO store temp. as cheque RECORD overwritten ...
				LET l_temp_source_ind = l_rec_cheque.source_ind 
				LET l_temp_source_text = l_rec_cheque.source_text 
			END IF 
			DECLARE c_cheque CURSOR FOR 
			SELECT * INTO l_rec_cheque.* FROM cheque 
			WHERE cheque.cmpy_code = p_cmpy 
			AND cheque.bank_acct_code = p_bank_acct_code 
			AND cheque.cheq_code = l_rec_cheque.cheq_code 
			AND cheque.vend_code = l_rec_cheque.vend_code 
			AND cheque.pay_meth_ind = p_pay_meth_ind 
			FOR UPDATE 
			FOREACH c_cheque 
				LET l_rec_cheque.next_appl_num = l_rec_cheque.next_appl_num + 1 
				IF l_temp_source_ind IS NOT NULL THEN 
					LET l_rec_cheque.source_ind = l_temp_source_ind 
					LET l_rec_cheque.source_text = l_temp_source_text 
				END IF 
				LET l_appl_amt = 0 
				LET l_discount_amt = 0 
				FOR i = 1 TO l_arr_size 
					IF l_arr_cheq[i].apply_amt != 0 
					AND l_arr_cheq[i].vouch_code != 0 THEN 
						DECLARE c2_voucher CURSOR FOR 
						SELECT * INTO l_rec_voucher.* FROM voucher 
						WHERE vouch_code = l_arr_cheq[i].vouch_code 
						AND cmpy_code = p_cmpy 
						FOR UPDATE 
						FOREACH c2_voucher 
							LET l_rec_voucher.paid_amt = l_rec_voucher.paid_amt 
							+ l_arr_cheq[i].apply_amt 
							+ l_arr_cheq[i].disc_amt 
							IF l_rec_voucher.paid_amt > l_rec_voucher.total_amt THEN 
								ROLLBACK WORK 
								LET l_msgresp = kandoomsg("P",7092,"") 
								#7092 Voucher VALUES have been altered - cannot apply.
								EXIT PROGRAM 
							END IF 
							IF l_rec_voucher.taken_disc_amt IS NULL THEN 
								LET l_rec_voucher.taken_disc_amt = 0 
							END IF 
							LET l_rec_voucher.pay_seq_num = l_rec_voucher.pay_seq_num 
							+ 1 
							LET l_rec_voucher.taken_disc_amt = 
							l_rec_voucher.taken_disc_amt 
							+ l_arr_cheq[i].disc_amt 
							IF l_rec_voucher.total_amt = l_rec_voucher.paid_amt THEN 
								LET l_rec_voucher.paid_date = l_rec_cheque.cheq_date 
							END IF 
							LET l_err_message = "P41 - Vouchead UPDATE" 
							UPDATE voucher 
							SET paid_amt = l_rec_voucher.paid_amt, 
							pay_seq_num = l_rec_voucher.pay_seq_num, 
							taken_disc_amt = l_rec_voucher.taken_disc_amt, 
							paid_date = l_rec_voucher.paid_date 
							WHERE CURRENT OF c2_voucher 
							LET l_appl_amt = l_appl_amt + l_arr_cheq[i].apply_amt 
							LET l_discount_amt = l_discount_amt + l_arr_cheq[i].disc_amt 
							LET l_rec_voucherpays.cmpy_code = p_cmpy 
							LET l_rec_voucherpays.vend_code = l_rec_cheque.vend_code 
							LET l_rec_voucherpays.vouch_code = l_rec_voucher.vouch_code 
							LET l_rec_voucherpays.seq_num = 0 
							LET l_rec_voucherpays.pay_num = l_rec_cheque.cheq_code 
							LET l_rec_voucherpays.pay_meth_ind = l_rec_cheque.pay_meth_ind 
							LET l_rec_voucherpays.apply_num = l_rec_voucher.pay_seq_num 
							LET l_rec_voucherpays.pay_type_code = "CH" 
							LET l_rec_voucherpays.pay_date = today 
							LET l_rec_voucherpays.apply_amt = l_arr_cheq[i].apply_amt 
							LET l_rec_voucherpays.disc_amt = l_arr_cheq[i].disc_amt 
							LET l_rec_voucherpays.withhold_tax_ind 
							= l_rec_cheque.withhold_tax_ind 
							LET l_rec_voucherpays.tax_code = l_rec_cheque.tax_code 
							LET l_rec_voucherpays.bank_code = l_rec_cheque.bank_code 
							LET l_rec_voucherpays.rev_flag = NULL 
							LET l_rec_voucherpays.tax_per = l_rec_cheque.tax_per 
							LET l_rec_voucherpays.remit_doc_num = 0 
							LET l_rec_voucherpays.pay_doc_num = l_rec_cheque.doc_num 
							LET l_err_message = "P41 - Voucpay INSERT" 
							INSERT INTO voucherpays VALUES (l_rec_voucherpays.*) 


							IF l_rec_voucher.conv_qty IS NOT NULL THEN 
								IF l_rec_voucher.conv_qty != 0 THEN 
									LET l_base_vouc_apply_amt = l_rec_voucherpays.apply_amt 
									/ l_rec_voucher.conv_qty 
									LET l_base_cheq_apply_amt = l_rec_voucherpays.apply_amt 
									/ l_rec_cheque.conv_qty 
									LET l_base_vouc_disc_amt = l_rec_voucherpays.disc_amt 
									/ l_rec_voucher.conv_qty 
									LET l_base_cheq_disc_amt = l_rec_voucherpays.disc_amt 
									/ l_rec_cheque.conv_qty 
								END IF 
							END IF 

							LET l_rec_exchangevar.exchangevar_amt = 
							l_base_cheq_apply_amt - l_base_vouc_apply_amt 
							IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
								LET l_rec_exchangevar.cmpy_code = l_rec_cheque.cmpy_code 
								LET l_rec_exchangevar.year_num = l_rec_cheque.year_num 
								LET l_rec_exchangevar.period_num = 
								l_rec_cheque.period_num 
								LET l_rec_exchangevar.source_ind = "P" 
								LET l_rec_exchangevar.tran_date = l_rec_cheque.cheq_date 
								LET l_rec_exchangevar.ref_code = l_rec_cheque.vend_code 
								LET l_rec_exchangevar.tran_type1_ind = "VO" 
								LET l_rec_exchangevar.ref1_num = l_rec_voucher.vouch_code 
								LET l_rec_exchangevar.tran_type2_ind = "CH" 
								LET l_rec_exchangevar.ref2_num = l_rec_cheque.cheq_code 
								LET l_rec_exchangevar.currency_code = l_rec_voucher.currency_code 
								LET l_rec_exchangevar.posted_flag = "N" 
								INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
							END IF 
							#create exchage variance on discount
							LET l_rec_exchangevar.exchangevar_amt = 
							l_base_cheq_disc_amt - l_base_vouc_disc_amt 
							IF l_rec_exchangevar.exchangevar_amt != 0 THEN 
								INSERT INTO exchangevar VALUES (l_rec_exchangevar.*) 
							END IF 
						END FOREACH 
					END IF 
				END FOR 
				IF l_discount_amt > 0 THEN 
					LET l_err_message = "P41 - Vendmain UPDATE" 
					DECLARE c_vendor CURSOR FOR 
					SELECT * 
					INTO l_rec_vendor.* 
					FROM vendor 
					WHERE cmpy_code = p_cmpy 
					AND vend_code = l_rec_cheque.vend_code 
					FOR UPDATE 
					FOREACH c_vendor 
						LET l_rec_vendor.curr_amt = l_rec_vendor.curr_amt 
						- l_discount_amt 
						LET l_rec_vendor.bal_amt = l_rec_vendor.bal_amt 
						- l_discount_amt 
						LET l_rec_vendor.last_payment_date = l_rec_cheque.cheq_date 
						LET l_rec_vendor.next_seq_num = l_rec_vendor.next_seq_num 
						+ 1 
						LET l_err_message = "P41 - Vendmain UPDATE" 
						UPDATE vendor 
						SET bal_amt = l_rec_vendor.bal_amt, 
						curr_amt = l_rec_vendor.curr_amt, 
						last_payment_date = 
						l_rec_vendor.last_payment_date, 
						next_seq_num = l_rec_vendor.next_seq_num 
						WHERE CURRENT OF c_vendor 
					END FOREACH 
					#now done it CALL init_p_ap() #init P/AP module
					#SELECT apparms.*
					#   INTO pr_apparms.*
					#   FROM apparms
					#   WHERE apparms.parm_code = "1"
					#     AND apparms.cmpy_code = p_cmpy
					#IF STATUS = NOTFOUND THEN
					#   LET l_msgresp = kandoomsg("P",5016,"")
					#   #5016 Accounts Payable Parameters NOT found; Refer Menu PZP.
					#   rollback work
					#   EXIT PROGRAM
					#END IF
					CALL db_period_what_period(p_cmpy, today) 
					RETURNING l_rec_apaudit.year_num, 
					l_rec_apaudit.period_num 
					LET l_rec_apaudit.cmpy_code = p_cmpy 
					LET l_rec_apaudit.tran_date = today 
					LET l_rec_apaudit.vend_code = l_rec_cheque.vend_code 
					LET l_rec_apaudit.seq_num = l_rec_vendor.next_seq_num 
					LET l_rec_apaudit.trantype_ind = "CH" 
					LET l_rec_apaudit.source_num = l_rec_cheque.cheq_code 
					LET l_rec_apaudit.tran_text = "Apply Discount" 
					LET l_rec_apaudit.tran_amt = 0 - l_discount_amt 
					LET l_rec_apaudit.entry_code = l_rec_cheque.entry_code 
					LET l_rec_apaudit.bal_amt = l_rec_vendor.bal_amt 
					LET l_rec_apaudit.currency_code = l_rec_cheque.currency_code 
					LET l_rec_apaudit.conv_qty = l_rec_cheque.conv_qty 
					LET l_rec_apaudit.entry_date = today 
					LET l_err_message = "P41 - Apdlog INSERT" 
					INSERT INTO apaudit VALUES (l_rec_apaudit.*) 
				END IF 
				LET l_err_message = "P41b - Cheque Header UPDATE" 
				LET l_rec_cheque.apply_amt = l_rec_cheque.apply_amt + l_appl_amt 
				LET l_rec_cheque.disc_amt = l_rec_cheque.disc_amt + l_discount_amt 
				IF l_rec_cheque.apply_amt > l_rec_cheque.pay_amt THEN 
					ROLLBACK WORK 
					LET l_msgresp = kandoomsg("P",7093,"") 
					#7093 Applied amount IS greater than cheque amount; Please try...
					CLOSE WINDOW p138 
					RETURN 0 
				END IF 
				UPDATE cheque SET * = l_rec_cheque.* 
				WHERE CURRENT OF c_cheque 
			END FOREACH 
		COMMIT WORK 
	END IF 
	CLOSE WINDOW p138 
	RETURN l_rec_cheque.cheq_code 
END FUNCTION 


