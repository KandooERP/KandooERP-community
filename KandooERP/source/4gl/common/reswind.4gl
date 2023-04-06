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

	Source code beautified by beautify.pl on 2020-01-02 10:35:31	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


############################################################
# FUNCTION show_res(p_cmpy_code)
#
#           reswind.4gl - show_res
#                         window FUNCTION FOR finding jmresource records
#                         returns res_code
############################################################
FUNCTION show_res(p_cmpy_code) 
	DEFINE p_cmpy_code LIKE company.cmpy_code 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_jmresource RECORD LIKE jmresource.* 
	DEFINE l_arr_rec_jmresource DYNAMIC ARRAY OF #array[100] OF RECORD 
		RECORD 
			res_code LIKE jmresource.res_code, 
			resgrp_code LIKE jmresource.resgrp_code, 
			desc_text LIKE jmresource.desc_text 
		END RECORD 
	DEFINE l_idx SMALLINT 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		OPEN WINDOW j121 with FORM "J121" 
		CALL winDecoration_j("J121") -- albo kd-756 

		WHILE TRUE 
			CLEAR FORM 
			LET l_msgresp = kandoomsg("U",1001,"") 
			#1001 " Enter Selection Criteria - ESC TO Continue"

			CONSTRUCT BY NAME l_where_text ON res_code, 
			resgrp_code, 
			desc_text 

				BEFORE CONSTRUCT 
					CALL publish_toolbar("kandoo","reswind","construct-jmresource") 
				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

			END CONSTRUCT 


			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				LET l_rec_jmresource.res_code = NULL 
				EXIT WHILE 
			END IF 
			LET l_msgresp = kandoomsg("U",1002,"") 
			#1002 " Searching database - please wait"
			LET l_query_text = "SELECT * FROM jmresource ", 
			"WHERE cmpy_code = '",p_cmpy_code,"' ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY res_code" 
			WHENEVER ERROR CONTINUE 
			OPTIONS SQL interrupt ON 
			PREPARE s_jmresource FROM l_query_text 
			DECLARE c_jmresource CURSOR FOR s_jmresource 

			LET l_idx = 0 
			FOREACH c_jmresource INTO l_rec_jmresource.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_jmresource[l_idx].res_code = l_rec_jmresource.res_code 
				LET l_arr_rec_jmresource[l_idx].resgrp_code = l_rec_jmresource.resgrp_code 
				LET l_arr_rec_jmresource[l_idx].desc_text = l_rec_jmresource.desc_text 
				IF l_idx = 100 THEN 
					LET l_msgresp = kandoomsg("U",6100,l_idx) 
					EXIT FOREACH 
				END IF 
			END FOREACH 

			LET l_msgresp=kandoomsg("U",9113,l_idx) 
			#U9113 l_idx records selected
			IF l_idx = 0 THEN 
				LET l_idx = 1 
				INITIALIZE l_arr_rec_jmresource[1].* TO NULL 
			END IF 
			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

			LET l_msgresp = kandoomsg("U",1006,"") 
			#1006 " ESC on line TO SELECT - F10 TO Add"
			CALL set_count(l_idx) 

			INPUT ARRAY l_arr_rec_jmresource WITHOUT DEFAULTS FROM sr_jmresource.* 
				BEFORE INPUT 
					CALL publish_toolbar("kandoo","reswind","input-arr-jmresource") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 


				BEFORE ROW 
					LET l_idx = arr_curr() 
					IF l_idx > 0 THEN 
						LET l_rec_jmresource.res_code = l_arr_rec_jmresource[l_idx].res_code 
					ELSE 
						LET l_rec_jmresource.res_code = NULL 
					END IF 

					#            LET scrn = scr_line()
					#            IF l_arr_rec_jmresource[l_idx].res_code IS NOT NULL THEN
					#               DISPLAY l_arr_rec_jmresource[l_idx].* TO sr_jmresource[scrn].*
					#            END IF
					NEXT FIELD res_code 

				ON KEY (F10) 
					CALL run_prog("J71","","","","") 
					NEXT FIELD res_code 

				AFTER FIELD res_code 
					IF fgl_lastkey() = fgl_keyval("down") 
					AND arr_curr() >= arr_count() THEN 
						LET l_msgresp = kandoomsg("U",9001,"") 
						NEXT FIELD resgrp_code 
					END IF 

				BEFORE FIELD resgrp_code 
					LET l_rec_jmresource.res_code = l_arr_rec_jmresource[l_idx].res_code 
					EXIT INPUT 

					#			AFTER ROW
					#            DISPLAY l_arr_rec_jmresource[l_idx].* TO sr_jmresource[scrn].*


			END INPUT 

			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
			ELSE 
				EXIT WHILE 
			END IF 

		END WHILE 

		CLOSE WINDOW j121 

		RETURN l_rec_jmresource.res_code 
END FUNCTION 


