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

	Source code beautified by beautify.pl on 2020-01-03 10:10:01	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW1_GLOBALS.4gl" 


FUNCTION get_rtime_criteria() 

	DEFINE 
	fv_found SMALLINT, 
	fr_rpttype RECORD LIKE rpttype.* 

	OPEN WINDOW g500 with FORM "TG500" 
	CALL windecoration_t("TG500") -- albo kd-768 

	LET gr_entry_criteria.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET gr_entry_criteria.worksheet_rpt = "S" 
	LET gr_entry_criteria.base_lit = "Base" 
	LET gr_entry_criteria.conv_flag = "N" 
	LET gr_entry_criteria.use_end_date = NULL 
	LET gr_entry_criteria.conv_curr = NULL 

	OPTIONS INPUT wrap 

	#MESSAGE "Enter run-time details - ACC TO accept"
	#  attribute (yellow)
	LET msgresp = kandoomsg("G",1604," ") 

	INPUT BY NAME gr_entry_criteria.cmpy_code, 
	gr_entry_criteria.rpt_date, 
	gr_entry_criteria.year_num, 
	gr_entry_criteria.period_num, 
	gr_entry_criteria.std_head_per_page, 
	gr_entry_criteria.col_hdr_per_page, 
	gr_entry_criteria.worksheet_rpt, 
	gr_entry_criteria.desc_type, 
	gr_entry_criteria.base_lit, 
	gr_entry_criteria.curr_slct, 
	gr_entry_criteria.conv_flag, 
	gr_entry_criteria.use_end_date, 
	gr_entry_criteria.conv_curr 
	WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW1a","input-gr_entry_criteria-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 


				ON ACTION "LOOKUP" infield(curr_slct)---------- browse infield(curr_slct) 
					LET gr_entry_criteria.curr_slct = show_curr(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME gr_entry_criteria.curr_slct 

				ON ACTION "LOOKUP" infield(conv_curr) ---------- browse infield(conv_curr) 
					LET gr_entry_criteria.conv_curr = show_curr(glob_rec_kandoouser.cmpy_code) 
					DISPLAY BY NAME gr_entry_criteria.conv_curr 


		BEFORE FIELD conv_curr 
			IF gr_entry_criteria.conv_flag = "N" 			OR gr_entry_criteria.use_end_date = "N" THEN 
				DISPLAY BY NAME gr_entry_criteria.conv_curr 
				NEXT FIELD cmpy_code 
			END IF 

		AFTER FIELD cmpy_code 
			IF gr_entry_criteria.cmpy_code IS NULL THEN 
				ERROR "Company must be entred" 
				NEXT FIELD cmpy_code 
			END IF 

			SELECT * 
			FROM company 
			WHERE cmpy_code = gr_entry_criteria.cmpy_code 

			IF status = notfound THEN 
				ERROR "Invalid company" 
				NEXT FIELD cmpy_code 
			END IF 

		AFTER FIELD rpt_date 
			IF gr_entry_criteria.rpt_date IS NULL THEN 
				ERROR "Report date must be entred" 
				NEXT FIELD rpt_date 
			END IF 

		AFTER FIELD year_num 
			IF gr_entry_criteria.year_num IS NULL THEN 
				ERROR "Year must be entered" 
				NEXT FIELD year_num 
			END IF 

			LET fv_found = false 
			DECLARE year_curs CURSOR FOR 
			SELECT * 
			FROM period 
			WHERE cmpy_code = gr_entry_criteria.cmpy_code 
			AND year_num = gr_entry_criteria.year_num 

			FOREACH year_curs 
				LET fv_found = true 
				EXIT FOREACH 
			END FOREACH 

			IF NOT fv_found THEN 
				ERROR "Invalid year FOR this company" 
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD period_num 
			IF gr_entry_criteria.period_num IS NULL THEN 
				ERROR "Period must be entered" 
				NEXT FIELD period_num 
			END IF 

			SELECT * 
			FROM period 
			WHERE cmpy_code = gr_entry_criteria.cmpy_code 
			AND year_num = gr_entry_criteria.year_num 
			AND period_num = gr_entry_criteria.period_num 

			IF status = notfound THEN 
				ERROR "Invalid year/period FOR this company" 
				NEXT FIELD year_num 
			END IF 

		AFTER FIELD std_head_per_page 
			IF NOT gr_entry_criteria.std_head_per_page matches "[YN ]" THEN 
				ERROR "Enter Y, N OR leave blank" 
				NEXT FIELD std_head_per_page 
			END IF 

		AFTER FIELD col_hdr_per_page 
			IF NOT gr_entry_criteria.col_hdr_per_page matches "[YN ]" THEN 
				ERROR "Enter Y, N OR leave blank" 
				NEXT FIELD col_hdr_per_page 
			END IF 

		AFTER FIELD worksheet_rpt 
			IF gr_entry_criteria.worksheet_rpt IS NULL THEN 
				ERROR "This field must be entered" 
				NEXT FIELD worksheet_rpt 
			END IF 

			IF NOT gr_entry_criteria.worksheet_rpt matches "[SW]" THEN 
				ERROR "Must be (S)tandard OR (W)orksheet" 
				NEXT FIELD worksheet_rpt 
			END IF 

		AFTER FIELD desc_type 
			IF gr_entry_criteria.desc_type IS NULL THEN 
				ERROR "This field must be entered" 
				NEXT FIELD desc_type 
			END IF 

			IF NOT gr_entry_criteria.desc_type matches "[CNB]" THEN 
				ERROR "Must be Code, Name, OR Both" 
				NEXT FIELD desc_type 
			END IF 

		AFTER FIELD base_lit 
			IF gr_entry_criteria.base_lit IS NULL 
			OR gr_entry_criteria.base_lit = " " THEN 
				ERROR "You must enter a description FOR base currency" 
				NEXT FIELD base_lit 
			END IF 

		AFTER FIELD curr_slct 
			IF gr_entry_criteria.curr_slct IS NULL 
			OR gr_entry_criteria.curr_slct = " " THEN 
				LET gr_entry_criteria.curr_slct = NULL 
			ELSE 
				SELECT 1 
				FROM currency 
				WHERE currency_code = gr_entry_criteria.curr_slct 

				IF status = notfound THEN 
					ERROR "This IS an invalid currency code - try lookup" 
					NEXT FIELD curr_slct 
				END IF 
			END IF 

		AFTER FIELD conv_flag 
			IF gr_entry_criteria.conv_flag IS NULL 
			OR gr_entry_criteria.conv_flag = " " THEN 
				ERROR "Convert-currency indicator must be entered" 
				NEXT FIELD conv_flag 
			END IF 

			IF NOT gr_entry_criteria.conv_flag matches "[YN]" THEN 
				ERROR "Convert-currency indicator must be Y OR N" 
				NEXT FIELD conv_flag 
			END IF 

			IF gr_entry_criteria.conv_flag = "N" THEN 
				LET gr_entry_criteria.use_end_date = NULL 
				LET gr_entry_criteria.conv_curr = NULL 
				LET gr_entry_criteria.conv_qty = NULL 
				DISPLAY BY NAME gr_entry_criteria.use_end_date, 
				gr_entry_criteria.conv_curr 
				NEXT FIELD cmpy_code 
			ELSE 
				LET gr_entry_criteria.use_end_date = "Y" 
			END IF 

		AFTER FIELD use_end_date 
			IF gr_entry_criteria.use_end_date IS NULL 
			OR gr_entry_criteria.use_end_date = " " THEN 
				ERROR "Use END Date indicator must be entered" 
				NEXT FIELD use_end_date 
			END IF 

			CASE 
				WHEN gr_entry_criteria.use_end_date = "N" 
					IF gr_entry_criteria.conv_flag = "Y" THEN 
						SELECT curr_code 
						INTO gv_base_curr 
						FROM company 
						WHERE cmpy_code = gr_entry_criteria.cmpy_code 

						CALL rept_curr(gr_entry_criteria.cmpy_code, 
						gv_base_curr) 
						RETURNING gr_entry_criteria.conv_curr, 
						gr_entry_criteria.conv_qty 
						IF gr_entry_criteria.conv_curr = " " THEN 
							LET gr_entry_criteria.conv_curr = NULL 
							LET gr_entry_criteria.conv_flag = "N" 
							LET gr_entry_criteria.use_end_date = "N" 
							NEXT FIELD conv_flag 
						END IF 

						IF int_flag OR quit_flag THEN 
							LET int_flag = false 
							LET quit_flag = false 
							NEXT FIELD use_end_date 
						END IF 
					END IF 

				WHEN gr_entry_criteria.use_end_date = "Y" 
					IF gr_entry_criteria.conv_flag <> "Y" THEN 
						ERROR "This IS only required IF you opt ", 
						"TO change currency" 
						LET gr_entry_criteria.conv_flag = "Y" 
						NEXT FIELD conv_flag 
					END IF 

				OTHERWISE 
					ERROR "Use END Date indicator must be Y OR N" 
					NEXT FIELD use_end_date 
			END CASE 

		AFTER FIELD conv_curr 
			CASE 
				WHEN gr_entry_criteria.conv_curr IS NULL 
					OR gr_entry_criteria.conv_curr = " " 
					LET gr_entry_criteria.conv_curr = NULL 

				WHEN gr_entry_criteria.conv_flag <> "Y" 
					ERROR "This IS only required IF you opt TO change currency" 
					LET gr_entry_criteria.conv_flag = "Y" 
					NEXT FIELD conv_flag 

				OTHERWISE 
					SELECT 1 
					FROM currency 
					WHERE currency_code = gr_entry_criteria.conv_curr 

					IF status = notfound THEN 
						ERROR "This IS an invalid currency code - try lookup" 
						NEXT FIELD conv_curr 
					END IF 
			END CASE 
	END INPUT 

	CLOSE WINDOW g500 

	OPTIONS INPUT no wrap 

	IF int_flag OR quit_flag OR gv_aborted THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET gv_aborted = true 
		RETURN 
	END IF 

	CALL segment_con(glob_rec_kandoouser.cmpy_code, 
	"AH") 
	RETURNING gv_segment_criteria 

	IF int_flag OR quit_flag THEN 
		#Unfortunately segment_con() sets the int_flag AND
		#quit_flag TO FALSE prior TO the RETURN
		#so this piece of code does NOT execute.
		#However some one may some day fix the bug.
		LET int_flag = false 
		LET quit_flag = false 
		LET gv_aborted = true 
	END IF 


	#SELECT run option
	MENU "Run Report" 

		BEFORE MENU 
			CALL publish_toolbar("kandoo","TGW1a","menu-Management_Reports-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
			CALL onlinehelp(getmoduleid(),null) 

		COMMAND "Interactively" "Run REPORT immediately" 
			LET gr_entry_criteria.run_opt = "I" 
			EXIT MENU 

		COMMAND "Background" "START REPORT running in background" 
			LET gr_entry_criteria.run_opt = "i" 
			EXIT MENU 

		COMMAND "Time" "Start reports running AT a specific time" 
			LET gr_entry_criteria.run_opt = "T" 
			EXIT MENU 

			#      COMMAND "Queue" "Send reports TO queue"
			#        LET gr_entry_criteria.run_opt = "Q"
			#        EXIT MENU

			#      COMMAND "Night-Queue" "Send reports TO night-queue"
			#        LET gr_entry_criteria.run_opt = "N"
			#        EXIT MENU

		COMMAND "Exit" "Abort REPORT processing" 
			IF upshift(kandoomsg("G","9601","")) = "Y" THEN 
				LET gv_aborted = true 
				EXIT MENU 
			ELSE 
				NEXT option "Interactively" 
			END IF 
	END MENU 

END FUNCTION #get_rtime_criteria() 
