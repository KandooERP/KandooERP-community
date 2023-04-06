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

#  This module contains the functions needed TO add a
#  new RECORD TO the rpthead table.

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW2_GLOBALS.4gl" 


{
FUNCTION            :   hdr_add
Description         :   This FUNCTION allows the user TO add a new
                        row TO the rpthead table. It performs the appropriate
                        uniqueness AND NOT NULL checks on the VALUES entered
Incoming parameters :   None
RETURN parameters   :   None
Impact GLOBALS      :   None
perform screens     :   hdr_maint
}

###########################################################################
# FUNCTION hdr_add() 
#
#
###########################################################################
FUNCTION hdr_add() 

	DEFINE fv_idx, 
	fv_count INTEGER 

	CLEAR FORM 
	LET int_flag = false 
	LET quit_flag = false 

	#DISPLAY "" AT 2,2
	#DISPLAY "Press ACC TO except the addition, OR DEL TO cancel it" AT 2,1
	LET msgresp = kandoomsg("A",1511," ") 

	INITIALIZE gr_rpthead TO NULL 

	#   assign the default VALUES
	LET gr_rpthead.cmpy_code = glob_rec_kandoouser.cmpy_code 

	INPUT BY NAME 
		gr_rpthead.rpt_id, 
		gr_rpthead.rpt_text, 
		gr_rpthead.rpt_desc1, 
		gr_rpthead.rpt_desc2, 
		gr_rpthead.rpt_desc_position, 
		gr_rpthead.rnd_code, 
		gr_rpthead.sign_code, 
		gr_rpthead.always_print_line, 
		gr_rpthead.acct_grp, 
		gr_rpthead.col_hdr_per_page, 
		gr_rpthead.col_code, 
		gr_rpthead.std_head_per_page, 
		gr_rpthead.line_code WITHOUT DEFAULTS 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","TGW2a","input-gr_rpthead-1")  

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 


				ON ACTION "LOOKUP" infield(rpt_desc_position) ---------- browse infield(rpt_desc_position) 
					CALL show_rptpos(gr_rpthead.rpt_desc_position) 
					RETURNING gr_rpthead.rpt_desc_position 
					DISPLAY BY NAME gr_rpthead.rpt_desc_position 
					NEXT FIELD rpt_desc_position 

				ON ACTION "LOOKUP" infield(rnd_code)---------- browse infield(rnd_code) 
					CALL show_rndcode(gr_rpthead.rnd_code) 
					RETURNING gr_rpthead.rnd_code 
					DISPLAY BY NAME gr_rpthead.rnd_code 
					NEXT FIELD rnd_code 

				ON ACTION "LOOKUP" infield(sign_code)---------- browse infield(sign_code) 
					CALL show_signcode(gr_rpthead.sign_code) 
					RETURNING gr_rpthead.sign_code 
					DISPLAY BY NAME gr_rpthead.sign_code 
					NEXT FIELD sign_code 

				ON ACTION "LOOKUP" infield(acct_grp) ---------- browse infield(acct_grp) 
					CALL show_actgrps 
					(gr_rpthead.cmpy_code, gr_rpthead.acct_grp) 
					RETURNING gr_rpthead.acct_grp 
					DISPLAY BY NAME gr_rpthead.acct_grp 
					NEXT FIELD acct_grp 

				ON ACTION "LOOKUP" infield(col_code) ---------- browse infield(col_code) 
					CALL show_colgrps(gr_rpthead.cmpy_code, gr_rpthead.col_code) 
					RETURNING gr_rpthead.col_code 
					DISPLAY BY NAME gr_rpthead.col_code 
					NEXT FIELD col_code 

				ON ACTION "LOOKUP" infield(line_code)---------- browse infield(line_code) 
					CALL show_linegrps(gr_rpthead.cmpy_code, gr_rpthead.line_code) 
					RETURNING gr_rpthead.line_code 
					DISPLAY BY NAME gr_rpthead.line_code 
					NEXT FIELD line_code 


		BEFORE FIELD col_hdr_per_page 
			IF gr_rpthead.col_hdr_per_page IS NULL OR gr_rpthead.col_hdr_per_page = " " THEN 
				LET gr_rpthead.col_hdr_per_page = "Y" 
				DISPLAY BY NAME gr_rpthead.col_hdr_per_page 
			END IF 

		BEFORE FIELD std_head_per_page 
			IF gr_rpthead.std_head_per_page IS NULL OR gr_rpthead.std_head_per_page = " " THEN 
				LET gr_rpthead.std_head_per_page = "Y" 
				DISPLAY BY NAME gr_rpthead.std_head_per_page 
			END IF 

		AFTER FIELD rpt_id 
			IF gr_rpthead.rpt_id IS NULL OR gr_rpthead.rpt_id = " " THEN 
				ERROR "Report id must be entered" 
				NEXT FIELD rpt_id 
			END IF 

			#Check that the rpt_id code IS unique.
			SELECT * FROM rpthead 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rpt_id = gr_rpthead.rpt_id 
			IF status != notfound THEN 
				ERROR "There IS already a REPORT with this ID - ", 	"please enter another" 
				NEXT FIELD rpt_id 
			END IF 

		AFTER FIELD rpt_text 
			IF gr_rpthead.rpt_text IS NULL OR gr_rpthead.rpt_text = " " THEN 
				ERROR "Report text must be entered" 
				NEXT FIELD rpt_text 
			END IF 

		AFTER FIELD rpt_desc_position 
			IF gr_rpthead.rpt_desc_position IS NULL OR gr_rpthead.rpt_desc_position = " " THEN 
				ERROR "Description position must be entered - try lookup" 
				NEXT FIELD rpt_desc_position 
			END IF 

			SELECT * 
			INTO gr_rptpos.* 
			FROM rptpos 
			WHERE rptpos_id = gr_rpthead.rpt_desc_position 

			IF status = notfound THEN 
				ERROR "Invalid description position code. ", 	"Please enter another" 
				NEXT FIELD rpt_desc_position 
			END IF 

			DISPLAY BY NAME gr_rptpos.rptpos_desc 

		AFTER FIELD rnd_code 
			IF gr_rpthead.rnd_code IS NULL OR gr_rpthead.rnd_code = " " THEN 
				ERROR "Rounding code must be entered - try lookup" 
				NEXT FIELD rnd_code 
			END IF 

			SELECT * 
			INTO gr_rndcode.* 
			FROM rndcode 
			WHERE rnd_code = gr_rpthead.rnd_code 

			IF status = notfound THEN 
				ERROR "Invalid REPORT rounding code. ", "Please enter another" 
				NEXT FIELD rnd_code 
			END IF 

			DISPLAY BY NAME gr_rndcode.rnd_desc 

		AFTER FIELD sign_code 
			IF gr_rpthead.sign_code IS NULL OR gr_rpthead.sign_code = " " THEN 
				ERROR "Sign code must be entered - try lookup" 
				NEXT FIELD sign_code 
			END IF 

			SELECT * 
			INTO gr_signcode.* 
			FROM signcode 
			WHERE sign_code = gr_rpthead.sign_code 

			IF status = notfound THEN 
				ERROR "Invalid REPORT sign code. ", 
				"Please enter another" 
				NEXT FIELD sign_code 
			END IF 

			DISPLAY BY NAME gr_signcode.sign_desc 

		AFTER FIELD always_print_line 
			IF NOT (gr_rpthead.always_print_line IS NULL OR gr_rpthead.always_print_line = " ") THEN 
				IF gr_rpthead.always_print_line <> "O" THEN 
					ERROR "Must be 'O', IF specified" 
					NEXT FIELD always_print_line 
				END IF 
			END IF 

		AFTER FIELD acct_grp 
			IF NOT (gr_rpthead.acct_grp IS NULL OR gr_rpthead.acct_grp = " ") THEN 
				SELECT count(*) 
				INTO fv_count 
				FROM acctgrp 
				WHERE cmpy_code = gr_rpthead.cmpy_code 
				AND group_code = gr_rpthead.acct_grp 

				IF fv_count = 0 THEN 
					ERROR "This account group IS NOT defined - use lookup" 
					NEXT FIELD acct_grp 
				END IF 
			END IF 

		AFTER FIELD col_code 
			IF gr_rpthead.col_code IS NULL OR gr_rpthead.col_code = " " THEN 
				ERROR "Column group must be entered - try lookup" 
				NEXT FIELD col_code 
			END IF 

			SELECT count(*) 
			INTO fv_count 
			FROM rptcolgrp 
			WHERE cmpy_code = gr_rpthead.cmpy_code 
			AND col_code = gr_rpthead.col_code 

			IF fv_count = 0 THEN 
				ERROR "This COLUMN code IS NOT defined - use ctrl-b TO lookup" 
				NEXT FIELD col_code 
			END IF 

		AFTER FIELD line_code 
			IF gr_rpthead.line_code IS NULL OR gr_rpthead.line_code = " " THEN 
				ERROR "Line group must be entered - try lookup" 
				NEXT FIELD line_code 
			END IF 

			SELECT count(*) 
			INTO fv_count 
			FROM rptlinegrp 
			WHERE cmpy_code = gr_rpthead.cmpy_code 
			AND line_code = gr_rpthead.line_code 

			IF fv_count = 0 THEN 
				ERROR "This line code IS NOT defined - use ctrl-b TO lookup" 
				NEXT FIELD line_code 
			END IF 

		AFTER FIELD col_hdr_per_page 
			IF gr_rpthead.col_hdr_per_page IS NULL OR gr_rpthead.col_hdr_per_page = " " THEN 
				ERROR "Column header per page indicator must be entered" 
				NEXT FIELD col_hdr_per_page 
			END IF 

			IF NOT gr_rpthead.col_hdr_per_page matches "[YN]" THEN 
				ERROR "Must be Y OR N" 
				NEXT FIELD col_hdr_per_page 
			END IF 

		AFTER FIELD std_head_per_page 
			IF gr_rpthead.std_head_per_page IS NULL 
			OR gr_rpthead.std_head_per_page = " " THEN 
				ERROR "Report header per page indicator must be entered" 
				NEXT FIELD std_head_per_page 
			END IF 

			IF NOT gr_rpthead.std_head_per_page matches "[YN]" THEN 
				ERROR "Must be Y OR N" 
				NEXT FIELD std_head_per_page 
			END IF 

		AFTER INPUT 

			IF int_flag OR quit_flag THEN 
				EXIT INPUT 
			END IF 

			#Check FOR Null VALUES.
			IF gr_rpthead.rpt_id IS NULL THEN 
				ERROR "Field must contain a value." 
				NEXT FIELD rpt_id 
			END IF 
			
			IF gr_rpthead.rpt_desc_position IS NULL THEN 
				ERROR "Field must contain a value." 
				NEXT FIELD rpt_desc_position 
			END IF 
			
			IF gr_rpthead.rnd_code IS NULL THEN 
				ERROR "Field must contain a value." 
				NEXT FIELD rnd_code 
			END IF 
			
			IF gr_rpthead.sign_code IS NULL THEN 
				ERROR "Field must contain a value." 
				NEXT FIELD sign_code 
			END IF 
			
			IF gr_rpthead.col_code IS NULL THEN 
				ERROR "Column code must be entered - ctrl-b TO lookup" 
				NEXT FIELD col_code 
			END IF 
			
			IF gr_rpthead.line_code IS NULL THEN 
				ERROR "Line code must be entered - ctrl-b TO lookup" 
				NEXT FIELD line_code 
			END IF 
			
			IF gr_rpthead.col_hdr_per_page IS NULL THEN 
				ERROR "Field must contain a value." 
				NEXT FIELD col_hdr_per_page 
			END IF 
			
			IF gr_rpthead.std_head_per_page IS NULL THEN 
				ERROR "Field must contain a value." 
				NEXT FIELD std_head_per_page 
			END IF 

			# Add rpthead
			INSERT INTO rpthead VALUES (gr_rpthead.*) 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		ERROR "Add aborted" 
	ELSE 
		MESSAGE "Report Header has been added" 
	END IF 

END FUNCTION 
###########################################################################
# END FUNCTION hdr_add() 
###########################################################################