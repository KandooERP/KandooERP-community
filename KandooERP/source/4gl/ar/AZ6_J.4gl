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

##################################################################
# GLOBAL Scope Variables
##################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZ6_J_GLOBALS.4gl" 

##################################################################
# Module Scope Variables
##################################################################

##################################################################
# FUNCTION AZ6_J_main()
#
# Debt Types Scan
##################################################################
FUNCTION AZ6_J_main() 
	DEFINE l_withquery SMALLINT 

	DEFER quit 
	DEFER interrupt 
	
	CALL setModuleId("AZ6_J") 

	OPEN WINDOW A229 with FORM "A229" 
	CALL windecoration_a("A229") 

	CALL scan_jmj_debttype() 

	CLOSE WINDOW A229
	 
END FUNCTION 
##################################################################
# END FUNCTION AZ6_J_main()
##################################################################


##################################################################
# FUNCTION select_jmj_debttype(p_filter)
#
#
##################################################################
FUNCTION select_jmj_debttype(p_filter) 
	DEFINE p_filter boolean 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_rec_jmj_debttype RECORD LIKE jmj_debttype.* 
	DEFINE l_arr_rec_jmj_debttype DYNAMIC ARRAY OF #array[100] OF 
	RECORD 
		scroll_flag CHAR(1), 
		debt_type_code LIKE jmj_debttype.debt_type_code, 
		desc_text LIKE jmj_debttype.desc_text 
	END RECORD 
	DEFINE l_idx SMALLINT 

	IF p_filter THEN 

		CLEAR FORM 
		MESSAGE kandoomsg2("A",1001,"")	#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			debt_type_code, 
			desc_text 

			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","AZ6_J","construct-debt") 

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

	MESSAGE kandoomsg2("A",1002,"")	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM jmj_debttype ", 
		"WHERE cmpy_code = '", glob_rec_kandoouser.cmpy_code, "' ", 
		"AND ", l_where_text clipped," ", 
		"ORDER BY jmj_debttype.debt_type_code" 
	PREPARE s_jmj_debttype FROM l_query_text 
	DECLARE c_jmj_debttype CURSOR FOR s_jmj_debttype 


	LET l_idx = 0 
	FOREACH c_jmj_debttype INTO l_rec_jmj_debttype.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_jmj_debttype[l_idx].debt_type_code = l_rec_jmj_debttype.debt_type_code 
		LET l_arr_rec_jmj_debttype[l_idx].desc_text = l_rec_jmj_debttype.desc_text 

		IF l_idx = glob_rec_settings.maxListArraySize THEN
			MESSAGE kandoomsg2("U",6100,l_idx)
			EXIT FOREACH
		END IF	
	END FOREACH 

	IF l_idx = 0 THEN 
		ERROR kandoomsg2("A",9004,"")	#9004" No entries satisfied selection criteria "
	ELSE
		MESSAGE l_idx CLIPPED , "rows selected"
	END IF 

	RETURN l_arr_rec_jmj_debttype 

END FUNCTION 
##################################################################
# END FUNCTION select_jmj_debttype(p_filter)
##################################################################


##################################################################
# FUNCTION scan_jmj_debttype()
#
#
##################################################################
FUNCTION scan_jmj_debttype() 
	DEFINE l_rec_jmj_debttype RECORD LIKE jmj_debttype.* 
	DEFINE l_arr_rec_jmj_debttype DYNAMIC ARRAY OF 
	RECORD 
		scroll_flag CHAR(1), 
		debt_type_code LIKE jmj_debttype.debt_type_code, 
		desc_text LIKE jmj_debttype.desc_text 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE i SMALLINT --,scrn 
	DEFINE l_idx SMALLINT --,scrn 
	DEFINE l_del_cnt SMALLINT --,scrn 

	#   LET l_idx = 0
	#   FOREACH c_jmj_debttype INTO l_rec_jmj_debttype.*
	#      LET l_idx = l_idx + 1
	#      LET l_arr_rec_jmj_debttype[l_idx].debt_type_code = l_rec_jmj_debttype.debt_type_code
	#      LET l_arr_rec_jmj_debttype[l_idx].desc_text = l_rec_jmj_debttype.desc_text
	#      IF l_idx = 100 THEN
	#         ERROR kandoomsg2("A",9214,l_idx)#         #9214 " First ??? entries Selected Only"
	#         EXIT FOREACH
	#      END IF
	#   END FOREACH
	#
	#   IF l_idx = 0 THEN
	#      ERROR kandoomsg2("A",9004,"")#      #9004" No entries satisfied selection criteria "
	#   END IF

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_jmj_debttype_get_count() > 1000 THEN 
		CALL select_jmj_debttype(true) RETURNING l_arr_rec_jmj_debttype 
	ELSE 
		CALL select_jmj_debttype(false) RETURNING l_arr_rec_jmj_debttype 
	END IF 

	MESSAGE kandoomsg2("A",1003,"") 	#" F1 TO Add - F2 TO Delete - RETURN on line TO Edit "
	INPUT ARRAY l_arr_rec_jmj_debttype WITHOUT DEFAULTS FROM sr_jmj_debttype.* attributes(UNBUFFERED, insert ROW = false, append ROW = TRUE, auto append = false, DELETE ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZ6_J","inp-arr-jmj_debttype")
			CALL dialog.setActionHidden("CANCEL",TRUE) #we keep only ACCEPT which can process the scroll field if this is still required...
			 
 			IF l_arr_rec_jmj_debttype.getSize() THEN 
 				CALL dialog.setActionHidden("DELETE",FALSE)
 			ELSE
 				CALL dialog.setActionHidden("DELETE",TRUE)
 			END IF

		BEFORE ROW 
			LET l_idx = arr_curr() 

 			IF l_arr_rec_jmj_debttype.getSize() THEN 
 				CALL dialog.setActionHidden("DELETE",FALSE)
 			ELSE
 				CALL dialog.setActionHidden("DELETE",TRUE)
 			END IF

			NEXT FIELD scroll_flag 


		ON ACTION "FILTER" 
			CALL select_jmj_debttype(true) RETURNING l_arr_rec_jmj_debttype 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		BEFORE INSERT 
			INITIALIZE l_rec_jmj_debttype.* TO NULL #why ??? 
			NEXT FIELD debt_type_code 

		AFTER INSERT
			IF NOT int_flag THEN
				LET l_rec_jmj_debttype.debt_type_code = l_arr_rec_jmj_debttype[l_idx].debt_type_code 
				LET  l_rec_jmj_debttype.desc_text  = l_arr_rec_jmj_debttype[l_idx].desc_text
				INSERT INTO jmj_debttype VALUES (l_rec_jmj_debttype.*)
			END IF

		BEFORE FIELD scroll_flag 
			LET l_scroll_flag = l_arr_rec_jmj_debttype[l_idx].scroll_flag 

		AFTER FIELD scroll_flag 

			LET l_rec_jmj_debttype.debt_type_code = l_arr_rec_jmj_debttype[l_idx].debt_type_code 
			LET l_rec_jmj_debttype.desc_text = l_arr_rec_jmj_debttype[l_idx].desc_text 

		AFTER FIELD debt_type_code 
			#         CASE
			#            WHEN fgl_lastkey() = fgl_keyval("accept")
			#              OR fgl_lastkey() = fgl_keyval("RETURN")
			#              OR fgl_lastkey() = fgl_keyval("tab")
			#              OR fgl_lastkey() = fgl_keyval("right")
			#              OR fgl_lastkey() = fgl_keyval("down")
			IF l_arr_rec_jmj_debttype[l_idx].debt_type_code IS NULL THEN 
				ERROR kandoomsg2("A",9225,"") 			#9225 Debt Type must be entered
				NEXT FIELD debt_type_code 
			ELSE 
				IF l_rec_jmj_debttype.debt_type_code IS NULL THEN 
					SELECT unique 1 FROM jmj_debttype 
					WHERE debt_type_code = l_arr_rec_jmj_debttype[l_idx].debt_type_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					IF status != NOTFOUND THEN 
						ERROR kandoomsg2("A",9226,"") 					# 9226 Debt Type already exists
						LET l_arr_rec_jmj_debttype[l_idx].debt_type_code 	= l_rec_jmj_debttype.debt_type_code 

						NEXT FIELD debt_type_code 
					ELSE 
						FOR i = 1 TO arr_count() 
							IF i <> l_idx THEN 
								IF l_arr_rec_jmj_debttype[l_idx].debt_type_code = l_arr_rec_jmj_debttype[i].debt_type_code THEN 
									ERROR kandoomsg2("A",9226,"") # 9226 Debt Type already exists
									LET l_arr_rec_jmj_debttype[l_idx].debt_type_code = l_rec_jmj_debttype.debt_type_code 

									NEXT FIELD debt_type_code 
								END IF 
							END IF 
						END FOR 
					END IF 
				ELSE 
					LET l_arr_rec_jmj_debttype[l_idx].debt_type_code	= l_rec_jmj_debttype.debt_type_code 
				END IF 
				IF fgl_lastkey() = fgl_keyval("accept") THEN 
					IF l_arr_rec_jmj_debttype[l_idx].desc_text IS NULL THEN 
						ERROR kandoomsg2("A",9101,"") #9101 A description must be entered
						NEXT FIELD desc_text 
					END IF 
					NEXT FIELD scroll_flag 
				END IF 
				NEXT FIELD NEXT 
			END IF 

		AFTER FIELD desc_text 
			#         CASE
			#            WHEN fgl_lastkey() = fgl_keyval("accept")
			#              OR fgl_lastkey() = fgl_keyval("RETURN")
			#              OR fgl_lastkey() = fgl_keyval("tab")
			#              OR fgl_lastkey() = fgl_keyval("right")
			#              OR fgl_lastkey() = fgl_keyval("down")
			IF l_arr_rec_jmj_debttype[l_idx].desc_text IS NULL THEN 
				ERROR kandoomsg2("A",9101,"") #9101 A desc_text must be entered
				NEXT FIELD desc_text 
			ELSE 
				IF fgl_lastkey() = fgl_keyval("accept") THEN 
					NEXT FIELD scroll_flag 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		ON ACTION "DELETE" #key(F2) --delete 
			IF l_idx > 0 THEN

				IF kandoomsg("A",8021,1) = "Y" THEN #8021 Confirm TO Delete ",l_del_cnt," Debt Type(s)? (Y/N)"
					DELETE FROM jmj_debttype 
					WHERE debt_type_code = l_arr_rec_jmj_debttype[l_idx].debt_type_code 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code
				END IF
			END IF 

			CALL select_jmj_debttype(FALSE) RETURNING l_arr_rec_jmj_debttype
{
			LET l_del_cnt = 0 
			FOR l_idx = 1 TO l_arr_rec_jmj_debttype.getlength() 
				IF l_arr_rec_jmj_debttype[l_idx].scroll_flag = "*" THEN 
					LET l_del_cnt = l_del_cnt + 1 
				END IF 
			END FOR 

			IF l_del_cnt > 0 THEN 
				IF kandoomsg("A",8021,l_del_cnt) = "Y" THEN #8021 Confirm TO Delete ",l_del_cnt," Debt Type(s)? (Y/N)"
					FOR l_idx = 1 TO l_arr_rec_jmj_debttype.getlength() #arr_count() 
						IF l_arr_rec_jmj_debttype[l_idx].scroll_flag = "*" THEN 
							DELETE FROM jmj_debttype 
							WHERE debt_type_code = l_arr_rec_jmj_debttype[l_idx].debt_type_code 
							AND cmpy_code = glob_rec_kandoouser.cmpy_code 
						END IF 
					END FOR 
				END IF 
			END IF 

			CALL select_jmj_debttype(true) RETURNING l_arr_rec_jmj_debttype 
 }
		AFTER INPUT 
			IF int_flag OR quit_flag THEN 
				IF NOT (infield(scroll_flag)) THEN 
					IF l_rec_jmj_debttype.debt_type_code IS NULL THEN 
--						LET l_arr_rec_jmj_debttype[l_idx].* = l_arr_rec_jmj_debttype[l_idx+1].* 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					ELSE 
						LET l_arr_rec_jmj_debttype[l_idx].debt_type_code	= l_rec_jmj_debttype.debt_type_code 
						LET l_arr_rec_jmj_debttype[l_idx].desc_text = l_rec_jmj_debttype.desc_text 
						LET int_flag = false 
						LET quit_flag = false 
						NEXT FIELD scroll_flag 
					END IF 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 --exit 
	ELSE 
		FOR l_idx = 1 TO arr_count() 
			IF l_arr_rec_jmj_debttype[l_idx].debt_type_code IS NOT NULL THEN 
				LET l_rec_jmj_debttype.cmpy_code = glob_rec_kandoouser.cmpy_code 
				LET l_rec_jmj_debttype.debt_type_code = l_arr_rec_jmj_debttype[l_idx].debt_type_code 
				LET l_rec_jmj_debttype.desc_text = l_arr_rec_jmj_debttype[l_idx].desc_text 

				UPDATE jmj_debttype 
				SET * = l_rec_jmj_debttype.* 
				WHERE debt_type_code = l_rec_jmj_debttype.debt_type_code 
				AND cmpy_code = glob_rec_kandoouser.cmpy_code 

				IF sqlca.sqlerrd[3] = 0 THEN 
					INSERT INTO jmj_debttype VALUES (l_rec_jmj_debttype.*) 
				END IF 

			END IF 
		END FOR 
	END IF 

END FUNCTION 
##################################################################
# END FUNCTION scan_jmj_debttype()
##################################################################