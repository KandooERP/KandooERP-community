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

	Source code beautified by beautify.pl on 2020-01-03 14:28:31	$Id: $
}



{
KandooERP runs on Querix Lycia www.querix.com
Adapted by eric@begooden.it,hoelzl@querix.com
}
# \file
# \brief module G2C allows the user TO CLEAR General Ledger Batches
#             FOR posting.

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 

############################################################
# MAIN
#
#
############################################################
MAIN 
	DEFINE l_msgresp LIKE language.yes_flag 

	#Initial UI Init
	CALL setModuleId("G2C") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_g_gl() #init g/gl general ledger module 

	SELECT * INTO glob_rec_glparms.* FROM glparms 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND key_code = "1" 

	IF status = NOTFOUND THEN 
		LET l_msgresp = kandoomsg("G",5007,"") 
		#5007 General Ledger Parameters Not Setup;  Refer Menu RZP.
		EXIT PROGRAM 
	END IF 

	OPEN WINDOW g149 with FORM "G149" 
	CALL windecoration_g("G149") 

	WHILE select_jour() 
		CALL clear_jour() 
	END WHILE 

	CLOSE WINDOW g149 
END MAIN 


############################################################
# FUNCTION select_jour()
#
#
############################################################
FUNCTION select_jour() 
	DEFINE l_where_text STRING 
	DEFINE l_query_text CHAR(980) 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	LET l_msgresp=kandoomsg("U",1001,"") 
	#1001 Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON jour_code, 
	jour_num, 
	cleared_flag, 
	jour_date, 
	period_num, 
	control_amt, 
	control_amt, 
	debit_amt 
		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","G2C","construct") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

	END CONSTRUCT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_msgresp=kandoomsg("U",1002,"") 
		#1002 Searching database;  Please wait.
		LET l_query_text = "SELECT * FROM batchhead ", 
		"WHERE cmpy_code='",glob_rec_kandoouser.cmpy_code,"' ", 
		"AND post_flag='N' ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY 1,3" 
		PREPARE s_batchhead FROM l_query_text 
		DECLARE c_batchhead CURSOR FOR s_batchhead 
		RETURN true 
	END IF 
END FUNCTION 


############################################################
# FUNCTION clear_jour()
#
#
############################################################
FUNCTION clear_jour() 
	DEFINE l_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_arr_rec_batchhead DYNAMIC ARRAY OF RECORD # array[300] OF RECORD 
		scroll_flag CHAR(1), 
		jour_code LIKE batchhead.jour_code, 
		jour_num LIKE batchhead.jour_num, 
		cleared_flag LIKE batchhead.cleared_flag, 
		jour_date LIKE batchhead.jour_date, 
		period_num LIKE batchhead.period_num, 
		control_amt LIKE batchhead.control_amt, 
		debit_amt LIKE batchhead.debit_amt, 
		balanced CHAR(1) 
	END RECORD 
	DEFINE i SMALLINT --, scrn 
	DEFINE l_idx SMALLINT --, scrn 
	DEFINE l_err_message CHAR(40) 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_idx = 0 
	FOREACH c_batchhead INTO l_rec_batchhead.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_batchhead[l_idx].scroll_flag = NULL 
		LET l_arr_rec_batchhead[l_idx].jour_code = l_rec_batchhead.jour_code 
		LET l_arr_rec_batchhead[l_idx].jour_num = l_rec_batchhead.jour_num 
		LET l_arr_rec_batchhead[l_idx].cleared_flag = l_rec_batchhead.cleared_flag 
		LET l_arr_rec_batchhead[l_idx].jour_date = l_rec_batchhead.jour_date 
		LET l_arr_rec_batchhead[l_idx].period_num = l_rec_batchhead.period_num 
		LET l_arr_rec_batchhead[l_idx].control_amt = l_rec_batchhead.control_amt 
		LET l_arr_rec_batchhead[l_idx].debit_amt = l_rec_batchhead.for_debit_amt 
		LET l_arr_rec_batchhead[l_idx].balanced = get_bal_flag(l_rec_batchhead.*) 
		IF l_idx = 300 THEN 
			LET l_msgresp=kandoomsg("G",9042,l_idx) 
			#9035 First 300 batches selected.
			EXIT FOREACH 
		END IF 
	END FOREACH 
	IF l_idx = 0 THEN 
		LET l_msgresp=kandoomsg("G",9043,"") 
		#9036 No journal disbursements selected.
		RETURN 
	END IF 
	CALL set_count(l_idx) 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	LET l_msgresp=kandoomsg("G",1047,"") 

	#1047 F3/F4 TO Page Fwd/Bwd;  F9 TO Toggle Clearance;  ENTER on line TO View.
	INPUT ARRAY l_arr_rec_batchhead WITHOUT DEFAULTS FROM sr_batchhead.* attributes (UNBUFFERED) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","G2C","input-arr-batchhead") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON KEY (F9) --toggle clearance 
			IF l_arr_rec_batchhead[l_idx].balanced = "N" THEN 
				LET l_msgresp = kandoomsg("G",8016,"") 
				#8016 Batch does NOT balance.  Continue? (y/n) "
				IF l_msgresp = "N" 
				OR l_msgresp = "n" THEN 
					NEXT FIELD scroll_flag 
				END IF 
			END IF 

			IF l_arr_rec_batchhead[l_idx].cleared_flag = "N" THEN 
				LET l_arr_rec_batchhead[l_idx].cleared_flag = "Y" 
			ELSE 
				LET l_arr_rec_batchhead[l_idx].cleared_flag = "N" 
			END IF 

			#DISPLAY l_arr_rec_batchhead[l_idx].* TO sr_batchhead[scrn].*

			NEXT FIELD scroll_flag 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			#LET scrn = scr_line()

			#BEFORE FIELD scroll_flag
			#   IF l_arr_rec_batchhead[l_idx].jour_code IS NOT NULL THEN
			#      DISPLAY l_arr_rec_batchhead[l_idx].* TO sr_batchhead[scrn].*
			#
			#   END IF

		AFTER FIELD scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF arr_curr() = arr_count() THEN 
					LET l_msgresp=kandoomsg("I",9001,"") 
					#9001 There are no more rows in the direction ...
					NEXT FIELD scroll_flag 
				ELSE 
					IF l_arr_rec_batchhead[l_idx+1].jour_code IS NULL THEN 
						LET l_msgresp=kandoomsg("I",9001,"") 
						#9001 There are no more rows in the direction ...
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 


		ON ACTION "DETAILS" --view details 
			OPEN WINDOW g109 with FORM "G109" 
			CALL windecoration_g("G109") 

			CALL disp_journal(glob_rec_kandoouser.cmpy_code,l_arr_rec_batchhead[l_idx].jour_num) 
			LET l_msgresp = kandoomsg("G",8015,"") 

			#8015 " View batch details (y/n) ?"
			IF l_msgresp = "Y" 
			OR l_msgresp = "y" THEN 
				CALL jo_det_scan(glob_rec_kandoouser.cmpy_code, l_arr_rec_batchhead[l_idx].jour_num) 
			END IF 

			CLOSE WINDOW g109 
			NEXT FIELD scroll_flag 


		BEFORE FIELD jour_code 

			OPEN WINDOW g109 with FORM "G109" 
			CALL windecoration_g("G109") 

			CALL disp_journal(glob_rec_kandoouser.cmpy_code,l_arr_rec_batchhead[l_idx].jour_num) 
			LET l_msgresp = kandoomsg("G",8015,"") 

			#8015 " View batch details (y/n) ?"
			IF l_msgresp = "Y" 
			OR l_msgresp = "y" THEN 
				CALL jo_det_scan(glob_rec_kandoouser.cmpy_code, l_arr_rec_batchhead[l_idx].jour_num) 
			END IF 
			CLOSE WINDOW g109 
			NEXT FIELD scroll_flag 

			#AFTER ROW
			#   DISPLAY l_arr_rec_batchhead[l_idx].* TO sr_batchhead[scrn].*

		ON KEY (control-w) --help 
			CALL kandoohelp("") 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
	ELSE 
		GOTO bypass 
		LABEL recovery: 
		LET l_msgresp = error_recover (l_err_message, status) 

		IF l_msgresp != "Y" THEN 
			EXIT PROGRAM 
		END IF 

		LABEL bypass: 
		WHENEVER ERROR 
		GOTO recovery 

		BEGIN WORK 
			FOR i = 1 TO arr_count() 
				UPDATE batchhead 
				SET cleared_flag = l_arr_rec_batchhead[i].cleared_flag 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND jour_num = l_arr_rec_batchhead[i].jour_num 
				AND jour_code = l_arr_rec_batchhead[i].jour_code 
			END FOR 
		COMMIT WORK 

		WHENEVER ERROR stop 

	END IF 

END FUNCTION 


############################################################
# FUNCTION get_bal_flag(p_rec_batchhead)
#
#
############################################################
FUNCTION get_bal_flag(p_rec_batchhead) 
	DEFINE p_rec_batchhead RECORD LIKE batchhead.* 
	DEFINE l_ret_bal_flag CHAR(1) 

	LET l_ret_bal_flag = NULL 
	CASE glob_rec_glparms.control_tot_flag 
		WHEN "Y" 
			IF p_rec_batchhead.conv_qty = 1.0 THEN 
				IF p_rec_batchhead.debit_amt = p_rec_batchhead.credit_amt 
				AND p_rec_batchhead.debit_amt = p_rec_batchhead.for_debit_amt 
				AND p_rec_batchhead.for_debit_amt = p_rec_batchhead.for_credit_amt 
				AND p_rec_batchhead.debit_amt = p_rec_batchhead.control_amt THEN 
					LET l_ret_bal_flag = "Y" 
				ELSE 
					LET l_ret_bal_flag = "N" 
				END IF 
			ELSE 
				IF p_rec_batchhead.debit_amt = p_rec_batchhead.credit_amt 
				AND p_rec_batchhead.for_debit_amt = p_rec_batchhead.for_credit_amt 
				AND p_rec_batchhead.for_debit_amt = p_rec_batchhead.control_amt THEN 
					LET l_ret_bal_flag = "Y" 
				ELSE 
					LET l_ret_bal_flag = "N" 
				END IF 
			END IF 
		WHEN "N" 
			IF p_rec_batchhead.conv_qty = 1.0 THEN 
				IF p_rec_batchhead.debit_amt = p_rec_batchhead.credit_amt 
				AND p_rec_batchhead.for_debit_amt = p_rec_batchhead.for_credit_amt 
				AND p_rec_batchhead.debit_amt = p_rec_batchhead.for_debit_amt THEN 
					LET l_ret_bal_flag = "Y" 
				ELSE 
					LET l_ret_bal_flag = "N" 
				END IF 
			ELSE 
				IF p_rec_batchhead.debit_amt = p_rec_batchhead.credit_amt 
				AND p_rec_batchhead.for_debit_amt = p_rec_batchhead.for_credit_amt THEN 
					LET l_ret_bal_flag = "Y" 
				ELSE 
					LET l_ret_bal_flag = "N" 
				END IF 
			END IF 
	END CASE 
	RETURN l_ret_bal_flag 
END FUNCTION 


