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

	Source code beautified by beautify.pl on 2020-01-03 13:41:16	$Id: $
}


#
{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - P11a.4gl
#
# Purpose - Contains common routines used by vendor add/edit
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P1_GLOBALS.4gl" 
GLOBALS "P11_GLOBALS.4gl" 

############################################################
# FUNCTION process_vendor(p_prog_code,p_mode,p_vend_code)
#
#
############################################################
FUNCTION process_vendor(p_prog_code,p_mode,p_vend_code) 
	DEFINE p_prog_code CHAR(3) 
	DEFINE p_mode CHAR(4)
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE l_prompt_msg CHAR(30) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_arg1 STRING #For run URL argument	
	DEFINE l_edit_status BOOLEAN
	DEFINE l_update_status BOOLEAN
	
	CALL initialize_globals(p_mode,p_vend_code) 

	CLEAR FORM 
	CALL db_country_localize(glob_rec_country.country_code) #Localize	
	--DISPLAY glob_rec_country.state_code_text TO state_code_text 
	--DISPLAY glob_rec_country.post_code_text TO post_code_text 
	#ATTRIBUTE(white)

	WHILE TRUE 
		CALL input_vendor_main(p_mode) RETURNING l_edit_status
		IF l_edit_status = true THEN
			MENU " Vendor" 
				BEFORE MENU 
					--IF p_prog_code = "P15" THEN #huho would be nice TO know why they are hidden FOR p15 
						--HIDE option "Credit" 
						--HIDE option "Payment" 
						--HIDE option "Purchase"
					IF p_mode = MODE_CLASSIC_ADD THEN 
						HIDE option "Contractor"   # contractor has a foreign on vendor and must be created previously
					END IF
					--END IF 

					CALL publish_toolbar("kandoo","P11a","menu-vendor-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),NULL) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				ON ACTION "Save" # " Save new vendor RECORD TO the database" 
					CALL update_database(p_mode) RETURNING l_update_status
					IF l_update_status = TRUE THEN --p_mode edit OR new
						LET l_msgresp = kandoomsg("P",7032,glob_rec_vendor.vend_code) 
						#7032  "Vendor added successfully" 
						IF glob_rec_vendor.drop_flag = "Y" THEN  #
							CALL dialog.setActionHidden("Contractor",false)
						END IF
					END IF 
					EXIT MENU 

				ON ACTION "Credit" # " Enter credit information" 
					CALL input_vendor_accounts() RETURNING l_edit_status
					
				ON ACTION "Payment" # " Enter payment information" 
					#Huho 18.04.2019 we need TO support more than AU AND NZ
					#AND the user should NOT choose twice

					CASE glob_rec_vendor.country_code 
						WHEN "US" --ukraine 
							CALL edit_vendor3us() 
						WHEN "NZ" 
							CALL edit_vendor3nz() 
						WHEN "AU" 
							CALL edit_vendor3au() 
						WHEN "UA" --ukraine 
							CALL edit_vendor3ua() 

						OTHERWISE --eu default 
							CALL edit_vendor3eu() 

					END CASE 

				ON ACTION "Purchase" #" Enter purchasing information" 
					IF edit_vendor4() THEN 
					END IF 

				ON ACTION "Contractor" # Set this vendor as a contractor 
					LET l_arg1 = glob_rec_vendor.vend_code
					CALL run_prog("P91",l_arg1,"","","")

				ON ACTION "Cancel" #" RETURN TO previous SCREEN" 
					LET quit_flag = TRUE 
					EXIT MENU 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),NULL) 

			END MENU 

			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
			ELSE 
				RETURN TRUE 
			END IF 

		ELSE 
			RETURN FALSE 
		END IF 

	END WHILE 
END FUNCTION 


############################################################
# FUNCTION INITIALIZE_globals(p_mode,p_vend_code)
#
#
############################################################
FUNCTION initialize_globals(p_mode,p_vend_code) 
	DEFINE p_mode CHAR(4)
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE l_msg STRING 
	--DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_msgresp STRING 

	IF get_debug() THEN 
		DISPLAY "########### P-Modules - INITIALIZE_globals(p_mode,p_vend_code) 1 ################" 
		DISPLAY "p_mode=", p_mode 
		DISPLAY "p_vend_code=", p_vend_code 
		DISPLAY "glob_rec_kandoouser.cmpy_code = ", glob_rec_kandoouser.cmpy_code 
	END IF 


	##
	## This FUNCTION sets up the following GLOBALS variables...
	##   country, company,  glparms,  apparms,  vendor
	##
	SELECT * INTO glob_rec_company.* FROM company 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("U",5100,"") 
		#5100 Company NOT SET up; Refer TO System Administrator.
		LET l_msg = "Problem in INITIALIZE_globals(p_mode=", trim(p_mode), ",p_vend_code=", trim(p_vend_code) , ")\npr_vend_code=", trim(p_vend_code), "\nEXIT PROGRAM) #5100" 
		CALL fgl_winmessage(l_msg, l_msgresp,"error") 
		EXIT PROGRAM 
	END IF 


	IF get_debug() THEN 
		DISPLAY "########### INITIALIZE_globals(p_mode,p_vend_code) 2 ################" 
		DISPLAY "p_mode=", p_mode 
		DISPLAY "p_vend_code=", p_vend_code 
	END IF 


	SELECT * INTO glob_rec_country.* FROM country 
	WHERE country_code = glob_rec_company.country_code 

	IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("U",5127,"") 
		LET l_msg = "Problem in INITIALIZE_globals(p_mode=", trim(p_mode), ",p_vend_code=", trim(p_vend_code) , ")\npr_vend_code=", trim(p_vend_code), "\nEXIT PROGRAM) #5127" 
		CALL fgl_winmessage(l_msg, l_msgresp,"error") 
		#5127 " Country Code NOT SET up.
		EXIT PROGRAM 
	END IF 

	CALL db_glparms_get_rec("1") RETURNING glob_rec_glparms.* 
	#SELECT * INTO glob_rec_glparms.* FROM glparms
	# WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#   AND key_code = "1"
	IF glob_rec_glparms IS NULL THEN #IF sqlca.sqlcode = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("U",5107,"") 
		LET l_msg = "Problem in INITIALIZE_globals(p_mode=", trim(p_mode), ",p_vend_code=", trim(p_vend_code) , ")\npr_vend_code=", trim(p_vend_code), "\nEXIT PROGRAM) #5107" 
		CALL fgl_winmessage(l_msg, l_msgresp,"error") 

		#5107 " GL Parameters NOT SET up, see menu option GZP"
		EXIT PROGRAM 
	END IF 

	#now done in 	CALL init_p_ap() #init P/AP module
	#   SELECT * INTO pr_apparms.* FROM apparms
	#    WHERE cmpy_code = glob_rec_kandoouser.cmpy_code
	#      AND parm_code = "1"
	#
	#   IF sqlca.sqlcode = NOTFOUND THEN
	#      LET l_msgresp = kandoomsg("U",5116,"")
	#      #5116 Accounts Payable Parameters NOT SET up; Refer Menu PZP.
	#      EXIT PROGRAM
	#   END IF

--	LET glob_temp_text= glob_rec_country.state_code_text clipped,".................." 
--	LET glob_rec_country.state_code_text = glob_temp_text 
--	LET glob_temp_text = glob_rec_country.post_code_text clipped,".................." 
--	LET glob_rec_country.post_code_text = glob_temp_text 
	##
	## Code below sets up the vendor record
	##
	INITIALIZE glob_rec_vendor.* TO NULL 
	IF p_mode = "ADD" THEN 
		LET glob_rec_vendor.cmpy_code = glob_rec_company.cmpy_code 
--@db-patch_2020_10_04--		LET glob_rec_vendor.country_text = glob_rec_company.country_text 
		LET glob_rec_vendor.country_code = glob_rec_company.country_code 
		LET glob_rec_vendor.language_code = glob_rec_company.language_code 
		LET glob_rec_vendor.setup_date = today 
		LET glob_rec_vendor.last_mail_date = today 
		LET glob_rec_vendor.limit_amt = 0 
		LET glob_rec_vendor.bal_amt = 0 
		LET glob_rec_vendor.highest_bal_amt = 0 
		LET glob_rec_vendor.curr_amt = 0 
		LET glob_rec_vendor.over1_amt = 0 
		LET glob_rec_vendor.over30_amt = 0 
		LET glob_rec_vendor.over60_amt = 0 
		LET glob_rec_vendor.over90_amt = 0 
		LET glob_rec_vendor.onorder_amt = 0 
		LET glob_rec_vendor.avg_day_paid_num = 0 
		LET glob_rec_vendor.last_debit_date = NULL 
		LET glob_rec_vendor.last_po_date = NULL 
		LET glob_rec_vendor.last_vouc_date = NULL 
		LET glob_rec_vendor.last_payment_date = NULL 
		LET glob_rec_vendor.next_seq_num = 0 
		LET glob_rec_vendor.ytd_amt = 0 
		LET glob_rec_vendor.min_ord_amt = 0 
		LET glob_rec_vendor.backorder_flag = "Y" 
		LET glob_rec_vendor.drop_flag = NULL ## default SET BY vendor type 
		LET glob_rec_vendor.finance_per = 0 
		LET glob_rec_vendor.currency_code = glob_rec_glparms.base_currency_code 
		LET glob_rec_vendor.contra_meth_ind = "0" 

		DECLARE c_bank CURSOR FOR 
		SELECT bank_code FROM bank 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = glob_rec_apparms.bank_acct_code 

		OPEN c_bank 
		FETCH c_bank INTO glob_rec_vendor.bank_code 

		LET glob_rec_vendor.pay_meth_ind = "1" 
		LET glob_rec_vendor.po_var_amt = 0 
		LET glob_rec_vendor.po_var_per = 0 
		LET glob_rec_vendor.bkdetls_mod_flag = "N" 
		LET glob_rec_vendor.def_exp_ind = "G" 
	ELSE 
		SELECT * INTO glob_rec_vendor.* 
		FROM vendor 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = p_vend_code 

		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_msgresp=kandoomsg("P",9060,p_vend_code) 
			#P9060" Logic error: vendor RECORD NOT found "
		END IF 

		## SELECT below IS in CASE vendor belongs TO more than one Group
		DECLARE c0_vendorgrp CURSOR FOR 
		SELECT * FROM vendorgrp 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND vend_code = p_vend_code 

		OPEN c0_vendorgrp 
		FETCH c0_vendorgrp INTO glob_rec_vendorgrp.* 
	END IF 

	IF get_debug() = TRUE THEN 
		DISPLAY "########### INITIALIZE_globals(p_mode,p_vend_code) 2 ################" 
		DISPLAY "p_mode=", p_mode 
		DISPLAY "p_vend_code=", p_vend_code 
		DISPLAY "END OF FUNCTION" 
		DISPLAY "----------------------------------------------------------------------" 
	END IF 

END FUNCTION 


############################################################
# FUNCTION input_vendor_main(p_mode)
#
#
############################################################
FUNCTION input_vendor_main(p_mode) 
	DEFINE p_mode CHAR(4) 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	#DEFINE l_rec_holdpay RECORD LIKE holdpay.* NOT used
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_currency_code LIKE bank.currency_code 
	DEFINE l_pr_save_text CHAR(20) 
	DEFINE l_msgresp LIKE language.yes_flag 

	MESSAGE kandoomsg2("P",1043,"") #1043  Enter Vendor Information

	IF glob_rec_vendor.type_code IS NOT NULL THEN 
		SELECT type_text INTO l_rec_vendortype.type_text 
		FROM vendortype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = glob_rec_vendor.type_code 

		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_vendortype.type_text = "**********" 
		END IF 

		DISPLAY BY NAME l_rec_vendortype.type_text 
	END IF 

	IF glob_rec_vendor.term_code IS NOT NULL THEN 
		SELECT desc_text INTO l_rec_term.desc_text 
		FROM term 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND term_code = glob_rec_vendor.term_code 

		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_term.desc_text = "**********" 
		END IF 
		DISPLAY l_rec_term.desc_text TO term.desc_text 
	END IF 

	IF glob_rec_vendor.tax_code IS NOT NULL THEN 
		SELECT desc_text INTO l_rec_tax.desc_text 
		FROM tax 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND tax_code = glob_rec_vendor.tax_code 

		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_tax.desc_text = "**********" 
		END IF 

		DISPLAY l_rec_tax.desc_text TO tax.desc_text 
	END IF 

	INPUT 
	glob_rec_vendor.vend_code, 
	glob_rec_vendor.name_text, 
	glob_rec_vendor.addr1_text, 
	glob_rec_vendor.addr2_text, 
	glob_rec_vendor.addr3_text, 
	glob_rec_vendor.city_text, 
	glob_rec_vendor.state_code, 
	glob_rec_vendor.post_code, 
	glob_rec_vendor.country_code, 
--	glob_rec_vendor.country_text, 
	glob_rec_vendor.currency_code, 
	glob_rec_vendor.type_code, 
	glob_rec_vendor.term_code, 
	glob_rec_vendor.tax_code, 
	glob_rec_vendor.vat_code, 
	glob_rec_vendor.tax_incl_flag, 
	glob_rec_vendor.our_acct_code, 
	glob_rec_vendor.contact_text, 
	glob_rec_vendor.tele_text, 
	glob_rec_vendor.extension_text, 
	glob_rec_vendor.fax_text 
	WITHOUT DEFAULTS 
	FROM 
	vend_code, 
	name_text, 
	addr1_text, 
	addr2_text, 
	addr3_text, 
	city_text, 
	state_code, 
	post_code, 
	country_code, 
--	country_text, 
	currency_code, 
	type_code, 
	term_code, 
	tax_code, 
	vat_code, 
	tax_incl_flag, 
	our_acct_code, 
	contact_text, 
	tele_text, 
	extension_text, 
	fax_text 
	ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P11a","inp-vendor-1") 
			CALL fgl_dialog_setactionlabel("ACCEPT","Confirm","{CONTEXT}/public/querix/icon/svg/24/ic_check_circle_24px.svg",2,FALSE,"Confirm changes")
			CALL db_country_localize(glob_rec_vendor.country_code) #Localize
			DISPLAY db_currency_get_desc_text(UI_OFF,glob_rec_vendor.currency_code) TO currency.desc_text
	
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

			#ON ACTION "LookupVendor"
			#	LET glob_rec_vendor.vend_code = vendorLookup(glob_rec_vendor.vend_code)

		ON ACTION "LookupCoa" 
			LET glob_rec_vendor.our_acct_code = db_coa_get_lookup(glob_rec_vendor.our_acct_code) 


		ON CHANGE country_code
			CALL db_country_localize(glob_rec_vendor.country_code) #Localize

		ON CHANGE currency_code
			DISPLAY db_currency_get_desc_text(UI_OFF,glob_rec_vendor.currency_code) TO currency.desc_text

		# ericv 20210123: this acct_code is the acct_code the knows us in his own system
		# this is not an internal GL code
		# we have to be lucky to have the same account code in OUR system
		-- ON CHANGE our_acct_code
			-- DISPLAY db_coa_get_desc_text(UI_OFF,glob_rec_vendor.our_acct_code) TO coa.desc_text 

		ON ACTION "LOOKUP" infield (type_code) 
			LET glob_winds_text = show_vtyp(glob_rec_kandoouser.cmpy_code) 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.type_code = glob_winds_text 
				NEXT FIELD type_code 
			END IF 
			CALL comboList_vendorType("type_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		ON ACTION "LOOKUP" infield (term_code) 
			LET glob_winds_text = show_term(glob_rec_kandoouser.cmpy_code) 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.term_code = glob_winds_text 
				NEXT FIELD term_code 
			END IF 
			CALL comboList_termCode("term_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		ON ACTION "LOOKUP" infield (tax_code) 
			LET glob_winds_text = show_tax(glob_rec_kandoouser.cmpy_code) 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.tax_code = glob_winds_text 
				NEXT FIELD tax_code 
			END IF 
			CALL comboList_tax_code("tax_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		ON ACTION "LOOKUP" infield (currency_code) 
			LET glob_winds_text = show_curr(glob_rec_kandoouser.cmpy_code) 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.currency_code = glob_winds_text 
				NEXT FIELD currency_code 
			END IF 
			CALL comboList_currency("currency_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT) 

		ON ACTION "LOOKUP" infield (country_code) 
			LET glob_winds_text = show_country() 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.country_code = glob_winds_text 
				NEXT FIELD country_code 
			END IF 
 
			CALL combolist_country("country_code",   COMBO_FIRST_ARG_IS_VALUE,COMBO_SORT_BY_VALUE,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,NULL,COMBO_NULL_NOT)

		BEFORE FIELD vend_code 
			IF p_mode = MODE_CLASSIC_EDIT THEN 
				SELECT currency_code INTO l_currency_code FROM bank 
				WHERE bank_code = glob_rec_vendor.vend_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET glob_sundry_vend_flag = FALSE 
				ELSE 
					LET glob_sundry_vend_flag = TRUE 
				END IF 
				NEXT FIELD NEXT 
			END IF 

		AFTER FIELD vend_code 
			IF glob_rec_vendor.vend_code IS NULL THEN 
				LET l_msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD vend_code 
			END IF 

			SELECT unique 1 FROM vendor 
			WHERE vend_code = glob_rec_vendor.vend_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF STATUS = 0 THEN 
				LET l_msgresp=kandoomsg("P",9169,"") 
				SLEEP 2 
				ERROR "vend_code: ",trim(glob_rec_vendor.vend_code), "Name: ", trim(db_vendor_get_name_text(UI_OFF,glob_rec_vendor.vend_code)) 
				#P9169" Vendor ID must be unique FROM others already entered"
				NEXT FIELD vend_code 
			END IF 

			SELECT currency_code INTO l_currency_code FROM bank 
			WHERE bank_code = glob_rec_vendor.vend_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF STATUS != NOTFOUND THEN 
				LET glob_sundry_vend_flag = TRUE 
				LET glob_rec_vendor.currency_code = l_currency_code 
			ELSE 
				LET glob_sundry_vend_flag = FALSE 
			END IF 

		AFTER FIELD country_code 
--@db-patch_2020_10_04--			CLEAR vendor.country_text 
			IF glob_rec_vendor.country_code IS NULL 
			OR glob_rec_vendor.country_code = " " THEN 
				ERROR kandoomsg2("U",9102,"")	#9102 Value must be entered.
--				LET glob_rec_vendor.country_text = NULL 
				NEXT FIELD country_code 
			END IF 

--@db-patch_2020_10_04--			SELECT country_text INTO glob_rec_vendor.country_text 
--@db-patch_2020_10_04--			FROM country 
--@db-patch_2020_10_04--			WHERE country_code = glob_rec_vendor.country_code 

			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("U",9105,"")	#U9105" RECORD NOT found try window
				NEXT FIELD country_code 
			END IF 

--@db-patch_2020_10_04--			DISPLAY BY NAME glob_rec_vendor.country_text 

		BEFORE FIELD currency_code 
			## change of currency FOR vendors with transactions NOT permitted
			IF glob_rec_vendor.next_seq_num > 0 THEN 
				IF NOT get_is_screen_navigation_forward() THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			ELSE 
				LET l_pr_save_text = glob_rec_vendor.currency_code 
			END IF 

		AFTER FIELD currency_code 
			IF glob_rec_vendor.currency_code IS NULL THEN 
				LET l_msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD currency_code 
			END IF 

			SELECT unique 1 FROM currency 
			WHERE currency_code = glob_rec_vendor.currency_code 
			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("U",9105,"") 
				#U9105" RECORD NOT found try window
				NEXT FIELD currency_code 
			END IF 

			IF glob_sundry_vend_flag 
			AND glob_rec_vendor.currency_code != l_currency_code THEN 
				LET l_msgresp = kandoomsg("P",9561,"") 
				#9561 Sundry Vendor currency code must be the same as associated ..
				LET glob_rec_vendor.currency_code = l_currency_code 
				DISPLAY BY NAME glob_rec_vendor.currency_code 

			END IF 

		ON CHANGE type_code
			SELECT * INTO l_rec_vendortype.* 
			FROM vendortype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = glob_rec_vendor.type_code 

			DISPLAY BY NAME l_rec_vendortype.type_text 

		AFTER FIELD type_code 
			CLEAR vendortype.type_text 
			IF glob_rec_vendor.type_code IS NULL THEN 
				LET l_msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD type_code 
			END IF 

			SELECT * INTO l_rec_vendortype.* 
			FROM vendortype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = glob_rec_vendor.type_code 

			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("U",9105,"") 
				#U9105" RECORD NOT found try window
				NEXT FIELD type_code 
			END IF 

			IF glob_sundry_vend_flag THEN 
				SELECT unique(1) FROM vendortype 
				WHERE type_code = glob_rec_vendor.type_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND withhold_tax_ind = 0 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9562,"") 
					#9562 Sundry Vendor cannot have type that requires ...
					NEXT FIELD type_code 
				END IF 
			END IF 

			IF p_mode = "ADD" THEN 
				IF l_rec_vendortype.withhold_tax_ind = "0" THEN 
					LET glob_rec_vendor.drop_flag = "N" 
				ELSE 
					LET glob_rec_vendor.drop_flag = "Y" 
				END IF 
			END IF 

			DISPLAY BY NAME l_rec_vendortype.type_text 

		ON CHANGE term_code
			SELECT desc_text INTO l_rec_term.desc_text 
			FROM term 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND term_code = glob_rec_vendor.term_code 

			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("P",9025,"") 
				#P9025" RECORD NOT found try window
				NEXT FIELD term_code 
			ELSE 
				DISPLAY l_rec_term.desc_text TO term.desc_text 

			END IF 
		
		AFTER FIELD term_code 
			CLEAR term.desc_text 
			IF glob_rec_vendor.term_code IS NULL THEN 
				LET l_msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD term_code 
			END IF 

			SELECT desc_text INTO l_rec_term.desc_text 
			FROM term 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND term_code = glob_rec_vendor.term_code 

			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("P",9025,"") 
				#P9025" RECORD NOT found try window
				NEXT FIELD term_code 
			ELSE 
				DISPLAY l_rec_term.desc_text TO term.desc_text 

			END IF 

		ON CHANGE tax_code
			SELECT desc_text INTO l_rec_tax.desc_text 
			FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = glob_rec_vendor.tax_code 
			
			DISPLAY l_rec_tax.desc_text TO tax.desc_text
						
		AFTER FIELD tax_code 
			CLEAR tax.desc_text 
			IF glob_rec_vendor.tax_code IS NULL THEN 
				LET l_msgresp=kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD tax_code 
			END IF 

			SELECT desc_text INTO l_rec_tax.desc_text 
			FROM tax 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND tax_code = glob_rec_vendor.tax_code 

			IF sqlca.sqlcode = NOTFOUND THEN 
				LET l_msgresp=kandoomsg("P",9106,"") 
				#P9106  Tax Code NOT found, try window"
				NEXT FIELD tax_code 
			ELSE 
				DISPLAY l_rec_tax.desc_text TO tax.desc_text 

			END IF 

			#HuHo 17.04.2019 - add an exemption rule for  N/D AND ZER
			IF (glob_rec_vendor.tax_code = "N/D") OR (glob_rec_vendor.tax_code = "ZER") THEN 
				NEXT FIELD tax_incl_flag 
			END IF 

		AFTER FIELD vat_code 
			IF glob_rec_vendor.vat_code IS NOT NULL THEN 


				#HuHo 17.04.2019 - add an exemption rule for  N/D AND ZER
				IF not(glob_rec_vendor.tax_code = "N/D" OR glob_rec_vendor.tax_code = "ZER") THEN 
					IF NOT validate_vat_registration_code(glob_rec_vendor.vat_code,glob_rec_vendor.country_code) THEN 
						NEXT FIELD vat_code 
					END IF 
				END IF 

				IF p_mode = "ADD" THEN 
					DECLARE c_abn CURSOR FOR 
					SELECT * FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vat_code = glob_rec_vendor.vat_code 
					OPEN c_abn 
					FETCH c_abn 
				ELSE 
					DECLARE c_abn2 CURSOR FOR 
					SELECT * FROM vendor 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND vend_code != glob_rec_vendor.vend_code 
					AND vat_code = glob_rec_vendor.vat_code 
					OPEN c_abn2 
					FETCH c_abn2 
				END IF 

				IF STATUS != NOTFOUND THEN 
					LET l_msgresp = kandoomsg("G",9609,"") 
					#9609 ABN already exists.
					NEXT FIELD vat_code 
				END IF 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF glob_rec_vendor.vend_code IS NULL THEN 
					LET l_msgresp=kandoomsg("U",9102,"") 
					#U9102" Value required in this field"
					NEXT FIELD vend_code 
				END IF 

				IF glob_rec_vendor.country_code IS NULL THEN 
					LET l_msgresp=kandoomsg("U",9102,"") 
					#U9102" Value required in this field"
					NEXT FIELD country_code 
				END IF 

				IF glob_rec_vendor.currency_code IS NULL THEN 
					LET l_msgresp=kandoomsg("U",9102,"") 
					#U9102" Value required in this field"
					NEXT FIELD currency_code 
				END IF 

				IF glob_sundry_vend_flag 
				AND glob_rec_vendor.currency_code != l_currency_code THEN 
					LET glob_rec_vendor.currency_code = l_currency_code 
				END IF 

				IF glob_rec_vendor.type_code IS NULL THEN 
					LET l_msgresp=kandoomsg("U",9102,"") 
					#U9102" Value required in this field"
					NEXT FIELD type_code 
				END IF 
				IF glob_rec_vendor.term_code IS NULL THEN 
					LET l_msgresp=kandoomsg("U",9102,"") 
					#U9102" Value required in this field"
					NEXT FIELD term_code 
				END IF 

				IF glob_rec_vendor.tax_code IS NULL THEN 
					LET l_msgresp=kandoomsg("U",9102,"") 
					#U9102" Value required in this field"
					NEXT FIELD tax_code 
				END IF 

			END IF 


		AFTER FIELD "our_acct_code"
			DISPLAY db_coa_get_desc_text(UI_OFF,glob_rec_vendor.our_acct_code) TO coa.desc_text

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = FALSE 
		LET int_flag = FALSE 
		LET glob_rec_vendor.* = l_rec_vendor.* 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 

END FUNCTION   # input_vendor_main



############################################################
# FUNCTION input_vendor_accounts()
#
#
############################################################
FUNCTION input_vendor_accounts() 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_holdpay RECORD LIKE holdpay.* 
	DEFINE l_rec_coa RECORD LIKE coa.* 
	DEFINE l_avail_cred_amt dec(16,2) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_avail_cred_amt = glob_rec_vendor.limit_amt 
	- glob_rec_vendor.bal_amt 
	- glob_rec_vendor.onorder_amt 

	OPEN WINDOW p103 with FORM "P103" 
	CALL windecoration_p("P103") 

	IF glob_rec_vendor.hold_code IS NOT NULL THEN 
		SELECT hold_text INTO l_rec_holdpay.hold_text 
		FROM holdpay 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND hold_code = glob_rec_vendor.hold_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_holdpay.hold_text = "**********" 
		END IF 
		DISPLAY BY NAME l_rec_holdpay.hold_text 

	END IF 
	IF glob_rec_vendor.usual_acct_code IS NOT NULL THEN 
		SELECT desc_text INTO l_rec_coa.desc_text 
		FROM coa 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND acct_code = glob_rec_vendor.usual_acct_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_coa.desc_text = "**********" 
		END IF 
		DISPLAY BY NAME l_rec_coa.desc_text,glob_rec_vendor.usual_acct_code 
	END IF 
	
	DISPLAY glob_rec_vendor.vend_code TO vendor.vend_code 
	DISPLAY glob_rec_vendor.name_text TO vendor.name_text
	DISPLAY glob_rec_vendor.curr_amt TO curr_amt
	DISPLAY glob_rec_vendor.over1_amt TO over1_amt
	DISPLAY glob_rec_vendor.over30_amt TO over30_amt
	DISPLAY glob_rec_vendor.over60_amt TO over60_amt
	DISPLAY glob_rec_vendor.over90_amt TO over90_amt
	DISPLAY glob_rec_vendor.limit_amt TO limit_amt
	DISPLAY glob_rec_vendor.onorder_amt TO onorder_amt
	DISPLAY l_avail_cred_amt TO avail_cred_amt
	DISPLAY glob_rec_vendor.highest_bal_amt TO highest_bal_amt
	DISPLAY glob_rec_vendor.avg_day_paid_num TO avg_day_paid_num
	DISPLAY glob_rec_vendor.setup_date TO setup_date
	DISPLAY glob_rec_vendor.last_payment_date TO last_payment_date
	DISPLAY glob_rec_vendor.last_vouc_date TO last_vouc_date
	DISPLAY glob_rec_vendor.last_debit_date TO last_debit_date
	DISPLAY glob_rec_vendor.last_po_date TO last_po_date
	DISPLAY glob_rec_vendor.currency_code TO vendor.currency_code 
	DISPLAY db_currency_get_desc_text(UI_OFF,glob_rec_vendor.currency_code) TO currency.desc_text

	DISPLAY glob_rec_vendor.bal_amt TO sr_vendor[1].bal_amt 
	DISPLAY glob_rec_vendor.bal_amt TO sr_vendor[2].bal_amt 

	LET l_msgresp = kandoomsg("P",1043,"") 
	#1043  Enter Vendor Information
	INPUT BY NAME glob_rec_vendor.hold_code, 
		glob_rec_vendor.def_exp_ind, 
		glob_rec_vendor.usual_acct_code, 
		glob_rec_vendor.limit_amt 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P11a","inp-vendor-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) infield (hold_code) 
			LET glob_winds_text = show_hold(glob_rec_kandoouser.cmpy_code) 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.hold_code = glob_winds_text 
				NEXT FIELD hold_code 
			END IF 

		ON KEY (control-b) infield (usual_acct_code) 
			LET glob_winds_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.usual_acct_code = glob_winds_text 
				NEXT FIELD usual_acct_code 
			END IF 

		AFTER FIELD usual_acct_code 
			CLEAR coa.desc_text 
			IF glob_rec_vendor.usual_acct_code IS NOT NULL THEN 
				SELECT * INTO l_rec_coa.* FROM coa 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND acct_code = glob_rec_vendor.usual_acct_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("U",9105,"") 
					#U9105" RECORD NOT found try window
					NEXT FIELD usual_acct_code 
				END IF 
				IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_coa.acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
					NEXT FIELD usual_acct_code 
				END IF 
				DISPLAY l_rec_coa.desc_text TO coa.desc_text 

			END IF 

		ON CHANGE hold_code
			IF glob_rec_vendor.hold_code IS NOT NULL THEN 
				SELECT * INTO l_rec_holdpay.* 
				FROM holdpay 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_vendor.hold_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9026,"") 
					#P9026 Invalid Hold Payment code - Try window "
					LET glob_rec_vendor.hold_code = NULL 
					NEXT FIELD hold_code 
				END IF 
				DISPLAY BY NAME l_rec_holdpay.hold_text 

			END IF 
		
		AFTER FIELD hold_code 
			CLEAR hold_text 
			IF glob_rec_vendor.hold_code IS NOT NULL THEN 
				SELECT * INTO l_rec_holdpay.* 
				FROM holdpay 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND hold_code = glob_rec_vendor.hold_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9026,"") 
					#P9026 Invalid Hold Payment code - Try window "
					LET glob_rec_vendor.hold_code = NULL 
					NEXT FIELD hold_code 
				END IF 
				DISPLAY BY NAME l_rec_holdpay.hold_text 

			END IF 

		AFTER FIELD limit_amt 
			IF glob_rec_vendor.limit_amt IS NULL THEN 
				LET glob_rec_vendor.limit_amt = 0 
				LET l_msgresp=kandoomsg("U",9102,"") 
				#U9102" Value required in this field"
				NEXT FIELD limit_amt 
			ELSE 
				LET l_avail_cred_amt = glob_rec_vendor.limit_amt 
				- glob_rec_vendor.bal_amt 
				- glob_rec_vendor.onorder_amt 
				DISPLAY l_avail_cred_amt TO avail_cred_amt 

			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF glob_rec_vendor.usual_acct_code IS NULL THEN 
					IF get_kandoooption_feature_state("AP","VA") = "Y" THEN 
						LET l_msgresp=kandoomsg("U",9102,"") 
						#U9102" Value required in this field"
						NEXT FIELD usual_acct_code 
					END IF 
				END IF 
			END IF 



	END INPUT 

	CLOSE WINDOW P103 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET glob_rec_vendor.* = glob_rec_vendor.* 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 



############################################################
# FUNCTION edit_vendor3nz()
#
# Vendor payment details for vendors based in New Zealand
############################################################
FUNCTION edit_vendor3nz() 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_save_contra_cust_code LIKE vendor.contra_cust_code 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	#DEFINE l_rec_bic RECORD LIKE bic.* NOT used
	DEFINE l_method_text CHAR(30) 
	DEFINE l_bic_text CHAR(6) 
	DEFINE l_acct_text CHAR(11) 
	DEFINE l_acct_suf CHAR(2) 
	DEFINE l_len SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW p116a with FORM "P116NZ" 
	CALL windecoration_p("P116NZ") 

	LET l_rec_vendor.* = glob_rec_vendor.* 
	SELECT * INTO l_rec_vendortype.* FROM vendortype 
	WHERE type_code = glob_rec_vendor.type_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF glob_rec_vendor.pay_meth_ind IS NOT NULL THEN 
		LET l_method_text = kandooword("vendor.pay_meth_ind",glob_rec_vendor.pay_meth_ind) 
		DISPLAY l_method_text TO method_text 

	END IF 

	IF glob_rec_vendor.bank_code IS NOT NULL THEN 
		SELECT name_acct_text INTO l_rec_bank.name_acct_text 
		FROM bank 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_rec_vendor.bank_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_bank.name_acct_text = "**********" 
		END IF 
		DISPLAY BY NAME l_rec_bank.name_acct_text 

	END IF 

	LET l_len = length(glob_rec_vendor.bank_acct_code) 
	IF glob_rec_vendor.bank_acct_code IS NOT NULL AND l_len > 0 THEN 
		IF l_len > 6 THEN 
			LET l_bic_text = glob_rec_vendor.bank_acct_code[1,6] 
			IF l_len > 10 THEN 
				LET l_acct_text = glob_rec_vendor.bank_acct_code[8,l_len-2] 
				LET l_acct_suf = glob_rec_vendor.bank_acct_code[l_len-1,l_len] 
			ELSE 
				LET l_acct_text = glob_rec_vendor.bank_acct_code[8,10] 
			END IF 
		ELSE 
			LET l_bic_text = glob_rec_vendor.bank_acct_code[1,l_len] 
		END IF 
	END IF 

	IF glob_rec_vendor.contra_meth_ind IS NULL THEN 
		LET glob_rec_vendor.contra_meth_ind = "0" 
	END IF 

	LET l_msgresp = kandoomsg("P",1043,"") 
	#1043  Enter Vendor Information
	INPUT 
	glob_rec_vendor.pay_meth_ind, 
	glob_rec_vendor.bank_code, 
	glob_rec_vendor.drop_flag, 
	glob_rec_vendor.contra_cust_code, 
	glob_rec_vendor.contra_meth_ind, 
	l_bic_text, 
	l_acct_text, 
	l_acct_suf 
	WITHOUT DEFAULTS 
	FROM 
	pay_meth_ind, 
	bank_code, 
	drop_flag, 
	contra_cust_code, 
	contra_meth_ind, 
	bic_text, 
	acct_text, 
	acct_suf 



		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P11a","inp-vendor-3") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 
			
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) 
			RETURNING glob_winds_text, 
			glob_temp_text 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.bank_code = glob_winds_text 
				NEXT FIELD bank_code 
			END IF 
			
		ON ACTION "LOOKUP" infield (contra_cust_code) 
			LET glob_winds_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.contra_cust_code = glob_winds_text 
				NEXT FIELD contra_cust_code 
			END IF 

		ON ACTION "LOOKUP" infield (l_bic_text) 
			LET glob_winds_text = show_bic() 
			IF glob_winds_text IS NOT NULL THEN 
				LET l_bic_text = glob_winds_text 
				NEXT FIELD bic_text 
			END IF 


		AFTER FIELD pay_meth_ind 
			CLEAR l_method_text 
			IF glob_rec_vendor.pay_meth_ind IS NOT NULL THEN 
				LET l_method_text = kandooword("vendor.pay_meth_ind", 
				glob_rec_vendor.pay_meth_ind) 
				DISPLAY l_method_text TO method_text 

			END IF 

			IF glob_sundry_vend_flag 
			AND glob_rec_vendor.pay_meth_ind != "1" 
			AND glob_rec_vendor.pay_meth_ind != "2" THEN 
				LET l_msgresp = kandoomsg("P",9560,"") 
				#9560 Sundry Vendor can only have a payment method of 1 OR 2.
				NEXT FIELD pay_meth_ind 
			END IF 
			IF glob_rec_vendor.pay_meth_ind = "3" 
			AND glob_rec_vendor.currency_code != glob_rec_glparms.base_currency_code THEN 
				LET l_msgresp = kandoomsg("P",9559,"") 
				#9559 Vendor must use base currency FOR EFT Payments.
				NEXT FIELD pay_meth_ind 
			END IF 

		AFTER FIELD bank_code 
			CLEAR name_acct_text 
			IF glob_rec_vendor.bank_code IS NOT NULL THEN 
				SELECT * INTO l_rec_bank.* 
				FROM bank 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_vendor.bank_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("P",9003,"") 
					#P9003 "bank NOT found, try window"
					NEXT FIELD bank_code 
				END IF 
				DISPLAY BY NAME l_rec_bank.name_acct_text 

			END IF 

		AFTER FIELD drop_flag 
			IF l_rec_vendortype.withhold_tax_ind != "0" 
			AND glob_rec_vendor.drop_flag = "N" THEN 
				LET l_msgresp = kandoomsg("P",9102,"") 
				#9102 Withholding Tax IS payable - sub-contractor flag must be Y
				NEXT FIELD drop_flag 
			END IF 

		BEFORE FIELD contra_cust_code 
			LET l_save_contra_cust_code = glob_rec_vendor.contra_cust_code 
			INITIALIZE l_rec_customer.* TO NULL 

		AFTER FIELD contra_cust_code 
			IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
				SELECT unique 1 FROM customer 
				WHERE cust_code = glob_rec_vendor.contra_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD Not Found; Try Window.
					NEXT FIELD contra_cust_code 
				END IF 
			END IF 

			IF (l_save_contra_cust_code IS NOT NULL 
			AND glob_rec_vendor.contra_cust_code IS NULL) 
			OR l_save_contra_cust_code != glob_rec_vendor.contra_cust_code THEN 
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cust_code = l_save_contra_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF l_rec_customer.bal_amt != 0 THEN 
					LET l_msgresp = kandoomsg("P",9084,"") 
					#9084 Previous customer balance != 0
				END IF 
			END IF 

		AFTER FIELD contra_meth_ind 
			IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
				IF glob_rec_vendor.contra_meth_ind != "1" 
				AND glob_rec_vendor.contra_meth_ind != "2" THEN 
					LET l_msgresp = kandoomsg("P",9082,"") 
					#9082 Contra method must NOT be 0 WHEN customer exists
					NEXT FIELD contra_meth_ind 
				END IF 
			END IF 

			IF glob_rec_vendor.contra_cust_code IS NULL THEN 
				IF glob_rec_vendor.contra_meth_ind != "0" THEN 
					LET l_msgresp = kandoomsg("P",9083,"") 
					#9082 Contra method must be 0 WHEN customer blank
					NEXT FIELD contra_meth_ind 
				END IF 
			END IF 

		AFTER FIELD acct_text 
			IF glob_rec_vendor.pay_meth_ind = "3" 
			AND (l_bic_text IS NULL OR l_acct_text IS NULL) THEN 
				LET l_msgresp = kandoomsg("G",9178,"") 
				#9178  bic AND Account number must NOT be NULL"
				NEXT FIELD bic_text 
			END IF 

		AFTER FIELD acct_suf 
			IF glob_rec_vendor.pay_meth_ind = "3" 
			AND (l_bic_text IS NULL OR l_acct_text IS NULL OR l_acct_suf IS NULL) THEN 
				LET l_msgresp = kandoomsg("G",9178,"") 
				#9178  bic AND Account number AND suffix must NOT be NULL"
				NEXT FIELD bic_text 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT withhold_tax_ind INTO l_rec_vendortype.withhold_tax_ind 
				FROM vendortype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = glob_rec_vendor.type_code 

				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9060,"Type") 
					#P9060" Logic error: vendor type NOT found "
					CONTINUE INPUT 
				END IF 

				IF glob_sundry_vend_flag 
				AND glob_rec_vendor.pay_meth_ind != "1" 
				AND glob_rec_vendor.pay_meth_ind != "2" THEN 
					LET l_msgresp = kandoomsg("P",9560,"") 
					#9560 Sundry Vendor can only have a payment method of 1 OR 2.
					NEXT FIELD pay_meth_ind 
				END IF 

				IF l_rec_vendortype.withhold_tax_ind != "0" 
				AND glob_rec_vendor.drop_flag = "N" THEN 
					LET l_msgresp = kandoomsg("P",9102,"") 
					#9102 Withholding Tax IS payable - sub-contractor flag must be Y
					NEXT FIELD drop_flag 
				END IF 

				IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
					IF glob_rec_vendor.contra_meth_ind != "1" 
					AND glob_rec_vendor.contra_meth_ind != "2" THEN 
						LET l_msgresp = kandoomsg("P",9082,"") 
						#9082 Contra method must NOT be "0" WHEN customer exists
						NEXT FIELD contra_meth_ind 
					END IF 
				END IF 

				IF glob_rec_vendor.contra_cust_code IS NULL THEN 
					IF glob_rec_vendor.contra_meth_ind != "0" THEN 
						LET l_msgresp = kandoomsg("P",9083,"") 
						#9082 Contra method must be 0 WHEN customer blank
						NEXT FIELD contra_meth_ind 
					END IF 
				END IF 

				IF glob_rec_vendor.pay_meth_ind = "3" 
				AND (l_bic_text IS NULL OR l_acct_text IS NULL) THEN 
					LET l_msgresp = kandoomsg("G",9178,"") 
					#9178  bic must NOT be NULL
					NEXT FIELD bic_text 
				END IF 

				IF glob_rec_vendor.pay_meth_ind = "3" 
				AND glob_rec_vendor.currency_code != glob_rec_glparms.base_currency_code THEN 
					LET l_msgresp = kandoomsg("P",9559,"") 
					#9559 Vendor must use base currency FOR EFT Payments.
					NEXT FIELD pay_meth_ind 
				END IF 

				LET glob_rec_vendor.bank_acct_code = l_bic_text," ",l_acct_text clipped,l_acct_suf 
				IF (glob_rec_vendor.pay_meth_ind = "3" AND 
				l_rec_vendor.bank_acct_code != glob_rec_vendor.bank_acct_code) 
				OR (glob_rec_vendor.pay_meth_ind = "3" AND 
				l_rec_vendor.name_text != glob_rec_vendor.name_text) 
				OR (l_rec_vendor.pay_meth_ind = "1" AND 
				glob_rec_vendor.pay_meth_ind = "3") THEN 
					LET glob_rec_vendor.bkdetls_mod_flag = "Y" 
				END IF 

			END IF 



	END INPUT 

	CLOSE WINDOW p116a 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET glob_rec_vendor.* = l_rec_vendor.* 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 



############################################################
# FUNCTION edit_vendor3us()
#
# Vendor payment details for vendors based in USA
############################################################
FUNCTION edit_vendor3us() 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_save_contra_cust_code LIKE vendor.contra_cust_code 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	#DEFINE l_rec_bic RECORD LIKE bic.* NOT used
	DEFINE l_method_text CHAR(30) 
	DEFINE l_bic_text CHAR(6) 
	DEFINE l_acct_text CHAR(11) 
	DEFINE l_acct_suf CHAR(2) 
	DEFINE l_len SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW p116a with FORM "P116US" 
	CALL windecoration_p("P116US") 

	LET l_rec_vendor.* = glob_rec_vendor.* 
	SELECT * INTO l_rec_vendortype.* FROM vendortype 
	WHERE type_code = glob_rec_vendor.type_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF glob_rec_vendor.pay_meth_ind IS NOT NULL THEN 
		LET l_method_text = kandooword("vendor.pay_meth_ind",glob_rec_vendor.pay_meth_ind) 
		DISPLAY l_method_text TO method_text 

	END IF 

	IF glob_rec_vendor.bank_code IS NOT NULL THEN 
		SELECT name_acct_text INTO l_rec_bank.name_acct_text 
		FROM bank 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_rec_vendor.bank_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_bank.name_acct_text = "**********" 
		END IF 
		DISPLAY BY NAME l_rec_bank.name_acct_text 

	END IF 

	LET l_len = length(glob_rec_vendor.bank_acct_code) 
	IF glob_rec_vendor.bank_acct_code IS NOT NULL AND l_len > 0 THEN 
		IF l_len > 6 THEN 
			LET l_bic_text = glob_rec_vendor.bank_acct_code[1,6] 
			IF l_len > 10 THEN 
				LET l_acct_text = glob_rec_vendor.bank_acct_code[8,l_len-2] 
				LET l_acct_suf = glob_rec_vendor.bank_acct_code[l_len-1,l_len] 
			ELSE 
				LET l_acct_text = glob_rec_vendor.bank_acct_code[8,10] 
			END IF 
		ELSE 
			LET l_bic_text = glob_rec_vendor.bank_acct_code[1,l_len] 
		END IF 
	END IF 

	IF glob_rec_vendor.contra_meth_ind IS NULL THEN 
		LET glob_rec_vendor.contra_meth_ind = "0" 
	END IF 

	LET l_msgresp = kandoomsg("P",1043,"") 
	#1043  Enter Vendor Information
	INPUT 
	glob_rec_vendor.pay_meth_ind, 
	glob_rec_vendor.bank_code, 
	glob_rec_vendor.drop_flag, 
	glob_rec_vendor.contra_cust_code, 
	glob_rec_vendor.contra_meth_ind, 
	l_bic_text, 
	l_acct_text, 
	l_acct_suf 
	WITHOUT DEFAULTS 
	FROM 
	pay_meth_ind, 
	bank_code, 
	drop_flag, 
	contra_cust_code, 
	contra_meth_ind, 
	bic_text, 
	acct_text, 
	acct_suf 



		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P11a","inp-vendor-3") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 
		
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) 
			RETURNING glob_winds_text, 
			glob_temp_text 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.bank_code = glob_winds_text 
				NEXT FIELD bank_code 
			END IF 
		
		ON ACTION "LOOKUP" infield (contra_cust_code) 
			LET glob_winds_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.contra_cust_code = glob_winds_text 
				NEXT FIELD contra_cust_code 
			END IF 
			
		ON ACTION "LOOKUP" infield (l_bic_text) 
			LET glob_winds_text = show_bic() 
			IF glob_winds_text IS NOT NULL THEN 
				LET l_bic_text = glob_winds_text 
				NEXT FIELD bic_text 
			END IF 


		AFTER FIELD pay_meth_ind 
			CLEAR l_method_text 
			IF glob_rec_vendor.pay_meth_ind IS NOT NULL THEN 
				LET l_method_text = kandooword("vendor.pay_meth_ind", 
				glob_rec_vendor.pay_meth_ind) 
				DISPLAY l_method_text TO method_text 

			END IF 

			IF glob_sundry_vend_flag 
			AND glob_rec_vendor.pay_meth_ind != "1" 
			AND glob_rec_vendor.pay_meth_ind != "2" THEN 
				LET l_msgresp = kandoomsg("P",9560,"") 
				#9560 Sundry Vendor can only have a payment method of 1 OR 2.
				NEXT FIELD pay_meth_ind 
			END IF 
			IF glob_rec_vendor.pay_meth_ind = "3" 
			AND glob_rec_vendor.currency_code != glob_rec_glparms.base_currency_code THEN 
				LET l_msgresp = kandoomsg("P",9559,"") 
				#9559 Vendor must use base currency FOR EFT Payments.
				NEXT FIELD pay_meth_ind 
			END IF 

		AFTER FIELD bank_code 
			CLEAR name_acct_text 
			IF glob_rec_vendor.bank_code IS NOT NULL THEN 
				SELECT * INTO l_rec_bank.* 
				FROM bank 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_vendor.bank_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("P",9003,"") 
					#P9003 "bank NOT found, try window"
					NEXT FIELD bank_code 
				END IF 
				DISPLAY BY NAME l_rec_bank.name_acct_text 

			END IF 

		AFTER FIELD drop_flag 
			IF l_rec_vendortype.withhold_tax_ind != "0" 
			AND glob_rec_vendor.drop_flag = "N" THEN 
				LET l_msgresp = kandoomsg("P",9102,"") 
				#9102 Withholding Tax IS payable - sub-contractor flag must be Y
				NEXT FIELD drop_flag 
			END IF 

		BEFORE FIELD contra_cust_code 
			LET l_save_contra_cust_code = glob_rec_vendor.contra_cust_code 
			INITIALIZE l_rec_customer.* TO NULL 

		AFTER FIELD contra_cust_code 
			IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
				SELECT unique 1 
				FROM customer 
				WHERE cust_code = glob_rec_vendor.contra_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD Not Found; Try Window.
					NEXT FIELD contra_cust_code 
				END IF 
			END IF 

			IF (l_save_contra_cust_code IS NOT NULL AND glob_rec_vendor.contra_cust_code IS NULL) 
			OR l_save_contra_cust_code != glob_rec_vendor.contra_cust_code THEN 
				SELECT * INTO l_rec_customer.* 
				FROM customer 
				WHERE cust_code = l_save_contra_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF l_rec_customer.bal_amt != 0 THEN 
					LET l_msgresp = kandoomsg("P",9084,"") 
					#9084 Previous customer balance != 0
				END IF 
			END IF 

		AFTER FIELD contra_meth_ind 
			IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
				IF glob_rec_vendor.contra_meth_ind != "1" 
				AND glob_rec_vendor.contra_meth_ind != "2" THEN 
					LET l_msgresp = kandoomsg("P",9082,"") 
					#9082 Contra method must NOT be 0 WHEN customer exists
					NEXT FIELD contra_meth_ind 
				END IF 
			END IF 

			IF glob_rec_vendor.contra_cust_code IS NULL THEN 
				IF glob_rec_vendor.contra_meth_ind != "0" THEN 
					LET l_msgresp = kandoomsg("P",9083,"") 
					#9082 Contra method must be 0 WHEN customer blank
					NEXT FIELD contra_meth_ind 
				END IF 
			END IF 

		AFTER FIELD acct_text 
			IF glob_rec_vendor.pay_meth_ind = "3" 
			AND (l_bic_text IS NULL OR l_acct_text IS NULL) THEN 
				LET l_msgresp = kandoomsg("G",9178,"") 
				#9178  bic AND Account number must NOT be NULL"
				NEXT FIELD bic_text 
			END IF 

		AFTER FIELD acct_suf 
			IF glob_rec_vendor.pay_meth_ind = "3" 
			AND (l_bic_text IS NULL OR l_acct_text IS NULL OR l_acct_suf IS NULL) THEN 
				LET l_msgresp = kandoomsg("G",9178,"") 
				#9178  bic AND Account number AND suffix must NOT be NULL"
				NEXT FIELD bic_text 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT withhold_tax_ind INTO l_rec_vendortype.withhold_tax_ind 
				FROM vendortype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = glob_rec_vendor.type_code 

				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9060,"Type") 
					#P9060" Logic error: vendor type NOT found "
					CONTINUE INPUT 
				END IF 

				IF glob_sundry_vend_flag 
				AND glob_rec_vendor.pay_meth_ind != "1" 
				AND glob_rec_vendor.pay_meth_ind != "2" THEN 
					LET l_msgresp = kandoomsg("P",9560,"") 
					#9560 Sundry Vendor can only have a payment method of 1 OR 2.
					NEXT FIELD pay_meth_ind 
				END IF 

				IF l_rec_vendortype.withhold_tax_ind != "0" 
				AND glob_rec_vendor.drop_flag = "N" THEN 
					LET l_msgresp = kandoomsg("P",9102,"") 
					#9102 Withholding Tax IS payable - sub-contractor flag must be Y
					NEXT FIELD drop_flag 
				END IF 

				IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
					IF glob_rec_vendor.contra_meth_ind != "1" 
					AND glob_rec_vendor.contra_meth_ind != "2" THEN 
						LET l_msgresp = kandoomsg("P",9082,"") 
						#9082 Contra method must NOT be "0" WHEN customer exists
						NEXT FIELD contra_meth_ind 
					END IF 
				END IF 

				IF glob_rec_vendor.contra_cust_code IS NULL THEN 
					IF glob_rec_vendor.contra_meth_ind != "0" THEN 
						LET l_msgresp = kandoomsg("P",9083,"") 
						#9082 Contra method must be 0 WHEN customer blank
						NEXT FIELD contra_meth_ind 
					END IF 
				END IF 

				IF glob_rec_vendor.pay_meth_ind = "3" 
				AND (l_bic_text IS NULL OR l_acct_text IS NULL) THEN 
					LET l_msgresp = kandoomsg("G",9178,"") 
					#9178  bic must NOT be NULL
					NEXT FIELD bic_text 
				END IF 

				IF glob_rec_vendor.pay_meth_ind = "3" 
				AND glob_rec_vendor.currency_code != glob_rec_glparms.base_currency_code THEN 
					LET l_msgresp = kandoomsg("P",9559,"") 
					#9559 Vendor must use base currency FOR EFT Payments.
					NEXT FIELD pay_meth_ind 
				END IF 

				LET glob_rec_vendor.bank_acct_code = l_bic_text," ",l_acct_text clipped,l_acct_suf 
				IF (glob_rec_vendor.pay_meth_ind = "3" AND 
				l_rec_vendor.bank_acct_code != glob_rec_vendor.bank_acct_code) 
				OR (glob_rec_vendor.pay_meth_ind = "3" AND 
				l_rec_vendor.name_text != glob_rec_vendor.name_text) 
				OR (l_rec_vendor.pay_meth_ind = "1" AND 
				glob_rec_vendor.pay_meth_ind = "3") THEN 
					LET glob_rec_vendor.bkdetls_mod_flag = "Y" 
				END IF 

			END IF 



	END INPUT 

	CLOSE WINDOW p116a 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET glob_rec_vendor.* = l_rec_vendor.* 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 

############################################################
# FUNCTION edit_vendor3eu()
#
# Vendor payment details for vendors based in EU/Europe OR compatible with Europe
############################################################
FUNCTION edit_vendor3eu() 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_save_contra_cust_code LIKE vendor.contra_cust_code 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	#DEFINE l_rec_bic RECORD LIKE bic.* NOT used
	DEFINE l_method_text CHAR(30) 
	DEFINE l_bic_text CHAR(6) 
	DEFINE l_acct_text CHAR(11) 
	DEFINE l_acct_suf CHAR(2) 
	DEFINE l_len SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW p116a with FORM "P116EU" 
	CALL windecoration_p("P116EU") 

	LET l_rec_vendor.* = glob_rec_vendor.* 
	SELECT * INTO l_rec_vendortype.* FROM vendortype 
	WHERE type_code = glob_rec_vendor.type_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF glob_rec_vendor.pay_meth_ind IS NOT NULL THEN 
		LET l_method_text = kandooword("vendor.pay_meth_ind",glob_rec_vendor.pay_meth_ind) 
		DISPLAY l_method_text TO method_text 

	END IF 

	IF glob_rec_vendor.bank_code IS NOT NULL THEN 
		SELECT name_acct_text INTO l_rec_bank.name_acct_text 
		FROM bank 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_rec_vendor.bank_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_bank.name_acct_text = "**********" 
		END IF 
		DISPLAY BY NAME l_rec_bank.name_acct_text 

	END IF 

	LET l_len = length(glob_rec_vendor.bank_acct_code) 
	IF glob_rec_vendor.bank_acct_code IS NOT NULL AND l_len > 0 THEN 
		IF l_len > 6 THEN 
			LET l_bic_text = glob_rec_vendor.bank_acct_code[1,6] 
			IF l_len > 10 THEN 
				LET l_acct_text = glob_rec_vendor.bank_acct_code[8,l_len-2] 
				LET l_acct_suf = glob_rec_vendor.bank_acct_code[l_len-1,l_len] 
			ELSE 
				LET l_acct_text = glob_rec_vendor.bank_acct_code[8,10] 
			END IF 
		ELSE 
			LET l_bic_text = glob_rec_vendor.bank_acct_code[1,l_len] 
		END IF 
	END IF 

	IF glob_rec_vendor.contra_meth_ind IS NULL THEN 
		LET glob_rec_vendor.contra_meth_ind = "0" 
	END IF 

	LET l_msgresp = kandoomsg("P",1043,"") 
	#1043  Enter Vendor Information
	INPUT 
	glob_rec_vendor.pay_meth_ind, 
	glob_rec_vendor.bank_code, 
	glob_rec_vendor.drop_flag, 
	glob_rec_vendor.contra_cust_code, 
	glob_rec_vendor.contra_meth_ind, 
	l_bic_text, 
	l_acct_text, 
	l_acct_suf 
	WITHOUT DEFAULTS 
	FROM 
	pay_meth_ind, 
	bank_code, 
	drop_flag, 
	contra_cust_code, 
	contra_meth_ind, 
	bic_text, 
	acct_text, 
	acct_suf 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P11a","inp-vendor-3") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) 
			RETURNING glob_winds_text, 
			glob_temp_text 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.bank_code = glob_winds_text 
				NEXT FIELD bank_code 
			END IF 
		
		ON ACTION "LOOKUP" infield (contra_cust_code) 
			LET glob_winds_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.contra_cust_code = glob_winds_text 
				NEXT FIELD contra_cust_code 
			END IF 
		
		ON ACTION "LOOKUP" infield (bic_text) 
			LET glob_winds_text = show_bic() 
			IF glob_winds_text IS NOT NULL THEN 
				LET l_bic_text = glob_winds_text 
				NEXT FIELD bic_text 
			END IF 


		AFTER FIELD pay_meth_ind 
			CLEAR l_method_text 
			IF glob_rec_vendor.pay_meth_ind IS NOT NULL THEN 
				LET l_method_text = kandooword("vendor.pay_meth_ind", 
				glob_rec_vendor.pay_meth_ind) 
				DISPLAY l_method_text TO method_text 

			END IF 

			IF glob_sundry_vend_flag 
			AND glob_rec_vendor.pay_meth_ind != "1" 
			AND glob_rec_vendor.pay_meth_ind != "2" THEN 
				LET l_msgresp = kandoomsg("P",9560,"") 
				#9560 Sundry Vendor can only have a payment method of 1 OR 2.
				NEXT FIELD pay_meth_ind 
			END IF 
			IF glob_rec_vendor.pay_meth_ind = "3" 
			AND glob_rec_vendor.currency_code != glob_rec_glparms.base_currency_code THEN 
				LET l_msgresp = kandoomsg("P",9559,"") 
				#9559 Vendor must use base currency FOR EFT Payments.
				NEXT FIELD pay_meth_ind 
			END IF 

		AFTER FIELD bank_code 
			CLEAR name_acct_text 
			IF glob_rec_vendor.bank_code IS NOT NULL THEN 
				SELECT * INTO l_rec_bank.* 
				FROM bank 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_vendor.bank_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("P",9003,"") 
					#P9003 "bank NOT found, try window"
					NEXT FIELD bank_code 
				END IF 
				DISPLAY BY NAME l_rec_bank.name_acct_text 

			END IF 

		AFTER FIELD drop_flag 
			IF l_rec_vendortype.withhold_tax_ind != "0" 
			AND glob_rec_vendor.drop_flag = "N" THEN 
				LET l_msgresp = kandoomsg("P",9102,"") 
				#9102 Withholding Tax IS payable - sub-contractor flag must be Y
				NEXT FIELD drop_flag 
			END IF 

		BEFORE FIELD contra_cust_code 
			LET l_save_contra_cust_code = glob_rec_vendor.contra_cust_code 
			INITIALIZE l_rec_customer.* TO NULL 

		AFTER FIELD contra_cust_code 
			IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
				SELECT unique 1 FROM customer 
				WHERE cust_code = glob_rec_vendor.contra_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD Not Found; Try Window.
					NEXT FIELD contra_cust_code 
				END IF 
			END IF 

			IF (l_save_contra_cust_code IS NOT NULL 
			AND glob_rec_vendor.contra_cust_code IS NULL) 
			OR l_save_contra_cust_code != glob_rec_vendor.contra_cust_code THEN 
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cust_code = l_save_contra_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF l_rec_customer.bal_amt != 0 THEN 
					LET l_msgresp = kandoomsg("P",9084,"") 
					#9084 Previous customer balance != 0
				END IF 
			END IF 

		AFTER FIELD contra_meth_ind 
			IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
				IF glob_rec_vendor.contra_meth_ind != "1" 
				AND glob_rec_vendor.contra_meth_ind != "2" THEN 
					LET l_msgresp = kandoomsg("P",9082,"") 
					#9082 Contra method must NOT be 0 WHEN customer exists
					NEXT FIELD contra_meth_ind 
				END IF 
			END IF 

			IF glob_rec_vendor.contra_cust_code IS NULL THEN 
				IF glob_rec_vendor.contra_meth_ind != "0" THEN 
					LET l_msgresp = kandoomsg("P",9083,"") 
					#9082 Contra method must be 0 WHEN customer blank
					NEXT FIELD contra_meth_ind 
				END IF 
			END IF 

		AFTER FIELD acct_text 
			IF glob_rec_vendor.pay_meth_ind = "3" 
			AND (l_bic_text IS NULL OR l_acct_text IS NULL) THEN 
				LET l_msgresp = kandoomsg("G",9178,"") 
				#9178  bic AND Account number must NOT be NULL"
				NEXT FIELD bic_text 
			END IF 

		AFTER FIELD acct_suf 
			IF glob_rec_vendor.pay_meth_ind = "3" 
			AND (l_bic_text IS NULL OR l_acct_text IS NULL OR l_acct_suf IS NULL) THEN 
				LET l_msgresp = kandoomsg("G",9178,"") 
				#9178  bic AND Account number AND suffix must NOT be NULL"
				NEXT FIELD bic_text 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT withhold_tax_ind INTO l_rec_vendortype.withhold_tax_ind 
				FROM vendortype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = glob_rec_vendor.type_code 

				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9060,"Type") 
					#P9060" Logic error: vendor type NOT found "
					CONTINUE INPUT 
				END IF 

				IF glob_sundry_vend_flag 
				AND glob_rec_vendor.pay_meth_ind != "1" 
				AND glob_rec_vendor.pay_meth_ind != "2" THEN 
					LET l_msgresp = kandoomsg("P",9560,"") 
					#9560 Sundry Vendor can only have a payment method of 1 OR 2.
					NEXT FIELD pay_meth_ind 
				END IF 

				IF l_rec_vendortype.withhold_tax_ind != "0" 
				AND glob_rec_vendor.drop_flag = "N" THEN 
					LET l_msgresp = kandoomsg("P",9102,"") 
					#9102 Withholding Tax IS payable - sub-contractor flag must be Y
					NEXT FIELD drop_flag 
				END IF 

				IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
					IF glob_rec_vendor.contra_meth_ind != "1" 
					AND glob_rec_vendor.contra_meth_ind != "2" THEN 
						LET l_msgresp = kandoomsg("P",9082,"") 
						#9082 Contra method must NOT be "0" WHEN customer exists
						NEXT FIELD contra_meth_ind 
					END IF 
				END IF 

				IF glob_rec_vendor.contra_cust_code IS NULL THEN 
					IF glob_rec_vendor.contra_meth_ind != "0" THEN 
						LET l_msgresp = kandoomsg("P",9083,"") 
						#9082 Contra method must be 0 WHEN customer blank
						NEXT FIELD contra_meth_ind 
					END IF 
				END IF 

				IF glob_rec_vendor.pay_meth_ind = "3" 
				AND (l_bic_text IS NULL OR l_acct_text IS NULL) THEN 
					LET l_msgresp = kandoomsg("G",9178,"") 
					#9178  bic must NOT be NULL
					NEXT FIELD bic_text 
				END IF 

				IF glob_rec_vendor.pay_meth_ind = "3" 
				AND glob_rec_vendor.currency_code != glob_rec_glparms.base_currency_code THEN 
					LET l_msgresp = kandoomsg("P",9559,"") 
					#9559 Vendor must use base currency FOR EFT Payments.
					NEXT FIELD pay_meth_ind 
				END IF 

				LET glob_rec_vendor.bank_acct_code = l_bic_text," ",l_acct_text clipped,l_acct_suf 
				IF (glob_rec_vendor.pay_meth_ind = "3" AND 
				l_rec_vendor.bank_acct_code != glob_rec_vendor.bank_acct_code) 
				OR (glob_rec_vendor.pay_meth_ind = "3" AND 
				l_rec_vendor.name_text != glob_rec_vendor.name_text) 
				OR (l_rec_vendor.pay_meth_ind = "1" AND 
				glob_rec_vendor.pay_meth_ind = "3") THEN 
					LET glob_rec_vendor.bkdetls_mod_flag = "Y" 
				END IF 

			END IF 



	END INPUT 

	CLOSE WINDOW p116a 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET glob_rec_vendor.* = l_rec_vendor.* 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 



############################################################
# FUNCTION edit_vendor3ua()
#
# Vendor payment details for vendors based in Ukraine
############################################################
FUNCTION edit_vendor3ua() #ukraine
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_save_contra_cust_code LIKE vendor.contra_cust_code 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	#DEFINE l_rec_bic RECORD LIKE bic.* NOT used
	DEFINE l_method_text CHAR(30) 
	DEFINE l_bic_text LIKE vendor.bic_code --CHAR(6) 
	DEFINE l_acct_text LIKE vendor.iban_code  --CHAR(11) 
	DEFINE l_acct_suf CHAR(2) 
	DEFINE l_len SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW p116a with FORM "P116UA" 
	CALL windecoration_p("P116UA") 

	LET l_rec_vendor.* = glob_rec_vendor.* 
	SELECT * INTO l_rec_vendortype.* FROM vendortype 
	WHERE type_code = glob_rec_vendor.type_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF glob_rec_vendor.pay_meth_ind IS NOT NULL THEN 
		LET l_method_text = kandooword("vendor.pay_meth_ind",glob_rec_vendor.pay_meth_ind) 
		DISPLAY l_method_text TO method_text 

	END IF 

	IF glob_rec_vendor.bank_code IS NOT NULL THEN 
		SELECT name_acct_text INTO l_rec_bank.name_acct_text 
		FROM bank 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_rec_vendor.bank_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_bank.name_acct_text = "**********" 
		END IF 
		DISPLAY BY NAME l_rec_bank.name_acct_text 

	END IF 

	LET l_len = length(glob_rec_vendor.bank_acct_code) 
	IF glob_rec_vendor.bank_acct_code IS NOT NULL AND l_len > 0 THEN 
		IF l_len > 6 THEN 
			LET l_bic_text = glob_rec_vendor.bank_acct_code[1,6] 
			IF l_len > 10 THEN 
				LET l_acct_text = glob_rec_vendor.bank_acct_code[8,l_len-2] 
				LET l_acct_suf = glob_rec_vendor.bank_acct_code[l_len-1,l_len] 
			ELSE 
				LET l_acct_text = glob_rec_vendor.bank_acct_code[8,10] 
			END IF 
		ELSE 
			LET l_bic_text = glob_rec_vendor.bank_acct_code[1,l_len] 
		END IF 
	END IF 

	IF glob_rec_vendor.contra_meth_ind IS NULL THEN 
		LET glob_rec_vendor.contra_meth_ind = "0" 
	END IF 

	LET l_msgresp = kandoomsg("P",1043,"") 
	#1043  Enter Vendor Information
	INPUT 
	glob_rec_vendor.pay_meth_ind, 
	glob_rec_vendor.bank_code, 
	glob_rec_vendor.drop_flag, 
	glob_rec_vendor.contra_cust_code, 
	glob_rec_vendor.contra_meth_ind, 
	l_bic_text, 
	l_acct_text, 
	l_acct_suf 
	WITHOUT DEFAULTS 
	FROM 
	pay_meth_ind, 
	bank_code, 
	drop_flag, 
	contra_cust_code, 
	contra_meth_ind, 
	bic_text, 
	acct_text, 
	acct_suf 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P11a","inp-vendor-3") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL)
			 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) 
			RETURNING glob_winds_text, 
			glob_temp_text 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.bank_code = glob_winds_text 
				NEXT FIELD bank_code 
			END IF 

		ON ACTION "LOOKUP" infield (contra_cust_code) 
			LET glob_winds_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.contra_cust_code = glob_winds_text 
				NEXT FIELD contra_cust_code 
			END IF 

		ON ACTION "LOOKUP" infield (bic_text) 
			LET glob_winds_text = show_bic() 
			IF glob_winds_text IS NOT NULL THEN 
				LET l_bic_text = glob_winds_text 
				NEXT FIELD bic_text 
			END IF 

		AFTER FIELD pay_meth_ind 
			CLEAR l_method_text 
			IF glob_rec_vendor.pay_meth_ind IS NOT NULL THEN 
				LET l_method_text = kandooword("vendor.pay_meth_ind", 
				glob_rec_vendor.pay_meth_ind) 
				DISPLAY l_method_text TO method_text 

			END IF 

			IF glob_sundry_vend_flag 
			AND glob_rec_vendor.pay_meth_ind != "1" 
			AND glob_rec_vendor.pay_meth_ind != "2" THEN 
				LET l_msgresp = kandoomsg("P",9560,"") 
				#9560 Sundry Vendor can only have a payment method of 1 OR 2.
				NEXT FIELD pay_meth_ind 
			END IF 
			IF glob_rec_vendor.pay_meth_ind = "3" 
			AND glob_rec_vendor.currency_code != glob_rec_glparms.base_currency_code THEN 
				LET l_msgresp = kandoomsg("P",9559,"") 
				#9559 Vendor must use base currency FOR EFT Payments.
				NEXT FIELD pay_meth_ind 
			END IF 

		AFTER FIELD bank_code 
			CLEAR name_acct_text 
			IF glob_rec_vendor.bank_code IS NOT NULL THEN 
				SELECT * INTO l_rec_bank.* 
				FROM bank 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_vendor.bank_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("P",9003,"") 
					#P9003 "bank NOT found, try window"
					NEXT FIELD bank_code 
				END IF 
				DISPLAY BY NAME l_rec_bank.name_acct_text 

			END IF 

		AFTER FIELD drop_flag 
			IF l_rec_vendortype.withhold_tax_ind != "0" 
			AND glob_rec_vendor.drop_flag = "N" THEN 
				LET l_msgresp = kandoomsg("P",9102,"") 
				#9102 Withholding Tax IS payable - sub-contractor flag must be Y
				NEXT FIELD drop_flag 
			END IF 

		BEFORE FIELD contra_cust_code 
			LET l_save_contra_cust_code = glob_rec_vendor.contra_cust_code 
			INITIALIZE l_rec_customer.* TO NULL 

		AFTER FIELD contra_cust_code 
			IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
				SELECT unique 1 FROM customer 
				WHERE cust_code = glob_rec_vendor.contra_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD Not Found; Try Window.
					NEXT FIELD contra_cust_code 
				END IF 
			END IF 

			IF (l_save_contra_cust_code IS NOT NULL 
			AND glob_rec_vendor.contra_cust_code IS NULL) 
			OR l_save_contra_cust_code != glob_rec_vendor.contra_cust_code THEN 
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cust_code = l_save_contra_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF l_rec_customer.bal_amt != 0 THEN 
					LET l_msgresp = kandoomsg("P",9084,"") 
					#9084 Previous customer balance != 0
				END IF 
			END IF 

		AFTER FIELD contra_meth_ind 
			IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
				IF glob_rec_vendor.contra_meth_ind != "1" 
				AND glob_rec_vendor.contra_meth_ind != "2" THEN 
					LET l_msgresp = kandoomsg("P",9082,"") 
					#9082 Contra method must NOT be 0 WHEN customer exists
					NEXT FIELD contra_meth_ind 
				END IF 
			END IF 

			IF glob_rec_vendor.contra_cust_code IS NULL THEN 
				IF glob_rec_vendor.contra_meth_ind != "0" THEN 
					LET l_msgresp = kandoomsg("P",9083,"") 
					#9082 Contra method must be 0 WHEN customer blank
					NEXT FIELD contra_meth_ind 
				END IF 
			END IF 

		AFTER FIELD acct_text 
			IF glob_rec_vendor.pay_meth_ind = "3" 
			AND (l_bic_text IS NULL OR l_acct_text IS NULL) THEN 
				LET l_msgresp = kandoomsg("G",9178,"") 
				#9178  bic AND Account number must NOT be NULL"
				NEXT FIELD bic_text 
			END IF 

		AFTER FIELD acct_suf 
			IF glob_rec_vendor.pay_meth_ind = "3" 
			AND (l_bic_text IS NULL OR l_acct_text IS NULL OR l_acct_suf IS NULL) THEN 
				LET l_msgresp = kandoomsg("G",9178,"") 
				#9178  bic AND Account number AND suffix must NOT be NULL"
				NEXT FIELD bic_text 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT withhold_tax_ind INTO l_rec_vendortype.withhold_tax_ind 
				FROM vendortype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = glob_rec_vendor.type_code 

				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9060,"Type") 
					#P9060" Logic error: vendor type NOT found "
					CONTINUE INPUT 
				END IF 

				IF glob_sundry_vend_flag 
				AND glob_rec_vendor.pay_meth_ind != "1" 
				AND glob_rec_vendor.pay_meth_ind != "2" THEN 
					LET l_msgresp = kandoomsg("P",9560,"") 
					#9560 Sundry Vendor can only have a payment method of 1 OR 2.
					NEXT FIELD pay_meth_ind 
				END IF 

				IF l_rec_vendortype.withhold_tax_ind != "0" 
				AND glob_rec_vendor.drop_flag = "N" THEN 
					LET l_msgresp = kandoomsg("P",9102,"") 
					#9102 Withholding Tax IS payable - sub-contractor flag must be Y
					NEXT FIELD drop_flag 
				END IF 

				IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
					IF glob_rec_vendor.contra_meth_ind != "1" 
					AND glob_rec_vendor.contra_meth_ind != "2" THEN 
						LET l_msgresp = kandoomsg("P",9082,"") 
						#9082 Contra method must NOT be "0" WHEN customer exists
						NEXT FIELD contra_meth_ind 
					END IF 
				END IF 

				IF glob_rec_vendor.contra_cust_code IS NULL THEN 
					IF glob_rec_vendor.contra_meth_ind != "0" THEN 
						LET l_msgresp = kandoomsg("P",9083,"") 
						#9082 Contra method must be 0 WHEN customer blank
						NEXT FIELD contra_meth_ind 
					END IF 
				END IF 

				IF glob_rec_vendor.pay_meth_ind = "3" 
				AND (l_bic_text IS NULL OR l_acct_text IS NULL) THEN 
					LET l_msgresp = kandoomsg("G",9178,"") 
					#9178  bic must NOT be NULL
					NEXT FIELD bic_text 
				END IF 

				IF glob_rec_vendor.pay_meth_ind = "3" 
				AND glob_rec_vendor.currency_code != glob_rec_glparms.base_currency_code THEN 
					LET l_msgresp = kandoomsg("P",9559,"") 
					#9559 Vendor must use base currency FOR EFT Payments.
					NEXT FIELD pay_meth_ind 
				END IF 

				LET glob_rec_vendor.bank_acct_code = l_bic_text," ",l_acct_text clipped,l_acct_suf 
				IF (glob_rec_vendor.pay_meth_ind = "3" AND 
				l_rec_vendor.bank_acct_code != glob_rec_vendor.bank_acct_code) 
				OR (glob_rec_vendor.pay_meth_ind = "3" AND 
				l_rec_vendor.name_text != glob_rec_vendor.name_text) 
				OR (l_rec_vendor.pay_meth_ind = "1" AND 
				glob_rec_vendor.pay_meth_ind = "3") THEN 
					LET glob_rec_vendor.bkdetls_mod_flag = "Y" 
				END IF 

			END IF 



	END INPUT 

	CLOSE WINDOW p116a 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET glob_rec_vendor.* = l_rec_vendor.* 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 


############################################################
# FUNCTION edit_vendor3au()
#
# Vendor payment details for Australia based vendors
############################################################
FUNCTION edit_vendor3au() 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_customer RECORD LIKE customer.* 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_save_contra_cust_code LIKE vendor.contra_cust_code 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	#DEFINE pr_bic RECORD LIKE bic.*
	DEFINE l_method_text CHAR(30) 
	DEFINE l_bic_text CHAR(6) 
	DEFINE l_acct_text CHAR(13) 
	DEFINE l_len SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 


	OPEN WINDOW p116 with FORM "P116AU" 
	CALL windecoration_p("P116AU") 

	LET l_rec_vendor.* = glob_rec_vendor.* 
	SELECT * INTO l_rec_vendortype.* FROM vendortype 
	WHERE type_code = glob_rec_vendor.type_code 
	AND cmpy_code = glob_rec_kandoouser.cmpy_code 

	IF glob_rec_vendor.pay_meth_ind IS NOT NULL THEN 
		LET l_method_text = kandooword("vendor.pay_meth_ind",glob_rec_vendor.pay_meth_ind) 
		DISPLAY l_method_text TO method_text 

	END IF 

	IF glob_rec_vendor.bank_code IS NOT NULL THEN 
		SELECT name_acct_text INTO l_rec_bank.name_acct_text 
		FROM bank 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND bank_code = glob_rec_vendor.bank_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_bank.name_acct_text = "**********" 
		END IF 
		DISPLAY BY NAME l_rec_bank.name_acct_text 

	END IF 

	LET l_len = length(glob_rec_vendor.bank_acct_code) 

	IF glob_rec_vendor.bank_acct_code IS NOT NULL AND l_len > 0 THEN 
		IF l_len > 6 THEN 
			LET l_bic_text = glob_rec_vendor.bank_acct_code[1,6] 
			IF l_len > 7 THEN 
				LET l_acct_text = glob_rec_vendor.bank_acct_code[8,l_len] 
			END IF 
		ELSE 
			LET l_bic_text = glob_rec_vendor.bank_acct_code[1,l_len] 
		END IF 
	END IF 
	IF glob_rec_vendor.contra_meth_ind IS NULL THEN 
		LET glob_rec_vendor.contra_meth_ind = "0" 
	END IF 

	LET l_msgresp = kandoomsg("P",1043,"") 
	#1043  Enter Vendor Information
	INPUT 
	glob_rec_vendor.pay_meth_ind, 
	glob_rec_vendor.bank_code, 
	glob_rec_vendor.drop_flag, 
	glob_rec_vendor.contra_cust_code, 
	glob_rec_vendor.contra_meth_ind, 
	l_bic_text, 
	l_acct_text 
	WITHOUT DEFAULTS 
	FROM 
	pay_meth_ind, 
	bank_code, 
	drop_flag, 
	contra_cust_code, 
	contra_meth_ind, 
	bic_text, 
	acct_text 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P11a","inp-vendor-4") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (bank_code) 
			CALL show_bank(glob_rec_kandoouser.cmpy_code) 
			RETURNING glob_winds_text, 
			glob_temp_text 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.bank_code = glob_winds_text 
				NEXT FIELD bank_code 
			END IF 
			
		ON ACTION "LOOKUP"infield (contra_cust_code) 
			LET glob_winds_text = show_clnt(glob_rec_kandoouser.cmpy_code) 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.contra_cust_code = glob_winds_text 
				NEXT FIELD contra_cust_code 
			END IF 

		ON ACTION "LOOKUP" infield (l_bic_text) 
			LET glob_winds_text = show_bic() 
			IF glob_winds_text IS NOT NULL THEN 
				LET l_bic_text = glob_winds_text 
				NEXT FIELD bic_text 
			END IF 


		AFTER FIELD pay_meth_ind 
			CLEAR l_method_text 
			IF glob_rec_vendor.pay_meth_ind IS NOT NULL THEN 
				LET l_method_text = kandooword("vendor.pay_meth_ind", 
				glob_rec_vendor.pay_meth_ind) 
				DISPLAY l_method_text TO method_text 

			END IF 
			IF glob_sundry_vend_flag 
			AND glob_rec_vendor.pay_meth_ind != "1" 
			AND glob_rec_vendor.pay_meth_ind != "2" THEN 
				LET l_msgresp = kandoomsg("P",9560,"") 
				#9560 Sundry Vendor can only have a payment method of 1 OR 2.
				NEXT FIELD pay_meth_ind 
			END IF 
			IF glob_rec_vendor.pay_meth_ind = "3" 
			AND glob_rec_vendor.currency_code != glob_rec_glparms.base_currency_code THEN 
				LET l_msgresp = kandoomsg("P",9559,"") 
				#9559 Vendor must use base currency FOR EFT Payments.
				NEXT FIELD pay_meth_ind 
			END IF 

		AFTER FIELD bank_code 
			CLEAR name_acct_text 
			IF glob_rec_vendor.bank_code IS NOT NULL THEN 
				SELECT * INTO l_rec_bank.* 
				FROM bank 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = glob_rec_vendor.bank_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("P",9003,"") 
					#P9003 "bank NOT found, try window"
					NEXT FIELD bank_code 
				END IF 
				DISPLAY BY NAME l_rec_bank.name_acct_text 

			END IF 

		AFTER FIELD drop_flag 
			IF l_rec_vendortype.withhold_tax_ind != "0" 
			AND glob_rec_vendor.drop_flag = "N" THEN 
				LET l_msgresp = kandoomsg("P",9102,"") 
				#9102 Withholding Tax IS payable - sub-contractor flag must be Y
				NEXT FIELD drop_flag 
			END IF 

		BEFORE FIELD contra_cust_code 
			LET l_save_contra_cust_code = glob_rec_vendor.contra_cust_code 
			INITIALIZE l_rec_customer.* TO NULL 

		AFTER FIELD contra_cust_code 
			IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
				SELECT unique 1 FROM customer 
				WHERE cust_code = glob_rec_vendor.contra_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#9105 RECORD Not Found; Try Window.
					NEXT FIELD contra_cust_code 
				END IF 
			END IF 

			IF (l_save_contra_cust_code IS NOT NULL 
			AND glob_rec_vendor.contra_cust_code IS NULL) 
			OR l_save_contra_cust_code != glob_rec_vendor.contra_cust_code THEN 
				SELECT * INTO l_rec_customer.* FROM customer 
				WHERE cust_code = l_save_contra_cust_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
				IF l_rec_customer.bal_amt != 0 THEN 
					LET l_msgresp = kandoomsg("P",9084,"") 
					#9084 Previous customer balance != 0
				END IF 
			END IF 

		AFTER FIELD contra_meth_ind 
			IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
				IF glob_rec_vendor.contra_meth_ind != "1" 
				AND glob_rec_vendor.contra_meth_ind != "2" THEN 
					LET l_msgresp = kandoomsg("P",9082,"") 
					#9082 Contra method must NOT be 0 WHEN customer exists
					NEXT FIELD contra_meth_ind 
				END IF 
			END IF 

			IF glob_rec_vendor.contra_cust_code IS NULL THEN 
				IF glob_rec_vendor.contra_meth_ind != "0" THEN 
					LET l_msgresp = kandoomsg("P",9083,"") 
					#9082 Contra method must be 0 WHEN customer blank
					NEXT FIELD contra_meth_ind 
				END IF 
			END IF 

		
		AFTER FIELD acct_text
			IF glob_rec_vendor.pay_meth_ind = "3" 
			AND (l_bic_text IS NULL OR l_acct_text IS NULL) THEN 
				LET l_msgresp = kandoomsg("G",9178,"") 
				#9178  bic AND Account number must NOT be NULL"
				NEXT FIELD _bic_text 
			END IF 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				SELECT withhold_tax_ind INTO l_rec_vendortype.withhold_tax_ind 
				FROM vendortype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = glob_rec_vendor.type_code 

				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp=kandoomsg("P",9060,"Type") 
					#P9060" Logic error: vendor type NOT found "
					CONTINUE INPUT 
				END IF 

				IF glob_sundry_vend_flag 
				AND glob_rec_vendor.pay_meth_ind != "1" 
				AND glob_rec_vendor.pay_meth_ind != "2" THEN 
					LET l_msgresp = kandoomsg("P",9560,"") 
					#9560 Sundry Vendor can only have a payment method of 1 OR 2.
					NEXT FIELD pay_meth_ind 
				END IF 

				IF l_rec_vendortype.withhold_tax_ind != "0" 
				AND glob_rec_vendor.drop_flag = "N" THEN 
					LET l_msgresp = kandoomsg("P",9102,"") 
					#9102 Withholding Tax IS payable - sub-contractor flag must be Y
					NEXT FIELD drop_flag 
				END IF 

				IF glob_rec_vendor.contra_cust_code IS NOT NULL THEN 
					IF glob_rec_vendor.contra_meth_ind != "1" 
					AND glob_rec_vendor.contra_meth_ind != "2" THEN 
						LET l_msgresp = kandoomsg("P",9082,"") 
						#9082 Contra method must NOT be "0" WHEN customer exists
						NEXT FIELD contra_meth_ind 
					END IF 
				END IF 

				IF glob_rec_vendor.contra_cust_code IS NULL THEN 
					IF glob_rec_vendor.contra_meth_ind != "0" THEN 
						LET l_msgresp = kandoomsg("P",9083,"") 
						#9082 Contra method must be 0 WHEN customer blank
						NEXT FIELD contra_meth_ind 
					END IF 
				END IF 

				IF glob_rec_vendor.pay_meth_ind = "3" 
				AND (l_bic_text IS NULL OR l_acct_text IS NULL) THEN 
					LET l_msgresp = kandoomsg("G",9178,"") 
					#9178  bic must NOT be NULL
					NEXT FIELD bic_text 
				END IF 

				IF glob_rec_vendor.pay_meth_ind = "3" 
				AND glob_rec_vendor.currency_code != glob_rec_glparms.base_currency_code THEN 
					LET l_msgresp = kandoomsg("P",9559,"") 
					#9559 Vendor must use base currency FOR EFT Payments.
					NEXT FIELD pay_meth_ind 
				END IF 

				LET glob_rec_vendor.bank_acct_code = l_bic_text," ",l_acct_text 
				IF (glob_rec_vendor.pay_meth_ind = "3" AND 
				l_rec_vendor.bank_acct_code != glob_rec_vendor.bank_acct_code) 
				OR (glob_rec_vendor.pay_meth_ind = "3" AND 
				l_rec_vendor.name_text != glob_rec_vendor.name_text) 
				OR (l_rec_vendor.pay_meth_ind = "1" AND 
				glob_rec_vendor.pay_meth_ind = "3") THEN 
					LET glob_rec_vendor.bkdetls_mod_flag = "Y" 
				END IF 

			END IF 


	END INPUT 

	CLOSE WINDOW p116 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET glob_rec_vendor.* = l_rec_vendor.* 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 
END FUNCTION 




############################################################
# FUNCTION edit_vendor4()
#
#
############################################################
FUNCTION edit_vendor4() 
	DEFINE l_rec_s_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_purchtype RECORD LIKE purchtype.* 
	DEFINE l_rec_s_vendorgrp RECORD LIKE vendorgrp.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW p118 with FORM "P118" 
	CALL windecoration_p("P118") 

	LET l_rec_s_vendor.* = glob_rec_vendor.* 
	LET l_rec_s_vendorgrp.* = glob_rec_vendorgrp.* 

	DISPLAY BY NAME glob_rec_vendor.currency_code 
	#ATTRIBUTE(green)

	IF glob_rec_vendor.purchtype_code IS NOT NULL THEN 
		SELECT desc_text INTO l_rec_purchtype.desc_text FROM purchtype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND purchtype_code = glob_rec_vendor.purchtype_code 
		IF sqlca.sqlcode = NOTFOUND THEN 
			LET l_rec_purchtype.desc_text = "**********" 
		END IF 
		DISPLAY BY NAME l_rec_purchtype.desc_text 

	END IF 

	IF glob_rec_vendorgrp.vend_code = glob_rec_vendor.vend_code THEN 
		DISPLAY glob_rec_vendorgrp.desc_text TO vendorgrp.desc_text 

	END IF 

	LET l_msgresp = kandoomsg("P",1043,"") 
	#1043  Enter Vendor Information
	INPUT 
	glob_rec_vendor.purchtype_code, 
	glob_rec_vendor.backorder_flag, 
	glob_rec_vendor.min_ord_amt, 
	glob_rec_vendor.po_var_amt, 
	glob_rec_vendor.po_var_per, 
	glob_rec_vendorgrp.mast_vend_code 
	WITHOUT DEFAULTS 
	FROM 
	purchtype_code, 
	backorder_flag, 
	min_ord_amt, 
	po_var_amt, 
	po_var_per, 
	mast_vend_code 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P11a","inp-vendor-5") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 
		
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield (purchtype_code) 
			LET glob_winds_text = show_purchtype(glob_rec_kandoouser.cmpy_code,"") 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendor.purchtype_code = glob_winds_text 
				NEXT FIELD purchtype_code 
			END IF 

		ON ACTION "LOOKUP" infield (mast_vend_code) 
			LET glob_winds_text = show_vendgrp(glob_rec_kandoouser.cmpy_code,"") 
			IF glob_winds_text IS NOT NULL THEN 
				LET glob_rec_vendorgrp.mast_vend_code = glob_winds_text 
				NEXT FIELD mast_vend_code 
			END IF 


		AFTER FIELD purchtype_code 
			CLEAR purchtype.desc_text 
			IF glob_rec_vendor.purchtype_code IS NOT NULL THEN 
				SELECT * INTO l_rec_purchtype.* FROM purchtype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND purchtype_code = glob_rec_vendor.purchtype_code 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#U9105 "purchtype NOT found, try window"
					NEXT FIELD purchtype_code 
				END IF 
				DISPLAY BY NAME l_rec_purchtype.desc_text 

			END IF 

		AFTER FIELD min_ord_amt 
			IF glob_rec_vendor.min_ord_amt IS NULL THEN 
				LET glob_rec_vendor.min_ord_amt = 0 
				DISPLAY BY NAME glob_rec_vendor.min_ord_amt 

			END IF 
			IF glob_rec_vendor.min_ord_amt < 0 THEN 
				LET l_msgresp = kandoomsg("U",9907,"0") 
				#9907 Value must be >= 0
				LET glob_rec_vendor.min_ord_amt = 0 
				NEXT FIELD min_ord_amt 
			END IF 

		AFTER FIELD po_var_amt 
			CASE 
				WHEN glob_rec_vendor.po_var_amt IS NULL 
					LET l_msgresp = kandoomsg("U",9102,"") 
					LET glob_rec_vendor.po_var_amt = 0 
					NEXT FIELD po_var_amt 
				WHEN glob_rec_vendor.po_var_amt < 0 
					LET l_msgresp = kandoomsg("U",9109,"") 
					LET glob_rec_vendor.po_var_amt = 0 
					NEXT FIELD po_var_amt 
			END CASE 

		AFTER FIELD po_var_per 
			CASE 
				WHEN glob_rec_vendor.po_var_per IS NULL 
					LET l_msgresp = kandoomsg("U",9102,"") 
					LET glob_rec_vendor.po_var_per = 0 
					NEXT FIELD po_var_per 
				WHEN glob_rec_vendor.po_var_per < 0 
					LET l_msgresp = kandoomsg("U",9109,"") 
					LET glob_rec_vendor.po_var_per = 0 
					NEXT FIELD po_var_per 
			END CASE 

		BEFORE FIELD mast_vend_code 
			SELECT unique 1 FROM vendorgrp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND mast_vend_code = glob_rec_vendor.vend_code 
			IF STATUS = 0 THEN 
				error" Vendor IS master creditor of group - TO alter refer RZ4" 
				NEXT FIELD previous 
			END IF 

		AFTER FIELD mast_vend_code 
			CLEAR vendorgrp.desc_text 
			IF glob_rec_vendorgrp.mast_vend_code IS NULL THEN 
				INITIALIZE glob_rec_vendorgrp.* TO NULL 
			ELSE 
				DECLARE c_vendorgrp CURSOR FOR 
				SELECT * FROM vendorgrp 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND mast_vend_code = glob_rec_vendorgrp.mast_vend_code 
				OPEN c_vendorgrp 
				FETCH c_vendorgrp INTO glob_rec_vendorgrp.* 
				IF sqlca.sqlcode = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",9105,"") 
					#U9105 "record NOT found, try window"
					NEXT FIELD mast_vend_code 
				END IF 
				LET glob_rec_vendorgrp.vend_code = glob_rec_vendor.vend_code 
				DISPLAY glob_rec_vendorgrp.desc_text TO vendorgrp.desc_text 

				SLEEP 1 ## included as its the LAST FIELD ON the screen 
			END IF 

	END INPUT 

	CLOSE WINDOW p118 

	IF int_flag OR quit_flag THEN 
		LET int_flag = FALSE 
		LET quit_flag = FALSE 
		LET glob_rec_vendor.* = l_rec_s_vendor.* 
		LET glob_rec_vendorgrp.* = l_rec_s_vendorgrp.* 
		RETURN FALSE 
	ELSE 
		RETURN TRUE 
	END IF 

END FUNCTION 



############################################################
# FUNCTION update_database(p_mode)
#
#
############################################################
FUNCTION update_database(p_mode) 
	DEFINE p_mode CHAR(4) 
	DEFINE l_err_message STRING 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp=kandoomsg("P",1005,"") 
	#1005 Updating database - please wait

	BEGIN WORK 
		IF p_mode = "ADD" THEN 
			LET l_err_message = "P11 - Inserting new vendor record" 
			INSERT INTO vendor VALUES (glob_rec_vendor.*) 
		ELSE 
			## Important: Only UPDATE fields that may change
			LET l_err_message = "P11 - Updating vendor record" 
			UPDATE vendor 
			SET name_text = glob_rec_vendor.name_text, 
			addr1_text = glob_rec_vendor.addr1_text, 
			addr2_text = glob_rec_vendor.addr2_text, 
			addr3_text = glob_rec_vendor.addr3_text, 
			city_text = glob_rec_vendor.city_text, 
			state_code = glob_rec_vendor.state_code, 
			post_code = glob_rec_vendor.post_code, 
			country_code = glob_rec_vendor.country_code, 
--@db-patch_2020_10_04--			country_text = glob_rec_vendor.country_text, 
			our_acct_code = glob_rec_vendor.our_acct_code, 
			fax_text = glob_rec_vendor.fax_text, 
			type_code = glob_rec_vendor.type_code, 
			term_code = glob_rec_vendor.term_code, 
			tax_code = glob_rec_vendor.tax_code, 
			vat_code = glob_rec_vendor.vat_code, 
			tax_incl_flag = glob_rec_vendor.tax_incl_flag, 
			drop_flag = glob_rec_vendor.drop_flag, 
			pay_meth_ind = glob_rec_vendor.pay_meth_ind, 
			contact_text = glob_rec_vendor.contact_text, 
			tele_text = glob_rec_vendor.tele_text, 
			extension_text = glob_rec_vendor.extension_text, 
			bank_acct_code = glob_rec_vendor.bank_acct_code, 
			bank_code = glob_rec_vendor.bank_code, 
			bkdetls_mod_flag = glob_rec_vendor.bkdetls_mod_flag, 
			purchtype_code = glob_rec_vendor.purchtype_code, 
			min_ord_amt = glob_rec_vendor.min_ord_amt, 
			currency_code = glob_rec_vendor.currency_code, 
			backorder_flag = glob_rec_vendor.backorder_flag, 
			hold_code = glob_rec_vendor.hold_code, 
			def_exp_ind = glob_rec_vendor.def_exp_ind, 
			usual_acct_code = glob_rec_vendor.usual_acct_code, 
			limit_amt = glob_rec_vendor.limit_amt, 
			po_var_amt = glob_rec_vendor.po_var_amt, 
			po_var_per = glob_rec_vendor.po_var_per, 
			contra_meth_ind = glob_rec_vendor.contra_meth_ind, 
			contra_cust_code = glob_rec_vendor.contra_cust_code 
			WHERE vend_code = glob_rec_vendor.vend_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 

			DELETE FROM vendorgrp 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND mast_vend_code = glob_rec_vendorgrp.mast_vend_code
			AND vend_code = glob_rec_vendor.vend_code 
			IF glob_rec_vendorgrp.mast_vend_code IS NOT NULL THEN 
				LET glob_rec_vendorgrp.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET glob_rec_vendorgrp.vend_code = glob_rec_vendor.vend_code 
				INSERT INTO vendorgrp VALUES (glob_rec_vendorgrp.*) 
			END IF 
		END IF 
	COMMIT WORK 
 
	IF p_mode = "ADD" THEN
		LET l_err_message = "New Vendor Record """,glob_rec_vendor.vend_code CLIPPED,""" Add Successful."
--		LET l_err_message = "New Vendor Record """,glob_rec_vendor.name_text CLIPPED,""" Add Successful."
	ELSE
		LET l_err_message = "Vendor Record """,glob_rec_vendor.vend_code CLIPPED,""" Update Successful."
--		LET l_err_message = "Vendor Record """,glob_rec_vendor.name_text CLIPPED,""" Update Successful."
	END IF
	CALL msgcontinue("",l_err_message)

	RETURN TRUE 

END FUNCTION 
