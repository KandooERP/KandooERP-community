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

	Source code beautified by beautify.pl on 2020-01-03 13:41:18	$Id: $
}


#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module P21a - FUNCTION 'input_voucher'  which adds vouchers
#
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P2_GLOBALS.4gl" 

# The SET up of this RECORD IS optional
# IF you require default VALUES

GLOBALS 
	DEFINE glob_rec_pa_default 	RECORD 
		term_code LIKE voucher.term_code, 
		tax_code LIKE voucher.tax_code, 
		vouch_date LIKE voucher.vouch_date, 
		year_num LIKE voucher.year_num, 
		period_num LIKE voucher.period_num 
	END RECORD 
END GLOBALS 

##################################################################################################
# FUNCTION input_voucher(p_cmpy,p_kandoouser_sign_on_code,p_vend_code,p_vouch_code,p_cheq_code)
##################################################################################################
FUNCTION input_voucher(p_cmpy,p_kandoouser_sign_on_code,p_vend_code,p_vouch_code,p_cheq_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_kandoouser_sign_on_code LIKE kandoouser.sign_on_code 
	DEFINE p_vend_code LIKE voucher.vend_code 
	DEFINE p_vouch_code LIKE voucher.vouch_code 
	DEFINE p_cheq_code LIKE cheque.cheq_code 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_holdpay RECORD LIKE holdpay.* 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_temp_text CHAR(20) 
	DEFINE l_temp_term CHAR(3) 
	DEFINE l_kandoooption LIKE kandoooption.feature_ind 
	DEFINE l_vouch_date LIKE voucher.vouch_date 
	DEFINE l_total_amt LIKE voucher.total_amt 
	DEFINE l_wth_tax_ind LIKE vendortype.withhold_tax_ind 
	DEFINE l_sundry_vend_flag CHAR(1) 
	DEFINE l_method_text CHAR(30) 
	DEFINE l_bic_text CHAR(6) 
	DEFINE l_acct_text CHAR(13) 
	DEFINE l_input_amt CHAR(5)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_mode SMALLINT #update, insert, DELETE MODE
	DEFINE l_msg STRING 
	#DEFINE name_text LIKE vendor.name_text  --test for double combo with name AND id lookup support

	IF p_vouch_code IS NULL THEN 
		LET l_mode = MODE_INSERT 
	ELSE 
		LET l_mode = MODE_UPDATE 
	END IF 

	CALL db_glparms_get_rec("1") RETURNING l_rec_glparms.* 
	IF l_rec_glparms IS NULL THEN 
		#LET l_msgresp=kandoomsg("P",5007,"")
		#P5007 " Parameters Not Found, See Menu GZP"
		EXIT PROGRAM 
	END IF 

	#   IF sqlca.sqlcode = NOTFOUND THEN
	#      LET l_msgresp=kandoomsg("P",5007,"")
	#      #P5007 " Parameters Not Found, See Menu GZP"
	#      EXIT PROGRAM
	#   END IF
	LET l_sundry_vend_flag = FALSE 

	IF p_vend_code IS NOT NULL THEN 
		CALL db_vendor_get_rec(UI_OFF,p_vend_code) RETURNING l_rec_vendor.* 
		IF l_rec_vendor IS NULL THEN 
			LET p_vend_code = NULL 
		ELSE 


			#      IF sqlca.sqlcode = NOTFOUND THEN
			#         LET p_vend_code = NULL
			#      ELSE
			LET l_rec_voucher.vend_code = l_rec_vendor.vend_code 
			LET l_rec_voucher.term_code = l_rec_vendor.term_code 
			LET l_rec_voucher.tax_code = l_rec_vendor.tax_code 
			LET l_rec_voucher.currency_code = l_rec_vendor.currency_code 
			LET l_rec_voucher.sales_text = l_rec_vendor.contact_text 
			LET l_rec_voucher.hold_code = l_rec_vendor.hold_code 

			CALL db_vendortype_get_withhold_tax_ind(l_rec_vendor.type_code) RETURNING l_rec_voucher.withhold_tax_ind 
			IF l_rec_voucher.withhold_tax_ind IS NULL THEN 
				LET l_rec_voucher.withhold_tax_ind = "0" 
			END IF 

			#Replacement by Eric
			SELECT 1 FROM bank 
			WHERE bank_code = l_rec_voucher.vend_code 
			AND cmpy_code = p_cmpy 

			#SELECT unique(1) FROM bank
			# WHERE bank_code = l_rec_voucher.vend_code
			#   AND cmpy_code = p_cmpy
			IF status != NOTFOUND THEN 
				LET l_sundry_vend_flag = TRUE 
			END IF 
		END IF 
	END IF 

	IF p_vouch_code IS NOT NULL THEN 
		CALL db_voucher_get_rec(ui_on,p_vouch_code,p_vend_code) RETURNING l_rec_voucher.* 
		IF l_rec_voucher IS NULL THEN 
			LET p_vend_code = NULL 
		END IF 

		IF l_sundry_vend_flag THEN 
			CALL db_vouchpayee_get_rec(p_vouch_code,p_vend_code) RETURNING l_rec_vouchpayee.* 

			IF l_rec_vouchpayee IS NULL THEN 
				INITIALIZE l_rec_vouchpayee.* TO NULL 
			ELSE 
				CALL fgl_winmessage("this needs checking","LET l_bic_text = l_rec_vouchpayee.bank_acct_code[1,6] LET l_acct_text = l_rec_vouchpayee.bank_acct_code[8,20]","info") 
				LET l_bic_text = l_rec_vouchpayee.bank_acct_code[1,6] 
				LET l_acct_text = l_rec_vouchpayee.bank_acct_code[8,20] 
			END IF 
		END IF 
	ELSE 
		LET l_rec_vendor.last_vouc_date = NULL 
		LET l_rec_voucher.cmpy_code = p_cmpy 
		LET l_rec_voucher.po_num = NULL 
		IF glob_rec_pa_default.vouch_date IS NULL 
		OR glob_rec_pa_default.vouch_date = '31/12/1899' THEN 
			LET l_rec_voucher.vouch_date = today 
		ELSE 
			LET l_rec_voucher.vouch_date = glob_rec_pa_default.vouch_date 
		END IF 

		IF glob_rec_pa_default.term_code IS NOT NULL THEN 
			LET l_rec_voucher.term_code = glob_rec_pa_default.term_code 
			CALL db_term_get_desc_text(UI_OFF,glob_rec_pa_default.term_code) RETURNING l_rec_term.desc_text 
			DISPLAY l_rec_term.desc_text TO term.desc_text 
		END IF 

		IF glob_rec_pa_default.tax_code IS NOT NULL THEN 
			LET l_rec_voucher.tax_code = glob_rec_pa_default.tax_code 
			CALL db_tax_get_desc_text(UI_OFF,glob_rec_pa_default.tax_code) RETURNING l_rec_tax.desc_text 
			DISPLAY l_rec_tax.desc_text TO tax.desc_text 
		END IF 

		LET l_rec_voucher.year_num = glob_rec_pa_default.year_num 
		LET l_rec_voucher.period_num = glob_rec_pa_default.period_num 

		IF ( l_rec_voucher.year_num = 0 
		AND l_rec_voucher.period_num = 0 ) 
		OR ( l_rec_voucher.year_num IS NULL 
		AND l_rec_voucher.period_num IS NULL ) THEN 
			CALL db_period_what_period(p_cmpy,l_rec_voucher.vouch_date) RETURNING l_rec_voucher.year_num, l_rec_voucher.period_num 
		END IF 

		LET l_rec_voucher.entry_code = p_kandoouser_sign_on_code 
		LET l_rec_voucher.entry_date = today 
		LET l_rec_voucher.goods_amt = 0 
		LET l_rec_voucher.tax_amt = 0 
		LET l_rec_voucher.total_amt = 0 
		LET l_rec_voucher.paid_amt = 0 
		LET l_rec_voucher.dist_qty = 0 
		LET l_rec_voucher.dist_amt = 0 
		LET l_rec_voucher.poss_disc_amt = 0 
		LET l_rec_voucher.taken_disc_amt = 0 
		LET l_rec_voucher.due_date = NULL 
		LET l_rec_voucher.disc_date = NULL 
		LET l_rec_voucher.paid_date = NULL 
		LET l_rec_voucher.post_flag = "N" 
		LET l_rec_voucher.paid_amt = 0 
		LET l_rec_voucher.post_date = NULL 
		LET l_rec_voucher.pay_seq_num = 0 
		LET l_rec_voucher.line_num = 0 
		LET l_rec_voucher.approved_code = NULL 
		LET l_rec_voucher.withhold_tax_ind = NULL 
		LET l_rec_voucher.source_ind = "1" 
	END IF 

	IF p_cheq_code IS NOT NULL THEN 
		## Voucher IS based upon an existing cheque
		CALL db_cheque_get_rec(p_vend_code,p_cheq_code) RETURNING l_rec_cheque.* 

		IF l_rec_cheque IS NULL OR l_rec_cheque.pay_meth_ind = "1" THEN 
			LET l_rec_voucher.vend_code = l_rec_cheque.vend_code 
			LET l_rec_voucher.vouch_date = l_rec_cheque.entry_date 
			LET l_rec_voucher.period_num = l_rec_cheque.period_num 
			LET l_rec_voucher.year_num = l_rec_cheque.year_num 
			LET l_rec_voucher.total_amt = l_rec_cheque.pay_amt 
			LET l_rec_voucher.conv_qty = l_rec_cheque.conv_qty 
			LET l_rec_voucher.com1_text = l_rec_cheque.com1_text 
			LET l_rec_voucher.com2_text = l_rec_cheque.com2_text 
			LET l_rec_voucher.inv_text = l_rec_cheque.com3_text 
			LET l_rec_voucher.sales_text = l_rec_cheque.com3_text 
			LET l_rec_voucher.source_ind = "3" 
			LET l_rec_voucher.source_text = l_rec_cheque.cheq_code 
			LET l_rec_voucher.withhold_tax_ind = l_rec_cheque.withhold_tax_ind 
		END IF 
	END IF 

	LET l_msgresp=kandoomsg("P",1015,"") 
	#P1015 Enter Vendor Invoice Info



	INPUT BY NAME l_rec_voucher.vend_code, 
	l_rec_voucher.inv_text, 
	l_rec_voucher.vouch_date, 
	l_rec_voucher.conv_qty, 
	l_rec_voucher.tax_code,     # order changed by ericv
	l_rec_voucher.withhold_tax_ind, 	
	l_input_amt,
	l_rec_voucher.total_amt,
	l_rec_voucher.goods_amt,
	l_rec_voucher.tax_amt,		# 20210120 added by ericv: I could not find anywhere where the tax_amt is set!
	l_rec_voucher.term_code, 
	l_rec_voucher.hold_code, 
	l_rec_voucher.due_date, 
	l_rec_voucher.disc_date, 
	l_rec_voucher.poss_disc_amt, 
	l_rec_voucher.year_num, 
	l_rec_voucher.period_num, 
	l_rec_voucher.entry_date, 
	l_rec_voucher.com1_text, 
	l_rec_voucher.com2_text WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P11a","inp-voucher-1") 
			CALL db_country_localize(db_vendor_get_country_code(UI_OFF,l_rec_voucher.vend_code)) #Localize	
			LET l_input_amt = 'gross'
			DISPLAY BY NAME l_input_amt
			DISPLAY glob_rec_kandoouser.sign_on_code TO entry_code 
			IF l_rec_voucher.vend_code IS NOT NULL THEN
				DISPLAY l_rec_voucher.post_flag TO post_flag 
				DISPLAY db_vendor_get_name_text(UI_OFF,l_rec_voucher.vend_code) TO vendor.name_text
				DISPLAY db_vendor_get_currency_code(UI_OFF,l_rec_voucher.vend_code) TO voucher.currency_code
				DISPLAY db_currency_get_desc_text(UI_OFF,l_rec_voucher.currency_code) TO currency.desc_text
				DISPLAY db_vendor_get_tax_code(UI_OFF,l_rec_voucher.vend_code)
			END IF			
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LookupVendor" 
			LET l_rec_voucher.vend_code = vendorlookup(l_rec_voucher.vend_code) 

		ON ACTION "Account Status"
		--ON KEY (F8) 
			IF l_rec_vendor.vend_code IS NOT NULL THEN 
				OPEN WINDOW p175 with FORM "P175" #attribute(BORDER,STYLE="CENTER") 
				CALL windecoration_p("P175") 

				DISPLAY BY NAME 
					l_rec_vendor.curr_amt, 
					l_rec_vendor.over1_amt, 
					l_rec_vendor.over30_amt, 
					l_rec_vendor.bal_amt, 
					l_rec_vendor.over60_amt, 
					l_rec_vendor.over90_amt, 
					l_rec_vendor.last_payment_date, 
					l_rec_vendor.last_vouc_date, 
					l_rec_vendor.last_po_date, 
					l_rec_vendor.last_debit_date 

				#LET l_msgresp = kandoomsg("U",1,"")
				CALL eventsuspend() 

				CLOSE WINDOW p175 
			ELSE 
				ERROR "You need TO define/select the vendor first (query NOT completed)" 
			END IF 

		ON ACTION "LOOKUP"infield (vend_code) 
			LET l_temp_text = show_vend(p_cmpy,l_rec_voucher.vend_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_voucher.vend_code = l_temp_text 
			END IF 
			NEXT FIELD vend_code 

		ON ACTION "LOOKUP" infield (term_code) 
			LET l_temp_text = show_term(p_cmpy) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_voucher.term_code = l_temp_text 
			END IF 
			NEXT FIELD term_code 

		ON ACTION "LOOKUP" infield (hold_code) 
			LET l_temp_text = show_hold(p_cmpy) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_voucher.hold_code = l_temp_text 
			END IF 
			NEXT FIELD hold_code 

		ON ACTION "LOOKUP" infield (tax_code) 
			LET l_temp_text = show_tax(p_cmpy) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_voucher.tax_code = l_temp_text 
			END IF 
			NEXT FIELD tax_code 

		BEFORE FIELD vend_code 
			IF p_vend_code IS NOT NULL THEN 
				DISPLAY BY NAME 
				l_rec_vendor.name_text, 
				l_rec_vendor.last_vouc_date, 
				l_rec_vendor.city_text, 
				l_rec_vendor.state_code 

				IF l_rec_voucher.post_flag = "Y" THEN 
					LET l_msgresp=kandoomsg("P",7014,"") 
					#7014 Warning: Voucher IS posted limited editing OPTIONS avail
				END IF 
				-- NEXT FIELD inv_text  # useless
			END IF 

		ON CHANGE vend_code
			CALL db_vendor_get_rec(UI_OFF,l_rec_voucher.vend_code) RETURNING l_rec_vendor.*
			CALL db_country_localize(db_vendor_get_country_code(UI_OFF,l_rec_voucher.vend_code)) #Localize		
			DISPLAY l_rec_vendor.name_text TO vendor.name_text		
			DISPLAY l_rec_vendor.city_text TO city_text
			DISPLAY l_rec_vendor.state_code TO state_code
			DISPLAY l_rec_vendor.country_code TO country_code
			#DISPLAY l_rec_voucher.post_flag TO post_flag 
			DISPLAY l_rec_vendor.currency_code TO voucher.currency_code
			DISPLAY db_currency_get_desc_text(UI_OFF,l_rec_vendor.currency_code) TO currency.desc_text
			DISPLAY l_rec_vendor.tax_code TO voucher.withhold_tax_ind
								
		AFTER FIELD vend_code 
			IF l_rec_voucher.vend_code IS NULL THEN 
				ERROR "You need to specify a vendor"
				NEXT FIELD vend_code 
			ELSE 
				LET l_rec_voucher.vend_code= trim(l_rec_voucher.vend_code) 
				IF field_touched(vend_code) THEN 
					CALL DIALOG.SetFieldTouched("vend_code", FALSE) #we do this TO support INPUT wrap - really? 
					CALL db_vendor_get_rec(UI_OFF,l_rec_voucher.vend_code) RETURNING l_rec_vendor.* 
					IF l_rec_vendor IS NULL THEN 
						LET l_msgresp=kandoomsg("P",9105,"") 
						#9105" Vendor NOT found - try window"
						NEXT FIELD vend_code 
					ELSE 
						SELECT unique(1) FROM bank 
						WHERE bank_code = l_rec_voucher.vend_code 
						AND cmpy_code = p_cmpy 

						IF status != NOTFOUND THEN 
							LET l_sundry_vend_flag = TRUE 
						ELSE 
							LET l_sundry_vend_flag = FALSE 
						END IF 

						IF glob_rec_pa_default.term_code IS NULL THEN 
							LET l_rec_voucher.term_code = l_rec_vendor.term_code 
						END IF 

						IF glob_rec_pa_default.tax_code IS NULL THEN 
							LET l_rec_voucher.tax_code = l_rec_vendor.tax_code 
						END IF 

						LET l_rec_voucher.currency_code = l_rec_vendor.currency_code 
						DISPLAY db_currency_get_desc_text(UI_OFF,l_rec_voucher.currency_code) TO currency.desc_text
						LET l_rec_voucher.sales_text = l_rec_vendor.contact_text 
						LET l_rec_voucher.hold_code = l_rec_vendor.hold_code 
						LET l_rec_voucher.conv_qty = get_conv_rate(p_cmpy,l_rec_voucher.currency_code, l_rec_voucher.vouch_date,"B") 

						CALL db_vendortype_get_withhold_tax_ind(l_rec_vendor.type_code) RETURNING l_rec_voucher.withhold_tax_ind 
						IF l_rec_voucher.withhold_tax_ind IS NULL THEN 
							LET l_rec_voucher.withhold_tax_ind = "0" 
						END IF 
					END IF 
				END IF 
			END IF 

		# ericv: general comments: BEFORE FIELD should be used at appropriate time and should not involve other fields not yet input ///
		# FIXME: all these data shoud be displayed if we are displaying a voucher, never when creating one, so this should be done out of INPUT block
		# This makes the code more unclear
		BEFORE FIELD inv_text 
			CALL db_country_localize(db_vendor_get_country_code(UI_OFF,l_rec_voucher.vend_code)) #Localize				
			DISPLAY db_term_get_desc_text(UI_OFF,l_rec_voucher.term_code) TO term.desc_text			
			DISPLAY db_tax_get_desc_text(UI_OFF,l_rec_voucher.tax_code) TO tax.desc_text
			DISPLAY db_holdpay_get_hold_text(UI_OFF,l_rec_voucher.hold_code ) TO holdpay.hold_text

			DISPLAY BY NAME l_rec_voucher.currency_code attribute(green) 

			IF l_rec_voucher.currency_code IS NOT NULL THEN 
				CALL db_currency_get_desc_text(UI_OFF,l_rec_voucher.currency_code) RETURNING l_rec_currency.desc_text 
				IF l_rec_currency IS NULL THEN 
					LET l_rec_currency.desc_text = "**********" 
				END IF 
				DISPLAY l_rec_currency.desc_text TO currency.desc_text 
			END IF 

			IF l_rec_voucher.term_code IS NOT NULL THEN 
				CALL db_term_get_rec(UI_OFF,l_rec_voucher.term_code) RETURNING l_rec_term.* 

				IF l_rec_term IS NULL THEN 
					LET l_rec_term.desc_text = "**********" 
				ELSE 
					IF p_vouch_code IS NULL AND (l_temp_term != l_rec_voucher.term_code OR l_temp_term IS null) THEN 
						LET l_temp_term = l_rec_voucher.term_code 
						CALL get_due_and_discount_date(l_rec_term.*,l_rec_voucher.vouch_date) RETURNING l_rec_voucher.due_date, l_rec_voucher.disc_date 

						IF l_rec_term.disc_day_num > 0 THEN 
							LET l_rec_voucher.poss_disc_amt = l_rec_voucher.total_amt * l_rec_term.disc_per/100 
						ELSE 
							LET l_rec_voucher.poss_disc_amt = 0 
						END IF 

					END IF 
				END IF 

				IF p_cheq_code IS NOT NULL THEN 
					## IF voucher IS based upon a cheque THEN
					## omit settlement discount calc
					LET l_rec_term.disc_per = 0 
				END IF 

				DISPLAY l_rec_term.desc_text TO term.desc_text 

				DISPLAY BY NAME l_rec_voucher.conv_qty, 
				l_rec_voucher.due_date, 
				l_rec_voucher.disc_date 
			END IF 

			IF l_rec_voucher.tax_code IS NOT NULL THEN 
				CALL db_tax_get_rec(UI_OFF,l_rec_voucher.tax_code) RETURNING l_rec_tax.* 
				IF l_rec_tax IS NULL THEN 
					LET l_rec_tax.desc_text = "**********" 
				END IF 
				DISPLAY l_rec_tax.desc_text TO tax.desc_text 
			END IF 

			IF l_rec_voucher.hold_code IS NOT NULL THEN 
				CALL db_holdpay_get_rec(l_rec_voucher.hold_code) RETURNING l_rec_holdpay.* 
				IF l_rec_holdpay IS NULL THEN 
					LET l_rec_holdpay.hold_text = "**********" 
				END IF 
				DISPLAY l_rec_holdpay.hold_text TO holdpay.hold_text 
			END IF 

		AFTER FIELD inv_text 
			IF l_rec_voucher.inv_text IS NOT NULL THEN 
				LET l_kandoooption = get_kandoooption_feature_state('AP','VI') 
				IF l_kandoooption = "Y" THEN
					IF db_vendorinvs_get_inv_text_is_used(UI_ON,l_rec_voucher.vend_code,l_rec_voucher.vouch_code,l_rec_voucher.inv_text) THEN 
						ERROR kandoomsg2("P",9023,"") 
						#P9023 " A Voucher already exists FOR the Invoice"
						IF l_kandoooption = "2" THEN 
							NEXT FIELD inv_text 
						END IF 
					END IF 
				END IF 
			END IF 

--				CASE l_kandoooption
--					WHEN '1'
--						SELECT * FROM vendorinvs
--						WHERE cmpy_code = p_cmpy
--						AND vend_code = l_rec_voucher.vend_code
--						AND vouch_code != l_rec_voucher.vouch_code
--						AND inv_text = l_rec_voucher.inv_text  # <- I can NOT believe this IS part of the PK
--
--						IF STATUS = 0 THEN
--							LET l_msgresp=kandoomsg("P",9023,"")
--							#P9023 " A Voucher already exists FOR the Invoice"
--						END IF
--
--					WHEN '2'
--						SELECT * FROM vendorinvs
--						WHERE cmpy_code = p_cmpy
--						AND vend_code = l_rec_voucher.vend_code
--						AND vouch_code != l_rec_voucher.vouch_code
--						AND inv_text = l_rec_voucher.inv_text   # <- I can NOT believe this IS part of the PK
--
--						IF STATUS = 0 THEN
--							LET l_msgresp=kandoomsg("P",9023,"")
--							#P9023 " A Voucher already exists FOR the Invoice"
--							NEXT FIELD inv_text
--						END IF
--
--					OTHERWISE
--
--				END CASE
--			END IF

		BEFORE FIELD vouch_date 
			--IF l_rec_voucher.post_flag = "Y" THEN 
			--	IF fgl_lastkey() = fgl_keyval("up") THEN 
			--		NEXT FIELD previous 
			--	ELSE 
			--		NEXT FIELD NEXT 
			--	END IF 
			--END IF 
				LET l_vouch_date = l_rec_voucher.vouch_date 

		AFTER FIELD vouch_date 
			IF l_rec_voucher.vouch_date IS NULL THEN 
				LET l_rec_voucher.vouch_date = today 
				NEXT FIELD vouch_date 
			ELSE 
				IF l_rec_voucher.vouch_date > (today + 30) THEN 
					LET l_temp_text = l_rec_voucher.vouch_date USING "dd/mm/yyyy" 
					LET l_msgresp = kandoomsg("U",9523,l_temp_text) 
				END IF 

				IF l_vouch_date <> l_rec_voucher.vouch_date THEN 
					IF p_vouch_code IS NULL AND p_cheq_code IS NULL THEN 
						CALL db_period_what_period(p_cmpy,l_rec_voucher.vouch_date) RETURNING l_rec_voucher.year_num, l_rec_voucher.period_num 
					END IF 
				END IF 

				IF NOT field_touched(conv_qty) THEN 
					LET l_rec_voucher.conv_qty = get_conv_rate(p_cmpy,l_rec_voucher.currency_code, l_rec_voucher.vouch_date,"B") 
				END IF 

				IF l_vouch_date != l_rec_voucher.vouch_date THEN 
					CALL get_due_and_discount_date(l_rec_term.*,l_rec_voucher.vouch_date) RETURNING l_rec_voucher.due_date, l_rec_voucher.disc_date 
					IF l_rec_voucher.post_flag = "N" THEN 
						IF l_rec_term.disc_day_num > 0 THEN 
							LET l_rec_voucher.poss_disc_amt = l_rec_voucher.total_amt * l_rec_term.disc_per/100 
						ELSE 
							LET l_rec_voucher.poss_disc_amt = 0 
						END IF 
					END IF 
				END IF 
			END IF 

			DISPLAY BY NAME l_rec_voucher.conv_qty, 
			l_rec_voucher.due_date, 
			l_rec_voucher.disc_date, 
			l_rec_voucher.poss_disc_amt, 
			l_rec_voucher.year_num, 
			l_rec_voucher.period_num 

		BEFORE FIELD conv_qty 
			# TODO: remove all those fglkeyval and replace by BEFORE INPUT setactivefield = false
			IF l_rec_voucher.post_flag = "Y" OR l_rec_voucher.currency_code = l_rec_glparms.base_currency_code THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			ELSE 
				IF l_rec_voucher.conv_qty = 0 THEN 
					LET l_rec_voucher.conv_qty = get_conv_rate(p_cmpy,l_rec_voucher.currency_code, l_rec_voucher.vouch_date,"B") 
				END IF 
			END IF 

		AFTER FIELD conv_qty 
			IF l_rec_voucher.conv_qty IS NULL THEN 
				LET l_rec_voucher.conv_qty = 0 
				NEXT FIELD conv_qty 
			ELSE 
				IF l_rec_voucher.conv_qty <= 0 THEN 
					LET l_msgresp=kandoomsg("P",9012,"") 
					#P9012 " Exchange Rate must be greater than zero"
					LET l_rec_voucher.conv_qty = 0 
					NEXT FIELD conv_qty 
				END IF 
			END IF 

		AFTER FIELD tax_code 
			IF l_rec_voucher.tax_code IS NULL THEN 
				LET l_rec_voucher.tax_code = l_rec_vendor.tax_code 
				NEXT FIELD tax_code 
			ELSE 
				CALL db_tax_get_rec(UI_OFF,l_rec_voucher.tax_code) RETURNING l_rec_tax.* 
				IF l_rec_tax IS NULL THEN 
					NEXT FIELD tax_code 
				ELSE 
					DISPLAY l_rec_tax.desc_text TO tax.desc_text 
				END IF 
			END IF 

			ON CHANGE tax_code
			DISPLAY db_tax_get_desc_text(UI_OFF,l_rec_voucher.tax_code) TO tax.desc_text

		BEFORE FIELD withhold_tax_ind 
			#MESSAGE l_rec_voucher.withhold_tax_ind, " AND ", l_wth_tax_ind
			CALL db_vendortype_get_withhold_tax_ind(l_rec_vendor.type_code) RETURNING l_wth_tax_ind 
				IF l_wth_tax_ind IS NULL THEN 
				LET l_wth_tax_ind = "0" 
			END IF 

			IF l_rec_voucher.post_flag = "Y" OR l_rec_voucher.paid_amt != 0 
				OR p_cheq_code IS NOT NULL 
				OR (l_rec_vendor.drop_flag IS NULL OR l_rec_vendor.drop_flag != "Y") 
				OR (l_rec_vendor.drop_flag = "Y" AND l_wth_tax_ind = "0") 	THEN 
				# TODO: replace by setfieldactive = false
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 
			#MESSAGE l_rec_voucher.withhold_tax_ind, " AND ", l_wth_tax_ind

		AFTER FIELD withhold_tax_ind 
			#MESSAGE l_rec_voucher.withhold_tax_ind, " AND ", l_wth_tax_ind
			IF l_rec_voucher.withhold_tax_ind IS NULL OR (NOT (l_rec_voucher.withhold_tax_ind matches "[0123]")) THEN 
				LET l_msgresp = kandoomsg("P",9112,"") 
				#9112 Withholding Tax Indicator must be 0, 1 ,2 OR 3
				NEXT FIELD withhold_tax_ind 
			END IF 
			#MESSAGE l_rec_voucher.withhold_tax_ind, " AND ", l_wth_tax_ind

		AFTER FIELD l_input_amt
			CASE 
					WHEN l_input_amt = "gross"
					CALL DIALOG.SetFieldActive("total_amt", true)
					CALL DIALOG.SetFieldActive("net_amt", false)
				WHEN l_input_amt = "net"
					CALL DIALOG.SetFieldActive("total_amt", false)
					CALL DIALOG.SetFieldActive("net_amt", true)
			END CASE

		BEFORE FIELD total_amt 
--			IF l_rec_voucher.post_flag = "Y" THEN 
--				IF fgl_lastkey() = fgl_keyval("up") THEN 
--					NEXT FIELD previous 
--				ELSE 
--					NEXT FIELD NEXT 
--				END IF 
--			END IF 
			LET l_total_amt = l_rec_voucher.total_amt 

		AFTER FIELD total_amt 
			CASE 
				WHEN l_rec_voucher.total_amt IS NULL 
					LET l_rec_voucher.total_amt = 0 
					NEXT FIELD total_amt 

				WHEN l_rec_voucher.total_amt < 0 
					LET l_msgresp=kandoomsg("P",9019,"") 
					#P9019" Vendors Invoice Amount Must Not be Negative"
					LET l_rec_voucher.total_amt = 0 
					NEXT FIELD total_amt 

				WHEN l_rec_voucher.total_amt = 0 
					LET l_rec_voucher.poss_disc_amt = 0 
					LET l_msgresp=kandoomsg("P",7015,"") 
					#P7015" Vendors Invoice Amount IS Zero
				OTHERWISE
			END CASE 

			IF l_rec_voucher.total_amt < l_rec_voucher.paid_amt THEN 
				LET l_msgresp=kandoomsg("P",9027,l_rec_voucher.paid_amt) 
				#P9027" Voucher paid amount excceeds voucher total"
				NEXT FIELD total_amt 
			END IF 

			IF l_rec_voucher.total_amt < l_rec_voucher.dist_amt THEN 
				LET l_msgresp=kandoomsg("P",7013,l_rec_voucher.paid_amt) 
				#P7013 " Warning: Dist amt excceeds voucher total
			END IF 

			IF l_total_amt != l_rec_voucher.total_amt THEN 
				IF l_rec_term.disc_day_num > 0 THEN 
					LET l_rec_voucher.poss_disc_amt = l_rec_voucher.total_amt * l_rec_term.disc_per/100 
				ELSE 
					LET l_rec_voucher.poss_disc_amt = 0 
				END IF 
			END IF 

			IF l_rec_voucher.post_flag <> "Y" THEN
				CALL calculate_tax_from_gross(l_rec_voucher.total_amt,l_rec_tax.tax_per,l_rec_voucher.withhold_tax_ind,glob_rec_kandoouser.cmpy_code)
				RETURNING l_rec_voucher.goods_amt,l_rec_voucher.tax_amt 
				DISPLAY BY NAME l_rec_voucher.tax_amt,l_rec_voucher.goods_amt 
			END IF
			DISPLAY BY NAME l_rec_voucher.poss_disc_amt 

		AFTER FIELD goods_amt
			IF l_rec_voucher.post_flag <> "Y" THEN
				CALL calculate_tax_from_net(l_rec_voucher.goods_amt,l_rec_tax.tax_per,l_rec_voucher.withhold_tax_ind,glob_rec_kandoouser.cmpy_code)
				RETURNING l_rec_voucher.total_amt,l_rec_voucher.tax_amt 
				DISPLAY BY NAME l_rec_voucher.tax_amt,l_rec_voucher.total_amt 					
			END IF

		BEFORE FIELD tax_amt
			IF l_rec_voucher.post_flag <> "Y" THEN
				--CASE l_input_amt
				--	WHEN "gross"
				--		CALL calculate_tax_from_gross(l_rec_voucher.total_amt,l_rec_tax.tax_per,l_rec_voucher.withhold_tax_ind,glob_rec_kandoouser.cmpy_code)
				--		RETURNING l_rec_voucher.goods_amt,l_rec_voucher.tax_amt 
				--		DISPLAY BY NAME l_rec_voucher.tax_amt,l_rec_voucher.goods_amt 
				--	WHEN "net"
				--		CALL calculate_tax_from_net(l_rec_voucher.goods_amt,l_rec_tax.tax_per,l_rec_voucher.withhold_tax_ind,glob_rec_kandoouser.cmpy_code)
				--		RETURNING l_rec_voucher.total_amt,l_rec_voucher.tax_amt 
				--		DISPLAY BY NAME l_rec_voucher.tax_amt,l_rec_voucher.total_amt 			
				--END CASE
			END IF
			
		ON CHANGE tax_amt
			CASE l_input_amt
				WHEN "gross"   # goods_amt must be modified
					LET l_rec_voucher.goods_amt = l_rec_voucher.total_amt - l_rec_voucher.tax_amt
					DISPLAY BY NAME l_rec_voucher.tax_amt,l_rec_voucher.goods_amt 
				WHEN "net"     # total_amt must be modified
					LET l_rec_voucher.total_amt = l_rec_voucher.goods_amt + l_rec_voucher.tax_amt
					DISPLAY BY NAME l_rec_voucher.tax_amt,l_rec_voucher.total_amt 			
			END CASE		
			
		AFTER FIELD due_date 
			IF l_rec_voucher.due_date IS NULL THEN 
				ERROR "Due Date must be specified" 
				CALL get_due_and_discount_date(l_rec_term.*,l_rec_voucher.vouch_date) RETURNING l_rec_voucher.due_date, l_temp_text 
				NEXT FIELD due_date 
			END IF 

			IF l_rec_voucher.due_date > (today + 366) OR l_rec_voucher.due_date < (today - 366) THEN 
				LET l_temp_text = l_rec_voucher.due_date USING "dd/mm/yyyy" 
				LET l_msgresp=kandoomsg("U",9522,l_temp_text) 
			END IF 

		AFTER FIELD disc_date 
			IF l_rec_voucher.disc_date IS NULL AND l_rec_voucher.poss_disc_amt != 0 THEN 
				IF l_rec_term.disc_day_num IS NULL THEN 
					LET l_rec_term.disc_day_num = 0 
				END IF 
				CALL get_due_and_discount_date(l_rec_term.*, l_rec_voucher.vouch_date) RETURNING l_temp_text, l_rec_voucher.disc_date 
				NEXT FIELD disc_date 
			END IF 

			IF l_rec_voucher.disc_date > (today + 366) OR l_rec_voucher.disc_date < (today - 366) THEN 
				LET l_temp_text = l_rec_voucher.disc_date USING "dd/mm/yyyy" 
				LET l_msgresp = kandoomsg("U",9522,l_temp_text) 
			END IF 

		BEFORE FIELD poss_disc_amt 
			IF l_rec_voucher.post_flag = "Y" THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD poss_disc_amt 
			IF l_rec_voucher.poss_disc_amt IS NULL THEN 
				LET l_rec_voucher.poss_disc_amt = 0 
				DISPLAY BY NAME l_rec_voucher.poss_disc_amt 

			END IF 

			IF l_rec_voucher.poss_disc_amt != 0 AND l_rec_voucher.disc_date IS NULL THEN 
				LET l_msgresp = kandoomsg("P",9530,"") 
				#9530 Discount Date must be entered WHEN a discount exists.
				NEXT FIELD disc_date 
			END IF 

		BEFORE FIELD year_num 
			IF l_rec_voucher.post_flag = "Y" THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		BEFORE FIELD period_num 
			IF l_rec_voucher.post_flag = "Y" THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD period_num 
			IF NOT valid_period2(p_cmpy,l_rec_voucher.year_num, 
			l_rec_voucher.period_num,"ap") THEN 
				LET l_msgresp=kandoomsg("P",9024,"") 
				#P9024 " Accounting period IS closed OR NOT SET up "
				NEXT FIELD year_num 
			END IF 

		ON CHANGE term_code
			DISPLAY db_term_get_desc_text(UI_OFF,l_rec_voucher.term_code) TO term.desc_text			

		BEFORE FIELD term_code 
			LET l_temp_term = l_rec_voucher.term_code 

		AFTER FIELD term_code 
			CLEAR term.desc_text 

			IF l_rec_voucher.term_code IS NULL THEN 
				LET l_rec_voucher.term_code = l_rec_vendor.term_code 
				NEXT FIELD term_code 
			ELSE 
				CALL db_term_get_rec(UI_OFF,l_rec_voucher.term_code) RETURNING l_rec_term.* 
				IF l_rec_term IS NULL THEN 
					LET l_msgresp=kandoomsg("P",9025,"") 
					#P9025" Term Code NOT found, try window"
					LET l_rec_voucher.term_code = l_rec_vendor.term_code 
					NEXT FIELD term_code 
				ELSE 
					DISPLAY l_rec_term.desc_text TO term.desc_text 

					IF p_cheq_code IS NOT NULL THEN 
						## IF voucher IS based upon a cheque THEN
						## omit settlement discount calc
						LET l_rec_term.disc_per = 0 
					END IF 

					IF l_temp_term != l_rec_voucher.term_code THEN 
						CALL get_due_and_discount_date(l_rec_term.*, l_rec_voucher.vouch_date) RETURNING l_rec_voucher.due_date, l_rec_voucher.disc_date 
						IF l_rec_voucher.post_flag = "N" THEN 
							IF l_rec_term.disc_day_num > 0 THEN 
								LET l_rec_voucher.poss_disc_amt = l_rec_voucher.total_amt * l_rec_term.disc_per/100 
							ELSE 
								LET l_rec_voucher.poss_disc_amt = 0 
							END IF 
						END IF 

						DISPLAY BY NAME 
						l_rec_voucher.due_date, 
						l_rec_voucher.disc_date, 
						l_rec_voucher.poss_disc_amt 

					END IF 
				END IF 
			END IF 

		ON CHANGE hold_code
			DISPLAY db_holdpay_get_hold_text(UI_OFF,l_rec_voucher.hold_code ) TO holdpay.hold_text

		AFTER FIELD hold_code 
			CLEAR holdpay.hold_text 
			IF l_rec_voucher.hold_code IS NULL THEN 
				LET l_rec_voucher.hold_code = l_rec_vendor.hold_code 
			ELSE 
				CALL db_holdpay_get_rec(l_rec_voucher.hold_code) RETURNING l_rec_holdpay.* 
				IF l_rec_holdpay IS NULL THEN 
					NEXT FIELD hold_code 
				ELSE 
					DISPLAY l_rec_holdpay.hold_text TO holdpay.hold_text 
				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN
			
				IF NOT db_vendor_pk_exists(UI_ON,l_rec_voucher.vend_code) THEN
					ERROR "No valid Vendor was specified"
					NEXT FIELD vend_code
				END IF
		
				IF (l_rec_voucher.total_amt IS NULL) OR (l_rec_voucher.total_amt = 0) THEN
					ERROR "No voucher amount was specified"
					NEXT FIELD total_amt
				END IF		 
				
				IF l_rec_voucher.inv_text IS NULL THEN
					LET l_msg = "You have not entered a vendor invoice reference.\nAre you sure you want to apply ?"
					IF NOT promptTF("Invoice Text is empty",l_msg,FALSE) THEN
						NEXT FIELD inv_text
					END IF
				END IF
			 
				IF l_rec_voucher.post_flag != "Y" THEN 
					IF NOT valid_period2(p_cmpy,l_rec_voucher.year_num, l_rec_voucher.period_num,"ap") THEN 
						ERROR kandoomsg2("P",9024,"") 
						#P9024 " Accounting period IS closed OR NOT SET up "
						NEXT FIELD year_num 
					END IF 
				END IF 
			END IF 
	END INPUT 

	################################

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		INITIALIZE l_rec_voucher.* TO NULL 
		INITIALIZE l_rec_vouchpayee.* TO NULL 
		RETURN l_rec_voucher.*, l_rec_vouchpayee.* 
	ELSE 
		IF NOT l_sundry_vend_flag THEN 
			RETURN l_rec_voucher.*, l_rec_vouchpayee.* 
		END IF 
	END IF 

	OPEN WINDOW p515 with FORM "P515" 
	CALL windecoration_p("P515") 

	IF l_rec_vouchpayee.vend_code IS NULL THEN 
		LET l_rec_vouchpayee.cmpy_code = p_cmpy 
		LET l_rec_vouchpayee.vend_code = l_rec_voucher.vend_code 
		LET l_rec_vouchpayee.vouch_code = l_rec_voucher.vouch_code 
	ELSE 
		LET l_method_text = kandooword("vendor.pay_meth_ind",l_rec_vouchpayee.pay_meth_ind) 
		DISPLAY l_method_text TO method_text 
	END IF 


	# ---------------------------------------------------------------------------------------
	INPUT l_rec_vouchpayee.name_text, 
		l_rec_vouchpayee.addr1_text, 
		l_rec_vouchpayee.addr2_text, 
		l_rec_vouchpayee.addr3_text, 
		l_rec_vouchpayee.city_text, 
		l_rec_vouchpayee.state_code, 
		l_rec_vouchpayee.post_code, 
		l_rec_vouchpayee.country_code, --@db-patch_2020_10_04-- 
		l_rec_vouchpayee.pay_meth_ind, 
		l_bic_text, 
		l_acct_text WITHOUT DEFAULTS
	FROM vouchpayee.name_text, 
		vouchpayee.addr1_text, 
		vouchpayee.addr2_text, 
		vouchpayee.addr3_text, 
		vouchpayee.city_text, 
		vouchpayee.state_code, 
		vouchpayee.post_code, 
		vouchpayee.country_code, --@db-patch_2020_10_04-- 
		vouchpayee.pay_meth_ind, 
		bic_text, 
		acct_text	

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P11a","inp-voucherpayee-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) infield (bic_text) 
			LET l_temp_text = show_bic() 
			IF l_temp_text IS NOT NULL THEN 
				LET l_bic_text = l_temp_text 
				NEXT FIELD bic_text 
			END IF 

		AFTER FIELD name_text 
			IF l_rec_vouchpayee.name_text IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD name_text 
			END IF 

		AFTER FIELD city_text 
			IF l_rec_vouchpayee.addr1_text IS NULL 
				AND l_rec_vouchpayee.addr2_text IS NULL 
				AND l_rec_vouchpayee.addr3_text IS NULL 
				AND l_rec_vouchpayee.city_text IS NULL THEN 
				LET l_msgresp = kandoomsg("P",9563,"") 
				#9563 AT least one of the address lines must be entered.
				NEXT FIELD addr1_text 
			END IF 

		AFTER FIELD pay_meth_ind 
			IF l_rec_vouchpayee.pay_meth_ind IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD pay_meth_ind 
			END IF 
			LET l_method_text = kandooword("vendor.pay_meth_ind",l_rec_vouchpayee.pay_meth_ind) 
			DISPLAY l_method_text TO method_text 

		AFTER FIELD acct_text 
			IF l_rec_vouchpayee.pay_meth_ind = "3" 
				AND (l_bic_text IS NULL 
				OR l_acct_text IS null) THEN 
				LET l_msgresp = kandoomsg("G",9178,"") 
				#9178 Bank/State/Branch code must NOT be blank.
				NEXT FIELD bic_text 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_vouchpayee.name_text IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered.
					NEXT FIELD name_text 
				END IF 

				IF l_rec_vouchpayee.addr1_text IS NULL 
				AND l_rec_vouchpayee.addr2_text IS NULL 
				AND l_rec_vouchpayee.addr3_text IS NULL 
				AND l_rec_vouchpayee.city_text IS NULL THEN 
					LET l_msgresp = kandoomsg("P",9563,"") 
					#9563 AT least one of the address lines must be entered.
					NEXT FIELD addr1_text 
				END IF 

				IF l_rec_vouchpayee.pay_meth_ind = "3" 
				AND (l_bic_text IS NULL OR l_acct_text IS null) THEN 
					LET l_msgresp = kandoomsg("G",9178,"") 
					#9178 Bank/State/Branch code must NOT be blank.
					NEXT FIELD bic_text 
				END IF 

			END IF 

	END INPUT 

	# ----------------------------------------------------------------------------------------

	CLOSE WINDOW p515 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		INITIALIZE l_rec_voucher.* TO NULL 
		INITIALIZE l_rec_vouchpayee.* TO NULL 
	ELSE 
		CALL fgl_winmessage("@check this","this IS may be some australian bank account code handling\nNeeds checking\nLET l_rec_vouchpayee.bank_acct_code[1,6] = l_bic_text\nLET l_rec_vouchpayee.bank_acct_code[8,20] = l_acct_text ","info") 
		LET l_rec_vouchpayee.bank_acct_code[1,6] = l_bic_text 
		LET l_rec_vouchpayee.bank_acct_code[8,20] = l_acct_text 
		LET l_rec_voucher.goods_amt = l_rec_voucher.total_amt 
		LET l_rec_voucher.tax_amt = 0 
		#Sundry Vouchers are marked with a source indicator of "S"
		LET l_rec_voucher.source_ind = "S" 
	END IF 

	RETURN l_rec_voucher.*, l_rec_vouchpayee.* 
END FUNCTION 
