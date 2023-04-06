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

	Source code beautified by beautify.pl on 2020-01-02 10:35:39	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - vinwind.4gl

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


##################################################################################
# FUNCTION vinq_vend(p_cmpy_code,p_vend_code)
#
# Purpose - Displays OPTIONS FOR user TO DISPLAY details WHEN doing a
#           vendor inquiry.
##################################################################################
FUNCTION vinq_vend(p_cmpy_code,p_vend_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_arr_rec_vendmenu DYNAMIC ARRAY OF 
	RECORD 
		option_num CHAR(1), 
		option_text CHAR(30) 
	END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_arg1,l_arg2 STRING #to CALL external program 
	DEFINE l_msg STRING 
	DEFINE i SMALLINT

	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy_code 
	AND vend_code = p_vend_code 
	IF STATUS = NOTFOUND THEN 
		LET l_msgresp=kandoomsg("P",9014,"") 
		#9014 Logic Error: Vendor NOT found
	ELSE 

		FOR i = 1 TO 10 
			CASE i 
				WHEN "1" ## general details 
					LET l_idx = 1 
					LET l_arr_rec_vendmenu[l_idx].option_num = "1" 
					LET l_arr_rec_vendmenu[l_idx].option_text = kandooword("vinwind",i) 

				WHEN "2" ## credit STATUS 
					LET l_idx = l_idx + 1 
					LET l_arr_rec_vendmenu[l_idx].option_num = "2" 
					LET l_arr_rec_vendmenu[l_idx].option_text = kandooword("vinwind",i) 

				WHEN "3" ## history 
					SELECT unique 1 FROM vendorhist 
					WHERE cmpy_code = p_cmpy_code 
					AND vend_code = p_vend_code 
					IF STATUS = 0 THEN 
						LET l_idx = l_idx + 1 
						LET l_arr_rec_vendmenu[l_idx].option_num = "3" 
						LET l_arr_rec_vendmenu[l_idx].option_text = kandooword("vinwind",i) 
					END IF 

				WHEN "4" ## ledger 
					LET l_idx = l_idx + 1 
					LET l_arr_rec_vendmenu[l_idx].option_num = "4" 
					LET l_arr_rec_vendmenu[l_idx].option_text = kandooword("vinwind",i) 

				WHEN "5" ## subcontractors 
					SELECT unique 1 FROM contractor 
					WHERE cmpy_code = p_cmpy_code 
					AND vend_code = p_vend_code 
					IF STATUS = 0 THEN 
						LET l_idx = l_idx + 1 
						LET l_arr_rec_vendmenu[l_idx].option_num = "5" 
						LET l_arr_rec_vendmenu[l_idx].option_text = kandooword("vinwind",i) 
					END IF 

				WHEN "6" ## oustanding vouchers 
					SELECT unique 1 FROM voucher 
					WHERE cmpy_code = p_cmpy_code 
					AND vend_code = p_vend_code 
					AND total_amt != paid_amt 
					IF STATUS = 0 THEN 
						LET l_idx = l_idx + 1 
						LET l_arr_rec_vendmenu[l_idx].option_num = "6" 
						LET l_arr_rec_vendmenu[l_idx].option_text = kandooword("vinwind",i) 
					END IF 

				WHEN "7" ## payment details 
					LET l_idx = l_idx + 1 
					LET l_arr_rec_vendmenu[l_idx].option_num = "7" 
					LET l_arr_rec_vendmenu[l_idx].option_text = kandooword("vinwind",i) 

				WHEN "8" ## purchase details 
					LET l_idx = l_idx + 1 
					LET l_arr_rec_vendmenu[l_idx].option_num = "8" 
					LET l_arr_rec_vendmenu[l_idx].option_text = kandooword("vinwind",i) 
				OTHERWISE 
					EXIT FOR 

			END CASE 

		END FOR 

		OPEN WINDOW w_vinwind with FORM "P212" attribute(BORDER, STYLE="CENTER") 
		CALL windecoration_p("P212") 


		DISPLAY BY NAME l_rec_vendor.vend_code, 
		l_rec_vendor.name_text 

		CALL set_count(l_idx) 
		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 
		LET l_msgresp=kandoomsg("A",1030,"") 

		DISPLAY ARRAY l_arr_rec_vendmenu TO sr_vendmenu.* ATTRIBUTE(UNBUFFERED) --huho WITHOUT DEFAULTS FROM sr_vendmenu.* 
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","vinwind","input-arr-vendmenu") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			BEFORE ROW 
				LET l_idx = arr_curr() 
				#LET scrn = scr_line()
				#DISPLAY l_arr_rec_vendmenu[l_idx].* TO sr_vendmenu[scrn].*

				#AFTER FIELD scroll_flag
				#   --#IF fgl_lastkey() = fgl_keyval("accept")
				#   --#AND fgl_fglgui() THEN
				#   --#   NEXT FIELD option_num
				#   --#END IF
				#   IF l_arr_rec_vendmenu[l_idx].scroll_flag IS NULL THEN
				#      IF fgl_lastkey() = fgl_keyval("down")
				#      AND arr_curr() = arr_count() THEN
				#         LET l_msgresp=kandoomsg("A",9001,"")
				#         NEXT FIELD scroll_flag
				#      END IF
				#   END IF
				#BEFORE FIELD option_num
				#   IF l_arr_rec_vendmenu[l_idx].scroll_flag IS NULL THEN
				#      LET l_arr_rec_vendmenu[l_idx].scroll_flag = l_arr_rec_vendmenu[l_idx].option_num
				#   ELSE
				#      LET i = 1
				#      WHILE (l_arr_rec_vendmenu[l_idx].scroll_flag IS NOT NULL)
				#         IF l_arr_rec_vendmenu[i].option_num IS NULL THEN
				#            LET l_arr_rec_vendmenu[l_idx].scroll_flag = NULL
				#         ELSE
				#            IF l_arr_rec_vendmenu[l_idx].scroll_flag =
				#               l_arr_rec_vendmenu[i].option_num THEN
				#               EXIT WHILE
				#            END IF
				#         END IF
				#         LET i = i + 1
				#      END WHILE
				#   END IF
				#
			ON ACTION "ACCEPT" 
				LET l_arg1 = "COMPANY_CODE=", trim(p_cmpy_code)    #LET l_arg1 = "COMPANY_CODE=", trim(getcurrentuser_cmpy_code()) #do we NEED TO keep this ? 
				LET l_arg2 = "VENDOR_CODE=", trim(p_vend_code) 
				CASE l_arr_rec_vendmenu[l_idx].option_num -- huho l_arr_rec_vendmenu[l_idx].scroll_flag 
					WHEN "1" 
						CALL vinq_dets(p_cmpy_code,p_vend_code) 
					WHEN "2" 
						CALL vinq_cred(p_cmpy_code,p_vend_code) 
					WHEN "3" #huho 7.5.2019 
						IF db_vendorhist_get_vendor_count(p_vend_code) < 1 THEN 
							LET l_msg = "There IS no history for Vendor ", p_vend_code 
							CALL fgl_winmessage("Vendor History",l_msg, "info") 
						ELSE 
							CALL run_prog("P1A",l_arg1,l_arg2,"","") 
						END IF 

					WHEN "4" 
						CALL run_prog("P1B",l_arg1,l_arg2,"","") 
					WHEN "5" 
						CALL vinq_subc(l_arg1,l_arg2) 
					WHEN "6" 

						OPEN WINDOW p213 with FORM "P213" 
						CALL windecoration_p("P213") 

						CALL vinq_vouc(p_cmpy_code,p_vend_code) 
						CLOSE WINDOW p213 
					WHEN "7" 
						CALL vinq_payd(p_cmpy_code,p_vend_code) 
					WHEN "8" 
						CALL vinq_purchd(p_cmpy_code,p_vend_code) 
				END CASE 
				#OPTIONS INSERT KEY F36,
				#        DELETE KEY F36
				#LET l_arr_rec_vendmenu[l_idx].scroll_flag = NULL
				#NEXT FIELD scroll_flag
				#AFTER ROW
				#   DISPLAY l_arr_rec_vendmenu[l_idx].* TO sr_vendmenu[scrn].*



		END DISPLAY 

		CLOSE WINDOW w_vinwind 

	END IF 

	LET int_flag = false 
	LET quit_flag = false 
END FUNCTION 

##################################################################################
# FUNCTION vinq_payd(p_cmpy,p_vend_code)
#
#
##################################################################################
FUNCTION vinq_payd(p_cmpy,p_vend_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_bank RECORD LIKE bank.* 
	DEFINE l_method_text CHAR(30) 
	DEFINE l_bic_text LIKE vendor.bank_acct_code 
	DEFINE l_acct_text LIKE vendor.bank_acct_code 
	DEFINE l_msgresp LIKE language.yes_flag 

	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = p_vend_code 


	CASE l_rec_vendor.country_code 
		WHEN "US" --usa 
			OPEN WINDOW p116 with FORM "P116US" 
			CALL windecoration_p("P116UA") 
		WHEN "NZ" 
			OPEN WINDOW p116 with FORM "P116NZ" 
			CALL windecoration_p("P116NZ") 
		WHEN "AU" 
			OPEN WINDOW p116 with FORM "P116AU" 
			CALL windecoration_p("P116AU") 
		WHEN "UA" --ukraine 
			OPEN WINDOW p116 with FORM "P116UA" 
			CALL windecoration_p("P116UA") 
		OTHERWISE --eu default 
			OPEN WINDOW p116 with FORM "P116EU" 
			CALL windecoration_p("P116EU") 
	END CASE 




	IF l_rec_vendor.pay_meth_ind IS NOT NULL THEN 
		LET l_method_text = kandooword("vendor.pay_meth_ind",l_rec_vendor.pay_meth_ind) 
		DISPLAY l_method_text TO method_text 

	END IF 

	IF l_rec_vendor.bank_code IS NOT NULL THEN 
		SELECT name_acct_text INTO l_rec_bank.name_acct_text FROM bank 
		WHERE cmpy_code = p_cmpy 
		AND bank_code = l_rec_vendor.bank_code 
		IF STATUS = NOTFOUND THEN 
			LET l_rec_bank.name_acct_text = "**********" 
		END IF 
		DISPLAY BY NAME l_rec_bank.name_acct_text 

	END IF 

	#   LET l_bic_text = l_rec_vendor.bank_acct_code[1,6]
	#   LET l_acct_text = l_rec_vendor.bank_acct_code[8,20]

	DISPLAY 
	l_rec_vendor.pay_meth_ind, 
	l_rec_vendor.bank_code, 
	l_rec_vendor.drop_flag, 
	l_rec_vendor.contra_cust_code, 
	l_rec_vendor.contra_meth_ind, 
	l_bic_text, 
	l_acct_text 
	TO 
	pay_meth_ind, 
	bank_code, 
	drop_flag, 
	contra_cust_code, 
	contra_meth_ind, 
	bic_text, 
	acct_text 


	#LET l_msgresp = kandoomsg("U",1,"")
	CALL eventsuspend() 

	CLOSE WINDOW p116 

END FUNCTION 


##################################################################################
# FUNCTION vinq_purchd(p_cmpy,p_vend_code)
#
#
##################################################################################
FUNCTION vinq_purchd(p_cmpy,p_vend_code) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_vend_code LIKE vendor.vend_code 
	DEFINE l_rec_vendor RECORD LIKE vendor.* 
	DEFINE l_rec_purchtype RECORD LIKE purchtype.* 
	DEFINE l_rec_vendorgrp RECORD LIKE vendorgrp.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW p118 with FORM "P118" 
	CALL windecoration_p("P118") 

	SELECT * INTO l_rec_vendor.* FROM vendor 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = p_vend_code 

	DISPLAY BY NAME l_rec_vendor.currency_code 
	attribute(green) 

	IF l_rec_vendor.purchtype_code IS NOT NULL THEN 
		SELECT desc_text INTO l_rec_purchtype.desc_text FROM purchtype 
		WHERE cmpy_code = p_cmpy 
		AND purchtype_code = l_rec_vendor.purchtype_code 
		IF STATUS = NOTFOUND THEN 
			LET l_rec_purchtype.desc_text = "**********" 
		END IF 
		DISPLAY BY NAME l_rec_purchtype.desc_text 

	END IF 
	DECLARE c_vendorgrp CURSOR FOR 
	SELECT * FROM vendorgrp 
	WHERE cmpy_code = p_cmpy 
	AND vend_code = p_vend_code 
	OPEN c_vendorgrp 
	FETCH c_vendorgrp INTO l_rec_vendorgrp.* 

	IF l_rec_vendorgrp.vend_code = l_rec_vendor.vend_code THEN 
		DISPLAY l_rec_vendorgrp.desc_text TO vendorgrp.desc_text 

	END IF 

	DISPLAY BY NAME l_rec_vendor.purchtype_code, 
	l_rec_vendor.backorder_flag, 
	l_rec_vendor.min_ord_amt, 
	l_rec_vendor.po_var_amt, 
	l_rec_vendor.po_var_per, 
	l_rec_vendorgrp.mast_vend_code 

	#LET l_msgresp = kandoomsg("U",1,"")
	CALL eventsuspend() 

	CLOSE WINDOW p118 

END FUNCTION 


