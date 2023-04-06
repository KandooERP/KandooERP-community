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
	Source code beautified by beautify.pl on 2020-01-03 13:41:19	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P2_GLOBALS.4gl" 

GLOBALS 
	#DEFINE pr_voucher RECORD LIKE voucher.*
	DEFINE glob_rec_voucher RECORD LIKE voucher.* 

END GLOBALS 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module P25 Voucher Inquiry
#                  allows the user TO view Voucher Information
############################################################
MAIN 
	DEFINE l_withquery SMALLINT 

	CALL setModuleId("P25") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p120 with FORM "P120" 
	CALL windecoration_p("P120") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_voucher_get_count() < 1000 THEN 
		CALL select_vouch(l_withquery) 
		LET l_withquery = 0 
	ELSE 
		LET l_withquery = 1 
	END IF 

	CALL query(l_withquery) 

	CLOSE WINDOW p120 

END MAIN 


############################################################
# FUNCTION select_vouch()
#
#
############################################################
FUNCTION select_vouch(p_withquery) 
	DEFINE p_withquery SMALLINT 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 

	#was commented..
	IF get_url_query_where_text() IS NOT NULL THEN --num_args() > 0 THEN 
		--   	CALL fgl_winmessage("debug","check this code P25.4gl Line ~84 AND ~217","info")
		--   	CALL fgl_winmessage("arg_val(1)",arg_val(1),"info")
		### Allows prog TO run with certain criteria
		LET l_where_text = get_url_query_where_text() #arg_val(1) 
		#   ELSE
	END IF 

	IF p_withquery = 1 THEN 

		CLEAR FORM 
		LET l_msgresp=kandoomsg("U",1001,"") 
		#1001 Enter Selection Criteria;  OK TO Continue.
		CONSTRUCT l_where_text ON voucher.vend_code, 
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
				CALL publish_toolbar("kandoo","P25","construct-voucher-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = "1=1" 
		END IF 

	ELSE 
		LET l_where_text = "1=1" 
	END IF 

	LET l_msgresp = kandoomsg("U",1002,"") 
	#1002 Searching database;  Please wait.
	LET l_query_text = "SELECT voucher.* ", 
	"FROM voucher,vendor ", 
	"WHERE voucher.cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND vendor.vend_code = voucher.vend_code ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY vouch_code" 

	PREPARE s_voucher FROM l_query_text 
	DECLARE c_voucher SCROLL CURSOR FOR s_voucher 
	OPEN c_voucher 
	FETCH c_voucher INTO glob_rec_voucher.* 

	IF status = NOTFOUND THEN 
		MESSAGE "Search criteria did NOT find any results" 
		#RETURN FALSE
		RETURN 0 
	ELSE 
		#RETURN TRUE
		RETURN 1 
	END IF 
END FUNCTION 



############################################################
# FUNCTION query(p_WithQuery)
#
#
############################################################
FUNCTION query(p_withquery) 
	DEFINE p_withquery SMALLINT 
	DEFINE l_rec_vouchpayee RECORD LIKE vouchpayee.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	MENU " Voucher" 
		BEFORE MENU 
			IF p_withquery THEN 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
				#IF num_args() > 0 THEN
				#   IF select_vouch() THEN
				#      CALL disp_vouch()
				#      show option "Detail"
				#   END IF
				#END IF
			ELSE 
				CALL disp_vouch() 
			END IF 

			CALL publish_toolbar("kandoo","P25","menu-voucher-1") 


		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Query" 
			#COMMAND "Query" " Enter selection criteria FOR vouchers "
			IF select_vouch(1) THEN 
				CALL disp_vouch() 
				FETCH FIRST c_voucher INTO glob_rec_voucher.* 
				SHOW option "Next" 
				SHOW option "Previous" 
				SHOW option "Detail" 
				SHOW option "First" 
				SHOW option "Last" 
			ELSE 
				HIDE option "Next" 
				HIDE option "Previous" 
				HIDE option "First" 
				HIDE option "Last" 
				HIDE option "Detail" 
				LET l_msgresp=kandoomsg("P",9044,"") 
			END IF 

		ON ACTION "Next" 
			#COMMAND KEY ("N",f21) "Next" " DISPLAY next selected voucher"
			FETCH NEXT c_voucher INTO glob_rec_voucher.* 
			IF status = NOTFOUND THEN 
				ERROR "You have reached the END of the vouchers selected" 
			ELSE 
				CALL disp_vouch() 
			END IF 

		ON ACTION "Previous" 
			#COMMAND KEY ("P",f19) "Previous" " DISPLAY previous selected voucher"
			FETCH previous c_voucher INTO glob_rec_voucher.* 
			IF status = NOTFOUND THEN 
				ERROR "You have reached the start of the vouchers selected" 
			ELSE 
				CALL disp_vouch() 
			END IF 

		ON ACTION "Detail" --" View voucher details" -- COMMAND KEY ("D",f20) 

			MENU " Voucher details" 
				BEFORE MENU 
					IF glob_rec_voucher.dist_amt <= 0 THEN 
						HIDE option "Distribution" 
					END IF 
					IF glob_rec_voucher.paid_amt <= 0 THEN 
						HIDE option "Payments" 
					END IF 
					SELECT unique 1 FROM wholdtax 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND tax_vend_code = glob_rec_voucher.vend_code 
					AND tax_tran_type = "1" 
					AND tax_ref_num = glob_rec_voucher.vouch_code 
					IF status = NOTFOUND THEN 
						HIDE option "Tax Trans" 
					END IF 
					IF glob_rec_voucher.source_ind = "S" THEN 
						SELECT * INTO l_rec_vouchpayee.* FROM vouchpayee 
						WHERE vend_code = glob_rec_voucher.vend_code 
						AND vouch_code = glob_rec_voucher.vouch_code 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						IF status = NOTFOUND THEN 
							HIDE option "Payee" 
						END IF 
					ELSE 
						HIDE option "Payee" 
					END IF 


				BEFORE MENU 
					CALL publish_toolbar("kandoo","P25","menu-voucher_details-1") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				ON ACTION "Distribution" --" View voucher distribution" 
					CALL disp_dist_amt(glob_rec_kandoouser.cmpy_code,glob_rec_voucher.vouch_code) 
				ON ACTION "Payments" --" View voucher payments" 
					CALL disp_vo_pay(glob_rec_kandoouser.cmpy_code, glob_rec_voucher.vend_code, 
					glob_rec_voucher.vouch_code) 
				ON ACTION "Payee" --" View voucher payee details" 
					CALL disp_payee_det(l_rec_vouchpayee.*) 
				ON ACTION "Tax Trans" --" View associated tax transactions" 
					CALL dispwtax(glob_rec_kandoouser.cmpy_code,glob_rec_voucher.vend_code,"1", 
					glob_rec_voucher.vouch_code) 
				ON ACTION "Exit" --" Exit FROM details" 

					LET int_flag = false 
					LET quit_flag = false 
					EXIT MENU 

			END MENU 

		ON ACTION "First" 
			#COMMAND KEY ("F",f18) "First" " DISPLAY first voucher in the selected list"
			FETCH FIRST c_voucher INTO glob_rec_voucher.* 
			IF status = NOTFOUND THEN 
				ERROR "You have reached the start of the vouchers selected" 
			ELSE 
				CALL disp_vouch() 
			END IF 

		ON ACTION "Last" 
			#COMMAND KEY ("L",f22) "Last" " DISPLAY last voucher in the selected list"
			FETCH LAST c_voucher INTO glob_rec_voucher.* 
			IF status = NOTFOUND THEN 
				ERROR "You have reached the END of the vouchers selected" 
			ELSE 
				CALL disp_vouch() 
			END IF 

		ON ACTION "Exit" 
			#COMMAND KEY(interrupt,"E") "Exit" " Exit FROM Inquiry"
			EXIT MENU 

	END MENU 

END FUNCTION 


############################################################
# FUNCTION disp_vouch()
#
#
############################################################
FUNCTION disp_vouch() 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_tax RECORD LIKE tax.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_rec_holdpay RECORD LIKE holdpay.* 
	DEFINE l_owing_amt LIKE voucher.total_amt 
	DEFINE l_pptax_amt LIKE voucher.total_amt 
	DEFINE l_withhold_tax_ind LIKE cheque.withhold_tax_ind 
	DEFINE l_tax_code LIKE cheque.tax_code 
	DEFINE l_tax_per LIKE cheque.tax_per 
	DEFINE l_net_pay_amt LIKE voucher.total_amt 

	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND vend_code = glob_rec_voucher.vend_code 
	SELECT desc_text INTO l_rec_tax.desc_text FROM tax 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND tax_code = glob_rec_voucher.tax_code 
	IF status = NOTFOUND THEN 
		LET l_rec_tax.desc_text = NULL 
	END IF 
	SELECT desc_text INTO l_rec_term.desc_text FROM term 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND term_code = glob_rec_voucher.term_code 
	IF status = NOTFOUND THEN 
		LET l_rec_term.desc_text = NULL 
	END IF 
	SELECT hold_text INTO l_rec_holdpay.hold_text 
	FROM holdpay 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND hold_code = glob_rec_voucher.hold_code 
	IF status = NOTFOUND THEN 
		LET l_rec_holdpay.hold_text = NULL 
	END IF 
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
			l_rec_vendor.type_code) 
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

	DISPLAY BY NAME l_rec_vendor.currency_code 
	attribute(green) 

	DISPLAY BY NAME glob_rec_voucher.vend_code, 
	l_rec_vendor.name_text, 
	glob_rec_voucher.vouch_code, 
	glob_rec_voucher.inv_text, 
	glob_rec_voucher.batch_num, 
	glob_rec_voucher.vouch_date, 
	glob_rec_voucher.due_date, 
	glob_rec_voucher.conv_qty, 
	glob_rec_voucher.withhold_tax_ind, 
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
	l_rec_tax.desc_text, 
	l_rec_term.desc_text 
	TO owing_amt, 
	tax.desc_text, 
	term.desc_text 

	DISPLAY l_pptax_amt 
	TO pptax_amt 

END FUNCTION 


############################################################
# FUNCTION disp_payee_det(p_rec_vouchpayee)
#
# FUNCTION: disp_payee_det
# Description: Displays the sundry voucher payee details.
# Note:        A copy of the same FUNCTION IS in "vohdwind" AND "P45"
#               - (TO save heaps of makefile changes)
############################################################
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
	OPEN WINDOW p515 at 4,9 with FORM "P515" 
	CALL windecoration_p("P515") 

	DISPLAY p_rec_vouchpayee.name_text TO name_text 
	DISPLAY p_rec_vouchpayee.addr1_text TO addr1_text 
	DISPLAY p_rec_vouchpayee.addr2_text TO addr2_text 
	DISPLAY p_rec_vouchpayee.addr3_text TO addr3_text 
	DISPLAY p_rec_vouchpayee.city_text TO city_text 
	DISPLAY p_rec_vouchpayee.state_code TO state_code 
	DISPLAY p_rec_vouchpayee.post_code TO post_code 
	DISPLAY p_rec_vouchpayee.country_code TO country_code --@db-patch_2020_10_04-- 
	DISPLAY p_rec_vouchpayee.pay_meth_ind TO pay_meth_ind 
	DISPLAY l_method_text TO method_text 
	DISPLAY l_bic_text TO bic_text 
	DISPLAY l_acct_text TO acct_text 

	LET l_msgresp = kandoomsg("U",2,"") 
	# Any Key TO Continue
	CLOSE WINDOW p515 

END FUNCTION 


