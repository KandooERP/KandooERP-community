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
# P6B - allows the user TO scan debits applied AND unapply those debits
#
###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ap/P_AP_GLOBALS.4gl" 
GLOBALS "../ap/P6_GROUP_GLOBALS.4gl"
GLOBALS "../ap/P6B_GLOBALS.4gl"
###########################################################################
# MODULE Scope Variables
###########################################################################


############################################################
# MAIN
############################################################
MAIN 

	#Initial UI Init
	CALL setModuleId("P6B") 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_p_ap() #init p/ap module 

	OPEN WINDOW p115 with FORM "P115" 
	CALL windecoration_p("P115") 
	CALL displaymoduletitle(NULL) --first FORM OF the module get's the title 

	WHILE scan_debits() 
	END WHILE 
	CLOSE WINDOW p115 
END MAIN 


FUNCTION scan_debits() 
	DEFINE l_debithead RECORD LIKE debithead.* 
	DEFINE l_arr_debithead ARRAY[205] OF RECORD 
		debit_num LIKE debithead.debit_num, 
		vend_code LIKE debithead.vend_code, 
		debit_date LIKE debithead.debit_date, 
		year_num LIKE debithead.year_num, 
		period_num LIKE debithead.period_num, 
		total_amt LIKE debithead.total_amt, 
		apply_amt LIKE debithead.apply_amt, 
		post_flag LIKE debithead.post_flag 
	END RECORD 
	DEFINE l_query_text CHAR(2200) 
	DEFINE l_where_text CHAR(2048) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE idx, scrn SMALLINT

	CLEAR FORM 
	LET l_msgresp = kandoomsg("P",1001,"") 
	#1001" Enter Selection Criteria;  OK TO Continue.
	CONSTRUCT BY NAME l_where_text ON debit_num, 
	vend_code, 
	debit_date, 
	year_num, 
	period_num, 
	total_amt, 
	apply_amt, 
	post_flag 

		BEFORE CONSTRUCT 
			CALL publish_toolbar("kandoo","P6B","construct-debithead-1") 

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
	LET l_query_text = "SELECT * FROM debithead ", 
	" WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
	" AND ", l_where_text clipped, 
	" AND apply_amt != 0 ", 
	" ORDER BY debit_num " 
	PREPARE s_debithead FROM l_query_text 
	DECLARE c_debithead CURSOR FOR s_debithead 
	LET idx = 0 
	FOREACH c_debithead INTO l_debithead.* 
		LET idx = idx + 1 
		LET l_arr_debithead[idx].debit_num = l_debithead.debit_num 
		LET l_arr_debithead[idx].vend_code = l_debithead.vend_code 
		LET l_arr_debithead[idx].debit_date = l_debithead.debit_date 
		LET l_arr_debithead[idx].year_num = l_debithead.year_num 
		LET l_arr_debithead[idx].period_num = l_debithead.period_num 
		LET l_arr_debithead[idx].total_amt = l_debithead.total_amt 
		LET l_arr_debithead[idx].apply_amt = l_debithead.apply_amt 
		LET l_arr_debithead[idx].post_flag = l_debithead.post_flag 
		IF idx = 200 THEN 
			LET l_msgresp = kandoomsg("U",6100,idx) 
			#6100" First idx records selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 
	LET l_msgresp = kandoomsg("U",9113,idx) 
	#9113  idx records selected
	IF idx = 0 THEN 
		LET idx = 1 
		INITIALIZE l_arr_debithead[idx].* TO NULL 
	END IF 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	CALL set_count (idx) 
	LET l_msgresp = kandoomsg("P",1066,"") 

	#1066 RETURN on line TO unapply Debit
	INPUT ARRAY l_arr_debithead WITHOUT DEFAULTS FROM sr_debithead.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","P6A","inp-debithead-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			DISPLAY l_arr_debithead[idx].* TO sr_debithead[scrn].* 

		AFTER ROW 
			IF fgl_lastkey() = fgl_keyval("down") THEN 
				IF l_arr_debithead[idx+1].debit_num IS NULL 
				OR arr_curr() >= arr_count() THEN 
					LET l_msgresp=kandoomsg("U",9001,"") 
					#9001 There no more rows...
					NEXT FIELD debit_num 
				END IF 
			END IF 
			DISPLAY l_arr_debithead[idx].* TO sr_debithead[scrn].* 

		BEFORE FIELD vend_code 
			IF l_arr_debithead[idx].debit_num IS NULL THEN 
				NEXT FIELD debit_num 
			END IF 
			SELECT * INTO l_debithead.* FROM debithead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND vend_code = l_arr_debithead[idx].vend_code 
			AND debit_num = l_arr_debithead[idx].debit_num 
			IF status = NOTFOUND THEN 
				ERROR " Debit NOT found" 
				NEXT FIELD debit_num 
			END IF 
			IF l_debithead.apply_amt = 0 THEN 
				ERROR " Debit has been unapplied" 
				NEXT FIELD debit_num 
			END IF 
			IF kandoomsg("P",8020,l_debithead.debit_num) = "Y" THEN 
				#8020 Confirm TO unapply debit ???
				CALL unapply_debit(glob_rec_kandoouser.cmpy_code, 
				l_debithead.debit_num) 
				SELECT * INTO l_debithead.* FROM debithead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND debit_num = l_arr_debithead[idx].debit_num 
				LET l_arr_debithead[idx].debit_num = l_debithead.debit_num 
				LET l_arr_debithead[idx].vend_code = l_debithead.vend_code 
				LET l_arr_debithead[idx].debit_date = l_debithead.debit_date 
				LET l_arr_debithead[idx].year_num = l_debithead.year_num 
				LET l_arr_debithead[idx].period_num = l_debithead.period_num 
				LET l_arr_debithead[idx].total_amt = l_debithead.total_amt 
				LET l_arr_debithead[idx].apply_amt = l_debithead.apply_amt 
				LET l_arr_debithead[idx].post_flag = l_debithead.post_flag 
				DISPLAY l_arr_debithead[idx].* TO sr_debithead[scrn].* 

			END IF 
			NEXT FIELD debit_num 

	END INPUT 
	OPTIONS INSERT KEY f1 
	OPTIONS DELETE KEY f2 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
	RETURN true 
END FUNCTION 



