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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P1_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################
#DEFINE l_rec_apaudit RECORD LIKE apaudit.*
#DEFINE l_rec_voucher RECORD LIKE voucher.*
#DEFINE l_rec_debithead RECORD LIKE debithead.*
#DEFINE pr_cheque RECORD LIKE cheque.*
#DEFINE l_arr_rec_audit DYNAMIC ARRAY OF
#	RECORD  --huho array[520] of record
#		tran_date LIKE apaudit.tran_date,
#		l_vend_code LIKE apaudit.vend_code,
#		currency_code LIKE vendor.currency_code,
#		seq_num LIKE apaudit.seq_num,
#		trantype_ind LIKE apaudit.trantype_ind,
#		source_num LIKE apaudit.source_num,
#		tran_text LIKE apaudit.tran_text,
#		tran_amt LIKE apaudit.tran_amt
#	END RECORD
#DEFINE vmname  LIKE vendor.name_text
#DEFINE l_bank_code LIKE cheque.bank_code

#DEFINE l_start_date date
#DEFINE l_end_date date
#DEFINE none_found SMALLINT
#DEFINE l_idx SMALLINT
#DEFINE id_flag SMALLINT
#DEFINE cnt SMALLINT
#DEFINE err_flag SMALLINT
#DEFINE l_where_part CHAR(400)
#DEFINE l_query_text CHAR(400)


############################################################
# MAIN
#
# P1C - Allows the user TO scan the daily Payables activity AND TO
#       review the Audit Trail
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P1C") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_p_ap() #init p/ap module 

	OPTIONS DELETE KEY f36 
	OPTIONS INSERT KEY f36 

	OPEN WINDOW wp109 with FORM "P109" 
	CALL winDecoration_p("P109") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	#LET none_found = 0  #huho where else was this used ? comment it
	WHILE getlog() 
	END WHILE 

	CLOSE WINDOW wp109 

END MAIN 


############################################################
# FUNCTION getlog()
#
#
############################################################
FUNCTION getlog() 
	DEFINE l_pay_meth_ind LIKE cheque.pay_meth_ind 
	DEFINE l_vend_code VARCHAR(30) --huho 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_where_part STRING 
	DEFINE l_query_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE l_start_date DATE 
	DEFINE l_end_date DATE 
	DEFINE l_bank_code LIKE cheque.bank_code 
	DEFINE l_rec_apaudit RECORD LIKE apaudit.* 
	DEFINE l_rec_voucher RECORD LIKE voucher.* 
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	DEFINE l_arr_rec_audit DYNAMIC ARRAY OF t_rec_audit_td_vc_cc_sn_ti_sn_tt_ta 
	#	DEFINE l_arr_rec_audit DYNAMIC ARRAY OF
	#		RECORD  --huho array[520] of record
	#			tran_date LIKE apaudit.tran_date,
	#			vend_code LIKE apaudit.vend_code,
	#			currency_code LIKE vendor.currency_code,
	#			seq_num LIKE apaudit.seq_num,
	#			trantype_ind LIKE apaudit.trantype_ind,
	#			source_num LIKE apaudit.source_num,
	#			tran_text LIKE apaudit.tran_text,
	#			tran_amt LIKE apaudit.tran_amt
	#		END RECORD

	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1020,"Date") 
	#1020 "Enter Audit Details; OK TO Continue"
	LET l_start_date = TODAY 
	LET l_end_date = TODAY 

	INPUT l_start_date, l_end_date WITHOUT DEFAULTS FROM start_date, end_date 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P1C","inp-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 



		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_end_date < l_start_date THEN 
					LET l_msgresp = kandoomsg("A",9095,"") 
					#9095 " END date must be greater OR equal TO start date "
					NEXT FIELD start_date 
				END IF 
			END IF 
			{
			################
			   LET l_msgresp = kandoomsg("U",1001,"")
			#1001 Enter Selection Criteria; OK TO Continue
			   CONSTRUCT BY NAME l_where_part on l_vend_code --huhoapaudit.vend_code

					BEFORE CONSTRUCT
						CALL publish_toolbar("kandoo","P1C","construct-vendor_code-1")

					ON ACTION "WEB-HELP"
						CALL onlineHelp(getModuleId(),NULL)
						ON ACTION "actToolbarManager"
					 	CALL setupToolbar()

					ON ACTION "Lookup"
						LET l_vend_code = vendorLookup(l_vend_code)
						DISPLAY l_vend_code TO filter.vend_code

				END CONSTRUCT

			   IF int_flag OR quit_flag THEN
			   	LET int_flag = FALSE
			      EXIT PROGRAM
			   END IF
			#################
			}


	END INPUT 

	IF int_flag OR quit_flag THEN 
		EXIT PROGRAM 
	END IF 

	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria; OK TO Continue
	CONSTRUCT BY NAME l_where_part ON vend_code --huho apaudit.vend_code 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P1C","construct-vendor_code-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "Lookup" infield(vend_code) 
			LET l_vend_code = vendorlookup(l_vend_code) 
			DISPLAY l_vend_code TO filter.vend_code 
			DISPLAY l_vend_code TO apaudit.vend_code 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		EXIT PROGRAM 
	END IF 

	LET l_msgresp = kandoomsg("P",1002,"") 
	#1002  Searching Database - please wait
	LET l_query_text = 
	"SELECT * FROM apaudit ", 
	" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" AND ", 
	" entry_date >= \"",l_start_date,"\" AND ", 
	" entry_date <= \"",l_end_date,"\" AND ", 
	l_where_part clipped, 
	" ORDER BY entry_date, vend_code, seq_num" 

	PREPARE choice FROM l_query_text 
	DECLARE c_log CURSOR FOR choice 

	LET l_idx = 0 
	CALL l_arr_rec_audit.clear() 
	FOREACH c_log INTO l_rec_apaudit.* 
		LET l_idx = l_idx + 1 
		#LET scrn = scr_line()
		LET l_arr_rec_audit[l_idx].tran_date = l_rec_apaudit.tran_date 
		LET l_arr_rec_audit[l_idx].vend_code = l_rec_apaudit.vend_code 

		SELECT vendor.currency_code INTO l_arr_rec_audit[l_idx].currency_code FROM vendor 
		WHERE vendor.vend_code = l_rec_apaudit.vend_code 
		AND vendor.cmpy_code = glob_rec_kandoouser.cmpy_code 

		LET l_arr_rec_audit[l_idx].seq_num = l_rec_apaudit.seq_num 
		LET l_arr_rec_audit[l_idx].trantype_ind = l_rec_apaudit.trantype_ind 
		LET l_arr_rec_audit[l_idx].source_num = l_rec_apaudit.source_num 
		LET l_arr_rec_audit[l_idx].tran_text = l_rec_apaudit.tran_text 
		LET l_arr_rec_audit[l_idx].tran_amt = l_rec_apaudit.tran_amt 
		#      IF l_idx = 500 THEN
		#         LET l_msgresp = kandoomsg("U",6100,l_idx)
		#         #6100 "First l_idx records selected "
		#         EXIT FOREACH
		#      END IF
	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_idx) 
	#9113 l_idx records selected
	#   CALL set_count(l_idx)

	IF l_idx = 0 THEN 
		LET l_msgresp = kandoomsg("I",9069,"") 
		#9069 No Records Satisfied Selection The Search Criteria
		RETURN TRUE 
	END IF 

	LET l_msgresp = kandoomsg("P",1007,"") 
	#1007  F3/F4 RETURN on line TO View
	#INPUT ARRAY l_arr_rec_audit WITHOUT DEFAULTS FROM sr_apaudit.* ATTRIBUTE(UNBUFFERED)
	DISPLAY ARRAY l_arr_rec_audit TO sr_apaudit.* --without DEFAULTS FROM sr_apaudit.* ATTRIBUTE(UNBUFFERED) 
		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","P1C","inp-arr-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_rec_apaudit.vend_code = l_arr_rec_audit[l_idx].vend_code 

			#      AFTER FIELD vend_code
			#         IF fgl_lastkey() = fgl_keyval("down")
			#         AND arr_curr() >= arr_count() THEN
			#             LET l_msgresp = kandoomsg("U",9001,"")
			#             #9001 There no more rows...
			#             NEXT FIELD vend_code
			#         END IF
			#
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF l_arr_rec_audit[l_idx+1].vend_code IS NULL THEN
			#              LET l_msgresp = kandoomsg("U",9001,"")
			#              #9001 There no more rows...
			#              NEXT FIELD vend_code
			#            END IF
			#         END IF
			#
			#         IF fgl_lastkey() = fgl_keyval("nextpage")
			#         AND l_arr_rec_audit[l_idx+10].vend_code IS NULL THEN
			#            LET l_msgresp = kandoomsg("U",9001,"")
			#            #9001 No more rows in this direction
			#            NEXT FIELD vend_code
			#         END IF


			#BEFORE FIELD currency_code
		ON ACTION "ACCEPT" 
			IF l_rec_apaudit.vend_code != l_arr_rec_audit[l_idx].vend_code THEN 
				LET l_arr_rec_audit[l_idx].vend_code = l_rec_apaudit.vend_code 
			ELSE 
				IF l_arr_rec_audit[l_idx].trantype_ind = "VO" OR 
				l_arr_rec_audit[l_idx].trantype_ind = "VD" OR 
				l_arr_rec_audit[l_idx].trantype_ind = "TF" THEN 
					CALL display_voucher_header( glob_rec_kandoouser.cmpy_code, l_arr_rec_audit[l_idx].source_num ) 
				END IF 

				IF l_arr_rec_audit[l_idx].trantype_ind = "CH" THEN 
					LET l_pay_meth_ind = "1" 
					IF l_arr_rec_audit[l_idx].tran_text matches "*EFT*" THEN 
						LET l_pay_meth_ind = "3" 
					END IF 
					#Bank code IS always NULL because we dont have the info
					LET l_bank_code = NULL 
					CALL disp_ck_head(glob_rec_kandoouser.cmpy_code, 
					l_rec_apaudit.vend_code, 
					l_arr_rec_audit[l_idx].source_num, 
					l_pay_meth_ind, 
					l_bank_code, 
					l_arr_rec_audit[l_idx].tran_amt * -1) 
				END IF 

				IF l_arr_rec_audit[l_idx].trantype_ind = "CC" THEN 
					LET l_msgresp = kandoomsg("P",7082,"") 
					#9193 " Payment Cancelled FROM within Cycle"
					#NEXT FIELD tran_date
				END IF 

				IF l_arr_rec_audit[l_idx].trantype_ind = "PP" THEN 
					LET l_msgresp = kandoomsg("P",9192,"") 
					#9192 " Chq no has NOT been allocated - Chq cycle in prog"
					#NEXT FIELD tran_date
				END IF 

				IF l_arr_rec_audit[l_idx].trantype_ind = "DB" THEN 
					CALL disp_dm_head( glob_rec_kandoouser.cmpy_code, l_arr_rec_audit[l_idx].source_num ) 
				END IF 

			END IF 

			#         NEXT FIELD vend_code



	END DISPLAY 

	LET int_flag = FALSE 
	LET quit_flag = FALSE 

	RETURN TRUE 
END FUNCTION 


