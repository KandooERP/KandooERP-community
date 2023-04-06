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
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZR_GLOBALS.4gl" 

###########################################################################
# MAIN
#
# \brief module AZR.4gl  - Credit Memo Reason Maintainence Facility
###########################################################################
MAIN 
	DEFINE l_withquery SMALLINT 

	CALL setModuleId("AZR") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
--	CALL init_a_ar() #init a/ar module 


	OPEN WINDOW wa605 with FORM "A605" 
	CALL windecoration_a("A605") 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_credreas_get_count() > 1000 THEN 
		LET l_withquery = 1 
	END IF 

	WHILE select_reas(l_withquery) 
		LET l_withquery = scan_reas() 
		IF l_withquery = 2 OR int_flag THEN 
			EXIT WHILE 
		END IF 
	END WHILE 

	CLOSE WINDOW wa605 
END MAIN 
###########################################################################
# MAIN
###########################################################################


##################################################################
# FUNCTION select_reas(p_withquery)
#
#
##################################################################
FUNCTION select_reas(p_withquery) 
	DEFINE p_withquery SMALLINT 
	DEFINE l_query_text CHAR(500) 
	DEFINE l_where_text CHAR(400) 

	IF p_withquery = 1 THEN 
		CLEAR FORM 
		MESSAGE kandoomsg2("A",1001,"") 		#1001 Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON reason_code,reason_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","AZR","construct-reason") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

		END CONSTRUCT 

		IF int_flag OR quit_flag THEN 
			LET int_flag = false 
			LET quit_flag = false 
			LET l_where_text = "1=1" 
		END IF 

	ELSE 
		LET l_where_text = "1=1" 
	END IF 

	LET l_query_text = 
		"SELECT * ", 
		"FROM credreas ", 
		"WHERE cmpy_code = \"",glob_rec_kandoouser.cmpy_code,"\" ", 
		"AND ",l_where_text clipped," ", 
		"ORDER BY cmpy_code,", 
		"reason_code" 
	PREPARE s_credreas FROM l_query_text 
	DECLARE c_credreas CURSOR FOR s_credreas 

	RETURN 1 

END FUNCTION 
##################################################################
# END FUNCTION select_reas(p_withquery)
##################################################################


##################################################################
# FUNCTION scan_reas()
#
#
##################################################################
FUNCTION scan_reas() 

	DEFINE l_rec_credreas RECORD LIKE credreas.* 
	DEFINE l_arr_rec_credreas array[100] OF 
	RECORD 
		scroll_flag CHAR(1), 
		reason_code LIKE credreas.reason_code, 
		reason_text LIKE credreas.reason_text 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 

	LET l_idx = 0 
	LET l_del_cnt = 0 
	
	FOREACH c_credreas INTO l_rec_credreas.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_credreas[l_idx].scroll_flag = NULL 
		LET l_arr_rec_credreas[l_idx].reason_code = l_rec_credreas.reason_code 
		LET l_arr_rec_credreas[l_idx].reason_text = l_rec_credreas.reason_text 
		
		IF l_idx = 100 THEN 
			ERROR kandoomsg2("A",9016,"100") 		#9016 " Only First 100 Credit Memo Reason Selected"
			EXIT FOREACH 
		END IF 
	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("A",9022,"") 
		LET l_idx = 1 
	END IF 
	
	CALL set_count(l_idx) 
	
	MESSAGE kandoomsg2("A",1003,"100")	#1003 " F1 TO Add, RETURN on line TO Edit - F2 TO delete"
	INPUT ARRAY l_arr_rec_credreas WITHOUT DEFAULTS FROM sr_credreas.* attribute(UNBUFFERED, DELETE ROW = false, append ROW = false,auto append = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZR","inp-arr-credreas") 

		BEFORE ROW 
			LET l_idx = arr_curr() 
			NEXT FIELD scroll_flag 

		AFTER ROW 
			LET l_rec_credreas.cmpy_code = glob_rec_kandoouser.cmpy_code 

			IF l_arr_rec_credreas[l_idx].reason_code IS NOT NULL THEN 
				UPDATE credreas 
				SET reason_text = l_arr_rec_credreas[l_idx].reason_text 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND reason_code = l_arr_rec_credreas[l_idx].reason_code 
				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO credreas VALUES ( 
					glob_rec_kandoouser.cmpy_code, 
					l_arr_rec_credreas[l_idx].reason_code, 
					l_arr_rec_credreas[l_idx].reason_text) 
				END IF 
			ELSE 
				INITIALIZE l_arr_rec_credreas[l_idx].* TO NULL 
			END IF 

		ON ACTION "FILTER" 
			RETURN 1 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD scroll_flag 
			LET l_scroll_flag = l_arr_rec_credreas[l_idx].scroll_flag 
			#DISPLAY l_arr_rec_credreas[l_idx].*
			#     TO sr_credreas[scrn].*

		AFTER FIELD scroll_flag 
			LET l_arr_rec_credreas[l_idx].scroll_flag = l_scroll_flag 
			IF fgl_lastkey() = fgl_keyval("down") 
			AND arr_curr() >= arr_count() THEN 
				ERROR kandoomsg2("A",9001,"") 
				NEXT FIELD scroll_flag 
			END IF 

		BEFORE FIELD reason_code 
			IF l_arr_rec_credreas[l_idx].reason_code IS NOT NULL THEN 
				NEXT FIELD reason_text 
			END IF 

		AFTER FIELD reason_code 
			IF l_arr_rec_credreas[l_idx].reason_code IS NULL THEN 
				ERROR kandoomsg2("U",9102,"") 				#9102 " Credit Memo Reason Code must be Entered"
				NEXT FIELD reason_code 
			ELSE 
				SELECT unique 1 FROM credreas 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND reason_code = l_arr_rec_credreas[l_idx].reason_code 
				IF status = 0 THEN 
					ERROR kandoomsg2("A",9018,"") 					#9018 " Credit Memo Reason Code already exists - Please Re Enter"
					LET l_arr_rec_credreas[l_idx].reason_code = NULL 
					NEXT FIELD reason_code 
				END IF 
				NEXT FIELD reason_text 
			END IF 

			BEFORE INSERT #new/add row/record 
				INITIALIZE l_arr_rec_credreas[l_idx].* TO NULL 
				IF arr_curr() < arr_count() THEN 
					NEXT FIELD reason_code 
				END IF 



		ON KEY (F2) #delete marker 
			IF l_arr_rec_credreas[l_idx].reason_code IS NOT NULL THEN 
				IF l_arr_rec_credreas[l_idx].scroll_flag IS NULL THEN 
					LET l_arr_rec_credreas[l_idx].scroll_flag = "*" 
					LET l_del_cnt = l_del_cnt + 1 
				ELSE 
					LET l_arr_rec_credreas[l_idx].scroll_flag = NULL 
					LET l_del_cnt = l_del_cnt - 1 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 --exit 

	ELSE 
		IF l_del_cnt > 0 THEN 
			IF  kandoomsg("A",8002,l_del_cnt) = "Y" THEN #8002 Confirmation TO delete l_del_cnt Credit Memo Reasons
				FOR l_idx = 1 TO arr_count() 
					IF l_arr_rec_credreas[l_idx].scroll_flag IS NOT NULL THEN 
						DELETE FROM credreas 
						WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
						AND reason_code = l_arr_rec_credreas[l_idx].reason_code 
					END IF 
				END FOR 
			END IF 
		END IF 

	END IF 

END FUNCTION 
##################################################################
# END FUNCTION scan_reas()
##################################################################