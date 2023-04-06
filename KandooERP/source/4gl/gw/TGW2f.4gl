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


#  This module contains the functions needed TO change a
#  RECORD in rpthead table.

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "T_GW_GLOBALS.4gl" 
GLOBALS "TGW2_GLOBALS.4gl" 


###########################################################################
# FUNCTION hdr_updt()#
# 
###########################################################################
# FUNCTION            :   hdr_updt
# Description         :   This FUNCTION allows the user TO change a
#                         row in the rpthead table. It performs the appropriate
#                         uniqueness AND NOT NULL checks on the VALUES entered
# Incoming parameters :   None
# RETURN parameters   :   None
# Impact GLOBALS      :   None
# perform screens     :   rpthead
#
###########################################################################
FUNCTION hdr_updt() 

	DEFINE fv_ans CHAR(1), 
	fv_counter, 
	fv_del_colaa INTEGER 

	#DISPLAY "" AT 2,1
	#DISPLAY "Press ACC TO accept changes, OR INT TO cancel" AT 2,1
	LET msgresp = kandoomsg("U",1525," ") 

	#   assign the default VALUES
	LET gr_rpthead.cmpy_code = glob_rec_kandoouser.cmpy_code 
	LET fv_del_colaa = false # SET DELETE redundant rptcolaa flag. 
	LET int_flag = false 
	LET quit_flag = false 

	INPUT BY NAME 
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
			CALL publish_toolbar("kandoo","TGW2f","input-gr_rpthead-1") -- albo kd-515 

		ON ACTION "WEB-HELP" -- albo kd-378 
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

				ON ACTION "LOOKUP" infield(acct_grp)---------- browse infield(acct_grp) 
					CALL show_actgrps(gr_rpthead.cmpy_code, gr_rpthead.acct_grp) 
					RETURNING gr_rpthead.acct_grp 
					DISPLAY BY NAME gr_rpthead.acct_grp 
					NEXT FIELD acct_grp 

				ON ACTION "LOOKUP" infield(col_code)---------- browse infield(col_code) 
					CALL show_colgrps(gr_rpthead.cmpy_code, gr_rpthead.col_code) 
					RETURNING gr_rpthead.col_code 
					DISPLAY BY NAME gr_rpthead.col_code 
					NEXT FIELD col_code 

				ON ACTION "LOOKUP" infield(line_code) ---------- browse infield(line_code) 
					CALL show_linegrps(gr_rpthead.cmpy_code, gr_rpthead.line_code) 
					RETURNING gr_rpthead.line_code 
					DISPLAY BY NAME gr_rpthead.line_code 
					NEXT FIELD line_code 

		AFTER FIELD rpt_desc_position 

			#Check that the rpt_desc_position code exist.
			SELECT * INTO gr_rptpos.* FROM rptpos 
			WHERE rptpos_id = gr_rpthead.rpt_desc_position 

			IF status = notfound THEN 

				ERROR "Invalid description position code. ", 	"Please enter another" 
				NEXT FIELD rpt_desc_position 

			END IF 

			DISPLAY BY NAME gr_rptpos.rptpos_desc 

		AFTER FIELD rnd_code 

			#Check that the rnd_code code exist.
			SELECT * INTO gr_rndcode.* FROM rndcode 
			WHERE rnd_code = gr_rpthead.rnd_code 

			IF status = notfound THEN 
				ERROR "Invalid REPORT rounding code. ", "Please enter another" 
				NEXT FIELD rnd_code 
			END IF 

			DISPLAY BY NAME gr_rndcode.rnd_desc 

		AFTER FIELD sign_code 

			#Check that the sign_code code exist.
			SELECT * INTO gr_signcode.* FROM signcode 
			WHERE sign_code = gr_rpthead.sign_code 
			IF status = notfound THEN 
				ERROR "Invalid REPORT sign code. ", "Please enter another" 
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
				INTO fv_counter 
				FROM acctgrp 
				WHERE cmpy_code = gr_rpthead.cmpy_code 
				AND group_code = gr_rpthead.acct_grp 

				IF fv_counter = 0 THEN 
					ERROR "This account group IS NOT defined - use lookup" 
					NEXT FIELD acct_grp 
				END IF 
			END IF 

		AFTER FIELD col_code 
			SELECT count(*) 
			INTO fv_counter 
			FROM rptcolgrp 
			WHERE cmpy_code = gr_rpthead.cmpy_code 
			AND col_code = gr_rpthead.col_code 

			IF fv_counter = 0 THEN 
				ERROR "This COLUMN code IS NOT defined - use ctrl-b TO lookup" 
				NEXT FIELD col_code 
			END IF 

		AFTER FIELD line_code 
			SELECT count(*) 
			INTO fv_counter 
			FROM rptlinegrp 
			WHERE cmpy_code = gr_rpthead.cmpy_code 
			AND line_code = gr_rpthead.line_code 

			IF fv_counter = 0 THEN 
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
			IF gr_rpthead.std_head_per_page IS NULL OR gr_rpthead.std_head_per_page = " " THEN 
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
			CASE 
				WHEN gr_rpthead.rpt_desc_position IS NULL 
					ERROR "Field must contain a value." 
					NEXT FIELD rpt_desc_position 
				WHEN gr_rpthead.rnd_code IS NULL 
					ERROR "Field must contain a value." 
					NEXT FIELD rnd_code 
				WHEN gr_rpthead.sign_code IS NULL 
					ERROR "Field must contain a value." 
					NEXT FIELD sign_code 
				WHEN gr_rpthead.col_code IS NULL 
					ERROR "Column code must be entered - ctrl-b TO lookup" 
					NEXT FIELD col_code 
				WHEN gr_rpthead.line_code IS NULL 
					ERROR "Line code must be entered - ctrl-b TO lookup" 
					NEXT FIELD line_code 
				WHEN gr_rpthead.col_hdr_per_page IS NULL 
					ERROR "Field must contain a value." 
					NEXT FIELD col_hdr_per_page 
				WHEN gr_rpthead.std_head_per_page IS NULL 
					ERROR "Field must contain a value." 
					NEXT FIELD std_head_per_page 
			END CASE 

			# Update rpthead
			UPDATE rpthead 
			SET rpthead.* = gr_rpthead.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND rpt_id = gr_rpthead.rpt_id 

			IF status THEN 
				ERROR "Could Not Update REPORT header Table. ", 	"DEL TO Exit, OR Try again." 
				NEXT FIELD rpt_text 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		ERROR "Update aborted" 
	ELSE 
		MESSAGE "Report header has been Updated" 
	END IF -- int_flag OR quit_flag 

END FUNCTION 
###########################################################################
# END FUNCTION hdr_updt()#
###########################################################################