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

	Source code beautified by beautify.pl on 2020-01-02 10:35:14	$Id: $
}




#############################################################
# GLOBAL Scope Variables
#############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 


################################################################
# FUNCTION show_rpttype(p_rpttype_id)
#
#     gtypeshow.4gl - show_rpttype
#                     window FUNCTION FOR finding rpttype records
#                     returns rpttype_id
################################################################
FUNCTION show_rpttype(p_rpttype_id) 
	DEFINE p_rpttype_id LIKE rpttype.rpttype_id 
	DEFINE l_msgresp LIKE language.yes_flag 
	DEFINE l_rpttype RECORD LIKE rpttype.* 
	DEFINE l_arr_rec_rpttype DYNAMIC ARRAY OF #array[100] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			rpttype_id LIKE rpttype.rpttype_id, 
			rpttype_desc LIKE rpttype.rpttype_desc 
		END RECORD 
		DEFINE l_idx SMALLINT 
		DEFINE l_query_text STRING 
		DEFINE l_where_text STRING 

		OPTIONS INSERT KEY f36, 
		DELETE KEY f36 

		OPEN WINDOW g507 with FORM "G507" 
		CALL windecoration_g("G507") 

		WHILE TRUE 
			IF db_rpttype_get_count() < get_settings_maxListArraySizeSwitch() THEN 
				LET l_where_text = " 1=1 " 
			ELSE 
				CLEAR FORM 
				LET l_msgresp = kandoomsg("U",1001,"") 
				#1001 " Enter Selection Criteria - ESC TO Continue"

				CONSTRUCT BY NAME l_where_text ON rpttype_id,rpttype_desc 
					BEFORE CONSTRUCT 
						CALL publish_toolbar("kandoo","gtypeshow","construct-rpttype") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 
				END CONSTRUCT 
			END IF 

			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
				LET l_rpttype.rpttype_id = NULL 
				EXIT WHILE 
			END IF 

			LET l_msgresp = kandoomsg("U",1002,"") 
			#1002 " Searching database - please wait"
			LET l_query_text = "SELECT * FROM rpttype ", 
			"WHERE ",l_where_text clipped," ", 
			"ORDER BY rpttype_id" 

			WHENEVER ERROR CONTINUE 

			OPTIONS SQL interrupt ON 

			PREPARE s_rpttype FROM l_query_text 
			DECLARE c_rpttype CURSOR FOR s_rpttype 

			LET l_idx = 0 
			FOREACH c_rpttype INTO l_rpttype.* 
				LET l_idx = l_idx + 1 
				LET l_arr_rec_rpttype[l_idx].rpttype_id = l_rpttype.rpttype_id 
				LET l_arr_rec_rpttype[l_idx].rpttype_desc = l_rpttype.rpttype_desc 

				#         IF l_idx = 100 THEN
				#            LET l_msgresp = kandoomsg("U",6100,l_idx)
				#            EXIT FOREACH
				#         END IF
			END FOREACH 

			LET l_msgresp=kandoomsg("U",9113,l_idx) 
			#U9113 l_idx records selected
			#      IF l_idx = 0 THEN
			#         LET l_idx = 1
			#         INITIALIZE l_arr_rec_rpttype[1].* TO NULL
			#      END IF

			WHENEVER ERROR stop 
			WHENEVER SQL ERROR CALL kandoo_sql_errors_handler 
			LET l_msgresp = kandoomsg("U",1019,"") 
			#1019 " Press ESC on line TO SELECT"

			#		CALL set_count(l_idx)
			#		INPUT ARRAY l_arr_rec_rpttype WITHOUT DEFAULTS FROM sr_rpttype.* ATTRIBUTE(UNBUFFERED)
			DISPLAY ARRAY l_arr_rec_rpttype TO sr_rpttype.* ATTRIBUTE(UNBUFFERED) 
				BEFORE DISPLAY 
					CALL publish_toolbar("kandoo","gtypeshow","input-arr-rpttype") 

				ON ACTION "WEB-HELP" 
					CALL onlinehelp(getmoduleid(),null) 

				ON ACTION "actToolbarManager" 
					CALL setuptoolbar() 

				BEFORE ROW 
					LET l_idx = arr_curr() 
					IF l_idx > 0 THEN 
						LET l_rpttype.rpttype_id = l_arr_rec_rpttype[l_idx].rpttype_id 
					END IF 

					#            LET scrn = scr_line()
					#IF l_arr_rec_rpttype[l_idx].rpttype_id IS NOT NULL THEN
					#   DISPLAY l_arr_rec_rpttype[l_idx].* TO sr_rpttype[scrn].*
					#
					#END IF
					#            NEXT FIELD scroll_flag

					#         AFTER FIELD scroll_flag
					#            LET l_arr_rec_rpttype[l_idx].scroll_flag = NULL
					#
					#            IF  fgl_lastkey() = fgl_keyval("down")
					#            AND arr_curr() >= arr_count() THEN
					#               LET l_msgresp = kandoomsg("U",9001,"")
					#               NEXT FIELD scroll_flag
					#            END IF

					#         BEFORE FIELD rpttype_id
					#            LET l_rpttype.rpttype_id = l_arr_rec_rpttype[l_idx].rpttype_id
					#            EXIT INPUT

					#AFTER ROW
					#   DISPLAY l_arr_rec_rpttype[l_idx].* TO sr_rpttype[scrn].*

					#         AFTER INPUT
					#            LET l_rpttype.rpttype_id = l_arr_rec_rpttype[l_idx].rpttype_id


			END DISPLAY 
			###############################

			IF int_flag OR quit_flag THEN 
				LET int_flag = FALSE 
				LET quit_flag = FALSE 
			ELSE 
				EXIT WHILE 
			END IF 

		END WHILE 

		CLOSE WINDOW g507 

		RETURN l_rpttype.rpttype_id 
END FUNCTION 


