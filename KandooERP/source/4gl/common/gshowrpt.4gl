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

	Source code beautified by beautify.pl on 2020-01-02 10:35:13	$Id: $
}



#     gshowrpt.4gl - show_rpt
#                    window FUNCTION FOR finding rpthead records
#                    returns rpt_id
GLOBALS "../common/glob_GLOBALS.4gl" 

######################################################################
# FUNCTION show_rpt(p_cmpy,p_rpt_id)
######################################################################
FUNCTION show_rpt(p_cmpy,p_rpt_id) 
	DEFINE p_cmpy LIKE company.cmpy_code 
	DEFINE p_rpt_id LIKE rpthead.rpt_id 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_rpthead RECORD LIKE rpthead.* 
	DEFINE l_arr_rec_rpthead DYNAMIC ARRAY OF #array[100] OF RECORD 
		RECORD 
			rpt_id LIKE rpthead.rpt_id, 
			rpt_text LIKE rpthead.rpt_text, 
			rpt_type LIKE rpthead.rpt_type 
		END RECORD 
		DEFINE l_idx SMALLINT 
		DEFINE l_query_text STRING 
		DEFINE l_where_text STRING 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		OPEN WINDOW g501 with FORM "G501" 
		CALL windecoration_g("G501") -- albo kd-767 

		WHILE true 

			IF db_rpthead_get_count() <= get_settings_maxListArraySizeSwitch() THEN 
				LET l_where_text = " 1=1 " 
			ELSE 
				CLEAR FORM 
				LET l_msgresp = kandoomsg("U",1001,"") 
				#1001 " Enter Selection Criteria - ESC TO Continue"

				CONSTRUCT BY NAME l_where_text ON rpt_id, 
				rpt_text, 
				rpt_type 

					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","gshowrpt","construct-rpthead") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 

				END CONSTRUCT 


				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET l_rec_rpthead.rpt_id = NULL 
					EXIT WHILE 
				END IF 
			END IF 

			LET l_msgresp = kandoomsg("U",1002,"") 

			#1002 " Searching database - please wait"
			LET l_query_text = "SELECT * FROM rpthead ", 
			"WHERE cmpy_code = '",p_cmpy,"' ", 
			"AND ",l_where_text clipped," ", 
			"ORDER BY rpt_id" 

			WHENEVER ERROR CONTINUE 

			OPTIONS SQL interrupt ON 

			PREPARE s_rpthead FROM l_query_text 
			DECLARE c_rpthead CURSOR FOR s_rpthead 

			LET l_idx = 0 
			FOREACH c_rpthead INTO l_rec_rpthead.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_rpthead[l_idx].rpt_id = l_rec_rpthead.rpt_id 
				LET l_arr_rec_rpthead[l_idx].rpt_text = l_rec_rpthead.rpt_text 
				LET l_arr_rec_rpthead[l_idx].rpt_type = l_rec_rpthead.rpt_type 

				#         IF l_idx = 100 THEN
				#            LET l_msgresp = kandoomsg("U",6100,l_idx)
				#            EXIT FOREACH
				#         END IF

			END FOREACH 

			LET l_msgresp=kandoomsg("U",9113,l_idx) 
			#U9113 l_idx records selected

			IF l_idx = 0 THEN 
				LET l_idx = 1 
				INITIALIZE l_arr_rec_rpthead[1].* TO NULL 
			END IF 

			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

			LET l_msgresp = kandoomsg("U",1019,"") 
			#1019 " Press ESC on line TO SELECT"

			#      CALL set_count(l_idx)
			DISPLAY ARRAY l_arr_rec_rpthead TO sa_rpthead.* ATTRIBUTE(UNBUFFERED) 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","gshowrpt","input-arr-rpthead") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					LET l_rec_rpthead.rpt_id = l_arr_rec_rpthead[l_idx].rpt_id 

					#            LET scrn = scr_line()
					#IF l_arr_rec_rpthead[l_idx].rpt_id IS NOT NULL THEN
					#   DISPLAY l_arr_rec_rpthead[l_idx].* TO sa_rpthead[scrn].*

					#END IF
					#            NEXT FIELD rpt_id

					#		AFTER FIELD rpt_id
					#            IF  fgl_lastkey() = fgl_keyval("down")
					#            AND arr_curr() >= arr_count() THEN
					#               LET l_msgresp = kandoomsg("U",9001,"")
					#               NEXT FIELD rpt_id
					#            END IF

					#		BEFORE FIELD rpt_text
					#            LET l_rec_rpthead.rpt_id = l_arr_rec_rpthead[l_idx].rpt_id
					#            EXIT INPUT

					#AFTER ROW
					#   DISPLAY l_arr_rec_rpthead[l_idx].* TO sa_rpthead[scrn].*

					#		AFTER INPUT
					#            LET l_rec_rpthead.rpt_id = l_arr_rec_rpthead[l_idx].rpt_id



			END DISPLAY 


			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				EXIT WHILE 
			END IF 

		END WHILE 


		CLOSE WINDOW g501 

		RETURN l_rec_rpthead.rpt_id 
END FUNCTION 


