# AP Parameters PZP
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

	Source code beautified by beautify.pl on 2020-01-03 13:41:52	$Id: $
}
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
############################################################
# Module Scope Variables
############################################################

############################################################
# MAIN
#
# \brief module PZP Accounts Payables Parameters
#                 provides FOR the maintenance of AP Parameters
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("PZP") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 


	OPEN WINDOW p140 with FORM "P140" 
	CALL windecoration_p("P140") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	MENU "Parameters" 
		BEFORE MENU 
			IF disp_parm() THEN 
				HIDE option "Add" 
			ELSE 
				HIDE option "EDIT" 
			END IF 

			CALL publish_toolbar("kandoo","PZP","menu-parameters-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		COMMAND "EDIT" " Edit Parameters" 
			CALL change_parm() 
			IF disp_parm() THEN 
			END IF 

		COMMAND "Add" " Add Parameters" 
			IF add_parm() THEN 
				HIDE option "Add" 
				SHOW option "Change" 
			END IF 
			IF disp_parm() THEN 
			END IF 

		COMMAND KEY(interrupt) "Exit" " Exit TO menus" 
			EXIT MENU 

	END MENU 

	CLOSE WINDOW p140 
END MAIN 


############################################################
# FUNCTION add_parm()
#
#
############################################################
FUNCTION add_parm() 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_rec_apparms RECORD LIKE apparms.* 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue.
	INITIALIZE l_rec_apparms.* TO NULL 
	LET l_rec_apparms.last_chq_prnt_date = today 
	LET l_rec_apparms.last_aging_date = today 
	LET l_rec_apparms.last_del_date = today 
	LET l_rec_apparms.next_vouch_num = 1 
	LET l_rec_apparms.next_deb_num = 1 
	LET l_rec_apparms.last_mail_date = today 
	LET l_rec_apparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET l_rec_apparms.parm_code = "1" 
	LET l_rec_apparms.gl_detl_flag = "N" 
	LET l_rec_apparms.vouch_approve_flag = "N" 
	LET l_rec_apparms.report_ord_flag = "C" 

	INPUT BY NAME l_rec_apparms.next_vouch_num, 
	l_rec_apparms.next_deb_num, 
	l_rec_apparms.chq_jour_code, 
	l_rec_apparms.pur_jour_code, 
	l_rec_apparms.bank_acct_code, 
	l_rec_apparms.pay_acct_code, 
	l_rec_apparms.freight_acct_code, 
	l_rec_apparms.salestax_acct_code, 
	l_rec_apparms.disc_acct_code, 
	l_rec_apparms.exch_acct_code, 
	l_rec_apparms.last_chq_prnt_date, 
	l_rec_apparms.last_aging_date, 
	l_rec_apparms.last_post_date, 
	l_rec_apparms.last_del_date, 
	l_rec_apparms.gl_flag, 
	l_rec_apparms.vouch_approve_flag, 
	l_rec_apparms.hist_flag, 
	l_rec_apparms.report_ord_flag WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PZP","inp-apparms-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 



		ON KEY (control-b) infield(chq_jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_apparms.chq_jour_code = l_temp_text 
				DISPLAY BY NAME l_rec_apparms.chq_jour_code 

			END IF 
			NEXT FIELD chq_jour_code 
		ON KEY (control-b) infield(pur_jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_apparms.pur_jour_code = l_temp_text 
				DISPLAY BY NAME l_rec_apparms.pur_jour_code 

			END IF 
			NEXT FIELD pur_jour_code 
		ON KEY (control-b) infield (bank_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_apparms.bank_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_apparms.bank_acct_code 

			END IF 
			NEXT FIELD bank_acct_code 
		ON KEY (control-b) infield (pay_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_apparms.pay_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_apparms.pay_acct_code 

			END IF 
			NEXT FIELD pay_acct_code 
		ON KEY (control-b) infield (freight_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_apparms.freight_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_apparms.freight_acct_code 

			END IF 
			NEXT FIELD freight_acct_code 
		ON KEY (control-b) infield (salestax_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_apparms.salestax_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_apparms.salestax_acct_code 

			END IF 
			NEXT FIELD salestax_acct_code 
		ON KEY (control-b) infield (disc_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_apparms.disc_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_apparms.disc_acct_code 

			END IF 
			NEXT FIELD disc_acct_code 
		ON KEY (control-b) infield (exch_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET l_rec_apparms.exch_acct_code = l_temp_text 
				DISPLAY BY NAME l_rec_apparms.exch_acct_code 

			END IF 
			NEXT FIELD exch_acct_code 

		AFTER FIELD next_vouch_num 
			IF l_rec_apparms.next_vouch_num <= 0 
			OR l_rec_apparms.next_vouch_num IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9927,0) 
				#9927 Value must be greater than 0
				NEXT FIELD next_vouch_num 
			END IF 
		AFTER FIELD next_deb_num 
			IF l_rec_apparms.next_deb_num <= 0 
			OR l_rec_apparms.next_vouch_num IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9927,0) 
				#9927 Value must be greater than 0
				NEXT FIELD next_deb_num 
			END IF 
		AFTER FIELD chq_jour_code 
			IF l_rec_apparms.chq_jour_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD chq_jour_code 
			END IF 
			SELECT unique 1 FROM journal 
			WHERE jour_code = l_rec_apparms.chq_jour_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9029,"") 
				#9029 Journal Code Not Found; Try Window.
				NEXT FIELD chq_jour_code 
			END IF 

		AFTER FIELD pur_jour_code 
			IF l_rec_apparms.pur_jour_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD pur_jour_code 
			END IF 
			SELECT unique 1 FROM journal 
			WHERE jour_code = l_rec_apparms.pur_jour_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9029,"") 
				#9029 Journal Code Not Found; Try Window.
				NEXT FIELD pur_jour_code 
			END IF 

		AFTER FIELD bank_acct_code 
			IF l_rec_apparms.bank_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD bank_acct_code 
			END IF 
			SELECT unique 1 FROM coa 
			WHERE acct_code = l_rec_apparms.bank_acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist; Try window.
				NEXT FIELD bank_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_apparms.bank_acct_code,COA_ACCOUNT_REQUIRED_IS_CONTROL_BANK,"") THEN 
				LET l_msgresp = kandoomsg("P",9531,"") 
				#9531 The account code entered IS NOT a bank account code.
				NEXT FIELD bank_acct_code 
			END IF 

		AFTER FIELD pay_acct_code 
			IF l_rec_apparms.pay_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD pay_acct_code 
			END IF 
			SELECT unique 1 FROM coa 
			WHERE acct_code = l_rec_apparms.pay_acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist; Try window.
				NEXT FIELD pay_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_apparms.pay_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER,"") THEN 
				NEXT FIELD pay_acct_code 
			END IF 

		AFTER FIELD freight_acct_code 
			IF l_rec_apparms.freight_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD freight_acct_code 
			END IF 
			SELECT unique 1 FROM coa 
			WHERE acct_code = l_rec_apparms.freight_acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist; Try window.
				NEXT FIELD freight_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_apparms.freight_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD freight_acct_code 
			END IF 

		AFTER FIELD salestax_acct_code 
			IF l_rec_apparms.salestax_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD salestax_acct_code 
			END IF 
			SELECT unique 1 FROM coa 
			WHERE acct_code = l_rec_apparms.salestax_acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist; Try window.
				NEXT FIELD salestax_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_apparms.salestax_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD salestax_acct_code 
			END IF 

		AFTER FIELD disc_acct_code 
			IF l_rec_apparms.disc_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD disc_acct_code 
			END IF 
			SELECT unique 1 FROM coa 
			WHERE acct_code = l_rec_apparms.disc_acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist; Try window.
				NEXT FIELD disc_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_apparms.disc_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD disc_acct_code 
			END IF 

		AFTER FIELD exch_acct_code 
			IF l_rec_apparms.exch_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD exch_acct_code 
			END IF 
			SELECT unique 1 FROM coa 
			WHERE acct_code = l_rec_apparms.exch_acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist; Try window.
				NEXT FIELD exch_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,l_rec_apparms.exch_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD exch_acct_code 
			END IF 

		AFTER FIELD vouch_approve_flag 
			IF l_rec_apparms.vouch_approve_flag IS NULL THEN 
				LET l_rec_apparms.vouch_approve_flag = "N" 
			END IF 

		AFTER FIELD report_ord_flag 
			IF l_rec_apparms.report_ord_flag IS NULL THEN 
				LET l_rec_apparms.report_ord_flag = "C" 
			END IF 

			-----------
		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_apparms.next_vouch_num <= 0 
				OR l_rec_apparms.next_vouch_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9927,0) 
					#9927 Value must be greater than 0
					NEXT FIELD next_vouch_num 
				END IF 
				IF l_rec_apparms.next_deb_num <= 0 
				OR l_rec_apparms.next_vouch_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9927,0) 
					#9927 Value must be greater than 0
					NEXT FIELD next_deb_num 
				END IF 
				IF l_rec_apparms.chq_jour_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD chq_jour_code 
				END IF 
				IF l_rec_apparms.pur_jour_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD pur_jour_code 
				END IF 
				IF l_rec_apparms.bank_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD bank_acct_code 
				END IF 
				IF l_rec_apparms.pay_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD pay_acct_code 
				END IF 
				IF l_rec_apparms.freight_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD freight_acct_code 
				END IF 
				IF l_rec_apparms.salestax_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD salestax_acct_code 
				END IF 
				IF l_rec_apparms.disc_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD disc_acct_code 
				END IF 
				IF l_rec_apparms.exch_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD exch_acct_code 
				END IF 
				INSERT INTO apparms VALUES (l_rec_apparms.*) 
			END IF 

	END INPUT 
	---------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	END IF 

	RETURN true 
END FUNCTION 



############################################################
# FUNCTION add_parm()
#
#
############################################################
FUNCTION change_parm() 
	DEFINE l_rec_apparms RECORD LIKE apparms.* 
	DEFINE l_rec_s_apparms RECORD LIKE apparms.* 
	DEFINE l_temp_vouch_num LIKE apparms.next_vouch_num 
	DEFINE l_temp_deb_num LIKE apparms.next_deb_num 
	DEFINE l_temp_text CHAR(30) 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_msgresp = kandoomsg("U",1070,"") 
	#1070 Enter Parameter details; OK TO continue.
	SELECT * INTO glob_rec_apparms.* FROM apparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	LET l_rec_s_apparms.* = glob_rec_apparms.* 

	INPUT BY NAME glob_rec_apparms.next_vouch_num, 
	glob_rec_apparms.next_deb_num, 
	glob_rec_apparms.chq_jour_code, 
	glob_rec_apparms.pur_jour_code, 
	glob_rec_apparms.bank_acct_code, 
	glob_rec_apparms.pay_acct_code, 
	glob_rec_apparms.freight_acct_code, 
	glob_rec_apparms.salestax_acct_code, 
	glob_rec_apparms.disc_acct_code, 
	glob_rec_apparms.exch_acct_code, 
	glob_rec_apparms.last_chq_prnt_date, 
	glob_rec_apparms.last_aging_date, 
	glob_rec_apparms.last_post_date, 
	glob_rec_apparms.last_del_date, 
	glob_rec_apparms.gl_flag, 
	glob_rec_apparms.vouch_approve_flag, 
	glob_rec_apparms.hist_flag, 
	glob_rec_apparms.report_ord_flag WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","PZP","inp-apparms-2") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (control-b) infield(chq_jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_apparms.chq_jour_code = l_temp_text 
				DISPLAY BY NAME glob_rec_apparms.chq_jour_code 

			END IF 
			NEXT FIELD chq_jour_code 
		ON KEY (control-b) infield(pur_jour_code) 
			LET l_temp_text = show_jour(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_apparms.pur_jour_code = l_temp_text 
				DISPLAY BY NAME glob_rec_apparms.pur_jour_code 

			END IF 
			NEXT FIELD pur_jour_code 
		ON KEY (control-b) infield (bank_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_apparms.bank_acct_code = l_temp_text 
				DISPLAY BY NAME glob_rec_apparms.bank_acct_code 

			END IF 
			NEXT FIELD bank_acct_code 
		ON KEY (control-b) infield (pay_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_apparms.pay_acct_code = l_temp_text 
				DISPLAY BY NAME glob_rec_apparms.pay_acct_code 

			END IF 
			NEXT FIELD pay_acct_code 
		ON KEY (control-b) infield (freight_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_apparms.freight_acct_code = l_temp_text 
				DISPLAY BY NAME glob_rec_apparms.freight_acct_code 

			END IF 
			NEXT FIELD freight_acct_code 
		ON KEY (control-b) infield (salestax_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_apparms.salestax_acct_code = l_temp_text 
				DISPLAY BY NAME glob_rec_apparms.salestax_acct_code 

			END IF 
			NEXT FIELD salestax_acct_code 
		ON KEY (control-b) infield (disc_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_apparms.disc_acct_code = l_temp_text 
				DISPLAY BY NAME glob_rec_apparms.disc_acct_code 

			END IF 
			NEXT FIELD disc_acct_code 
		ON KEY (control-b) infield (exch_acct_code) 
			LET l_temp_text = show_acct(glob_rec_kandoouser.cmpy_code) 
			IF l_temp_text IS NOT NULL THEN 
				LET glob_rec_apparms.exch_acct_code = l_temp_text 
				DISPLAY BY NAME glob_rec_apparms.exch_acct_code 

			END IF 
			NEXT FIELD exch_acct_code 


		BEFORE FIELD next_vouch_num 
			LET l_temp_vouch_num = glob_rec_apparms.next_vouch_num 

		AFTER FIELD next_vouch_num 
			IF l_temp_vouch_num != glob_rec_apparms.next_vouch_num THEN 
				SELECT max(vouch_code) INTO l_temp_vouch_num FROM voucher 
				WHERE voucher.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_temp_vouch_num = l_temp_vouch_num + 1 
			END IF 
			IF glob_rec_apparms.next_vouch_num < l_temp_vouch_num 
			OR glob_rec_apparms.next_vouch_num IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9907,l_temp_vouch_num) 
				#9927 Values must be greater than OR equal TO l_temp_vouch_num
				LET glob_rec_apparms.next_vouch_num = l_temp_vouch_num 
				NEXT FIELD next_vouch_num 
			END IF 

		BEFORE FIELD next_deb_num 
			LET l_temp_deb_num = glob_rec_apparms.next_deb_num 

		AFTER FIELD next_deb_num 
			IF l_temp_deb_num != glob_rec_apparms.next_deb_num THEN 
				SELECT max(debit_num) INTO l_temp_deb_num FROM debithead 
				WHERE debithead.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_temp_deb_num = l_temp_deb_num + 1 
			END IF 
			IF glob_rec_apparms.next_deb_num < l_temp_deb_num 
			OR glob_rec_apparms.next_deb_num IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9907,l_temp_deb_num) 
				#9927 Values must be greater than OR equal TO l_temp_deb_num
				LET glob_rec_apparms.next_deb_num = l_temp_deb_num 
				NEXT FIELD next_deb_num 
			END IF 

		AFTER FIELD chq_jour_code 
			IF glob_rec_apparms.chq_jour_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD chq_jour_code 
			END IF 
			SELECT unique 1 FROM journal 
			WHERE jour_code = glob_rec_apparms.chq_jour_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9029,"") 
				#9029 Journal Code Not Found; Try Window.
				NEXT FIELD chq_jour_code 
			END IF 

		AFTER FIELD pur_jour_code 
			IF glob_rec_apparms.pur_jour_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD pur_jour_code 
			END IF 
			SELECT unique 1 FROM journal 
			WHERE jour_code = glob_rec_apparms.pur_jour_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9029,"") 
				#9029 Journal Code Not Found; Try Window.
				NEXT FIELD pur_jour_code 
			END IF 

		AFTER FIELD bank_acct_code 
			IF glob_rec_apparms.bank_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD bank_acct_code 
			END IF 
			SELECT unique 1 FROM coa 
			WHERE acct_code = glob_rec_apparms.bank_acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist; Try window.
				NEXT FIELD bank_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_apparms.bank_acct_code,COA_ACCOUNT_REQUIRED_IS_CONTROL_BANK,"") THEN 
				LET l_msgresp = kandoomsg("P",9531,"") 
				#9531 The account code entered IS NOT a bank account code.
				NEXT FIELD bank_acct_code 
			END IF 

		AFTER FIELD pay_acct_code 
			IF glob_rec_apparms.pay_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD pay_acct_code 
			END IF 
			SELECT unique 1 FROM coa 
			WHERE acct_code = glob_rec_apparms.pay_acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist; Try window.
				NEXT FIELD pay_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_apparms.pay_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_CONTROL_OTHER,"") THEN 
				NEXT FIELD pay_acct_code 
			END IF 

		AFTER FIELD freight_acct_code 
			IF glob_rec_apparms.freight_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD freight_acct_code 
			END IF 
			SELECT unique 1 FROM coa 
			WHERE acct_code = glob_rec_apparms.freight_acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist; Try window.
				NEXT FIELD freight_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_apparms.freight_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD freight_acct_code 
			END IF 

		AFTER FIELD salestax_acct_code 
			IF glob_rec_apparms.salestax_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD salestax_acct_code 
			END IF 
			SELECT unique 1 FROM coa 
			WHERE acct_code = glob_rec_apparms.salestax_acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist; Try window.
				NEXT FIELD salestax_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_apparms.salestax_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD salestax_acct_code 
			END IF 

		AFTER FIELD disc_acct_code 
			IF glob_rec_apparms.disc_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD disc_acct_code 
			END IF 
			SELECT unique 1 FROM coa 
			WHERE acct_code = glob_rec_apparms.disc_acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist; Try window.
				NEXT FIELD disc_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_apparms.disc_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD disc_acct_code 
			END IF 

		AFTER FIELD exch_acct_code 
			IF glob_rec_apparms.exch_acct_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD exch_acct_code 
			END IF 
			SELECT unique 1 FROM coa 
			WHERE acct_code = glob_rec_apparms.exch_acct_code 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			IF status = NOTFOUND THEN 
				LET l_msgresp = kandoomsg("G",9112,"") 
				#9112 Account code does NOT exist; Try window.
				NEXT FIELD exch_acct_code 
			END IF 
			IF NOT acct_type(glob_rec_kandoouser.cmpy_code,glob_rec_apparms.exch_acct_code,COA_ACCOUNT_REQUIRED_CAN_BE_NORMAL_TRANSACTION,"Y") THEN 
				NEXT FIELD exch_acct_code 
			END IF 

		AFTER FIELD vouch_approve_flag 
			IF glob_rec_apparms.vouch_approve_flag IS NULL THEN 
				LET glob_rec_apparms.vouch_approve_flag = "N" 
			END IF 

		AFTER FIELD report_ord_flag 
			IF glob_rec_apparms.report_ord_flag IS NULL THEN 
				LET glob_rec_apparms.report_ord_flag = "C" 
			END IF 

			-----------
		AFTER INPUT 
			IF int_flag OR int_flag THEN 
				EXIT INPUT 
			ELSE 
				LET glob_rec_apparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET glob_rec_apparms.parm_code = "1" 
				LET glob_rec_apparms.gl_detl_flag = "N" 
				IF glob_rec_apparms.next_vouch_num <= 0 
				OR glob_rec_apparms.next_vouch_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9927,0) 
					#9927 Value must be greater than 0
					NEXT FIELD next_vouch_num 
				END IF 
				IF glob_rec_apparms.next_deb_num <= 0 
				OR glob_rec_apparms.next_vouch_num IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9927,0) 
					#9927 Value must be greater than 0
					NEXT FIELD next_deb_num 
				END IF 
				IF glob_rec_apparms.chq_jour_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD chq_jour_code 
				END IF 
				IF glob_rec_apparms.pur_jour_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD pur_jour_code 
				END IF 
				IF glob_rec_apparms.bank_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD bank_acct_code 
				END IF 
				IF glob_rec_apparms.pay_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD pay_acct_code 
				END IF 
				IF glob_rec_apparms.freight_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD freight_acct_code 
				END IF 
				IF glob_rec_apparms.salestax_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD salestax_acct_code 
				END IF 
				IF glob_rec_apparms.disc_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD disc_acct_code 
				END IF 
				IF glob_rec_apparms.exch_acct_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9102,"") 
					#9102 Value must be entered
					NEXT FIELD exch_acct_code 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		LET l_msgresp = "N" 
		GOTO bypass 
		LABEL recovery: 
		IF error_recover(l_err_message, status) = "N" THEN 
			RETURN 
		END IF 
		LABEL bypass: 
		WHENEVER ERROR GOTO recovery 


		BEGIN WORK 

			LET l_err_message = "PZP - Locking Parameters Record" 
			DECLARE c_apparms CURSOR FOR 
			SELECT * FROM apparms 
			WHERE apparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND apparms.parm_code = "1" 

			OPEN c_apparms 
			FETCH c_apparms INTO l_rec_apparms.* 

			IF l_rec_apparms.next_vouch_num != l_rec_s_apparms.next_vouch_num 
			OR l_rec_apparms.next_deb_num != l_rec_s_apparms.next_deb_num THEN 
				ROLLBACK WORK 
				LET l_msgresp = kandoomsg("U",7050,"") 
				#7050 Parameter Values have been updated since changes. ...
				RETURN 
			END IF 

			UPDATE apparms 
			SET * = glob_rec_apparms.* 
			WHERE apparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND apparms.parm_code = "1" 

			IF l_rec_s_apparms.pay_acct_code != glob_rec_apparms.pay_acct_code 
			OR l_rec_s_apparms.freight_acct_code != glob_rec_apparms.freight_acct_code 
			OR l_rec_s_apparms.salestax_acct_code != glob_rec_apparms.salestax_acct_code 
			OR l_rec_s_apparms.disc_acct_code != glob_rec_apparms.disc_acct_code 
			OR l_rec_s_apparms.exch_acct_code != glob_rec_apparms.exch_acct_code THEN 
				LET l_msgresp = kandoomsg("P",8007,"") 
				#8007 G/L account has changes, UPDATE vendor types?
			END IF 

			IF l_msgresp = "Y" THEN 
				LET l_err_message = "PZP - Update Vendor Types" 
				CALL update_vendortype() 
			END IF 

		COMMIT WORK 
		WHENEVER ERROR stop 

	END IF 

END FUNCTION 



############################################################
# FUNCTION disp_parm()
#
#
############################################################
FUNCTION disp_parm() 
	DEFINE l_rec_apparms RECORD LIKE apparms.* 

	CLEAR FORM 
	SELECT apparms.* INTO l_rec_apparms.* FROM apparms 
	WHERE apparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND apparms.parm_code = "1" 
	IF status = NOTFOUND THEN 
		RETURN false 
	END IF 

	DISPLAY BY NAME l_rec_apparms.next_vouch_num, 
	l_rec_apparms.next_deb_num, 
	l_rec_apparms.chq_jour_code, 
	l_rec_apparms.pur_jour_code, 
	l_rec_apparms.bank_acct_code, 
	l_rec_apparms.pay_acct_code, 
	l_rec_apparms.freight_acct_code, 
	l_rec_apparms.salestax_acct_code, 
	l_rec_apparms.disc_acct_code, 
	l_rec_apparms.exch_acct_code, 
	l_rec_apparms.last_chq_prnt_date, 
	l_rec_apparms.last_post_date, 
	l_rec_apparms.last_aging_date, 
	l_rec_apparms.last_del_date, 
	l_rec_apparms.gl_flag, 
	l_rec_apparms.hist_flag, 
	l_rec_apparms.vouch_approve_flag, 
	l_rec_apparms.report_ord_flag 

	RETURN true 
END FUNCTION 


############################################################
# FUNCTION update_vendortype()
#
#
############################################################
FUNCTION update_vendortype() 
	DEFINE l_rowid SMALLINT 
	DEFINE l_rec_vendortype RECORD LIKE vendortype.* 
	DEFINE l_rec_apparms RECORD LIKE apparms.* 

	SELECT * INTO l_rec_apparms.* FROM apparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND parm_code = "1" 
	DECLARE c_vendortype CURSOR FOR 
	SELECT rowid, * FROM vendortype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	FOREACH c_vendortype INTO l_rowid, l_rec_vendortype.* 
		IF l_rec_vendortype.pay_acct_code = l_rec_apparms.pay_acct_code THEN 
			LET l_rec_vendortype.pay_acct_code = glob_rec_apparms.pay_acct_code 
		END IF 
		IF l_rec_vendortype.freight_acct_code = l_rec_apparms.freight_acct_code THEN 
			LET l_rec_vendortype.freight_acct_code = glob_rec_apparms.freight_acct_code 
		END IF 
		IF l_rec_vendortype.salestax_acct_code = l_rec_apparms.salestax_acct_code THEN 
			LET l_rec_vendortype.salestax_acct_code = glob_rec_apparms.salestax_acct_code 
		END IF 
		IF l_rec_vendortype.disc_acct_code = l_rec_apparms.disc_acct_code THEN 
			LET l_rec_vendortype.disc_acct_code = glob_rec_apparms.disc_acct_code 
		END IF 
		IF l_rec_vendortype.exch_acct_code = l_rec_apparms.exch_acct_code THEN 
			LET l_rec_vendortype.exch_acct_code = glob_rec_apparms.exch_acct_code 
		END IF 
		UPDATE vendortype 
		SET * = l_rec_vendortype.* 
		WHERE rowid = l_rowid 
	END FOREACH 

END FUNCTION 
