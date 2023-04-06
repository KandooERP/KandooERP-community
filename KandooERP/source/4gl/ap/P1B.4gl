#Vendor Ledger
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


{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - P1B

#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P1_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
#DEFINE l_msgresp LIKE language.yes_flag
DEFINE modu_rec_apaudit RECORD LIKE apaudit.* 
#DEFINE pr_voucher RECORD LIKE voucher.*
#DEFINE pr_debithead RECORD LIKE debithead.*
#DEFINE pr_cheque RECORD LIKE cheque.*
#DEFINE glob_rec_vendor RECORD LIKE vendor.*
DEFINE modu_arr_rec_audit DYNAMIC ARRAY OF 
RECORD --array[320] OF RECORD 
	tran_date LIKE apaudit.tran_date, 
	seq_num LIKE apaudit.seq_num, 
	trantype_ind LIKE apaudit.trantype_ind, 
	source_num LIKE apaudit.source_num, 
	tran_text LIKE apaudit.tran_text, 
	tran_amt LIKE apaudit.tran_amt, 
	bal_amt LIKE apaudit.bal_amt 
END RECORD 
#DEFINE pr_bank_code LIKE cheque.bank_code

#huho 14.03.2019       pr_rec_kandoouser RECORD LIKE kandoouser.*,
#DEFINE idx SMALLINT
#DEFINE id_flag SMALLINT
#DEFINE cnt SMALLINT
#DEFINE err_flag SMALLINT
DEFINE modu_passed_cmpy LIKE company.cmpy_code 
DEFINE modu_passed_vend LIKE vendor.vend_code 
#DEFINE ans CHAR(1)



############################################################
# MAIN
#
# Purpose - allows the user TO view vendor activity in date ORDER
#           AND TO reveiw in more detail the various transactions
############################################################
MAIN 
	DEFINE l_err_flag SMALLINT 

	#Initial UI Init
	CALL setModuleId("P1B") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW wp106 with FORM "P106" 
	CALL winDecoration_p("P106") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	IF NOT (get_url_company_code() OR get_url_vendor_code()) THEN #num_args() > 0 THEN 
		LET modu_passed_cmpy = get_url_company_code() #arg_val(1) 
		LET modu_passed_vend = get_url_vendor_code() #arg_val(2) 
		LET l_err_flag = getledg() 
	ELSE 
		WHILE getledg() 
		END WHILE 
	END IF 

	CLOSE WINDOW wp106 

END MAIN 


############################################################
# FUNCTION getledg()
#
#
############################################################
FUNCTION getledg() 
	DEFINE l_filter_tran_date LIKE apaudit.tran_date #huho FOR initial DATE search 
	DEFINE l_msgresp LIKE language.yes_flag 
	#DEFINE l_rec_voucher RECORD LIKE voucher.* #not used
	DEFINE l_rec_debithead RECORD LIKE debithead.* 
	#DEFINE l_rec_cheque RECORD LIKE cheque.* #not used
	DEFINE l_idx SMALLINT 

	CLEAR FORM 
	LET l_msgresp = kandoomsg("P",1043,"") 
	#1043  Enter Vendor Information
	LET l_filter_tran_date = today - 90 
	#LET modu_rec_apaudit.tran_date = today - 90

	IF modu_passed_cmpy IS NOT NULL THEN 
		SELECT * INTO glob_rec_vendor.* FROM vendor 
		WHERE cmpy_code = modu_passed_cmpy 
		AND vend_code = modu_passed_vend 
		LET glob_rec_kandoouser.cmpy_code = modu_passed_cmpy #huho... this needs checking 
		LET modu_rec_apaudit.vend_code = modu_passed_vend 
		DISPLAY BY NAME glob_rec_vendor.name_text, 
		glob_rec_vendor.vend_code 

		DISPLAY BY NAME glob_rec_vendor.currency_code 
		#attribute (green)
	ELSE 
		LET modu_rec_apaudit.vend_code = "" 
	END IF 

	#OPTIONS INSERT KEY F36,
	#        DELETE KEY F36

	INPUT 
	modu_rec_apaudit.vend_code, 
	l_filter_tran_date WITHOUT DEFAULTS 
	FROM 
	vend_code, 
	filter_tran_date 
	ATTRIBUTE(UNBUFFERED) 
	#modu_rec_apaudit.tran_date WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)

		ON ACTION "Lookup" 
			LET modu_rec_apaudit.vend_code = vendorlookup(modu_rec_apaudit.vend_code) 


		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P1B","inp-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield (vend_code) 
			LET modu_rec_apaudit.vend_code = show_vend(glob_rec_kandoouser.cmpy_code,modu_rec_apaudit.vend_code) 
			DISPLAY BY NAME modu_rec_apaudit.vend_code 

			#OPTIONS INSERT KEY F36,
			#        DELETE KEY F36
			NEXT FIELD vend_code 


		BEFORE FIELD vend_code 
			IF modu_passed_vend IS NOT NULL THEN 
				NEXT FIELD NEXT 
			END IF 

		AFTER FIELD vend_code 
			SELECT * INTO glob_rec_vendor.* FROM vendor 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = modu_rec_apaudit.vend_code 

			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("U",9105,"") 
				#9105 RECORD NOT found; Try Window.
				NEXT FIELD vend_code 
			END IF 

			DISPLAY BY NAME glob_rec_vendor.name_text, 
			glob_rec_vendor.vend_code 

			DISPLAY BY NAME glob_rec_vendor.currency_code 
			#attribute (green)

	END INPUT 
	----------------------

	IF int_flag OR quit_flag THEN 
		EXIT PROGRAM 
	END IF 

	DECLARE dledg CURSOR FOR 
	SELECT apaudit.* INTO modu_rec_apaudit.* FROM apaudit 
	WHERE apaudit.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND apaudit.tran_date >= modu_rec_apaudit.tran_date 
	AND apaudit.vend_code = modu_rec_apaudit.vend_code 
	ORDER BY apaudit.vend_code, apaudit.seq_num 

	LET l_idx = 0 

	CALL modu_arr_rec_audit.clear() --init/clear ARRAY 
	FOREACH dledg 
		LET l_idx = l_idx + 1 
		#LET scrn = scr_line()
		LET modu_arr_rec_audit[l_idx].tran_date = modu_rec_apaudit.tran_date 
		LET modu_arr_rec_audit[l_idx].seq_num = modu_rec_apaudit.seq_num 
		LET modu_arr_rec_audit[l_idx].trantype_ind = modu_rec_apaudit.trantype_ind 
		LET modu_arr_rec_audit[l_idx].source_num = modu_rec_apaudit.source_num 
		LET modu_arr_rec_audit[l_idx].tran_text = modu_rec_apaudit.tran_text 
		LET modu_arr_rec_audit[l_idx].tran_amt = modu_rec_apaudit.tran_amt 
		LET modu_arr_rec_audit[l_idx].bal_amt = modu_rec_apaudit.bal_amt 
		#IF l_idx = 300 THEN
		#   LET l_msgresp = kandoomsg("U",6100,l_idx)
		#   #6100 "First l_idx records selected "
		#   EXIT FOREACH
		#END IF

	END FOREACH 

	LET l_msgresp = kandoomsg("U",9113,l_idx) 
	#9113 l_idx records selected
	#CALL set_count(l_idx)

	IF l_idx = 0 THEN 
		LET l_msgresp = kandoomsg("I",9069,"") 
		#9069 No records satisfied selection criteria
	ELSE 
		LET l_msgresp = kandoomsg("P",1007,"") 
		#1007  F3/F4 RETURN TO View
		CALL scanner() 
	END IF 

	RETURN true 
END FUNCTION 



############################################################
# FUNCTION scanner()
#
#
############################################################
FUNCTION scanner() 
	DEFINE l_pay_meth_ind LIKE cheque.pay_meth_ind 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_bank_code LIKE cheque.bank_code 
	DEFINE l_idx SMALLINT 

	DISPLAY ARRAY modu_arr_rec_audit TO sr_apaudit.* ATTRIBUTE(UNBUFFERED) --huho WITHOUT DEFAULTS FROM sr_apaudit.* ATTRIBUTE(UNBUFFERED) 

		BEFORE DISPLAY 
			CALL publish_toolbar("kandoo","P1B","inp-arr-vendor-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()
			LET modu_rec_apaudit.tran_date = modu_arr_rec_audit[l_idx].tran_date 

			#AFTER FIELD tran_date
			#   IF fgl_lastkey() = fgl_keyval("down")
			#   AND arr_curr() >= arr_count() THEN
			#      LET l_msgresp = kandoomsg("U",9001,"")
			#      #9001 There no more rows...
			#      NEXT FIELD tran_date
			#   END IF
			#
			#   IF fgl_lastkey() = fgl_keyval("down") THEN
			#      IF modu_arr_rec_audit[l_idx+1].tran_date IS NULL
			#      OR modu_arr_rec_audit[l_idx+1].tran_date = "31/12/1899" THEN
			#         LET l_msgresp = kandoomsg("U",9001,"")
			#         #9001 There no more rows...
			#         NEXT FIELD tran_date
			#      END IF
			#   END IF
			#
			#   IF fgl_lastkey() = fgl_keyval("nextpage")
			#   AND (modu_arr_rec_audit[l_idx+10].tran_date IS NULL
			#   OR modu_arr_rec_audit[l_idx+10].tran_date = "31/12/1899") THEN
			#      LET l_msgresp = kandoomsg("U",9001,"")
			#      #9001 No more rows in this direction
			#      NEXT FIELD tran_date
			#   END IF

		ON ACTION "DOUBLECLICK" #"ACCEPT" 
			#BEFORE FIELD seq_num
			#             IF modu_rec_apaudit.tran_date IS NULL
			#             OR modu_rec_apaudit.tran_date = "31/12/1899" THEN
			#                NEXT FIELD tran_date
			#             END IF

			IF modu_rec_apaudit.tran_date != modu_arr_rec_audit[l_idx].tran_date THEN 
				LET modu_arr_rec_audit[l_idx].tran_date = modu_rec_apaudit.tran_date 
				#DISPLAY modu_arr_rec_audit[l_idx].tran_date
				#     TO sr_apaudit[scrn].tran_date
				#NEXT FIELD tran_date

			ELSE 
				#                 IF modu_arr_rec_audit[l_idx].trantype_ind = "VO" OR
				#                    modu_arr_rec_audit[l_idx].trantype_ind = "VD" OR
				#                     modu_arr_rec_audit[l_idx].trantype_ind = "TF" THEN
				#                     CALL display_voucher_header(glob_rec_kandoouser.cmpy_code,
				#                                       modu_arr_rec_audit[l_idx].source_num )
				#         #            NEXT FIELD tran_date
				#                 END IF

				CASE modu_arr_rec_audit[l_idx].trantype_ind 

					WHEN "VO" 
						CALL display_voucher_header(glob_rec_kandoouser.cmpy_code, modu_arr_rec_audit[l_idx].source_num ) 

					WHEN "VD" 
						CALL display_voucher_header(glob_rec_kandoouser.cmpy_code, modu_arr_rec_audit[l_idx].source_num ) 

					WHEN "TF" 
						CALL display_voucher_header(glob_rec_kandoouser.cmpy_code, modu_arr_rec_audit[l_idx].source_num ) 

					WHEN "CH" 
						#                 IF modu_arr_rec_audit[l_idx].trantype_ind = "CH" THEN
						LET l_pay_meth_ind = "1" 

						IF modu_arr_rec_audit[l_idx].tran_text matches "*EFT*" THEN 
							LET l_pay_meth_ind = "3" 
						END IF 

						IF modu_arr_rec_audit[l_idx].tran_text matches "Direct*" THEN 
							LET l_pay_meth_ind = "4" 
						END IF 

						#Bank code IS always NULL because we dont have the info
						LET l_rec_bank_code = NULL 
						CALL disp_ck_head(glob_rec_kandoouser.cmpy_code, 
						modu_rec_apaudit.vend_code, 
						modu_arr_rec_audit[l_idx].source_num, 
						l_pay_meth_ind, 
						l_rec_bank_code, 
						modu_arr_rec_audit[l_idx].tran_amt * -1) 
						#           NEXT FIELD tran_date
						#                END IF
					WHEN "CC" 
						#                 IF modu_arr_rec_audit[l_idx].trantype_ind = "CC" THEN
						LET l_msgresp = kandoomsg("P",7082,"") 
						#9193 " Payment Cancelled FROM within Cycle"
						#          NEXT FIELD tran_date
						#                 END IF

					WHEN "PP" 
						#                 IF modu_arr_rec_audit[l_idx].trantype_ind = "PP" THEN
						LET l_msgresp = kandoomsg("P",9192,"") 
						#9192 " Chq no has NOT been allocated - Chq cycle in prog"
						#          NEXT FIELD tran_date
						#                 END IF

					WHEN "DB" 
						#                 IF modu_arr_rec_audit[l_idx].trantype_ind = "DB" THEN
						CALL disp_dm_head(glob_rec_kandoouser.cmpy_code, 
						modu_arr_rec_audit[l_idx].source_num ) 
						#           NEXT FIELD tran_date
						#                 END IF

					OTHERWISE 
						ERROR "modu_arr_rec_audit[l_idx].trantype_ind=", modu_arr_rec_audit[l_idx].trantype_ind 
						#7037 Invalid transaction type.
						LET l_msgresp = kandoomsg("I",7037,"") 
						EXIT DISPLAY 
				END CASE 
			END IF 

			#7037 Invalid transaction type.
			#       NEXT FIELD tran_date
			#             END IF

			#             LET l_msgresp = "Y" #huho what does this help ?

			# EXIT DISPLAY

	END DISPLAY 
	########################

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 

END FUNCTION 


