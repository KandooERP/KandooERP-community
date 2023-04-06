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

	Source code beautified by beautify.pl on 2020-01-02 19:48:02	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "J_JM_GLOBALS.4gl" 

# Purpose - Allows the user TO search FOR job ledger on selected info

GLOBALS 
	DEFINE 
	formname CHAR(15), 
	pr_jobledger RECORD LIKE jobledger.*, 
	pr_rec_kandoouser RECORD LIKE kandoouser.*, 
	pr_user_scan_code LIKE kandoouser.acct_mask_code, 
	pa_jobledger array[310] OF RECORD 
		job_code LIKE jobledger.job_code, 
		var_code LIKE jobledger.var_code, 
		activity_code LIKE jobledger.activity_code, 
		trans_type_ind LIKE jobledger.trans_type_ind, 
		trans_date LIKE jobledger.trans_date, 
		trans_source_num LIKE jobledger.trans_source_num, 
		trans_source_text LIKE jobledger.trans_source_text, 
		trans_amt LIKE jobledger.trans_amt, 
		year_num LIKE jobledger.year_num, 
		period_num LIKE jobledger.period_num, 
		posted_flag LIKE jobledger.posted_flag 
	END RECORD, 
	idx, scrn SMALLINT 
END GLOBALS 


MAIN 
	#Initial UI Init
	CALL setModuleId("J15") -- albo 
	CALL ui_init(0) 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 

	CALL user_security(glob_rec_kandoouser.cmpy_code, glob_rec_kandoouser.sign_on_code) 

	RETURNING pr_rec_kandoouser.acct_mask_code, 
	pr_user_scan_code 
	OPEN WINDOW j133 with FORM "J133" -- alch kd-747 
	CALL winDecoration_j("J133") -- alch kd-747 
	IF num_args() > 0 THEN 
		IF scan_jobledge() THEN 
			CALL disp_jobledg() 
		END IF 
	ELSE 
		WHILE scan_jobledge() 
			CALL disp_jobledg() 
		END WHILE 
	END IF 
	CLOSE WINDOW j133 
END MAIN 


FUNCTION scan_jobledge() 
	DEFINE 
	query_text, where_part CHAR(500) 

	WHILE true 
		CLEAR FORM 
		IF num_args() > 0 THEN 
			LET where_part = arg_val(1) 
		ELSE 
			LET msgresp = kandoomsg("U",1001," ") 
			# MESSAGE " Enter selection criteria - ESC TO Continue"
			CONSTRUCT BY NAME where_part 
				ON jobledger.job_code, 
				jobledger.var_code, 
				jobledger.activity_code, 
				jobledger.trans_type_ind, 
				jobledger.trans_date, 
				jobledger.trans_source_num, 
				jobledger.trans_source_text, 
				jobledger.trans_amt, 
				jobledger.year_num, 
				jobledger.period_num, 
				jobledger.posted_flag 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","J15","const-jobledger_job_code-1") -- alch kd-506 
				ON ACTION "WEB-HELP" -- albo kd-373 
					CALL onlinehelp(getmoduleid(),null) 
			END CONSTRUCT 
		END IF 
		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			RETURN false 
		END IF 

		LET query_text = 
		"SELECT jobledger.* ", 
		"FROM jobledger,", 
		"job ", 


		"WHERE jobledger.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		" AND job.cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND job.job_code = jobledger.job_code AND ", 
		where_part clipped," ", 
		"AND (job.locked_ind <= \"1\" ", 
		"OR job.acct_code matches \"",pr_user_scan_code,"\") ", 
		"ORDER BY job_code, var_code, activity_code " 


		PREPARE s_jobledg FROM query_text 
		DECLARE c_jobledg CURSOR FOR s_jobledg 
		LET idx = 0 
		FOREACH c_jobledg INTO pr_jobledger.* 
			LET idx = idx + 1 
			LET pa_jobledger[idx].job_code = pr_jobledger.job_code 
			LET pa_jobledger[idx].var_code = pr_jobledger.var_code 
			LET pa_jobledger[idx].activity_code = 
			pr_jobledger.activity_code 
			LET pa_jobledger[idx].trans_type_ind = 
			pr_jobledger.trans_type_ind 
			LET pa_jobledger[idx].trans_date = pr_jobledger.trans_date 
			LET pa_jobledger[idx].trans_source_num = 
			pr_jobledger.trans_source_num 
			LET pa_jobledger[idx].trans_source_text = 
			pr_jobledger.trans_source_text 
			LET pa_jobledger[idx].trans_amt = pr_jobledger.trans_amt 
			LET pa_jobledger[idx].year_num = pr_jobledger.year_num 
			LET pa_jobledger[idx].period_num = pr_jobledger.period_num 
			LET pa_jobledger[idx].posted_flag = pr_jobledger.posted_flag 
			IF idx = 300 THEN 
				# MESSAGE " Only first 300 Jobledger Transactions selected "


				LET msgresp = kandoomsg("U",1504," ") 
				EXIT FOREACH 
			END IF 
		END FOREACH 
		IF idx = 0 THEN 
			IF num_args() > 0 THEN 
				LET msgresp = kandoomsg("U",9506," ") 
				#ERROR "No Transactions Selected "
				RETURN false 
			ELSE 
				LET msgresp = kandoomsg("U",9506," ") 
				#ERROR "No Transactions Satisfied the Selection ",
				#      "Criteria - Re SELECT"
			END IF 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE 
	RETURN true 
END FUNCTION 


FUNCTION disp_jobledg() 
	DEFINE runner CHAR(200) 
	DEFINE cnt SMALLINT
	DEFINE l_arg1 STRING 

	# MESSAGE " RETURN TO View - DEL TO Exit"

	LET msgresp = kandoomsg("J",1012," ") 
	WHENEVER ERROR CONTINUE 
	OPTIONS INSERT KEY f36, 
	DELETE KEY f36 
	WHENEVER ERROR stop 
	CALL set_count (idx) 
	INPUT ARRAY pa_jobledger WITHOUT DEFAULTS FROM sr_jobledger.* 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","J15","input_arr-pa_jobledger-1") -- alch kd-506 

		ON ACTION "WEB-HELP" -- albo kd-373 
			CALL onlinehelp(getmoduleid(),null) 

		BEFORE ROW 
			LET idx = arr_curr() 
			LET scrn = scr_line() 
			IF arr_curr() >= arr_count() THEN 
				#ERROR "No more rows in the direction you are going"
				LET msgresp = kandoomsg("U",3513," ") 
			END IF 
			--- modif ericv init # AFTER FIELD job_code
			--#IF fgl_fglgui()
			--#AND fgl_lastkey() = fgl_keyval("accept") THEN
			--#NEXT FIELD var_code
			--#END IF

		BEFORE FIELD var_code 
			LET cnt = arr_curr() 
			IF pa_jobledger[cnt].trans_source_num IS NULL THEN 
				LET pa_jobledger[cnt].trans_source_num = -1 
			END IF 
			CASE 

				WHEN pa_jobledger[cnt].trans_type_ind = "VO" 
					LET runner = " vouch_code = ", 
					pa_jobledger[cnt].trans_source_num
					LET l_arg1 = "QUERY_WHERE_TEXT=", trim(runner) 
					CALL run_prog("P25",l_arg1,"","","") 

				WHEN pa_jobledger[cnt].trans_type_ind = "DB" 
					LET runner = " debit_num = ", 
					pa_jobledger[cnt].trans_source_num 
					LET l_arg1 = "QUERY_WHERE_TEXT=", trim(runner)
					CALL run_prog("P65",l_arg1,"","","") 

				WHEN pa_jobledger[cnt].trans_type_ind = "RE" 
					CALL run_prog("J76",pa_jobledger[cnt].trans_source_num,"","","") 

				WHEN pa_jobledger[cnt].trans_type_ind = "AD"
					CALL run_prog("J25",pa_jobledger[cnt].trans_source_num,"","","") 

				WHEN pa_jobledger[cnt].trans_type_ind = "TS" 
					CALL run_prog("J84",pa_jobledger[cnt].trans_source_num,"","","") 

				WHEN pa_jobledger[cnt].trans_type_ind = "PU" 
					CALL run_prog("R16",pa_jobledger[cnt].trans_source_num,"","","") 

				WHEN pa_jobledger[cnt].trans_type_ind = "IS" 
					LET runner = 
					" jobledger.trans_source_num =", 
					pa_jobledger[cnt].trans_source_num , 
					" AND jobledger.job_code='",pa_jobledger[cnt].job_code, 
					"' AND jobledger.var_code='",pa_jobledger[cnt].var_code, 
					"' AND jobledger.activity_code='", 
					pa_jobledger[cnt].activity_code, "'" 
					LET l_arg1 = "QUERY_WHERE_TEXT=", trim(runner)
					CALL run_prog("J92",l_arg1,"","","") 

			END CASE 
			NEXT FIELD job_code 

		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	END IF 
END FUNCTION 
