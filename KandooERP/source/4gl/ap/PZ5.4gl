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

	Source code beautified by beautify.pl on 2020-01-03 13:41:51	$Id: $
}

{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com,a.bondar@querix.com
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 

FUNCTION PZ5_whenever_sqlerror ()
	# this code instanciates the default sql errors handling for all the code lines below this function
	# it is a compiler preprocessor instruction. It is not necessary to execute that function
	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION


############################################################
# MAIN
#
# \brief module PZ5  This Program allows the user TO enter AND maintain Vendor Types
############################################################
MAIN 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_arr_rec_vendortype DYNAMIC ARRAY OF 
	RECORD 
		type_code LIKE vendortype.type_code, 
		type_text LIKE vendortype.type_text 
	END RECORD 
	DEFINE l_msgtext STRING 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_cnt INTEGER
	DEFINE l_idx SMALLINT 

	DEFER QUIT 
	DEFER INTERRUPT 

	#Initial UI Init
	CALL setModuleId("PZ5") 
	CALL ui_init(0) 
	CALL authenticate(getmoduleid()) #authenticate 
--	CALL init_p_ap() #init p/ap module #PZ5 configurations is required for PZP 

	OPEN WINDOW P166 WITH FORM "P166"
	CALL windecoration_p("P166") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 
	MESSAGE kandoomsg2("U",1003,"") 

	CALL db_vendortype_get_arr_rec() RETURNING l_arr_rec_vendortype 

	DISPLAY ARRAY l_arr_rec_vendortype TO sr_vendortype.* 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","PZ5","inp-arr-vendortype-1")
			CALL dialog.setActionHidden("CANCEL",TRUE)
			CALL fgl_dialog_setactionlabel("EXIT","Exit","{CONTEXT}/public/querix/icon/svg/24/ic_cancel_24px.svg",1,FALSE,"Exit")

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "DELETE" 
			LET l_idx = arr_curr()
			IF l_idx > 0 THEN
				SELECT COUNT(*) INTO l_cnt FROM vendor
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND
						type_code = l_arr_rec_vendortype[l_idx].type_code
				IF l_cnt > 0 THEN
					#let msgresp=maxmsg("P",9575,"")
					#9575 Vendor type is currently being used by vendor(s).
					LET l_msgtext = "Vendor type is currently being used by vendor(s).\nDeletion NOT Permitted."
					CALL msgerror("",l_msgtext)
					CONTINUE DISPLAY
				ELSE 
					LET l_msgtext = "Confirmation to delete Vendor Type?"
					IF promptTF("",l_msgtext,0) THEN
						DELETE FROM vendortype
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND
								type_code = l_arr_rec_vendortype[l_idx].type_code
						CALL db_vendortype_get_arr_rec() RETURNING l_arr_rec_vendortype
					END IF
				END IF
			END IF

		ON ACTION ("EDIT","DOUBLECLICK") 
			LET l_idx = arr_curr()
			IF l_idx > 0 THEN 
				IF change_vendtype(l_arr_rec_vendortype[l_idx].type_code) THEN 
					CALL db_vendortype_get_arr_rec() RETURNING l_arr_rec_vendortype 
				END IF 
			END IF 

		ON ACTION "NEW" 
			IF add_vendtype() THEN 
				CALL db_vendortype_get_arr_rec() RETURNING l_arr_rec_vendortype 
			END IF 

		ON ACTION "EXIT"
			EXIT DISPLAY

	END DISPLAY 

	CLOSE WINDOW P166 

END MAIN 


############################################################
# FUNCTION add_vendtype()
#
#
############################################################
FUNCTION add_vendtype() 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_vendor_found SMALLINT 
	DEFINE l_vendor_type LIKE vendor.type_code 
	DEFINE l_vendor_tax_ind LIKE vendortype.withhold_tax_ind 
	DEFINE l_vendor_currency LIKE vendor.currency_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_ret_acct_code LIKE coa.acct_code
	DEFINE i SMALLINT 

	OPEN WINDOW p174 WITH FORM "P174"
	CALL windecoration_p("P174")

	CLEAR FORM

	LET l_rec_vendortype.cmpy_code = glob_rec_kandoouser.cmpy_code 

	# Convert ComboBoxes to TextFields via dynamic morphing function
	CALL Convert_ComboBox_To_TextField("pay_acct_code")
	CALL Convert_ComboBox_To_TextField("freight_acct_code")
	CALL Convert_ComboBox_To_TextField("salestax_acct_code")	
	CALL Convert_ComboBox_To_TextField("disc_acct_code")
	CALL Convert_ComboBox_To_TextField("exch_acct_code")

	MESSAGE kandoomsg2("P",1567,"") 
	#1567 Enter Vendor Type details; OK TO continue.
	INPUT BY NAME	l_rec_vendortype.type_code, 
						l_rec_vendortype.type_text, 
						l_rec_vendortype.withhold_tax_ind, 
						l_rec_vendortype.tax_vend_code, 
						l_rec_vendortype.pay_acct_code, 
						l_rec_vendortype.freight_acct_code, 
						l_rec_vendortype.salestax_acct_code, 
						l_rec_vendortype.disc_acct_code, 
						l_rec_vendortype.exch_acct_code ATTRIBUTE(UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PZ5","inp-vendortype-1") 
			DISPLAY l_rec_vendortype.type_code TO type_code 
			DISPLAY db_withhold_tax_ind_get_desc_text(l_rec_vendortype.withhold_tax_ind) TO withhold_tax_ind_desc_text 
			DISPLAY db_vendor_get_name_text(UI_OFF,l_rec_vendortype.tax_vend_code) TO name_text 

		BEFORE FIELD tax_vend_code
			IF l_rec_vendortype.withhold_tax_ind = "0" THEN
				IF fgl_lastkey() = fgl_keyval("TAB") OR
					fgl_lastkey() = fgl_keyval("DOWN") OR 
					fgl_lastkey() = fgl_keyval("RIGHT") OR
					fgl_lastkey() = fgl_keyval("RETURN") THEN
					NEXT FIELD NEXT 
				ELSE 
					NEXT FIELD PREVIOUS 
				END IF
			END IF

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP" infield(tax_vend_code) 
			LET l_rec_vendortype.tax_vend_code = show_vend(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.tax_vend_code) 
			DISPLAY BY NAME l_rec_vendortype.tax_vend_code
			DISPLAY db_vendor_get_name_text(UI_OFF,l_rec_vendortype.tax_vend_code) TO name_text

		ON ACTION "LOOKUP" infield(pay_acct_code) 
			CALL show_acct(glob_rec_kandoouser.cmpy_code)RETURNING l_ret_acct_code
			IF l_ret_acct_code IS NOT NULL THEN
				LET l_rec_vendortype.pay_acct_code = l_ret_acct_code 
			END IF
			CALL display_desc(1,l_rec_vendortype.*) 

		ON ACTION "LOOKUP" infield(freight_acct_code) 
			CALL show_acct(glob_rec_kandoouser.cmpy_code)RETURNING l_ret_acct_code
			IF l_ret_acct_code IS NOT NULL THEN
				LET l_rec_vendortype.freight_acct_code = l_ret_acct_code  
			END IF
			CALL display_desc(2,l_rec_vendortype.*) 

		ON ACTION "LOOKUP" infield(salestax_acct_code) 
			CALL show_acct(glob_rec_kandoouser.cmpy_code)RETURNING l_ret_acct_code
			IF l_ret_acct_code IS NOT NULL THEN
				LET l_rec_vendortype.salestax_acct_code = l_ret_acct_code
			END IF 
			CALL display_desc(3,l_rec_vendortype.*) 

		ON ACTION "LOOKUP" infield(disc_acct_code) 
			CALL show_acct(glob_rec_kandoouser.cmpy_code)RETURNING l_ret_acct_code
			IF l_ret_acct_code IS NOT NULL THEN
				LET l_rec_vendortype.disc_acct_code = l_ret_acct_code
			END IF 
			CALL display_desc(4,l_rec_vendortype.*) 

		ON ACTION "LOOKUP" infield(exch_acct_code) 
			CALL show_acct(glob_rec_kandoouser.cmpy_code)RETURNING l_ret_acct_code
			IF l_ret_acct_code IS NOT NULL THEN
				LET l_rec_vendortype.exch_acct_code = l_ret_acct_code
			END IF 
			CALL display_desc(5,l_rec_vendortype.*) 

		AFTER FIELD type_code 
			IF l_rec_vendortype.type_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD type_code 
			ELSE 
				IF LENGTH(l_rec_vendortype.type_code) < 3 THEN
					MESSAGE "A three character code is used for the Vendor Type."
					NEXT FIELD type_code 
				END IF 
				IF db_vendortype_pk_exists(l_rec_vendortype.type_code) THEN 
					LET l_msgresp = kandoomsg("J",9546,"") 
					#9546 You must enter a unique type code.
					NEXT FIELD type_code 
				END IF 
			END IF 

		AFTER FIELD withhold_tax_ind 
			IF l_rec_vendortype.withhold_tax_ind IS NULL OR 
			(NOT (l_rec_vendortype.withhold_tax_ind MATCHES "[0123]")) THEN 
				LET l_msgresp = kandoomsg("P", 9112, "") 
				#9112 Withholding Tax Indicator must be 0, 1 ,2 OR 3
				NEXT FIELD withhold_tax_ind 
			ELSE 
				DISPLAY db_withhold_tax_ind_get_desc_text(l_rec_vendortype.withhold_tax_ind) TO withhold_tax_ind_desc_text 
			END IF 

			IF l_rec_vendortype.withhold_tax_ind = "0" THEN 
				CALL set_fieldAttribute_readOnly("tax_vend_code",TRUE)
				LET l_rec_vendortype.tax_vend_code = NULL
				CLEAR vendortype.tax_vend_code 
				CLEAR vendor.name_text 
			ELSE 
				CALL set_fieldAttribute_readOnly("tax_vend_code",FALSE)
			END IF 

		AFTER FIELD tax_vend_code 
			IF l_rec_vendortype.tax_vend_code IS NULL AND  -- add to AFTER INPUT !!!
				l_rec_vendortype.withhold_tax_ind != "0" THEN
				LET l_msgresp = kandoomsg("P",9114,"") 
				#9114 Tax Vendor must be entered
				NEXT FIELD tax_vend_code 
			END IF 

			CALL get_vendor(l_rec_vendortype.tax_vend_code) 
			RETURNING l_vendor_found, 
						 l_vendor_type, 
						 l_vendor_tax_ind, 
						 l_vendor_currency 
			IF NOT l_vendor_found THEN 
				LET l_msgresp = kandoomsg("P",9105,"") 
				#9105 Vendor NOT found - try window
				NEXT FIELD tax_vend_code 
			END IF 
			IF l_vendor_tax_ind != "0" THEN 
				LET l_msgresp = kandoomsg("P",9113,"") 
				#9113 Vendor IS a withholding tax payer - invalid type
				NEXT FIELD tax_vend_code 
			END IF 
			IF l_vendor_currency != glob_rec_glparms.base_currency_code THEN 
				LET l_msgresp = kandoomsg("P",9116,"") 
				#9116 Vendor must use Base currency FOR Withholding Tax
				NEXT FIELD tax_vend_code 
			END IF 
			IF l_vendor_type = l_rec_vendortype.type_code THEN 
				LET l_msgresp = kandoomsg("P",9124,l_rec_vendortype.type_code) 
				#9124 Tax Vendor IS also of type,l_rec_vendortype.type-code,
				#     cannot be made tax payable
				NEXT FIELD withhold_tax_ind 
			END IF 
			DISPLAY db_vendor_get_name_text(UI_OFF,l_rec_vendortype.tax_vend_code) TO name_text 

		AFTER FIELD pay_acct_code 
			IF l_rec_vendortype.pay_acct_code IS NULL THEN 
				LET l_rec_vendortype.pay_acct_code = glob_rec_apparms.pay_acct_code 
				DISPLAY BY NAME l_rec_vendortype.pay_acct_code 
			END IF 
			IF NOT display_desc(1,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD pay_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.pay_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER,"Y") THEN 
				NEXT FIELD pay_acct_code 
			END IF 

		AFTER FIELD freight_acct_code 
			IF l_rec_vendortype.freight_acct_code IS NULL THEN 
				LET l_rec_vendortype.freight_acct_code = glob_rec_apparms.freight_acct_code 
				DISPLAY BY NAME l_rec_vendortype.freight_acct_code 
			END IF 
			IF NOT display_desc(2,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD freight_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.freight_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD freight_acct_code 
			END IF 

		AFTER FIELD salestax_acct_code 
			IF l_rec_vendortype.salestax_acct_code IS NULL THEN 
				LET l_rec_vendortype.salestax_acct_code = glob_rec_apparms.salestax_acct_code 
				DISPLAY BY NAME l_rec_vendortype.salestax_acct_code 
			END IF 
			IF NOT display_desc(3,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD salestax_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.salestax_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD salestax_acct_code 
			END IF 

		AFTER FIELD disc_acct_code 
			IF l_rec_vendortype.disc_acct_code IS NULL THEN 
				LET l_rec_vendortype.disc_acct_code = glob_rec_apparms.disc_acct_code 
				DISPLAY BY NAME l_rec_vendortype.disc_acct_code 
			END IF 
			IF NOT display_desc(4,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD disc_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.disc_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD disc_acct_code 
			END IF 

		AFTER FIELD exch_acct_code 
			IF l_rec_vendortype.exch_acct_code IS NULL THEN 
				LET l_rec_vendortype.exch_acct_code = glob_rec_apparms.exch_acct_code 
				DISPLAY BY NAME l_rec_vendortype.exch_acct_code
			END IF 
			IF NOT display_desc(5,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD exch_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.exch_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD exch_acct_code 
			END IF 

		AFTER INPUT 
			IF int_flag = 0 AND quit_flag = 0 THEN
			# "Apply" action activated.
			IF l_rec_vendortype.type_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered.
				NEXT FIELD type_code 
			ELSE 
				IF LENGTH(l_rec_vendortype.type_code) < 3 THEN
					MESSAGE "A three character code is used for the Vendor Type."
					NEXT FIELD type_code 
				END IF 
				IF db_vendortype_pk_exists(l_rec_vendortype.type_code) THEN 
					LET l_msgresp = kandoomsg("J",9546,"") 
					#9546 You must enter a unique type code.
					NEXT FIELD type_code 
				END IF 
			END IF

			IF l_rec_vendortype.withhold_tax_ind IS NULL OR 
			(NOT (l_rec_vendortype.withhold_tax_ind MATCHES "[0123]")) THEN 
				LET l_msgresp = kandoomsg("P", 9112, "") 
				#9112 Withholding Tax Indicator must be 0, 1 ,2 OR 3
				NEXT FIELD withhold_tax_ind 
			END IF 

			IF l_rec_vendortype.withhold_tax_ind != "0" THEN 
				IF l_rec_vendortype.tax_vend_code IS NULL THEN 
					LET l_msgresp = kandoomsg("P",9114,"") 
					#9114 Tax Vendor must be entered
					NEXT FIELD tax_vend_code 
				END IF 
				CALL get_vendor(l_rec_vendortype.tax_vend_code) 
				RETURNING l_vendor_found, 
							 l_vendor_type, 
							 l_vendor_tax_ind, 
							 l_vendor_currency 
				IF NOT l_vendor_found THEN 
					LET l_msgresp = kandoomsg("P",9105,"") 
					#9105 Vendor NOT found - try window
					NEXT FIELD tax_vend_code 
				END IF 
				IF l_vendor_tax_ind != "0" THEN 
					LET l_msgresp = kandoomsg("P",9113,"") 
					#9113 Vendor IS a withholding tax payer - invalid type
					NEXT FIELD tax_vend_code 
				END IF 
				IF l_vendor_currency != glob_rec_glparms.base_currency_code THEN 
					LET l_msgresp = kandoomsg("P",9116,"") 
					#9116 Vendor must use Base currency FOR Withholding Tax
					NEXT FIELD tax_vend_code 
				END IF 
				IF l_vendor_type = l_rec_vendortype.type_code THEN 
					LET l_msgresp = kandoomsg("P",9124,l_rec_vendortype.type_code) 
					#9124 Tax Vendor IS also of type,l_rec_vendortype.type-code,
					#     cannot be made tax payable
					NEXT FIELD withhold_tax_ind 
				END IF 
			END IF 

			IF l_rec_vendortype.pay_acct_code IS NULL THEN 
				LET l_rec_vendortype.pay_acct_code = glob_rec_apparms.pay_acct_code 
				DISPLAY BY NAME l_rec_vendortype.pay_acct_code 
			END IF 
			IF NOT display_desc(1,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD pay_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.pay_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER,"Y") THEN 
				NEXT FIELD pay_acct_code 
			END IF 

			IF l_rec_vendortype.freight_acct_code IS NULL THEN 
				LET l_rec_vendortype.freight_acct_code = glob_rec_apparms.freight_acct_code 
				DISPLAY BY NAME l_rec_vendortype.freight_acct_code 
			END IF 
			IF NOT display_desc(2,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD freight_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.freight_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD freight_acct_code 
			END IF 
			
			IF l_rec_vendortype.salestax_acct_code IS NULL THEN 
				LET l_rec_vendortype.salestax_acct_code = glob_rec_apparms.salestax_acct_code 
				DISPLAY BY NAME l_rec_vendortype.salestax_acct_code 
			END IF 
			IF NOT display_desc(3,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD salestax_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.salestax_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD salestax_acct_code 
			END IF 

			IF l_rec_vendortype.disc_acct_code IS NULL THEN 
				LET l_rec_vendortype.disc_acct_code = glob_rec_apparms.disc_acct_code 
				DISPLAY BY NAME l_rec_vendortype.disc_acct_code 
			END IF 
			IF NOT display_desc(4,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD disc_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.disc_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD disc_acct_code 
			END IF 
			
			IF l_rec_vendortype.exch_acct_code IS NULL THEN 
				LET l_rec_vendortype.exch_acct_code = glob_rec_apparms.exch_acct_code 
				DISPLAY BY NAME l_rec_vendortype.exch_acct_code
			END IF 
			IF NOT display_desc(5,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD exch_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.exch_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD exch_acct_code 
			END IF 
			END IF

	END INPUT 

	IF int_flag = 1 OR quit_flag = 1 THEN 
		# "Cancel" action activated.
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		CLOSE WINDOW p174
		RETURN FALSE 
	ELSE 
		# "Apply" action activated.
		INSERT INTO vendortype VALUES(l_rec_vendortype.*)
		CLOSE WINDOW p174
		RETURN TRUE
	END IF 

END FUNCTION 


############################################################
# FUNCTION change_vendtype()
#
#
############################################################
FUNCTION change_vendtype(p_type_code) 
	DEFINE p_type_code LIKE vendor.type_code 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_vendor_found SMALLINT 
	DEFINE l_vendor_type LIKE vendor.type_code 
	DEFINE l_vendor_tax_ind LIKE vendortype.withhold_tax_ind 
	DEFINE l_vendor_currency LIKE vendor.currency_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_ret_acct_code LIKE coa.acct_code
	DEFINE i SMALLINT

	OPEN WINDOW p174 WITH FORM "P174"
	CALL windecoration_p("P174")

	CLEAR FORM
	
	SELECT * INTO l_rec_vendortype FROM vendortype 
	WHERE vendortype.cmpy_code = glob_rec_kandoouser.cmpy_code AND 
	      vendortype.type_code = p_type_code

	# Convert ComboBoxes to TextFields via dynamic morphing function
	CALL Convert_ComboBox_To_TextField("pay_acct_code")
	CALL Convert_ComboBox_To_TextField("freight_acct_code")
	CALL Convert_ComboBox_To_TextField("salestax_acct_code")	
	CALL Convert_ComboBox_To_TextField("disc_acct_code")
	CALL Convert_ComboBox_To_TextField("exch_acct_code")

	LET l_msgresp = kandoomsg("P",1567,"") 
	#1567 Enter Vendor Type details; OK TO continue.
	INPUT BY NAME	l_rec_vendortype.type_text, 
						l_rec_vendortype.withhold_tax_ind, 
						l_rec_vendortype.tax_vend_code, 
						l_rec_vendortype.pay_acct_code, 
						l_rec_vendortype.freight_acct_code, 
						l_rec_vendortype.salestax_acct_code, 
						l_rec_vendortype.disc_acct_code, 
						l_rec_vendortype.exch_acct_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PZ5","inp-vendortype-2")
			DISPLAY l_rec_vendortype.type_code TO type_code 
			DISPLAY db_withhold_tax_ind_get_desc_text(l_rec_vendortype.withhold_tax_ind) TO withhold_tax_ind_desc_text 
			DISPLAY db_vendor_get_name_text(UI_OFF,l_rec_vendortype.tax_vend_code) TO name_text 
			CALL display_desc(1,l_rec_vendortype.*) 
			CALL display_desc(2,l_rec_vendortype.*) 
			CALL display_desc(3,l_rec_vendortype.*) 
			CALL display_desc(4,l_rec_vendortype.*) 
			CALL display_desc(5,l_rec_vendortype.*) 

		BEFORE FIELD tax_vend_code
			IF l_rec_vendortype.withhold_tax_ind = "0" THEN
				IF fgl_lastkey() = fgl_keyval("TAB") OR
					fgl_lastkey() = fgl_keyval("DOWN") OR 
					fgl_lastkey() = fgl_keyval("RIGHT") OR
					fgl_lastkey() = fgl_keyval("RETURN") THEN
					NEXT FIELD NEXT 
				ELSE 
					NEXT FIELD PREVIOUS 
				END IF
			END IF

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),NULL) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "LOOKUP"  infield(tax_vend_code) 
			LET l_rec_vendortype.tax_vend_code = show_vend(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.tax_vend_code) 
			DISPLAY BY NAME l_rec_vendortype.tax_vend_code
			DISPLAY db_vendor_get_name_text(UI_OFF,l_rec_vendortype.tax_vend_code) TO name_text

		ON ACTION "LOOKUP"  infield(pay_acct_code) 
			CALL show_acct(glob_rec_kandoouser.cmpy_code)RETURNING l_ret_acct_code
			IF l_ret_acct_code IS NOT NULL THEN
				LET l_rec_vendortype.pay_acct_code = l_ret_acct_code
			END IF 
			CALL display_desc(1,l_rec_vendortype.*) 

		ON ACTION "LOOKUP"  infield(freight_acct_code) 
			CALL show_acct(glob_rec_kandoouser.cmpy_code)RETURNING l_ret_acct_code
			IF l_ret_acct_code IS NOT NULL THEN
				LET l_rec_vendortype.freight_acct_code = l_ret_acct_code
			END IF 
			CALL display_desc(2,l_rec_vendortype.*) 

		ON ACTION "LOOKUP"  infield(salestax_acct_code) 
			CALL show_acct(glob_rec_kandoouser.cmpy_code)RETURNING l_ret_acct_code
			IF l_ret_acct_code IS NOT NULL THEN
				LET l_rec_vendortype.salestax_acct_code = l_ret_acct_code
			END IF 
			CALL display_desc(3,l_rec_vendortype.*) 

		ON ACTION "LOOKUP"  infield(disc_acct_code) 
			CALL show_acct(glob_rec_kandoouser.cmpy_code)RETURNING l_ret_acct_code
			IF l_ret_acct_code IS NOT NULL THEN
				LET l_rec_vendortype.disc_acct_code = l_ret_acct_code
			END IF 
			CALL display_desc(4,l_rec_vendortype.*) 

		ON ACTION "LOOKUP"  infield(exch_acct_code) 
			CALL show_acct(glob_rec_kandoouser.cmpy_code)RETURNING l_ret_acct_code
			IF l_ret_acct_code IS NOT NULL THEN
				LET l_rec_vendortype.exch_acct_code = l_ret_acct_code
			END IF 
			CALL display_desc(5,l_rec_vendortype.*) 

		AFTER FIELD withhold_tax_ind 
			IF l_rec_vendortype.withhold_tax_ind IS NULL OR 
			(NOT (l_rec_vendortype.withhold_tax_ind MATCHES "[0123]")) THEN 
				LET l_msgresp = kandoomsg("P", 9112, "") 
				#9112 Withholding Tax Indicator must be 0, 1 ,2 OR 3
				NEXT FIELD withhold_tax_ind 
			ELSE 
				DISPLAY db_withhold_tax_ind_get_desc_text(l_rec_vendortype.withhold_tax_ind) TO withhold_tax_ind_desc_text 
			END IF 

			IF l_rec_vendortype.withhold_tax_ind = "0" THEN 
				CALL set_fieldAttribute_readOnly("tax_vend_code",TRUE)
				LET l_rec_vendortype.tax_vend_code = NULL
				CLEAR vendortype.tax_vend_code 
				CLEAR vendor.name_text 
			ELSE 
				CALL set_fieldAttribute_readOnly("tax_vend_code",FALSE)
			END IF 

		AFTER FIELD tax_vend_code 
			IF l_rec_vendortype.tax_vend_code IS NULL AND  -- add to AFTER INPUT !!!
				l_rec_vendortype.withhold_tax_ind != "0" THEN
				LET l_msgresp = kandoomsg("P",9114,"") 
				#9114 Tax Vendor must be entered
				NEXT FIELD tax_vend_code 
			END IF 

			CALL get_vendor(l_rec_vendortype.tax_vend_code) 
			RETURNING l_vendor_found, 
						 l_vendor_type, 
						 l_vendor_tax_ind, 
						 l_vendor_currency 
			IF NOT l_vendor_found THEN 
				LET l_msgresp = kandoomsg("P",9105,"") 
				#9105 Vendor NOT found - try window
				NEXT FIELD tax_vend_code 
			END IF 
			IF l_vendor_tax_ind != "0" THEN 
				LET l_msgresp = kandoomsg("P",9113,"") 
				#9113 Vendor IS a withholding tax payer - invalid type
				NEXT FIELD tax_vend_code 
			END IF 
			IF l_vendor_currency != glob_rec_glparms.base_currency_code THEN 
				LET l_msgresp = kandoomsg("P",9116,"") 
				#9116 Vendor must use Base currency FOR Withholding Tax
				NEXT FIELD tax_vend_code 
			END IF 
			IF l_vendor_type = l_rec_vendortype.type_code THEN 
				LET l_msgresp = kandoomsg("P",9124,l_rec_vendortype.type_code) 
				#9124 Tax Vendor IS also of type,l_rec_vendortype.type-code,
				#     cannot be made tax payable
				NEXT FIELD withhold_tax_ind 
			END IF 
			DISPLAY db_vendor_get_name_text(UI_OFF,l_rec_vendortype.tax_vend_code) TO name_text 

		AFTER FIELD pay_acct_code 
			IF l_rec_vendortype.pay_acct_code IS NULL THEN 
				LET l_rec_vendortype.pay_acct_code = glob_rec_apparms.pay_acct_code 
				DISPLAY BY NAME l_rec_vendortype.pay_acct_code 
			END IF 
			IF NOT display_desc(1,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD pay_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.pay_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER,"Y") THEN 
				NEXT FIELD pay_acct_code 
			END IF 

		AFTER FIELD freight_acct_code 
			IF l_rec_vendortype.freight_acct_code IS NULL THEN 
				LET l_rec_vendortype.freight_acct_code = glob_rec_apparms.freight_acct_code 
				DISPLAY BY NAME l_rec_vendortype.freight_acct_code 
			END IF 
			IF NOT display_desc(2,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD freight_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.freight_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD freight_acct_code 
			END IF 

		AFTER FIELD salestax_acct_code 
			IF l_rec_vendortype.salestax_acct_code IS NULL THEN 
				LET l_rec_vendortype.salestax_acct_code = glob_rec_apparms.salestax_acct_code 
				DISPLAY BY NAME l_rec_vendortype.salestax_acct_code 
			END IF 
			IF NOT display_desc(3,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD salestax_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.salestax_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD salestax_acct_code 
			END IF 

		AFTER FIELD disc_acct_code 
			IF l_rec_vendortype.disc_acct_code IS NULL THEN 
				LET l_rec_vendortype.disc_acct_code = glob_rec_apparms.disc_acct_code 
				DISPLAY BY NAME l_rec_vendortype.disc_acct_code 
			END IF 
			IF NOT display_desc(4,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD disc_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.disc_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD disc_acct_code 
			END IF 

		AFTER FIELD exch_acct_code 
			IF l_rec_vendortype.exch_acct_code IS NULL THEN 
				LET l_rec_vendortype.exch_acct_code = glob_rec_apparms.exch_acct_code 
				DISPLAY BY NAME l_rec_vendortype.exch_acct_code
			END IF 
			IF NOT display_desc(5,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD exch_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.exch_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD exch_acct_code 
			END IF 

		AFTER INPUT 
			IF int_flag = 0 AND quit_flag = 0 THEN
			# "Apply" action activated.
			IF l_rec_vendortype.withhold_tax_ind IS NULL OR 
			(NOT (l_rec_vendortype.withhold_tax_ind MATCHES "[0123]")) THEN 
				LET l_msgresp = kandoomsg("P", 9112, "") 
				#9112 Withholding Tax Indicator must be 0, 1 ,2 OR 3
				NEXT FIELD withhold_tax_ind 
			END IF 

			IF l_rec_vendortype.withhold_tax_ind != "0" THEN 
				IF l_rec_vendortype.tax_vend_code IS NULL THEN 
					LET l_msgresp = kandoomsg("P",9114,"") 
					#9114 Tax Vendor must be entered
					NEXT FIELD tax_vend_code 
				END IF 
				CALL get_vendor(l_rec_vendortype.tax_vend_code) 
				RETURNING l_vendor_found, 
							 l_vendor_type, 
							 l_vendor_tax_ind, 
							 l_vendor_currency 
				IF NOT l_vendor_found THEN 
					LET l_msgresp = kandoomsg("P",9105,"") 
					#9105 Vendor NOT found - try window
					NEXT FIELD tax_vend_code 
				END IF 
				IF l_vendor_tax_ind != "0" THEN 
					LET l_msgresp = kandoomsg("P",9113,"") 
					#9113 Vendor IS a withholding tax payer - invalid type
					NEXT FIELD tax_vend_code 
				END IF 
				IF l_vendor_currency != glob_rec_glparms.base_currency_code THEN 
					LET l_msgresp = kandoomsg("P",9116,"") 
					#9116 Vendor must use Base currency FOR Withholding Tax
					NEXT FIELD tax_vend_code 
				END IF 
				IF l_vendor_type = l_rec_vendortype.type_code THEN 
					LET l_msgresp = kandoomsg("P",9124,l_rec_vendortype.type_code) 
					#9124 Tax Vendor IS also of type,l_rec_vendortype.type-code,
					#     cannot be made tax payable
					NEXT FIELD withhold_tax_ind 
				END IF 
			END IF 

			IF l_rec_vendortype.pay_acct_code IS NULL THEN 
				LET l_rec_vendortype.pay_acct_code = glob_rec_apparms.pay_acct_code 
				DISPLAY BY NAME l_rec_vendortype.pay_acct_code 
			END IF 
			IF NOT display_desc(1,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD pay_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.pay_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER,"Y") THEN 
				NEXT FIELD pay_acct_code 
			END IF 

			IF l_rec_vendortype.freight_acct_code IS NULL THEN 
				LET l_rec_vendortype.freight_acct_code = glob_rec_apparms.freight_acct_code 
				DISPLAY BY NAME l_rec_vendortype.freight_acct_code 
			END IF 
			IF NOT display_desc(2,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD freight_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.freight_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD freight_acct_code 
			END IF 
			
			IF l_rec_vendortype.salestax_acct_code IS NULL THEN 
				LET l_rec_vendortype.salestax_acct_code = glob_rec_apparms.salestax_acct_code 
				DISPLAY BY NAME l_rec_vendortype.salestax_acct_code 
			END IF 
			IF NOT display_desc(3,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD salestax_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.salestax_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD salestax_acct_code 
			END IF 

			IF l_rec_vendortype.disc_acct_code IS NULL THEN 
				LET l_rec_vendortype.disc_acct_code = glob_rec_apparms.disc_acct_code 
				DISPLAY BY NAME l_rec_vendortype.disc_acct_code 
			END IF 
			IF NOT display_desc(4,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD disc_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.disc_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD disc_acct_code 
			END IF 
			
			IF l_rec_vendortype.exch_acct_code IS NULL THEN 
				LET l_rec_vendortype.exch_acct_code = glob_rec_apparms.exch_acct_code 
				DISPLAY BY NAME l_rec_vendortype.exch_acct_code
			END IF 
			IF NOT display_desc(5,l_rec_vendortype.*) THEN 
				LET l_msgresp = kandoomsg("A",9129,"") 
				#9129 Account number does NOT exist; Try Lookup.
				NEXT FIELD exch_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_vendortype.exch_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD exch_acct_code 
			END IF 
			END IF

	END INPUT 

	IF int_flag = 1 OR quit_flag = 1 THEN 
		# "Cancel" action activated.
		LET int_flag = FALSE 
		LET quit_flag = FALSE
		CLOSE WINDOW p174
		RETURN FALSE 
	ELSE 
		# "Apply" action activated.
		UPDATE vendortype SET vendortype.* = l_rec_vendortype.*
		WHERE vendortype.cmpy_code = glob_rec_kandoouser.cmpy_code AND
				vendortype.type_code = l_rec_vendortype.type_code
		CLOSE WINDOW p174
		RETURN TRUE 
	END IF 

END FUNCTION 


############################################################
# FUNCTION display_desc(p_i,p_rec_vendorType)
#
#
############################################################
FUNCTION display_desc(p_i,p_rec_vendortype) 
	DEFINE p_i SMALLINT 
	DEFINE p_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_account_code LIKE coa.acct_code 
	DEFINE l_acct_desc LIKE coa.desc_text 

	CASE p_i 
		WHEN 1 
			LET l_account_code = p_rec_vendortype.pay_acct_code 
		WHEN 2 
			LET l_account_code = p_rec_vendortype.freight_acct_code 
		WHEN 3 
			LET l_account_code = p_rec_vendortype.salestax_acct_code 
		WHEN 4 
			LET l_account_code = p_rec_vendortype.disc_acct_code 
		WHEN 5 
			LET l_account_code = p_rec_vendortype.exch_acct_code 
	END CASE 
 
	IF l_account_code IS NOT NULL AND l_account_code != " " THEN 
		SELECT desc_text INTO l_acct_desc FROM coa 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code	AND 
				acct_code = l_account_code 
		IF STATUS = NOTFOUND THEN
			LET l_acct_desc = " "
		END IF		
	END IF 
	CASE p_i 
		WHEN 1 
			DISPLAY l_acct_desc TO desc_text1 
		WHEN 2 
			DISPLAY l_acct_desc TO desc_text2 
		WHEN 3 
			DISPLAY l_acct_desc TO desc_text3 
		WHEN 4 
			DISPLAY l_acct_desc TO desc_text4 
		WHEN 5 
			DISPLAY l_acct_desc TO desc_text5 
	END CASE 
	IF l_acct_desc = " " THEN 
		RETURN FALSE 
	ELSE 
		RETURN TRUE
	END IF 
 
END FUNCTION 


############################################################
# FUNCTION get_vendor(p_vend_code)
#
#
############################################################
FUNCTION get_vendor(p_vend_code) 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE l_vend_type LIKE vendor.type_code 
	DEFINE l_vendor_found SMALLINT 
	DEFINE l_vendor_name LIKE vendor.name_text 
	DEFINE l_tax_indicator LIKE vendortype.withhold_tax_ind 
	DEFINE l_vendor_currency LIKE vendor.currency_code 

	LET l_tax_indicator = "0" 
	LET l_vendor_name = NULL 

	SELECT name_text,type_code,currency_code INTO l_vendor_name,l_vend_type,l_vendor_currency 
	FROM vendor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code AND 
			vend_code = p_vend_code 
	IF STATUS = NOTFOUND THEN 
		LET l_vendor_found = FALSE 
	ELSE 
		DISPLAY l_vendor_name TO vendor.name_text 
		LET l_vendor_found = TRUE 

		SELECT withhold_tax_ind INTO l_tax_indicator 
		FROM vendortype 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND type_code = l_vend_type 
		IF STATUS = NOTFOUND THEN 
			LET l_tax_indicator = "0" 
		END IF 
	END IF 

	RETURN l_vendor_found,l_vend_type,l_tax_indicator,l_vendor_currency 

END FUNCTION 
