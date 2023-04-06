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



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module P44 allows the user TO Scan Client cheques THEN cancel
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_P4_GLOBALS.4gl" 

############################################################
# MAIN
############################################################
MAIN 
	DEFINE l_rec_poststatus RECORD LIKE poststatus.*
	DEFINE l_msgresp LIKE language.yes_flag

	#Initial UI Init
	CALL setModuleId("P44") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	SELECT * INTO l_rec_poststatus.* FROM poststatus 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND module_code = "AP" 
	IF status = 0 THEN 
		IF l_rec_poststatus.post_running_flag = "Y" THEN 
			LET l_msgresp = kandoomsg("P",7008, "Accounts Payable") 
			#Account Payable posting IS running. Try again WHEN posting complete.
			EXIT PROGRAM 
		END IF 
	END IF 
	OPEN WINDOW p133 with FORM "P133" 
	CALL windecoration_p("P133") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE scan_vend() 
	END WHILE 
	CLOSE WINDOW p133 
END MAIN 


FUNCTION scan_vend() 
	DEFINE l_rec_cheque RECORD LIKE cheque.*
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_arr_cheque ARRAY[220] OF RECORD 
		scroll_flag CHAR(1), 
		vend_code LIKE cheque.vend_code, 
		bank_code LIKE cheque.bank_code, 
		cheq_code LIKE cheque.cheq_code, 
		net_pay_amt LIKE cheque.net_pay_amt, 
		cheq_date LIKE cheque.cheq_date, 
		pay_meth_ind LIKE cheque.pay_meth_ind 
	END RECORD 
	DEFINE l_arr_cheque_info ARRAY[220] OF RECORD 
		pay_amt LIKE cheque.pay_amt, 
		apply_amt LIKE cheque.apply_amt, 
		com3_text LIKE cheque.com3_text, 
		post_flag LIKE cheque.post_flag, 
		year_num LIKE cheque.year_num, 
		period_num LIKE cheque.period_num 
	END RECORD
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx, scrn SMALLINT
	DEFINE i,j SMALLINT

	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria; OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON cheque.vend_code, 
	cheque.bank_code, 
	cheque.cheq_code, 
	cheque.net_pay_amt, 
	cheque.cheq_date, 
	cheque.pay_meth_ind, 
	cheque.pay_amt, 
	cheque.apply_amt, 
	cheque.com3_text, 
	cheque.post_flag, 
	cheque.year_num, 
	cheque.period_num 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P44","construct-cheque-1") 

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
	#1002 Searching Database; Please Wait.
	LET l_query_text = "SELECT * FROM cheque ", 
	" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
	" AND cheq_code != 0 ", 
	" AND cheq_code IS NOT NULL ", 
	" AND ",l_where_text clipped," ", 
	" ORDER BY cheq_code" 
	PREPARE s_cheque FROM l_query_text 
	DECLARE c_cheque CURSOR FOR s_cheque 
	LET idx = 0 
	FOREACH c_cheque INTO l_rec_cheque.* 
		LET idx = idx + 1 
		LET l_arr_cheque[idx].vend_code = l_rec_cheque.vend_code 
		LET l_arr_cheque[idx].bank_code = l_rec_cheque.bank_code 
		LET l_arr_cheque[idx].cheq_code = l_rec_cheque.cheq_code 
		LET l_arr_cheque[idx].net_pay_amt = l_rec_cheque.net_pay_amt 
		LET l_arr_cheque[idx].cheq_date = l_rec_cheque.cheq_date 
		LET l_arr_cheque[idx].pay_meth_ind = l_rec_cheque.pay_meth_ind 
		LET l_arr_cheque_info[idx].pay_amt = l_rec_cheque.pay_amt 
		LET l_arr_cheque_info[idx].apply_amt = l_rec_cheque.apply_amt 
		LET l_arr_cheque_info[idx].com3_text = l_rec_cheque.com3_text 
		LET l_arr_cheque_info[idx].post_flag = l_rec_cheque.post_flag 
		LET l_arr_cheque_info[idx].year_num = l_rec_cheque.year_num 
		LET l_arr_cheque_info[idx].period_num = l_rec_cheque.period_num 
		IF idx = 200 THEN 
			LET l_msgresp = kandoomsg("U",6100,idx) 
			#9042 First 200 entries selected "
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET l_msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE l_arr_cheque[idx].* TO NULL 
		INITIALIZE l_arr_cheque_info[idx].* TO NULL 
	END IF 
	CALL set_count (idx) 
	LET l_msgresp = kandoomsg("P",1059,"") 
	#1059 ENTER on line TO Cancel
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	INPUT ARRAY l_arr_cheque WITHOUT DEFAULTS FROM sr_cheque.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P44","inp-arr-cheque-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY l_arr_cheque[idx].* TO sr_cheque[scrn].* 

			DISPLAY BY NAME l_arr_cheque_info[idx].pay_amt, 
			l_arr_cheque_info[idx].apply_amt, 
			l_arr_cheque_info[idx].com3_text, 
			l_arr_cheque_info[idx].post_flag, 
			l_arr_cheque_info[idx].year_num, 
			l_arr_cheque_info[idx].period_num 

		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				LET l_msgresp = kandoomsg("U",9001,"") 
				#9001 There no more rows...
				NEXT FIELD scroll_flag 
			END IF 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_cheque[idx+1].vend_code IS NULL THEN 
					LET l_msgresp = kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD scroll_flag 
				END IF 
			END IF 
			IF fgl_lastkey() = fgl_keyval("nextpage") 
			AND l_arr_cheque[idx+10].vend_code IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9001,"") 
				#9001 No more rows in this direction
				NEXT FIELD scroll_flag 
			END IF 
		BEFORE FIELD vend_code 
			IF l_arr_cheque[idx].cheq_code IS NULL 
			OR l_arr_cheque[idx].cheq_code = 0 THEN 
			ELSE 
				SELECT * INTO l_rec_cheque.* FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = l_arr_cheque[idx].bank_code 
				AND cheq_code = l_arr_cheque[idx].cheq_code 
				AND vend_code = l_arr_cheque[idx].vend_code 
				AND pay_meth_ind = l_arr_cheque[idx].pay_meth_ind 
				IF status = NOTFOUND THEN 
					LET l_msgresp = kandoomsg("U",7001,"Cheque") 
					#7001 " Logic Error: Cheque NOT found"
					NEXT FIELD scroll_flag 
				END IF 
				SELECT * INTO l_rec_glparms.* FROM glparms 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND key_code = "1" 
				IF (l_rec_cheque.rec_state_num IS NOT NULL OR 
				l_rec_cheque.rec_state_num != 0) 
				AND (l_rec_cheque.rec_line_num IS NOT NULL OR 
				l_rec_cheque.rec_line_num != 0 ) 
				AND l_rec_glparms.cash_book_flag = "Y" THEN 
					LET l_msgresp = kandoomsg("P",9088,"") 
					#9088 "Cheque has been reconciled - cannot be cancelled"
				ELSE 
					IF l_rec_cheque.apply_amt > 0 THEN 
						LET l_msgresp = kandoomsg("P",3526,"") 
						#3526 Cancel Applied Cheque (Y/N)?
					ELSE 
						LET l_msgresp = kandoomsg("P",8006,"") 
						#9004 Cancel Cheque (Y/N)?
					END IF 
					IF l_msgresp = "Y" THEN 
						CALL setup_cancel(l_arr_cheque[idx].bank_code, 
						l_arr_cheque[idx].cheq_code, 
						l_arr_cheque[idx].pay_meth_ind) 
					END IF 
				END IF 
				SELECT * INTO l_rec_cheque.* FROM cheque 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND bank_code = l_arr_cheque[idx].bank_code 
				AND cheq_code = l_arr_cheque[idx].cheq_code 
				AND vend_code = l_arr_cheque[idx].vend_code 
				AND pay_meth_ind = l_arr_cheque[idx].pay_meth_ind 
				IF status = NOTFOUND THEN 
					# take row out of stored ARRAY - do NOT move acount = arr_count
					# as arr_count can alter without entering a BEFORE ROW-
					LET i = arr_count() 
					FOR j = idx TO (i - 1) 
						LET l_arr_cheque[j].* = l_arr_cheque[j+1].* 
						LET l_arr_cheque_info[j].* = l_arr_cheque_info[j+1].* 
					END FOR 
					INITIALIZE l_arr_cheque[i].* TO NULL 
					INITIALIZE l_arr_cheque_info[i].* TO NULL 
					LET j = scrn 
					FOR i = idx TO idx + (10 - scrn) 
						IF l_arr_cheque[i].cheq_code IS NULL 
						OR l_arr_cheque[i].cheq_code = 0 THEN 
							INITIALIZE l_arr_cheque[i].* TO NULL 
							INITIALIZE l_arr_cheque_info[i].* TO NULL 
						END IF 
						DISPLAY l_arr_cheque[i].* TO sr_cheque[j].* 

						DISPLAY BY NAME l_arr_cheque_info[i].pay_amt, 
						l_arr_cheque_info[i].apply_amt, 
						l_arr_cheque_info[i].com3_text, 
						l_arr_cheque_info[i].post_flag, 
						l_arr_cheque_info[i].year_num, 
						l_arr_cheque_info[i].period_num 

						LET j = j + 1 
					END FOR 
					LET l_rec_cheque.cheq_code = l_arr_cheque[idx].cheq_code 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
		AFTER ROW 
			DISPLAY l_arr_cheque[idx].* TO sr_cheque[scrn].* 

	END INPUT 
	LET int_flag = false 
	LET quit_flag = false 
	RETURN true 
END FUNCTION 


FUNCTION setup_cancel(p_bank_code,p_cheq_code,p_pay_method) 
	DEFINE p_bank_code LIKE cheque.bank_code 
	DEFINE p_cheq_code LIKE cheque.cheq_code 
	DEFINE p_pay_method LIKE cheque.pay_meth_ind 
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_err_message CHAR(60) 
	DEFINE l_jour_number INTEGER 
	DEFINE l_dbase_status INTEGER
	DEFINE l_call_status SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_com1_text, l_com2_text CHAR(30)

	SELECT * INTO l_rec_cheque.* FROM cheque 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND bank_code = p_bank_code 
	AND cheq_code = p_cheq_code 
	AND pay_meth_ind = p_pay_method 
	OPEN WINDOW p164 with FORM "P164" 
	CALL windecoration_p("P164") 

	LET l_msgresp = kandoomsg("U",1020,"Cancellation") 

	INPUT l_com1_text, l_com2_text WITHOUT DEFAULTS FROM com1_text, com2_text  

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P44","inp-com-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		AFTER FIELD com1_text 
			IF l_com1_text IS NULL THEN 
				LET l_msgresp = kandoomsg("U",9102,"") 
				#9102 Value must be entered
				NEXT FIELD com1_text 
			END IF 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		CLOSE WINDOW p164 
		RETURN 
	END IF 
	CLOSE WINDOW p164 
	GOTO bypass 
	LABEL recovery: 
	IF error_recover(l_err_message,l_dbase_status) = "N" THEN 
		RETURN 
	END IF 
	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		DECLARE c_glparms CURSOR FOR 
		SELECT * FROM glparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		FOR UPDATE 
		OPEN c_glparms 
		FETCH c_glparms INTO l_rec_glparms.* 
		CALL cancel_payment(glob_rec_kandoouser.cmpy_code, 
		glob_rec_kandoouser.sign_on_code, 
		l_rec_cheque.bank_code, 
		l_rec_cheque.cheq_code, 
		l_rec_cheque.pay_meth_ind, 
		l_com1_text, 
		l_com2_text, 
		l_rec_cheque.rec_state_num, 
		l_rec_glparms.*) 
		RETURNING l_call_status, 
		l_dbase_status, 
		l_err_message, 
		l_jour_number 
		IF l_call_status < 0 THEN 
			LET status = l_dbase_status 
			GOTO recovery 
		END IF 
		LET l_err_message = "Cancel Cheque - UPDATE journal number" 
		UPDATE glparms 
		SET next_jour_num = l_jour_number 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = '1' 
	COMMIT WORK 
END FUNCTION 


