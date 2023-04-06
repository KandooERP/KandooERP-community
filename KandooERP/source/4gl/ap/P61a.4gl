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
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P6_GROUP_GLOBALS.4gl"
GLOBALS "../ap/P61_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################

############################################################
# FUNCTION enter_debit(p_cmpy, p_kandoouser_sign_on_code, p_vend_code, p_deb_num)
#
# \file
# \brief module - P61a - Allows the user TO enter Payables debits
############################################################
FUNCTION enter_debit(p_cmpy,p_kandoouser_sign_on_code,p_vend_code,p_deb_num) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE p_deb_num LIKE debithead.debit_num 
	DEFINE l_rec_default 
		RECORD 
			debit_date LIKE debithead.debit_date, 
			year_num LIKE debithead.year_num, 
			period_num LIKE debithead.period_num 
		END RECORD
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_desc_text LIKE currency.desc_text 
	DEFINE l_total_amt LIKE debithead.total_amt 
	DEFINE l_conv_qty LIKE debithead.conv_qty 
	DEFINE l_last_conv_qty LIKE debithead.conv_qty 
	DEFINE l_base_currency LIKE glparms.base_currency_code 
	DEFINE l_set_up_conv_qty SMALLINT 
	DEFINE l_failed_it INTEGER 
	DEFINE l_last_field CHAR(18) 
	DEFINE l_mode CHAR(4) 
	DEFINE l_save_date LIKE debithead.debit_date 
	DEFINE l_year_num LIKE debithead.year_num 
	DEFINE l_period_num LIKE debithead.period_num 
	DEFINE l_option LIKE kandoooption.feature_ind # used TO store max option OF apvi 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_vend_code IS NOT NULL THEN 
		SELECT * INTO l_rec_vendor.* FROM vendor 
		WHERE cmpy_code = p_cmpy 
		AND vend_code = p_vend_code 
		IF status = NOTFOUND THEN 
			LET p_vend_code = NULL 
		ELSE 
			DISPLAY BY NAME l_rec_vendor.name_text, 
			l_rec_vendor.bal_amt, 
			l_rec_vendor.curr_amt, 
			l_rec_vendor.over1_amt, 
			l_rec_vendor.over30_amt, 
			l_rec_vendor.over60_amt, 
			l_rec_vendor.over90_amt, 
			l_rec_vendor.vend_code, 
			l_rec_vendor.last_debit_date, 
			l_rec_vendor.last_payment_date 

		END IF 
	END IF 
	IF p_deb_num IS NOT NULL THEN 
		SELECT * INTO l_rec_debithead.* FROM debithead 
		WHERE cmpy_code = p_cmpy 
		AND vend_code = p_vend_code 
		AND debit_num = p_deb_num 
		IF status = NOTFOUND THEN 
			RETURN l_rec_debithead.* 
		ELSE 
			LET l_desc_text = NULL 
			SELECT desc_text INTO l_desc_text FROM currency 
			WHERE currency_code = l_rec_vendor.currency_code 
			DISPLAY l_rec_debithead.total_amt, 
			l_rec_debithead.entry_code, 
			l_rec_debithead.entry_date, 
			l_rec_debithead.currency_code, 
			l_desc_text, 
			l_rec_debithead.conv_qty 
			TO debithead.total_amt, 
			debithead.entry_code, 
			debithead.entry_date, 
			debithead.currency_code, 
			currency.desc_text, 
			debithead.conv_qty 

			LET l_mode = MODE_CLASSIC_EDIT 
		END IF 
	ELSE 
		INITIALIZE l_rec_debithead.* TO NULL 
		LET l_rec_debithead.cmpy_code = p_cmpy 
		LET l_rec_debithead.entry_code = p_kandoouser_sign_on_code 
		LET l_rec_debithead.entry_date = today 
		LET l_rec_debithead.post_flag = "N" 
		LET l_rec_debithead.post_date = NULL 
		LET l_rec_debithead.vend_code = NULL 
		LET l_rec_debithead.disc_amt = 0 
		LET l_rec_debithead.goods_amt = 0 
		LET l_rec_debithead.tax_amt = 0 
		LET l_rec_debithead.total_amt = 0 
		LET l_rec_debithead.appl_seq_num = 0 
		LET l_rec_debithead.dist_qty = 0 
		LET l_rec_debithead.dist_amt = 0 
		LET l_rec_debithead.apply_amt = 0 
		LET l_rec_debithead.conv_qty = 0 
		LET l_mode = "ADD" 
		IF l_rec_default.year_num IS NOT NULL 
		OR l_rec_default.year_num != 0 THEN 
			LET l_rec_debithead.year_num = l_rec_default.year_num 
		END IF 
		IF l_rec_default.period_num IS NOT NULL 
		OR l_rec_default.period_num != 0 THEN 
			LET l_rec_debithead.period_num = l_rec_default.period_num 
		END IF 
	END IF 
	LET l_set_up_conv_qty = true 
	SELECT base_currency_code INTO l_base_currency FROM glparms 
	WHERE key_code = "1" 
	AND cmpy_code = p_cmpy 
	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5007,"") 
		#5007 General Ledger Parameters Not Set Up;  Refer menu GZP.
		RETURN l_rec_debithead.* 
	END IF 
	LET l_option = get_kandoooption_feature_state("AP","VI") 
	LET l_msgresp = kandoomsg("P",1019,"") 
	#1019 Enter Debit Information.
	INPUT BY NAME l_rec_debithead.vend_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P61A","inp-debithead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) 
			IF infield (vend_code) THEN 
				LET l_rec_debithead.vend_code = show_vend(p_cmpy,l_rec_debithead.vend_code) 
				DISPLAY BY NAME l_rec_debithead.vend_code 

				NEXT FIELD vend_code 
			END IF 
		BEFORE FIELD vend_code 
			IF p_vend_code IS NOT NULL THEN 
				EXIT INPUT 
			END IF 
		AFTER FIELD vend_code 
			SELECT * INTO l_rec_vendor.* FROM vendor 
			WHERE vendor.cmpy_code = p_cmpy 
			AND vendor.vend_code = l_rec_debithead.vend_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("P",9105,"") 
				#9105 Vendor NOT found;  Try Window.
				NEXT FIELD vend_code 
			ELSE 
				DISPLAY BY NAME l_rec_vendor.name_text, 
				l_rec_vendor.bal_amt, 
				l_rec_vendor.curr_amt, 
				l_rec_vendor.over1_amt, 
				l_rec_vendor.over30_amt, 
				l_rec_vendor.over60_amt, 
				l_rec_vendor.over90_amt, 
				l_rec_vendor.vend_code, 
				l_rec_vendor.last_debit_date, 
				l_rec_vendor.last_payment_date 

				LET l_rec_debithead.tax_code = l_rec_vendor.tax_code 
				LET l_rec_debithead.contact_text = l_rec_vendor.contact_text 
				LET l_rec_debithead.currency_code = l_rec_vendor.currency_code 
				LET l_desc_text = NULL 
				SELECT desc_text INTO l_desc_text FROM currency 
				WHERE currency_code = l_rec_vendor.currency_code 
				DISPLAY l_rec_debithead.total_amt, 
				l_rec_debithead.entry_code, 
				l_rec_debithead.entry_date, 
				l_rec_debithead.currency_code, 
				l_desc_text, 
				l_rec_debithead.conv_qty 
				TO debithead.total_amt, 
				debithead.entry_code, 
				debithead.entry_date, 
				debithead.currency_code, 
				currency.desc_text, 
				debithead.conv_qty 

			END IF 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_rec_debithead.vend_code = NULL 
		RETURN l_rec_debithead.* 
	END IF 
	INPUT BY NAME l_rec_debithead.debit_date, 
	l_rec_debithead.year_num, 
	l_rec_debithead.period_num, 
	l_rec_debithead.total_amt, 
	l_rec_debithead.debit_text, 
	l_rec_debithead.conv_qty, 
	l_rec_debithead.com1_text, 
	l_rec_debithead.com2_text WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P61A","inp-debithead-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD total_amt 
			LET l_total_amt = l_rec_debithead.total_amt 
		AFTER FIELD total_amt 
			IF l_rec_debithead.total_amt <= 0 
			AND l_mode = "ADD" THEN 
				LET l_msgresp = kandoomsg("P",9041,"") 
				#9041 Debit total amount must be greater than zero"
				NEXT FIELD total_amt 
			END IF 
			IF l_rec_debithead.total_amt < 0 
			AND l_mode = MODE_CLASSIC_EDIT THEN 
				LET l_msgresp = kandoomsg("P",9089,"") 
				#9089 Debit total amount must be greater than zero"
				NEXT FIELD total_amt 
			END IF 
			IF l_rec_debithead.apply_amt > 0 
			AND l_rec_debithead.total_amt < l_rec_debithead.apply_amt THEN 
				LET l_msgresp=kandoomsg("P",7027,"") 
				#7027" Debit has been applied - Un-apply before making changes"
				LET l_rec_debithead.total_amt = l_total_amt 
				NEXT FIELD total_amt 
			END IF 
			IF l_rec_debithead.dist_amt > l_rec_debithead.total_amt THEN 
				LET l_msgresp=kandoomsg("P",7013,"") 
				#7013" Distributions Exceed Total"
			END IF 
		BEFORE FIELD debit_date 
			IF l_rec_debithead.debit_date IS NULL THEN 
				IF l_rec_default.debit_date IS NULL 
				OR l_rec_default.debit_date = '31/12/1899' THEN 
					LET l_rec_debithead.debit_date = today 
				ELSE 
					LET l_rec_debithead.debit_date = l_rec_default.debit_date 
				END IF 
			END IF 
			LET l_save_date = l_rec_debithead.debit_date 
			IF (l_rec_debithead.year_num IS NULL OR l_rec_debithead.year_num = 0) 
			AND (l_rec_debithead.period_num IS NULL OR l_rec_debithead.period_num = 0) 
			THEN 
				CALL db_period_what_period(p_cmpy, l_rec_debithead.debit_date) 
				RETURNING l_rec_debithead.year_num, l_rec_debithead.period_num 
			END IF 
			IF l_set_up_conv_qty THEN 
				CALL get_conv_rate(p_cmpy, l_rec_debithead.currency_code, 
				l_rec_debithead.debit_date, "B") 
				RETURNING l_rec_debithead.conv_qty 
				IF l_rec_debithead.conv_qty IS NULL 
				OR l_rec_debithead.conv_qty = "" THEN 
					LET l_rec_debithead.conv_qty = 0 
				END IF 
			END IF 
			DISPLAY BY NAME l_rec_debithead.debit_num, 
			l_rec_debithead.debit_date, 
			l_rec_debithead.conv_qty, 
			l_rec_debithead.year_num, 
			l_rec_debithead.period_num 

		AFTER FIELD debit_date 
			CALL db_period_what_period(p_cmpy, l_rec_debithead.debit_date) 
			RETURNING l_year_num, l_period_num 

			# Don't want TO over ride defaults
			IF l_save_date != l_rec_debithead.debit_date THEN 
				LET l_rec_debithead.year_num = l_year_num 
				LET l_rec_debithead.period_num = l_period_num 
			END IF 
			IF l_set_up_conv_qty THEN 
				CALL get_conv_rate(p_cmpy, l_rec_debithead.currency_code, 
				l_rec_debithead.debit_date, "B") 
				RETURNING l_rec_debithead.conv_qty 
				IF l_rec_debithead.conv_qty IS NULL 
				OR l_rec_debithead.conv_qty = "" THEN 
					LET l_rec_debithead.conv_qty = 0 
				END IF 
			END IF 
			DISPLAY BY NAME l_rec_debithead.debit_num, 
			l_rec_debithead.debit_date, 
			l_rec_debithead.conv_qty, 
			l_rec_debithead.year_num, 
			l_rec_debithead.period_num 

		AFTER FIELD debit_text 
			IF NOT check_debit_text(p_cmpy, l_option, l_rec_debithead.debit_num, 
			l_rec_debithead.debit_text, 
			l_rec_debithead.vend_code) THEN 
				NEXT FIELD debit_text 
			END IF 
			LET l_last_field = "debit_text" 

		BEFORE FIELD conv_qty 
			LET l_last_conv_qty = l_rec_debithead.conv_qty 
			IF l_rec_debithead.currency_code = l_base_currency THEN 
				IF l_last_field = "debit_text" THEN 
					NEXT FIELD com1_text 
				ELSE 
					NEXT FIELD debit_text 
				END IF 
			END IF 

		AFTER FIELD conv_qty 
			IF l_rec_debithead.conv_qty IS NULL THEN 
				LET l_msgresp = kandoomsg("P",9012,"") 
				#9012 Exchange Rate must be greater than zero
				NEXT FIELD conv_qty 
			END IF 
			IF l_rec_debithead.conv_qty <= 0 THEN 
				LET l_msgresp = kandoomsg("P",9012,"") 
				#9012 Exchange Rate must be greater than zero
				NEXT FIELD conv_qty 
			END IF 
			IF l_last_conv_qty != l_rec_debithead.conv_qty THEN 
				LET l_set_up_conv_qty = false 
			END IF 

		AFTER FIELD period_num 
			IF l_rec_debithead.period_num IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD period_num 
			END IF 
			CALL valid_period(p_cmpy, l_rec_debithead.year_num, 
			l_rec_debithead.period_num, "ap") 
			RETURNING l_rec_debithead.year_num, 
			l_rec_debithead.period_num, 
			l_failed_it 
			IF l_failed_it THEN 
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD com1_text 
			LET l_last_field = "com1_text" 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_debithead.total_amt IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD total_amt 
				END IF 
				IF l_rec_debithead.total_amt <= 0 
				AND l_mode = "ADD" THEN 
					LET l_msgresp = kandoomsg("P",9041,"") 
					#9041 Debit total amount must be greater than zero"
					NEXT FIELD total_amt 
				END IF 
				IF l_rec_debithead.total_amt < 0 
				AND l_mode = MODE_CLASSIC_EDIT THEN 
					LET l_msgresp = kandoomsg("P",9089,"") 
					#9089 Debit total amount must be greater than zero"
					NEXT FIELD total_amt 
				END IF 
				IF l_rec_debithead.debit_date IS NULL THEN 
					LET l_rec_debithead.debit_date = today 
				END IF 
				CALL valid_period(p_cmpy, l_rec_debithead.year_num, 
				l_rec_debithead.period_num, "ap") 
				RETURNING l_rec_debithead.year_num, 
				l_rec_debithead.period_num, 
				l_failed_it 
				IF l_failed_it THEN 
					NEXT FIELD year_num 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		INITIALIZE l_rec_debithead.* TO NULL 
	END IF 
	RETURN l_rec_debithead.* 
END FUNCTION 


FUNCTION check_debit_text(p_cmpy_code,p_option,p_debit_num,p_debit_text,p_vend_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_option LIKE kandoooption.feature_ind 
	DEFINE p_debit_num LIKE debithead.debit_num 
	DEFINE p_debit_text LIKE debithead.debit_text 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	IF p_option != 0 
	AND p_option IS NOT NULL 
	AND p_debit_text IS NOT NULL THEN 
		CASE 
			WHEN p_debit_num IS NULL 
				SELECT unique(1) FROM debithead 
				WHERE debit_text = p_debit_text 
				AND vend_code = p_vend_code 
				AND cmpy_code = p_cmpy_code 
			OTHERWISE 
				SELECT unique(1) FROM debithead 
				WHERE debit_num != p_debit_num 
				AND debit_text = p_debit_text 
				AND vend_code = p_vend_code 
				AND cmpy_code = p_cmpy_code 
		END CASE 
		IF status != NOTFOUND THEN 
			LET l_msgresp = kandoomsg("P",9023,"") 
			#9023 Vendor invoice number already exists.
			IF p_option = 1 THEN 
				RETURN true 
			ELSE 
				RETURN false 
			END IF 
		END IF 
	END IF 
	RETURN true 
END FUNCTION 


