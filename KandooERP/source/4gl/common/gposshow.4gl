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



############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


##########################################################################
# FUNCTION show_rptpos(p_rptpos_id)
#     gposshow.4gl - show_rptpos
#                    window FUNCTION FOR finding rptpos records
#                    returns rptpos_id
#
##########################################################################
FUNCTION show_rptpos(p_rptpos_id) 
	DEFINE p_rptpos_id CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rec_rptpos RECORD LIKE rptpos.* 
	DEFINE l_arr_rec_rptpos DYNAMIC ARRAY OF #array[100] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			rptpos_id LIKE rptpos.rptpos_id, 
			rptpos_desc LIKE rptpos.rptpos_desc 
		END RECORD 
		DEFINE l_idx SMALLINT 
		DEFINE l_query_text CHAR(800) 
		DEFINE l_where_text CHAR(400) 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		OPEN WINDOW g504 with FORM "G504" 
		CALL windecoration_g("G504") 

		WHILE true 
			IF db_rptpos_get_count() < get_settings_maxListArraySizeSwitch() THEN 
				LET l_where_text = " 1=1 " 
			ELSE 
				CLEAR FORM 
				LET l_msgresp = kandoomsg("U",1001,"") 
				#1001 " Enter Selection Criteria - ESC TO Continue"

				CONSTRUCT BY NAME l_where_text ON rptpos_id, rptpos_desc 
					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","gposshow","construct-rptpos") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 
				END CONSTRUCT 
			END IF 

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
				LET l_rec_rptpos.rptpos_id = NULL 
				EXIT WHILE 
			END IF 

			LET l_msgresp = kandoomsg("U",1002,"") 
			#1002 " Searching database - please wait"
			LET l_query_text = "SELECT * FROM rptpos ", 
			"WHERE ",l_where_text clipped," ", 
			"ORDER BY rptpos_id" 

			WHENEVER ERROR CONTINUE 

			OPTIONS SQL interrupt ON 

			PREPARE s_rptpos FROM l_query_text 
			DECLARE c_rptpos CURSOR FOR s_rptpos 

			LET l_idx = 0 
			FOREACH c_rptpos INTO l_rec_rptpos.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_rptpos[l_idx].rptpos_id = l_rec_rptpos.rptpos_id 
				LET l_arr_rec_rptpos[l_idx].rptpos_desc = l_rec_rptpos.rptpos_desc 
				#         IF l_idx = 100 THEN
				#            LET l_msgresp = kandoomsg("U",6100,l_idx)
				#            EXIT FOREACH
				#         END IF
			END FOREACH 

			LET l_msgresp=kandoomsg("U",9113,l_idx) 
			#U9113 l_idx records selected
			IF l_idx = 0 THEN 
				LET l_idx = 1 
				INITIALIZE l_arr_rec_rptpos[1].* TO NULL 
			END IF 

			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
			LET l_msgresp = kandoomsg("U",1019,"") 
			#1006 "Press ESC on line TO SELECT"
			#		CALL set_count(l_idx)

			#		INPUT ARRAY l_arr_rec_rptpos WITHOUT DEFAULTS FROM sr_rptpos.* ATTRIBUTE(UNBUFFERED)
			DISPLAY ARRAY l_arr_rec_rptpos TO sr_rptpos.* ATTRIBUTE(UNBUFFERED) 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","gposshow","input-arr-rptpos") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					IF l_idx > 0 THEN 
						LET l_rec_rptpos.rptpos_id = l_arr_rec_rptpos[l_idx].rptpos_id 
					END IF 

					#            LET scrn = scr_line()
					#IF l_arr_rec_rptpos[l_idx].rptpos_id IS NOT NULL THEN
					#   DISPLAY l_arr_rec_rptpos[l_idx].* TO sr_rptpos[scrn].*
					#END IF
					#            NEXT FIELD scroll_flag

					#			AFTER FIELD scroll_flag
					#            LET l_arr_rec_rptpos[l_idx].scroll_flag = NULL
					#            IF  fgl_lastkey() = fgl_keyval("down")
					#            AND arr_curr() >= arr_count() THEN
					#               LET l_msgresp = kandoomsg("U",9001,"")
					#               NEXT FIELD scroll_flag
					#            END IF

					#			BEFORE FIELD rptpos_id
					#            LET l_rec_rptpos.rptpos_id = l_arr_rec_rptpos[l_idx].rptpos_id
					#            EXIT INPUT

					#AFTER ROW
					#DISPLAY l_arr_rec_rptpos[l_idx].* TO sr_rptpos[scrn].*

					#			AFTER INPUT
					#            LET l_rec_rptpos.rptpos_id = l_arr_rec_rptpos[l_idx].rptpos_id


			END DISPLAY 
			###############################

			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false 
			ELSE 
				EXIT WHILE 
			END IF 

		END WHILE 

		CLOSE WINDOW g504 

		RETURN l_rec_rptpos.rptpos_id 
END FUNCTION 
