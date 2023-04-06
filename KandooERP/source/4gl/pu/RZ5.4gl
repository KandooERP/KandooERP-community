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

	Source code beautified by beautify.pl on 2020-01-02 17:06:24	Source code beautified by beautify.pl on 2020-01-02 17:03:33	$Id: $
}


############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_userDataTypes.4gl"
GLOBALS "R_PU_GLOBALS.4gl" 
############################################################
# MODULE Scope Variables
############################################################

#######################################################################
# MAIN
#
# \brief module RZ5 - Maintain Descriptions
#   Purpose - Allow the user TO Add, UPDATE AND query product description
#######################################################################
MAIN 

	CALL setModuleId("RZ5") -- albo 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) 
	CALL init_r_pu() #init r/pu purchase ORDER module 

	OPEN WINDOW r608 with FORM "R608" 
	CALL  windecoration_r("R608") 

	#   WHILE select_desc()
	CALL edit_desc() 
	#   END WHILE
	CLOSE WINDOW r608 
END MAIN 


############################################################
# FUNCTION select_desc()
#
#
############################################################
FUNCTION select_desc(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	#DEFINE i INTEGER
	DEFINE idx SMALLINT 
	DEFINE l_rec_jmpo_desc RECORD LIKE jmpo_description.* 
	DEFINE l_arr_rec_jmpo_desc DYNAMIC ARRAY OF t_rec_jmpo_pd_with_scrollflag 

	IF p_filter THEN 
		#	FOR i = 1 TO 10
		#		CLEAR sr_jmpo_desc[i].*
		#	END FOR
		CLEAR FORM --huho 
		LET msgresp = kandoomsg("U",1001,"") 
		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON po_description 
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","RZ5","construct-jmpo_desc-1") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = " 1=1 " 
		END IF 
	ELSE 
		LET l_where_text = " 1=1 " 
	END IF 

	LET msgresp = kandoomsg("A",1002,"") 
	#1002 " Searching database - please wait"
	LET l_query_text = "SELECT jmpo_description.* FROM jmpo_description ", 
	"WHERE cmpy_code = ","'",glob_rec_kandoouser.cmpy_code,"'", 
	"AND ", l_where_text clipped," ", 
	"ORDER BY 1,2" 
	PREPARE s_description FROM l_query_text 
	DECLARE c_description CURSOR FOR s_description 

	LET idx = 0 
	FOREACH c_description INTO l_rec_jmpo_desc.* 
		LET idx = idx + 1 
		LET l_arr_rec_jmpo_desc[idx].po_description = l_rec_jmpo_desc.po_description 
		#		IF idx = 100 THEN
		#		LET msgresp = kandoomsg("R",9506,"100")
		#			#9506 " Only first 100 lines selected only"
		#		EXIT FOREACH
		#		END IF
	END FOREACH 
	LET msgresp=kandoomsg("U",9113,idx) 
	#9113 idx records selected

	RETURN l_arr_rec_jmpo_desc 

END FUNCTION 


############################################################
# FUNCTION edit_desc()
#
#
############################################################
FUNCTION edit_desc() 
	DEFINE l_rec_jmpo_desc RECORD LIKE jmpo_description.* 
	DEFINE l_arr_rec_jmpo_desc DYNAMIC ARRAY OF t_rec_jmpo_pd_with_scrollflag 
	#	DEFINE l_arr_rec_jmpo_desc DYNMAIC ARRAY OF #array[100] OF
	#		RECORD
	#			scroll_flag CHAR(1),
	#			po_description LIKE jmpo_description.po_description
	#		END RECORD
	#DEFINE l_scroll_flag CHAR(1)
	DEFINE idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 


	CALL select_desc(false) RETURNING l_arr_rec_jmpo_desc 


	#   IF idx = 0 THEN
	#      LET msgresp = kandoomsg("R",9002,"")
	#      #9002 No rows satisfied selection criteria
	#      LET idx = idx + 1
	#      INITIALIZE l_arr_rec_jmpo_desc[idx].* TO NULL
	#   END IF

	OPTIONS INSERT KEY f1 
	OPTIONS DELETE KEY f36 
	#   CALL set_count(idx)

	LET msgresp = kandoomsg("U",1003,"") 
	#1003 " F1 TO Add - F2 TO Delete - TAB TO edit line "
	INPUT ARRAY l_arr_rec_jmpo_desc WITHOUT DEFAULTS FROM sr_jmpo_desc.* attribute(UNBUFFERED, append ROW = false, auto append = false, DELETE ROW = false) 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","RZ5","inp-arr-jmpo_desc-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		ON ACTION "FILTER" 
			CALL select_desc(true) RETURNING l_arr_rec_jmpo_desc 

		BEFORE ROW 
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			LET l_rec_jmpo_desc.po_description = l_arr_rec_jmpo_desc[idx].po_description 
			#         IF arr_curr() <= arr_count() THEN
			#            DISPLAY l_arr_rec_jmpo_desc[idx].* TO sr_jmpo_desc[scrn].*
			#
			#         ELSE
			#            LET msgresp = kandoomsg("U",9001,"")
			#            #9001 There are no more rows in the direction you are going
			#         END IF
		BEFORE FIELD scroll_flag 
			LET idx = arr_curr() 
			#LET scrn = scr_line()
			#LET l_scroll_flag = l_arr_rec_jmpo_desc[idx].scroll_flag
			# DISPLAY l_arr_rec_jmpo_desc[idx].*
			#      TO sr_jmpo_desc[scrn].*


			#      AFTER FIELD scroll_flag
			#         #LET l_arr_rec_jmpo_desc[idx].scroll_flag = l_scroll_flag
			#         #DISPLAY l_arr_rec_jmpo_desc[idx].scroll_flag
			#         #     TO sr_jmpo_desc[scrn].scroll_flag
			#
			#         LET l_rec_jmpo_desc.po_description = l_arr_rec_jmpo_desc[idx].po_description
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF l_arr_rec_jmpo_desc[idx+1].po_description IS NULL
			#            OR arr_curr() >= arr_count() THEN
			#               LET msgresp=kandoomsg("U",9001,"")
			#               #9001 There are no more rows...
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF

		AFTER FIELD po_description 
			IF l_arr_rec_jmpo_desc[idx].po_description IS NULL THEN 
				LET msgresp = kandoomsg("R",9004,"") 
				#9004 " Description must be entered"
				NEXT FIELD po_description 
			END IF 


		BEFORE INSERT 
			#         IF idx > arr_count() THEN
			#            LET msgresp=kandoomsg("U",9001,"")
			#               #9001 There are no more rows...
			#         END IF
			INITIALIZE l_arr_rec_jmpo_desc[idx].* TO NULL 
			#         #CLEAR sr_jmpo_desc[scrn].*
			NEXT FIELD po_description 

		AFTER INSERT 
			IF l_arr_rec_jmpo_desc[idx].po_description IS NOT NULL AND NOT desc_exists(l_arr_rec_jmpo_desc[idx].po_description) THEN 
				LET l_rec_jmpo_desc.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_jmpo_desc.po_description = l_arr_rec_jmpo_desc[idx].po_description 
				INSERT INTO jmpo_description VALUES (l_rec_jmpo_desc.*) 
			END IF 

		AFTER ROW 

			IF l_rec_jmpo_desc.po_description != l_arr_rec_jmpo_desc[idx].po_description THEN 
				UPDATE jmpo_description 
				SET po_description = l_arr_rec_jmpo_desc[idx].po_description 
				WHERE po_description = l_rec_jmpo_desc.po_description 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			END IF 

		ON KEY (F2) --delete marker 
			IF l_arr_rec_jmpo_desc[idx].po_description IS NOT NULL THEN 
				IF l_arr_rec_jmpo_desc[idx].scroll_flag IS NULL THEN 
					LET l_arr_rec_jmpo_desc[idx].scroll_flag = "*" 
					LET l_del_cnt = l_del_cnt + 1 
				ELSE 
					LET l_arr_rec_jmpo_desc[idx].scroll_flag = NULL 
					LET l_del_cnt = l_del_cnt - 1 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")
	END INPUT 
	-------------------------------------------------------------

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		IF l_del_cnt > 0 THEN 
			LET msgresp = kandoomsg("R",8503,l_del_cnt) 
			#8503 Confirm TO Delete ",l_del_cnt," Product descriptions (Y/N)?"
			IF msgresp = "Y" THEN 
				FOR idx = 1 TO arr_count() 
					IF l_arr_rec_jmpo_desc[idx].scroll_flag = "*" THEN 
						DELETE FROM jmpo_description 
						WHERE po_description = l_arr_rec_jmpo_desc[idx].po_description 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				END FOR 
			END IF 
		END IF 
	END IF 
END FUNCTION 


############################################################
# FUNCTION desc_exists(p_desc)
#
#
############################################################
FUNCTION desc_exists(p_desc) 
	DEFINE cnt SMALLINT 
	DEFINE p_desc LIKE jmpo_description.po_description 

	LET cnt = 0 
	SELECT count(*) 
	INTO cnt 
	FROM jmpo_description 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND po_description = p_desc 
	RETURN cnt 
END FUNCTION 

