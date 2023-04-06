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

	Source code beautified by beautify.pl on 2020-01-03 13:41:29	$Id: $
}



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P4_GLOBALS.4gl" 
GLOBALS 
	DEFINE glob_rec_cheque RECORD 
				vend_code LIKE cheque.vend_code, 
				name_text LIKE vendor.name_text, 
				currency_code LIKE cheque.currency_code, 
				cheq_code LIKE cheque.cheq_code, 
				pay_meth_ind LIKE cheque.pay_meth_ind, 
				entry_code LIKE cheque.entry_code, 
				entry_date LIKE cheque.entry_date, 
				bank_acct_code LIKE cheque.bank_acct_code, 
				com3_text LIKE cheque.com3_text, 
				cheq_date LIKE cheque.cheq_date, 
				name_acct_text LIKE bank.name_acct_text, 
				bank_code LIKE bank.bank_code, 
				iban LIKE bank.iban, 
				pay_amt LIKE cheque.pay_amt, 
				conv_qty LIKE cheque.conv_qty, 
				year_num LIKE cheque.year_num, 
				period_num LIKE cheque.period_num, 
				apply_amt LIKE cheque.apply_amt, 
				post_flag LIKE cheque.post_flag, 
				disc_amt LIKE cheque.disc_amt, 
				rec_state_num LIKE cheque.rec_state_num, 
				rec_line_num LIKE cheque.rec_line_num, 
				com1_text LIKE cheque.com1_text, 
				com2_text LIKE cheque.com2_text, 
				net_pay_amt LIKE cheque.net_pay_amt, 
				tax_code LIKE cheque.tax_code, 
				tax_per LIKE cheque.tax_per, 
				tax_amt LIKE cheque.tax_amt, 
				contra_amt LIKE cheque.contra_amt, 
				source_ind LIKE cheque.source_ind, 
				source_text LIKE cheque.source_text 
	END RECORD
END GLOBALS 

############################################################
# MAIN
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P45") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p132 with FORM "P132" 
	CALL windecoration_p("P132") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	CALL query() 
	CLOSE WINDOW p132 
END MAIN 


FUNCTION select_cheq() 
	DEFINE l_where_part CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp=kandoomsg("U",1001,"") 
	#1001 " Enter criteria FOR selection - ESC TO Continue
	CONSTRUCT BY NAME l_where_part ON cheque.vend_code , 
	vendor.name_text, 
	bank.bank_code, 
	bank.name_acct_text, 
	cheque.cheq_code, 
	cheque.pay_meth_ind, 
	vendor.currency_code, 
	cheque.pay_amt, 
	cheque.tax_amt, 
	cheque.contra_amt, 
	cheque.net_pay_amt, 
	cheque.apply_amt, 
	cheque.disc_amt , 
	cheque.tax_code, 
	cheque.tax_per, 
	cheque.cheq_date, 
	cheque.com3_text, 
	cheque.entry_code, 
	cheque.entry_date, 
	cheque.post_flag , 
	cheque.year_num, 
	cheque.period_num, 
	cheque.bank_acct_code, 
	cheque.rec_state_num, 
	cheque.rec_line_num, 
	cheque.com1_text, 
	cheque.com2_text 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P45","construct-cheque-1") 

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
	"SELECT cheque.vend_code, vendor.name_text, ", 
	" cheque.currency_code, cheque.cheq_code, ", 
	" cheque.pay_meth_ind, ", 
	" cheque.entry_code, cheque.entry_date, ", 
	" cheque.bank_acct_code, cheque.com3_text, ", 
	" cheque.cheq_date, bank.name_acct_text, ", 
	" bank.bank_code,bank.iban, cheque.pay_amt, ", 
	" cheque.conv_qty, ", 
	" cheque.year_num, cheque.period_num, ", 
	" cheque.apply_amt, cheque.post_flag, ", 
	" cheque.disc_amt, cheque.rec_state_num, ", 
	" cheque.rec_line_num, cheque.com1_text, cheque.com2_text, ", 
	" cheque.net_pay_amt, cheque.tax_code, cheque.tax_per, ", 
	" cheque.tax_amt, cheque.contra_amt, ", 
	" cheque.source_ind, cheque.source_text ", 
	"FROM cheque , vendor, bank ", 
	"WHERE vendor.vend_code = cheque.vend_code AND ", 
	" cheque.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" bank.cmpy_code = cheque.cmpy_code AND ", 
	" bank.acct_code = cheque.bank_acct_code AND ", 
	" vendor.cmpy_code = cheque.cmpy_code AND ", 
	l_where_part clipped, 
	" ORDER BY cheque.vend_code, cheque.cheq_code " 
	PREPARE s_cheque FROM l_query_text 
	DECLARE c_cheque SCROLL CURSOR FOR s_cheque 
	OPEN c_cheque 
	FETCH c_cheque INTO glob_rec_cheque.* 
	IF status = NOTFOUND THEN 
		ERROR "No cheques satisfied the query criteria" 
		RETURN false 
	ELSE 
		CALL disp_cheq() 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION query() 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 

	MENU " Cheque" 
		BEFORE MENU 
			HIDE option "Next" 
			HIDE option "Previous" 
			HIDE option "First" 
			HIDE option "Last" 
			HIDE option "Detail" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","P45","menu-cheque-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		COMMAND "Query" " Enter selection criteria FOR payments" 
			IF select_cheq() THEN 
				FETCH FIRST c_cheque INTO glob_rec_cheque.* 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "Detail" 
				SHOW option "First" 
				SHOW option "Last" 
				NEXT option "Next" 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
			END IF 
		COMMAND KEY ("N",f21) "Next" " DISPLAY next selected payment" 
			FETCH NEXT c_cheque INTO glob_rec_cheque.* 
			IF status = NOTFOUND THEN 
				ERROR "You have reached the END of the payments selected" 
			ELSE 
				CALL disp_cheq() 
			END IF 
		COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected payment" 
			FETCH previous c_cheque INTO glob_rec_cheque.* 
			IF status = NOTFOUND THEN 
				ERROR "You have reached the start of the payments selected" 
			ELSE 
				CALL disp_cheq() 
			END IF 

		COMMAND KEY ("D",f20) "Detail" " View payment details" 
			MENU " Payment details" 

				BEFORE MENU 
					IF glob_rec_cheque.source_ind = "S" THEN 
						SELECT * INTO l_rec_vouchpayee.* FROM vouchpayee 
						WHERE vend_code = glob_rec_cheque.vend_code 
						AND vouch_code = glob_rec_cheque.source_text 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						IF status = NOTFOUND THEN 
							HIDE option "Payee" 
						END IF 
					ELSE 
						HIDE option "Payee" 
					END IF 


					CALL publish_toolbar("kandoo","P45","menu-payment-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				COMMAND "Applications" " View application details" 
					CALL cheq_appl(glob_rec_kandoouser.cmpy_code, 
					glob_rec_cheque.cheq_code, 
					glob_rec_cheque.bank_acct_code, 
					glob_rec_cheque.vend_code, 
					glob_rec_cheque.pay_meth_ind) 
				COMMAND "Payee" " View payee details" 
					CALL disp_payee_det(l_rec_vouchpayee.*) 
				COMMAND KEY(interrupt,"E") "Exit" " Exit FROM details" 
					LET int_flag = false 
					LET quit_flag = false 
					EXIT MENU 

			END MENU 
		COMMAND KEY ("F",f18) "First" " DISPLAY first payment in the selected list" 
			FETCH FIRST c_cheque INTO glob_rec_cheque.* 
			IF status = NOTFOUND THEN 
				ERROR "You have reached the start of the payments selected" 
			ELSE 
				CALL disp_cheq() 
			END IF 
		COMMAND KEY ("L",f22) "Last" " DISPLAY last payment in the selected list" 
			FETCH LAST c_cheque INTO glob_rec_cheque.* 
			IF status = NOTFOUND THEN 
				ERROR "You have reached the END of the payments selected" 
			ELSE 
				CALL disp_cheq() 
			END IF 
		COMMAND KEY (interrupt,"E") "Exit" " Exit FROM Inquiry" 
			EXIT MENU 

	END MENU 
END FUNCTION 


FUNCTION disp_cheq() 
	DEFINE l_pay_meth_text CHAR(25)
	DEFINE l_date_pres LIKE bankstatement.tran_date 
	DEFINE l_recon_ind LIKE bankstatement.recon_ind 

	DISPLAY BY NAME glob_rec_cheque.vend_code, 
	glob_rec_cheque.name_text, 
	glob_rec_cheque.cheq_code, 
	glob_rec_cheque.pay_meth_ind, 
	glob_rec_cheque.entry_code, 
	glob_rec_cheque.entry_date, 
	glob_rec_cheque.bank_acct_code, 
	glob_rec_cheque.com3_text, 
	glob_rec_cheque.cheq_date, 
	glob_rec_cheque.name_acct_text, 
	glob_rec_cheque.bank_code, 
	glob_rec_cheque.iban, 
	glob_rec_cheque.pay_amt, 
	glob_rec_cheque.tax_amt, 
	glob_rec_cheque.contra_amt, 
	glob_rec_cheque.net_pay_amt, 
	glob_rec_cheque.tax_code, 
	glob_rec_cheque.tax_per, 
	glob_rec_cheque.conv_qty, 
	glob_rec_cheque.year_num, 
	glob_rec_cheque.period_num, 
	glob_rec_cheque.apply_amt, 
	glob_rec_cheque.post_flag, 
	glob_rec_cheque.disc_amt, 
	glob_rec_cheque.rec_state_num, 
	glob_rec_cheque.rec_line_num, 
	glob_rec_cheque.com1_text, 
	glob_rec_cheque.com2_text 

	LET l_pay_meth_text = "" 
	IF glob_rec_cheque.pay_meth_ind = "1" THEN 
		LET l_pay_meth_text = "Auto/Manual Cheques" 
	ELSE 
		LET l_pay_meth_text = "EFT Payments " 
	END IF 
	DISPLAY l_pay_meth_text TO pay_meth_text 

	DISPLAY BY NAME glob_rec_cheque.currency_code 
	attribute (green) 
	CLEAR date_presented, close_flag 
	IF glob_rec_cheque.rec_state_num IS NOT NULL THEN 
		SELECT tran_date, recon_ind 
		INTO l_date_pres, l_recon_ind 
		FROM bankstatement 
		WHERE bank_code = glob_rec_cheque.bank_code 
		AND sheet_num = glob_rec_cheque.rec_state_num 
		AND seq_num = glob_rec_cheque.rec_line_num 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		IF NOT status THEN 
			DISPLAY l_date_pres TO date_presented 

			IF l_recon_ind <> "2" THEN 
				DISPLAY "*" TO close_flag 

			END IF 
		END IF 
	END IF 
END FUNCTION 


# FUNCTION: disp_payee_det
# Description: Displays the sundry payment payee details.
# Note:        A copy of the same FUNCTION IS in "vohdwind" AND P25
#               - (TO save heaps of makefile changes)
FUNCTION disp_payee_det(p_rec_vouchpayee) 
	DEFINE p_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_bic_text CHAR(6) 
	DEFINE l_acct_text CHAR(13) 
	DEFINE l_method_text CHAR(30) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_bic_text = p_rec_vouchpayee.bank_acct_code[1,6] 
	LET l_acct_text = p_rec_vouchpayee.bank_acct_code[8,20] 
	LET l_method_text 
	= kandooword("vendor.pay_meth_ind",p_rec_vouchpayee.pay_meth_ind) 
	OPEN WINDOW p515 with FORM "P515" 
	CALL windecoration_p("P515") 

	DISPLAY BY NAME 
		p_rec_vouchpayee.name_text, 
		p_rec_vouchpayee.addr1_text, 
		p_rec_vouchpayee.addr2_text, 
		p_rec_vouchpayee.addr3_text, 
		p_rec_vouchpayee.city_text, 
		p_rec_vouchpayee.state_code, 
		p_rec_vouchpayee.post_code, 
		p_rec_vouchpayee.country_code,  --@db-patch_2020_10_04--
		p_rec_vouchpayee.pay_meth_ind 

	DISPLAY 
		l_method_text, 
		l_bic_text, 
		l_acct_text
	TO
		method_text, 
		bic_text, 
		acct_text

	LET l_msgresp = kandoomsg("U",2,"")# Any Key TO Continue
	CLOSE WINDOW p515 
END FUNCTION 


