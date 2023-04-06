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
#####################################################################
# FUNCTION show_fin(p_cmpy_code)
# show_fin
#                        Window FUNCTION FOR finding reporthead records
#                        returns report_code
#####################################################################
FUNCTION show_fin(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_reporthead RECORD LIKE reporthead.* 
	DEFINE l_arr_rec_reporthead DYNAMIC ARRAY OF #array[100] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			report_code LIKE reporthead.report_code, 
			desc_text LIKE reporthead.desc_text 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

		OPEN WINDOW G119 with FORM "G119" 
		CALL windecoration_g("G119") -- albo kd-767 

		WHILE true 
			CLEAR FORM 
			MESSAGE kandoomsg2("U",1001,"") 		#1001 " Enter Selection Criteria - ESC TO Continue"
			CONSTRUCT BY NAME l_where_text ON report_code, desc_text 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","finwind","construct-REPORT") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 
					
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 


			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET l_rec_reporthead.report_code = NULL 
				EXIT WHILE 
			END IF 

			MESSAGE kandoomsg2("U",1002,"") 			#1002 " Searching database - please wait"
			LET l_query_text = "SELECT * FROM reporthead ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY report_code" 

			WHENEVER ERROR CONTINUE 
			OPTIONS SQL interrupt ON 

			PREPARE s_reporthead FROM l_query_text 
			DECLARE c_reporthead CURSOR FOR s_reporthead 

			LET l_idx = 0 
			FOREACH c_reporthead INTO l_rec_reporthead.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_reporthead[l_idx].report_code = l_rec_reporthead.report_code 
				LET l_arr_rec_reporthead[l_idx].desc_text = l_rec_reporthead.desc_text 
			END FOREACH 

			MESSAGE kandoomsg2("U",9113,l_idx) 	#U9113 l_idx records selected

			IF l_idx = 0 THEN 
				LET l_idx = 1 
				INITIALIZE l_arr_rec_reporthead[1].* TO NULL 
			END IF 

			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

			MESSAGE kandoomsg2("U",1006,"") 			#1006 " ESC on line TO SELECT - F10 TO Add"

			DISPLAY ARRAY l_arr_rec_reporthead TO sr_reporthead.*
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","finwind","input-arr-reporthead") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null)
					 
				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					LET l_rec_reporthead.report_code = l_arr_rec_reporthead[l_idx].report_code
					#            LET scrn = scr_line()
					#            IF l_arr_rec_reporthead[l_idx].report_code IS NOT NULL THEN
					#               DISPLAY l_arr_rec_reporthead[l_idx].* TO sr_reporthead[scrn].*
					#
					#            END IF

				ON ACTION "Fin.Reports Maint." #ON KEY (F10) #Financial Reports Maintenance 
					CALL run_prog("GZ5","","","","") 

			END DISPLAY 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				EXIT WHILE 
			END IF 

		END WHILE 

		CLOSE WINDOW G119 

		RETURN l_rec_reporthead.report_code 
END FUNCTION