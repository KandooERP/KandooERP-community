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

	Source code beautified by beautify.pl on 2020-01-03 13:41:30	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module - P49
# Purpose - Allows the user TO scan cheques applied AND
#           fully (OR OTHERWISE) unapply them IF they are NOT posted
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

	#Initial UI Init
	CALL setModuleId("P49") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p135 with FORM "P135" 
	CALL windecoration_p("P135") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE scan_cheque() 
	END WHILE 
	CLOSE WINDOW p135 
END MAIN 


FUNCTION scan_cheque() 
	DEFINE l_arr_x_cheque ARRAY[420] OF RECORD 
		bank_code LIKE cheque.bank_code, 
		pay_meth_ind LIKE cheque.pay_meth_ind, 
		disc_amt LIKE cheque.disc_amt 
	END RECORD
	DEFINE l_rec_cheque RECORD LIKE cheque.*
	DEFINE l_arr_cheque ARRAY[420] OF RECORD 
		cheq_code LIKE cheque.cheq_code, 
		vend_code LIKE cheque.vend_code, 
		cheq_date LIKE cheque.cheq_date, 
		year_num LIKE cheque.year_num, 
		period_num LIKE cheque.period_num, 
		pay_amt LIKE cheque.pay_amt, 
		apply_amt LIKE cheque.apply_amt, 
		post_flag LIKE cheque.post_flag 
	END RECORD
	DEFINE l_query_text CHAR(2048)
	DEFINE l_where_text CHAR(2200) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx, scrn SMALLINT

	CLEAR FORM 
	LET l_msgresp = kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria; OK TO Continue
	CONSTRUCT BY NAME l_where_text ON cheq_code, 
	vend_code, 
	cheq_date, 
	year_num, 
	period_num, 
	pay_amt, 
	apply_amt, 
	post_flag 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P49","construct-cheque-1") 

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
	#1002 Searching Database; Please Wait
	LET l_query_text = "SELECT * FROM cheque ", 
	" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\"", 
	" AND cheq_code != 0 ", 
	" AND cheq_code IS NOT NULL ", 
	" AND apply_amt != 0 ", 
	" AND ",l_where_text clipped, 
	" ORDER BY cheq_code " 
	PREPARE s_cheque FROM l_query_text 
	DECLARE c2_cheque CURSOR FOR s_cheque 
	LET idx = 0 
	FOREACH c2_cheque INTO l_rec_cheque.* 
		LET idx = idx + 1 
		LET l_arr_x_cheque[idx].bank_code = l_rec_cheque.bank_code 
		LET l_arr_x_cheque[idx].pay_meth_ind = l_rec_cheque.pay_meth_ind 
		LET l_arr_x_cheque[idx].disc_amt = l_rec_cheque.disc_amt 
		LET l_arr_cheque[idx].cheq_code = l_rec_cheque.cheq_code 
		LET l_arr_cheque[idx].vend_code = l_rec_cheque.vend_code 
		LET l_arr_cheque[idx].cheq_date = l_rec_cheque.cheq_date 
		LET l_arr_cheque[idx].year_num = l_rec_cheque.year_num 
		LET l_arr_cheque[idx].period_num = l_rec_cheque.period_num 
		LET l_arr_cheque[idx].pay_amt = l_rec_cheque.pay_amt 
		LET l_arr_cheque[idx].apply_amt = l_rec_cheque.apply_amt 
		LET l_arr_cheque[idx].post_flag = l_rec_cheque.post_flag 
		IF idx = 400 THEN 
			LET l_msgresp = kandoomsg("U",6100,idx) 
			#6100 First idx records selected
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET l_msgresp = kandoomsg("U",9113,idx) 
	#9113 idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE l_arr_cheque[idx].* TO NULL 
		INITIALIZE l_arr_x_cheque[idx].* TO NULL 
	END IF 
	CALL set_count(idx) 
	LET l_msgresp = kandoomsg("P",9509,"") 
	#9509 Enter on line TO Unapply Cheque

	INPUT ARRAY l_arr_cheque WITHOUT DEFAULTS FROM sr_cheque.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P49","inp-arr-cheque-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			LET l_rec_cheque.cheq_code = l_arr_cheque[idx].cheq_code 
			LET l_rec_cheque.vend_code = l_arr_cheque[idx].vend_code 
			LET l_rec_cheque.cheq_date = l_arr_cheque[idx].cheq_date 
			LET l_rec_cheque.year_num = l_arr_cheque[idx].year_num 
			LET l_rec_cheque.period_num = l_arr_cheque[idx].period_num 
			LET l_rec_cheque.pay_amt = l_arr_cheque[idx].pay_amt 
			LET l_rec_cheque.apply_amt = l_arr_cheque[idx].apply_amt 
			LET l_rec_cheque.post_flag = l_arr_cheque[idx].post_flag 
			DISPLAY l_arr_cheque[idx].* TO sr_cheque[scrn].* 

		AFTER ROW 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_cheque[idx+1].cheq_code IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("W",9001,"") 
					#9001 There no more rows...
					NEXT FIELD cheq_code 
				END IF 
			END IF 
			DISPLAY l_arr_cheque[idx].* TO sr_cheque[scrn].* 

		BEFORE FIELD vend_code 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF l_arr_cheque[idx].cheq_code IS NOT NULL THEN 
				IF l_arr_cheque[idx].apply_amt != 0 THEN 
					## check IF posted with discount  - until  a database change IS
					## made, these cannot be unapplied.
					IF l_arr_x_cheque[idx].disc_amt != 0 
					AND l_arr_cheque[idx].post_flag = "Y" THEN 
						LET l_msgresp = kandoomsg("P",9512," ") 
						NEXT FIELD cheq_code 
					END IF 
					CALL setup_unapply(l_arr_x_cheque[idx].bank_code, 
					l_arr_cheque[idx].cheq_code, 
					l_arr_x_cheque[idx].pay_meth_ind) 
					SELECT * INTO l_rec_cheque.* FROM cheque 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND bank_code = l_arr_x_cheque[idx].bank_code 
					AND pay_meth_ind = l_arr_x_cheque[idx].pay_meth_ind 
					AND cheq_code = l_arr_cheque[idx].cheq_code 
					AND cheq_code != 0 
					AND cheq_code IS NOT NULL 
					LET l_arr_cheque[idx].apply_amt = l_rec_cheque.apply_amt 
					DISPLAY l_arr_cheque[idx].* TO sr_cheque[scrn].* 

				ELSE 
					LET l_msgresp = kandoomsg("P",9529,"") 
					#9529 Cheque has already been unapplied.
				END IF 
			END IF 
			NEXT FIELD cheq_code 

	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	RETURN true 
END FUNCTION 

FUNCTION setup_unapply(p_bank_code,p_cheq_code,p_pay_meth_ind) 
	DEFINE p_bank_code LIKE cheque.bank_code
	DEFINE p_cheq_code LIKE cheque.cheq_code 
	DEFINE p_pay_meth_ind LIKE cheque.pay_meth_ind
	DEFINE l_rec_cheque RECORD LIKE cheque.* 
	DEFINE l_call_status INTEGER
	DEFINE l_db_status INTEGER
	DEFINE l_err_message CHAR(80)
	DEFINE l_kandoo_log_msg CHAR(80)
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE try_again CHAR(1)

	GOTO bypass 
	LABEL recovery: 
	LET try_again = error_recover(l_err_message, status) 
	IF try_again != "Y" THEN 
		EXIT PROGRAM 
	END IF 

	LABEL bypass: 
	WHENEVER ERROR GOTO recovery 
	BEGIN WORK 
		DECLARE c_cheque CURSOR FOR 
		SELECT * FROM cheque 
		WHERE bank_code = p_bank_code 
		AND cheq_code = p_cheq_code 
		AND cheq_code != 0 
		AND pay_meth_ind = p_pay_meth_ind 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		FOR UPDATE 
		OPEN c_cheque 
		FETCH c_cheque INTO l_rec_cheque.* 
		IF status = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("P",9130,"") 
			ROLLBACK WORK 
			RETURN 
		END IF 
		CALL unapply_payment(glob_rec_kandoouser.sign_on_code, l_rec_cheque.*) 
		RETURNING l_call_status, l_db_status, l_err_message 
		IF l_call_status = -2 THEN 
			LET status = l_db_status 
			GOTO recovery 
		END IF 
		IF l_call_status != 0 THEN 
			LET l_msgresp=kandoomsg("U",7020,"") 
			#7020 Database Update Error Occurred - See trim(get_settings_logFile())
			CALL errorlog(l_err_message) 
			LET l_kandoo_log_msg = "Above error encountered by ", glob_rec_kandoouser.sign_on_code, 
			" in P49.4gi" 
			CALL errorlog(l_kandoo_log_msg) 
			ROLLBACK WORK 
		ELSE 
		COMMIT WORK 
	END IF 
END FUNCTION 


