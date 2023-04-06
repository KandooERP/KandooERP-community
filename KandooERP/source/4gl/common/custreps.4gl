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

###########################################################################
#Program custreps  - Customer Grouping
###########################################################################

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

###########################################################################
# FUNCTION report_criteria(p_cmpy_code,p_module)
#
#
###########################################################################
FUNCTION report_criteria(p_cmpy_code,p_module) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE p_module LIKE kandoooption.module_code
	DEFINE l_rec_arparms RECORD LIKE arparms.* 
	DEFINE l_seq_num SMALLINT 
	DEFINE l_where_text STRING
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_where_text = "1=1" 
	CASE 
		WHEN p_module = "AR" 
			#get Account Receivable Parameters Record
			CALL db_arparms_get_rec(UI_ON,1) RETURNING l_rec_arparms.*

			IF l_rec_arparms.parm_code IS NULL THEN #notfound  
				ERROR kandoomsg2("A",5001,"")			#5001 AR Parameters NOT SET up - Refer Menu WZP
			END IF 

			IF get_kandoooption_feature_state("AR","CP") = 0 THEN 
				LET l_where_text = "1=1" 
				ERROR kandoomsg2("A",9304,"")			#9304 Customer Reporting Codes NOT available - Refer menu US1
			END IF 

			IF l_rec_arparms.ref1_text IS NOT NULL 
			OR l_rec_arparms.ref2_text IS NOT NULL 
			OR l_rec_arparms.ref3_text IS NOT NULL 
			OR l_rec_arparms.ref4_text IS NOT NULL 
			OR l_rec_arparms.ref5_text IS NOT NULL 
			OR l_rec_arparms.ref6_text IS NOT NULL 
			OR l_rec_arparms.ref7_text IS NOT NULL 
			OR l_rec_arparms.ref8_text IS NOT NULL THEN 
				LET l_rec_arparms.ref1_text = make_rep_prompt(l_rec_arparms.ref1_text) 
				LET l_rec_arparms.ref2_text = make_rep_prompt(l_rec_arparms.ref2_text) 
				LET l_rec_arparms.ref3_text = make_rep_prompt(l_rec_arparms.ref3_text) 
				LET l_rec_arparms.ref4_text = make_rep_prompt(l_rec_arparms.ref4_text) 
				LET l_rec_arparms.ref5_text = make_rep_prompt(l_rec_arparms.ref5_text) 
				LET l_rec_arparms.ref6_text = make_rep_prompt(l_rec_arparms.ref6_text) 
				LET l_rec_arparms.ref7_text = make_rep_prompt(l_rec_arparms.ref7_text) 
				LET l_rec_arparms.ref8_text = make_rep_prompt(l_rec_arparms.ref8_text) 

				OPEN WINDOW A656 with FORM "A656" 
				CALL windecoration_a("A656") -- albo kd-752 

				DISPLAY BY NAME l_rec_arparms.ref1_text, 
				l_rec_arparms.ref2_text, 
				l_rec_arparms.ref3_text, 
				l_rec_arparms.ref4_text, 
				l_rec_arparms.ref5_text, 
				l_rec_arparms.ref6_text, 
				l_rec_arparms.ref7_text, 
				l_rec_arparms.ref8_text attribute(white)
				 
				MESSAGE kandoomsg2("A",1001,"")		#1001 Enter Selection Criteria - ESC TO Continue
				CONSTRUCT BY NAME l_where_text ON customer.ref1_code, 
				customer.ref2_code, 
				customer.ref3_code, 
				customer.ref4_code, 
				customer.ref5_code, 
				customer.ref6_code, 
				customer.ref7_code, 
				customer.ref8_code 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","custreps","construct-customer") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

					BEFORE FIELD ref1_code 
						IF l_rec_arparms.ref1_text IS NULL THEN 
							LET l_seq_num = 1 
							NEXT FIELD ref2_code 
						END IF 

					AFTER FIELD ref1_code 
						LET l_seq_num = 1 

					BEFORE FIELD ref2_code 
						IF l_rec_arparms.ref2_text IS NULL THEN 
							IF l_seq_num > 2 THEN 
								LET l_seq_num = 2 
								NEXT FIELD ref1_code 
							ELSE 
								LET l_seq_num = 2 
								NEXT FIELD ref3_code 
							END IF 
						END IF 

					AFTER FIELD ref2_code 
						LET l_seq_num = 2 

					BEFORE FIELD ref3_code 
						IF l_rec_arparms.ref3_text IS NULL THEN 
							IF l_seq_num > 3 THEN 
								LET l_seq_num = 3 
								NEXT FIELD ref2_code 
							ELSE 
								LET l_seq_num = 3 
								NEXT FIELD ref4_code 
							END IF 
						END IF 

					AFTER FIELD ref3_code 
						LET l_seq_num = 3 

					BEFORE FIELD ref4_code 
						IF l_rec_arparms.ref4_text IS NULL THEN 
							IF l_seq_num > 4 THEN 
								LET l_seq_num = 4 
								NEXT FIELD ref3_code 
							ELSE 
								LET l_seq_num = 4 
								NEXT FIELD ref5_code 
							END IF 
						END IF 

					AFTER FIELD ref4_code 
						LET l_seq_num = 4 

					BEFORE FIELD ref5_code 
						IF l_rec_arparms.ref5_text IS NULL THEN 
							IF l_seq_num > 5 THEN 
								LET l_seq_num = 5 
								NEXT FIELD ref4_code 
							ELSE 
								LET l_seq_num = 5 
								NEXT FIELD ref6_code 
							END IF 
						END IF 

					AFTER FIELD ref5_code 
						LET l_seq_num = 5 

					BEFORE FIELD ref6_code 
						IF l_rec_arparms.ref6_text IS NULL THEN 
							IF l_seq_num > 6 THEN 
								LET l_seq_num = 6 
								NEXT FIELD ref5_code 
							ELSE 
								LET l_seq_num = 6 
								NEXT FIELD ref7_code 
							END IF 
						END IF 

					AFTER FIELD ref6_code 
						LET l_seq_num = 6 

					BEFORE FIELD ref7_code 
						IF l_rec_arparms.ref7_text IS NULL THEN 
							IF l_seq_num > 7 THEN 
								LET l_seq_num = 7 
								NEXT FIELD ref6_code 
							ELSE 
								LET l_seq_num = 7 
								NEXT FIELD ref8_code 
							END IF 
						END IF 

					AFTER FIELD ref7_code 
						LET l_seq_num = 7 

					BEFORE FIELD ref8_code 
						IF l_rec_arparms.ref8_text IS NULL THEN 
							LET l_seq_num = 8 
							EXIT CONSTRUCT 
						END IF 

					AFTER FIELD ref8_code 
						LET l_seq_num = 8 

				END CONSTRUCT 

				CLOSE WINDOW A656
			ELSE
				CALL fgl_winmessage("Reporting Codes","Your system configuration does not include any reporting codes","info") 
				LET l_where_text = NULL
			END IF
			 
		OTHERWISE 

	END CASE 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		LET l_where_text = NULL 
	END IF 

	RETURN l_where_text 
END FUNCTION 
###########################################################################
# END FUNCTION report_criteria(p_cmpy_code,p_module)
###########################################################################


###########################################################################
# FUNCTION make_rep_prompt(p_ref_text)
#
#
###########################################################################
FUNCTION make_rep_prompt(p_ref_text) 
	DEFINE p_ref_text LIKE arparms.ref1_text
	DEFINE l_temp_text STRING 

	IF p_ref_text IS NULL THEN 
		LET l_temp_text = NULL 
	ELSE 
		LET l_temp_text = p_ref_text clipped, "...................." 
	END IF 
	
	RETURN l_temp_text 
END FUNCTION 
###########################################################################
# END FUNCTION make_rep_prompt(p_ref_text)
###########################################################################