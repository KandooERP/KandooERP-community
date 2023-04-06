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
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../gl/G_GL_GLOBALS.4gl" 
GLOBALS "GW1_GLOBALS.4gl" 
############################################################
# FUNCTION get_rtime_criteria()
#
#
############################################################
FUNCTION get_rtime_criteria() 
	DEFINE l_rec_rpttype RECORD LIKE rpttype.* 
	DEFINE l_rec_currency RECORD LIKE currency.* 
	DEFINE l_rec_glparms RECORD LIKE glparms.* 
	DEFINE l_winds_text DATE 
	DEFINE l_msgresp LIKE language.yes_flag 

	CLEAR FORM 
	WHILE true 
		LET l_msgresp = kandoomsg("G",1053,"") 
		#1053 Enter Report Code
		SELECT * INTO l_rec_glparms.* FROM glparms 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND key_code = "1" 
		IF status = NOTFOUND THEN 
			LET l_msgresp = kandoomsg("G",5007,"") 
			#5007 " General Ledger parameters NOT found, see menu GZP"
			EXIT WHILE 
		END IF 
		LET glob_report_type = "0" 
		LET glob_curr_code = l_rec_glparms.base_currency_code 
		LET glob_conv_qty = 1 

		INPUT 
		glob_rec_rpthead.rpt_id, 
		glob_report_type, 
		glob_curr_code, 
		glob_conv_qty, 
		glob_rec_rpthead.rpt_desc1, 
		glob_rec_rpthead.rpt_desc2 WITHOUT DEFAULTS 
		FROM 
		rpt_id, 
		report_type, 
		curr_code, 
		conv_qty, 
		rpt_desc1, 
		rpt_desc2 

			BEFORE INPUT 
				CALL publish_toolbar("kandoo","GW1","inp-rep1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			
		ON ACTION "LOOKUP" infield(rpt_id) 
				LET glob_rec_rpthead.rpt_id = show_rpt(glob_rec_kandoouser.cmpy_code, glob_rec_rpthead.rpt_id) 
				NEXT FIELD rpt_id 

		ON ACTION "LOOKUP" infield(glob_curr_code) 
				LET glob_curr_code = show_curr(glob_rec_kandoouser.cmpy_code) 
				DISPLAY glob_curr_code TO curr_code 

				NEXT FIELD curr_code 

			AFTER FIELD rpt_id 
				LET glob_rec_entry_criteria.detailed_rpt = "C" 
				LET glob_print_ledg = "N" 
				SELECT * INTO glob_rec_rpthead.* FROM rpthead 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND rpt_id = glob_rec_rpthead.rpt_id 
				IF status THEN 
					LET l_msgresp = kandoomsg("G",9100,"") 
					#9100 "Report identifier does NOT exist"
					NEXT FIELD rpt_id 
				ELSE 
					SELECT * INTO l_rec_rpttype.* FROM rpttype 
					WHERE rpttype_id = glob_rec_rpthead.rpt_type 
					IF status THEN 
						LET l_msgresp = kandoomsg("G",9101,"") 
						#9101 "Report type does NOT exist"
						NEXT FIELD rpt_id 
					END IF 

					DISPLAY glob_rec_rpthead.rpt_id TO rpt_id 
					DISPLAY glob_rec_rpthead.rpt_text TO rpt_text 
					DISPLAY glob_conv_qty TO conv_qty 
					DISPLAY glob_rec_rpthead.rpt_desc1 TO rpt_desc1 
					DISPLAY glob_rec_rpthead.rpt_desc2 TO rpt_desc2 
					DISPLAY glob_rec_entry_criteria.glob_rpt_date TO rpt_date 
					DISPLAY glob_rec_entry_criteria.year_num TO year_num 
					DISPLAY glob_rec_entry_criteria.period_num TO period_num 
					DISPLAY glob_rec_rpthead.col_hdr_per_page TO col_hdr_per_page 
					DISPLAY glob_rec_rpthead.std_head_per_page TO std_head_per_page 
					DISPLAY glob_rec_entry_criteria.detailed_rpt TO detailed_rpt 
					DISPLAY glob_print_ledg TO print_ledg 

				END IF 

			AFTER FIELD report_type 
				IF glob_report_type = "2" THEN 
					IF l_rec_glparms.use_currency_flag = "N" THEN 
						LET l_msgresp = kandoomsg("G",9504,"") 
						#9504 Dont Use Foreign Currency
						LET glob_report_type = "0" 
						DISPLAY glob_report_type TO report_type 

					END IF 
				END IF 
				IF glob_report_type = "0" THEN 
					LET glob_curr_code = l_rec_glparms.base_currency_code 
					LET glob_conv_qty = 1 
					DISPLAY glob_curr_code TO curr_code 
					DISPLAY glob_conv_qty TO conv_qty 

				END IF 

			BEFORE FIELD curr_code 
				IF glob_report_type = "0" THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD previous 
					ELSE 
						NEXT FIELD NEXT 
					END IF 
				END IF 

			AFTER FIELD curr_code 
				IF glob_report_type = "1" THEN 
					IF glob_curr_code IS NOT NULL THEN 
						SELECT * INTO l_rec_currency.* FROM currency 
						WHERE currency_code = glob_curr_code 
						IF status = NOTFOUND THEN 
							LET l_msgresp = kandoomsg("U",9105,"") #9105 Value NOT found try window
							NEXT FIELD curr_code 
						END IF 

						#passing ' ' as rate type TO obtain budget rate
						CALL get_conv_rate(
							glob_rec_kandoouser.cmpy_code, 
							glob_curr_code, 
							today, 
							" ") 
						RETURNING glob_conv_qty 
						
						IF glob_conv_qty IS NULL OR glob_conv_qty = 0 THEN 
							LET glob_conv_qty = 1 
						END IF 
						
						DISPLAY glob_conv_qty TO conv_qty 

					END IF 
				ELSE 
					SELECT * INTO l_rec_currency.* FROM currency 
					WHERE currency_code = glob_curr_code 
					IF status = NOTFOUND THEN 
						LET l_msgresp = kandoomsg("U",9105,"") 	#9105 Value NOT found try window
						NEXT FIELD curr_code 
					END IF 
					
					LET glob_conv_qty = NULL 
					DISPLAY glob_conv_qty TO conv_qty 

				END IF 

			BEFORE FIELD conv_qty 
				IF glob_report_type = "0" 
				OR glob_report_type = "2" THEN 
					IF fgl_lastkey() = fgl_keyval("up") THEN 
						NEXT FIELD previous 
					ELSE 
						NEXT FIELD NEXT 
					END IF 
				END IF 

				#           ON KEY (control-w)
				#              CALL kandoohelp("")

		END INPUT 


		IF int_flag OR quit_flag THEN 
			EXIT WHILE 
		END IF 

		WHILE true 
			LET l_msgresp = kandoomsg("G",1001,"") 
			#1001 Enter Selection Criteria - ESC TO Continue

			CONSTRUCT BY NAME glob_entry_criteria ON coa.cmpy_code,coa.group_code 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","GW1a","construct-coa") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
			# Use default cmpy_code IF criteria = " 1=1"
			IF glob_entry_criteria = " 1=1" THEN 
				LET glob_entry_criteria = "coa.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' AND ", 
				"account.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' AND " 
				IF glob_report_type = "2" THEN 
					LET glob_entry_criteria = glob_entry_criteria clipped, 
					" accounthistcur.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'" 
				ELSE 
					LET glob_entry_criteria = glob_entry_criteria clipped, 
					" accounthist.cmpy_code = '",glob_rec_kandoouser.cmpy_code,"'" 
				END IF 
				DISPLAY glob_rec_kandoouser.cmpy_code TO cmpy_code 

			END IF 

			LET l_msgresp = kandoomsg("G",1001,"") 
			#1001 Enter Selection Criteria - ESC TO Continue

			CONSTRUCT BY NAME glob_consol_criteria ON consolhead.consol_code 
				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","GW1a","construct-consolhead") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 
			END CONSTRUCT 

			IF int_flag OR quit_flag THEN 
				EXIT WHILE 
			END IF 
			LET glob_rec_entry_criteria.detailed_rpt = "C" 

			WHILE true 
				LET l_msgresp = kandoomsg("G",1054,"") 
				#1054 Enter Report Details
				INPUT glob_rec_entry_criteria.glob_rpt_date, 
				glob_rec_entry_criteria.year_num, 
				glob_rec_entry_criteria.period_num, 
				glob_rec_rpthead.col_hdr_per_page, 
				glob_rec_rpthead.std_head_per_page, 
				glob_rec_entry_criteria.detailed_rpt, 
				glob_print_ledg WITHOUT DEFAULTS 
				FROM 
				rpt_date, 
				year_num, 
				period_num, 
				col_hdr_per_page, 
				std_head_per_page, 
				detailed_rpt, 
				print_ledg 

					BEFORE INPUT 
						CALL publish_toolbar("kandoo","GW1","inp-rep2") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

					ON ACTION "LOOKUP" infield(glob_rpt_date) 
						LET l_winds_text = showdate(glob_rec_entry_criteria.glob_rpt_date) 
						IF l_winds_text IS NOT NULL THEN 
							LET glob_rec_entry_criteria.glob_rpt_date = l_winds_text 
						END IF 

						DISPLAY glob_rec_entry_criteria.glob_rpt_date TO glob_rpt_date 

						NEXT FIELD glob_rpt_date 

						#                 ON KEY (control-w)
						#                    CALL kandoohelp("")
				END INPUT 

				IF int_flag OR quit_flag THEN 
					EXIT WHILE 
				END IF 

				IF glob_report_type = "2" THEN 
					CALL segment_con(glob_rec_kandoouser.cmpy_code, "accounthistcur") 
					RETURNING glob_segment_criteria 
				ELSE 
					CALL segment_con(glob_rec_kandoouser.cmpy_code, "accounthist") 
					RETURNING glob_segment_criteria 
				END IF 

				IF glob_segment_criteria IS NULL THEN 
					LET int_flag = true 
				END IF 

				EXIT WHILE 

			END WHILE 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				CONTINUE WHILE 
			END IF 
			EXIT WHILE 

		END WHILE 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			CONTINUE WHILE 
		END IF 
		EXIT WHILE 

	END WHILE 

END FUNCTION 
