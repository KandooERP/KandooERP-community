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
	#DEFINE glob_rec_holdpay RECORD LIKE holdpay.*
	#DEFINE l_where_part CHAR(500)
	#DEFINE l_query_text CHAR(550)
	#DEFINE l_exist SMALLINT
END GLOBALS 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module P2B allows the user TO view Voucher Information
#                    AND modify the hold codes only
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P2B") 
	CALL ui_init(0) 


	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p120 with FORM "P120" 
	CALL winDecoration_p("P120") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE hold_vouch() 
	END WHILE 
	CLOSE WINDOW p120 
END MAIN 


############################################################
# FUNCTION hold_vouch()
#
#
############################################################
FUNCTION hold_vouch() 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_holdpay RECORD LIKE holdpay.* 
	DEFINE l_owing_amt LIKE voucher.total_amt 
	DEFINE l_pptax_amt LIKE voucher.total_amt 
	DEFINE l_withhold_tax_ind LIKE voucher.withhold_tax_ind 
	DEFINE l_tax_code LIKE voucher.tax_code 
	DEFINE l_tax_per LIKE voucherpays.tax_per 
	DEFINE l_net_pay_amt LIKE voucher.total_amt 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_where_part CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_exist SMALLINT 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT l_where_part ON voucher.vend_code, 
	vendor.name_text, 
	voucher.vouch_code, 
	voucher.batch_num, 
	vendor.currency_code, 
	voucher.inv_text, 
	voucher.vouch_date, 
	voucher.due_date, 
	voucher.conv_qty, 
	voucher.withhold_tax_ind, 
	voucher.total_amt, 
	voucher.dist_amt, 
	voucher.paid_amt, 
	voucher.paid_date, 
	voucher.term_code, 
	voucher.tax_code, 
	voucher.hold_code, 
	voucher.disc_date, 
	voucher.taken_disc_amt, 
	voucher.poss_disc_amt, 
	voucher.post_flag, 
	voucher.year_num, 
	voucher.period_num, 
	voucher.entry_code, 
	voucher.entry_date, 
	voucher.com1_text, 
	voucher.com2_text 
	FROM voucher.vend_code, 
	vendor.name_text, 
	voucher.vouch_code, 
	voucher.batch_num, 
	vendor.currency_code, 
	voucher.inv_text, 
	voucher.vouch_date, 
	voucher.due_date, 
	voucher.conv_qty, 
	voucher.withhold_tax_ind, 
	voucher.total_amt, 
	voucher.dist_amt, 
	voucher.paid_amt, 
	voucher.paid_date, 
	voucher.term_code, 
	voucher.tax_code, 
	voucher.hold_code, 
	voucher.disc_date, 
	voucher.taken_disc_amt, 
	voucher.poss_disc_amt, 
	voucher.post_flag, 
	voucher.year_num, 
	voucher.period_num, 
	voucher.entry_code, 
	voucher.entry_date, 
	voucher.com1_text, 
	voucher.com2_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P2B","construct-voucher-1") 

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
	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching database;  Please wait.
	LET l_query_text = "SELECT * FROM voucher,vendor ", 
	"WHERE vendor.vend_code = voucher.vend_code ", 
	" AND voucher.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'", 
	" AND vendor.cmpy_code = voucher.cmpy_code", 
	" AND voucher.paid_amt != voucher.total_amt", 
	" AND ", l_where_part clipped, 
	" ORDER BY voucher.vend_code, voucher.vouch_code" 
	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher CURSOR FOR s_voucher 
	LET l_exist = false 
	FOREACH c_voucher INTO glob_rec_voucher.*, 
		glob_rec_vendor.* 
		LET l_exist = true 
		SELECT desc_text 
		INTO l_rec_tax.desc_text 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = glob_rec_voucher.tax_code 
		SELECT desc_text 
		INTO l_rec_term.desc_text 
		FROM term 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND term_code = glob_rec_voucher.term_code 
		SELECT hold_text 
		INTO l_rec_holdpay.hold_text 
		FROM holdpay 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND hold_code = glob_rec_voucher.hold_code 
		LET l_owing_amt = glob_rec_voucher.total_amt - glob_rec_voucher.paid_amt 
		IF glob_rec_voucher.withhold_tax_ind != 0 THEN 
			IF l_owing_amt = 0 THEN 
				SELECT sum((apply_amt * tax_per) / 100) 
				INTO l_pptax_amt 
				FROM voucherpays 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND vend_code = glob_rec_voucher.vend_code 
				AND vouch_code = glob_rec_voucher.vouch_code 
			ELSE 
				CALL get_whold_tax(glob_rec_kandoouser.cmpy_code,glob_rec_voucher.vend_code, 
				glob_rec_vendor.type_code) 
				RETURNING l_withhold_tax_ind, 
				l_tax_code, 
				l_tax_per 
				CALL wtaxcalc(l_owing_amt, 
				l_tax_per, 
				l_withhold_tax_ind, glob_rec_kandoouser.cmpy_code) 
				RETURNING l_net_pay_amt, 
				l_pptax_amt 
			END IF 
		ELSE 
			LET l_pptax_amt = NULL 
		END IF 
		DISPLAY BY NAME glob_rec_vendor.currency_code 
		attribute (green) 
		DISPLAY BY NAME glob_rec_voucher.vend_code, 
		glob_rec_vendor.name_text, 
		glob_rec_voucher.vouch_code, 
		glob_rec_voucher.batch_num, 
		glob_rec_vendor.currency_code, 
		glob_rec_voucher.inv_text, 
		glob_rec_voucher.withhold_tax_ind, 
		glob_rec_voucher.vouch_date, 
		glob_rec_voucher.due_date, 
		glob_rec_voucher.conv_qty, 
		glob_rec_voucher.term_code, 
		glob_rec_voucher.tax_code, 
		glob_rec_voucher.hold_code, 
		l_rec_holdpay.hold_text, 
		glob_rec_voucher.total_amt, 
		glob_rec_voucher.dist_amt, 
		glob_rec_voucher.paid_amt, 
		glob_rec_voucher.paid_date, 
		glob_rec_voucher.disc_date, 
		glob_rec_voucher.taken_disc_amt, 
		glob_rec_voucher.poss_disc_amt, 
		glob_rec_voucher.post_flag, 
		glob_rec_voucher.year_num, 
		glob_rec_voucher.period_num, 
		glob_rec_voucher.entry_code, 
		glob_rec_voucher.entry_date, 
		glob_rec_voucher.com1_text, 
		glob_rec_voucher.com2_text 

		DISPLAY l_owing_amt, 
		l_pptax_amt, 
		l_rec_tax.desc_text, 
		l_rec_term.desc_text 
		TO owing_amt, 
		pptax_amt, 
		tax.desc_text, 
		term.desc_text 

		LET l_msgresp = kandoomsg("P",1052,"") 

		#1052 Enter Hold Code
		INPUT BY NAME glob_rec_voucher.hold_code WITHOUT DEFAULTS attributes(UNBUFFERED) 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","P2B","inp-hold_code-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "LOOKUP"
				LET glob_rec_voucher.hold_code = show_hold(glob_rec_kandoouser.cmpy_code) 
				DISPLAY BY NAME glob_rec_voucher.hold_code 
				NEXT FIELD hold_code 

				#HuHo 17.07.2019 logic did not allow to remove hold code (NULL is NOT / no longer on hold)
				#Seem to have NULL value issues with combobox in this scenario
			AFTER FIELD hold_code 
				IF glob_rec_voucher.hold_code IS NOT NULL THEN #huho 17.07.2019 - anna feedback 
					SELECT * INTO l_rec_holdpay.* FROM holdpay 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND hold_code = glob_rec_voucher.hold_code 

					IF status = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("P",9134,"") 
						#9134 Hold Pay Code NOT found - Try Window "
						NEXT FIELD hold_code 
					END IF 
					DISPLAY l_rec_holdpay.hold_text TO hold_text 
				ELSE 
					LET l_rec_holdpay.hold_code = NULL 
					LET l_rec_holdpay.hold_text = NULL 
					DISPLAY l_rec_holdpay.hold_code TO hold_code 
					DISPLAY l_rec_holdpay.hold_text TO hold_text 
				END IF 


				#HuHo 17.07.2019 logic did not allow to remove hold code (NULL is NOT / no longer on hold)
			AFTER INPUT 
				IF int_flag OR quit_flag THEN 
					EXIT INPUT 
				END IF 

				IF glob_rec_voucher.hold_code IS NOT NULL THEN #huho 17.07.2019 - anna feedback 
					SELECT * INTO l_rec_holdpay.* FROM holdpay 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND hold_code = glob_rec_voucher.hold_code 

					IF status = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("P",9134,"") 
						#9134 Hold Pay Code NOT found - Try Window "
						NEXT FIELD hold_code 
					END IF 
					DISPLAY l_rec_holdpay.hold_text TO hold_text 
				ELSE 
					LET l_rec_holdpay.hold_code = NULL 
					LET l_rec_holdpay.hold_text = NULL 
					DISPLAY l_rec_holdpay.hold_code TO hold_code 
					DISPLAY l_rec_holdpay.hold_text TO hold_text 
				END IF 

				#  IF glob_rec_voucher.hold_code IS NOT NULL
				#  AND check_payment_cycle(glob_rec_kandoouser.cmpy_code, glob_rec_voucher.vouch_code) THEN
				IF check_payment_cycle(glob_rec_kandoouser.cmpy_code, glob_rec_voucher.vouch_code) THEN 
					LET l_msgresp = kandoomsg("P",7095,"") 
					#P7095 - Auto Payment cycle in progress.
					NEXT FIELD hold_code 
				END IF 

				DISPLAY l_rec_holdpay.hold_code TO hold_code 
				DISPLAY l_rec_holdpay.hold_text TO hold_text 


		END INPUT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			EXIT FOREACH 
		ELSE 
			UPDATE voucher 
			SET hold_code = glob_rec_voucher.hold_code 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = glob_rec_voucher.vend_code 
			AND vouch_code = glob_rec_voucher.vouch_code 
		END IF 
	END FOREACH 
	IF NOT l_exist THEN 
		LET l_msgresp = kandoomsg("P",9044,"") 
		#9044  No Voucher satisfies this query"
		LET glob_rec_voucher.vend_code = NULL 
	END IF 
	RETURN true 
END FUNCTION 


############################################################
# FUNCTION check_payment_cycle(p_cmpy, p_vouch_code)
#
# RETURN TRUE IF in a payment cycle
#        FALSE IF NOT in a payment cycle
############################################################
FUNCTION check_payment_cycle(p_cmpy, p_vouch_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_vouch_code LIKE voucher.vouch_code 
	DEFINE l_cycle_num LIKE tentpays.cycle_num 

	SELECT cycle_num 
	INTO l_cycle_num 
	FROM tentpays 
	WHERE cmpy_code = p_cmpy 
	AND vouch_code = p_vouch_code 
	IF status = NOTFOUND THEN 
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 


