#Invoice Load Parameters A627
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

	Source code beautified by beautify.pl on 2020-01-03 11:19:28	$Id: $
}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../ar/A_AR_GLOBALS.4gl" 
GLOBALS "../ar/AZ_GROUP_GLOBALS.4gl" 
GLOBALS "../ar/AZI_GLOBALS.4gl" 

############################################################
# Module Scope Variables
############################################################


##################################################################
# MAIN
#
# AZI - Invoice Load Parameters
##################################################################
MAIN 
	DEFINE l_withquery SMALLINT 

	CALL setModuleId("AZI") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_a_ar() #init a/ar module 

	OPEN WINDOW A627 with FORM "A627" 
	CALL windecoration_a("A627") 

	#if the the table has more than 1000 rows, force a query TO filter data
	IF db_loadparms_get_count() > 1000 THEN 
		LET l_withquery = 1 
	END IF 

	CALL scan_ldparms() 
	#   WHILE select_ldparms(l_withQuery)
	#		LET l_withQuery = scan_ldparms()
	#		IF l_withQuery = 2 OR int_flag THEN
	#			EXIT WHILE
	#		END IF
	#	END WHILE

	CLOSE WINDOW A627 
END MAIN 


##################################################################
# FUNCTION select_ldparms(pWithQuery)
#
#
##################################################################
FUNCTION select_ldparms(pwithquery) 
	DEFINE pwithquery SMALLINT 
	DEFINE l_query_text CHAR(500) 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT 
	DEFINE l_arr_rec_loadparms DYNAMIC ARRAY OF #array[100] OF 
	RECORD 
		scroll_flag CHAR(1), 
		load_ind LIKE loadparms.load_ind, 
		desc_text LIKE loadparms.desc_text 
	END RECORD 
	DEFINE l_rec_loadparms RECORD LIKE loadparms.* 

	IF pwithquery = filter_query_on THEN 

		CLEAR FORM 
		MESSAGE kandoomsg2("A",1001,"") 		#1001 " Enter Selection Criteria - ESC TO Continue"
		CONSTRUCT BY NAME l_where_text ON 
			load_ind, 
			desc_text 


			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","AZI","construct-load") 

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

	MESSAGE kandoomsg2("A",1002,"") 	#1002 " Searching database - please wait"
	LET l_query_text = 
		"SELECT * FROM loadparms ", 
		"WHERE cmpy_code = ","'",glob_rec_kandoouser.cmpy_code,"'", 
		"AND module_code = 'AR' ", 
		"AND ", l_where_text clipped," ", 
		"ORDER BY loadparms.load_ind" 

	PREPARE s_loadparms FROM l_query_text 
	DECLARE c_loadparms CURSOR FOR s_loadparms 

	LET l_idx = 0 
	FOREACH c_loadparms INTO l_rec_loadparms.* 
		LET l_idx = l_idx + 1 
		LET l_arr_rec_loadparms[l_idx].load_ind = l_rec_loadparms.load_ind 
		LET l_arr_rec_loadparms[l_idx].desc_text = l_rec_loadparms.desc_text 
		#      IF l_idx = 100 THEN
		#         MESSAGE kandoomsg2("A",9211,l_idx)      #9211 " First ??? Load Indicator Selected Only"
		#         EXIT FOREACH
		#      END IF
	END FOREACH 

	RETURN l_arr_rec_loadparms 
END FUNCTION 


##################################################################
# FUNCTION scan_ldparms()
#
#
##################################################################
FUNCTION scan_ldparms() 
	DEFINE l_rec_loadparms RECORD LIKE loadparms.* 
	DEFINE l_arr_rec_loadparms DYNAMIC ARRAY OF #array[100] OF 
	RECORD 
		scroll_flag CHAR(1), 
		load_ind LIKE loadparms.load_ind, 
		desc_text LIKE loadparms.desc_text 
	END RECORD 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_curr SMALLINT 
	DEFINE l_cnt SMALLINT 
	DEFINE l_idx SMALLINT 
	DEFINE l_del_cnt SMALLINT 
	DEFINE l_rowid SMALLINT 



	#   LET l_idx = 0
	#   FOREACH c_loadparms INTO l_rec_loadparms.*
	#      LET l_idx = l_idx + 1
	#      LET l_arr_rec_loadparms[l_idx].load_ind = l_rec_loadparms.load_ind
	#      LET l_arr_rec_loadparms[l_idx].desc_text = l_rec_loadparms.desc_text
	#      IF l_idx = 100 THEN
	#         ERROR kandoomsg2("A",9211,l_idx)      #9211 " First ??? Load Indicator Selected Only"
	#         EXIT FOREACH
	#      END IF
	#   END FOREACH
	#
	#   IF l_idx = 0 THEN
	#      ERROR kandoomsg2("A",9210,"")   #9210 No Load Indicators satisfied selection criteria
	#      LET l_idx = 1
	#   END IF
	#OPTIONS INSERT KEY F1,
	#        DELETE KEY F36
	#   CALL set_count(l_idx)

	IF 1 = 1 THEN #needs TO be replaced with count 
		CALL select_ldparms(filter_query_off) RETURNING l_arr_rec_loadparms 
	ELSE 
		CALL select_ldparms(filter_query_on) RETURNING l_arr_rec_loadparms 
	END IF 

	MESSAGE kandoomsg2("A",1003,"") #1003 " F1 TO Add - F2 TO Delete - RETURN on line TO Edit "

	INPUT ARRAY l_arr_rec_loadparms WITHOUT DEFAULTS FROM sr_loadparms.* attributes(UNBUFFERED, append ROW = false, auto append = false, DELETE ROW = false) 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZI","inp-arr-loadparms") 

		BEFORE ROW 
			LET l_idx = arr_curr() 

		ON ACTION "FILTER" 
			CALL select_ldparms(filter_query_on) RETURNING l_arr_rec_loadparms 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD scroll_flag 
			LET l_idx = arr_curr() 
			#         #LET scrn = scr_line()
			#         LET l_scroll_flag = l_arr_rec_loadparms[l_idx].scroll_flag
			#         #DISPLAY l_arr_rec_loadparms[l_idx].*
			#         #     TO sr_loadparms[scrn].*
			#
			#      AFTER FIELD scroll_flag
			#         LET l_arr_rec_loadparms[l_idx].scroll_flag = l_scroll_flag
			#         #DISPLAY l_arr_rec_loadparms[l_idx].scroll_flag
			#         #     TO sr_loadparms[scrn].scroll_flag
			#
			#         IF fgl_lastkey() = fgl_keyval("down") THEN
			#            IF l_arr_rec_loadparms[l_idx+1].load_ind IS NULL
			#            OR arr_curr() >= arr_count() THEN
			#               ERROR kandoomsg2("A",9001,"")            #9001 There no more rows...
			#               NEXT FIELD scroll_flag
			#            END IF
			#         END IF

		ON ACTION ("EDIT","doubleClick","ACCEPT") --edit INPUT 
			IF l_arr_rec_loadparms[l_idx].load_ind IS NOT NULL THEN 
				LET l_rec_loadparms.load_ind = l_arr_rec_loadparms[l_idx].load_ind 
				LET l_rec_loadparms.desc_text = l_arr_rec_loadparms[l_idx].desc_text 
				LET l_curr = arr_curr() 
				LET l_cnt = arr_count() 
				IF edit_loadparms(l_rec_loadparms.load_ind,"U") THEN 
					SELECT * 
					INTO l_rec_loadparms.* 
					FROM loadparms 
					WHERE load_ind = l_rec_loadparms.load_ind 
					AND module_code = 'AR' 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_arr_rec_loadparms[l_idx].load_ind = l_rec_loadparms.load_ind 
					LET l_arr_rec_loadparms[l_idx].desc_text = l_rec_loadparms.desc_text 
				END IF 
			END IF 
			CALL select_ldparms(filter_query_off) RETURNING l_arr_rec_loadparms 
			NEXT FIELD scroll_flag 
			#RETURN 0

		BEFORE FIELD load_ind 
			IF l_arr_rec_loadparms[l_idx].load_ind IS NOT NULL THEN 
				LET l_rec_loadparms.load_ind = l_arr_rec_loadparms[l_idx].load_ind 
				LET l_rec_loadparms.desc_text = l_arr_rec_loadparms[l_idx].desc_text 
				LET l_curr = arr_curr() 
				LET l_cnt = arr_count() 
				IF edit_loadparms(l_rec_loadparms.load_ind,"U") THEN 
					SELECT * 
					INTO l_rec_loadparms.* 
					FROM loadparms 
					WHERE load_ind = l_rec_loadparms.load_ind 
					AND module_code = 'AR' 
					AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					LET l_arr_rec_loadparms[l_idx].load_ind = l_rec_loadparms.load_ind 
					LET l_arr_rec_loadparms[l_idx].desc_text = l_rec_loadparms.desc_text 
				END IF 
			END IF 
			NEXT FIELD scroll_flag 
			RETURN 0 

		BEFORE INSERT #new ROW 
			--         IF arr_curr() < arr_count() THEN  #????
			LET l_curr = arr_curr() 
			LET l_cnt = arr_count() 
			LET l_rowid = edit_loadparms("","A") 
			IF l_rowid = 0 THEN 
				#    FOR l_idx = l_curr TO l_cnt
				#       LET l_arr_rec_loadparms[l_idx].* = l_arr_rec_loadparms[l_idx+1].*
				#       IF scrn <= 10 THEN
				#          DISPLAY l_arr_rec_loadparms[l_idx].* TO sr_loadparms[scrn].*
				#
				#          LET scrn = scrn + 1
				#       END IF
				#    END FOR
				#    INITIALIZE l_arr_rec_loadparms[l_idx].* TO NULL
			ELSE 
				SELECT * 
				INTO l_rec_loadparms.* 
				FROM loadparms 
				WHERE rowid = l_rowid 
				LET l_arr_rec_loadparms[l_idx].load_ind = l_rec_loadparms.load_ind 
				LET l_arr_rec_loadparms[l_idx].desc_text = l_rec_loadparms.desc_text 
			END IF 
			#         ELSE
			#            IF l_idx > 1 THEN
			#               ERROR kandoomsg2("A",9001,"")           #9001 There are no more rows....
			#            END IF
			--         END IF

		ON ACTION "DELETE" #new - DELETE currently selected ROW instantly 
			LET l_del_cnt = 0 
			FOR l_idx = 1 TO l_arr_rec_loadparms.getlength() 
				IF l_arr_rec_loadparms[l_idx].scroll_flag = "*" THEN 
					LET l_del_cnt = l_del_cnt + 1 
				END IF 
			END FOR 
			
			IF l_del_cnt = 0 THEN 
				LET l_del_cnt = 1 
				LET l_arr_rec_loadparms[l_curr].scroll_flag = "*" 
			END IF 

			IF kandoomsg("A",8014,l_del_cnt) = "Y" THEN #8014 Confirm TO Delete ",l_del_cnt," Load Indicator(s)? (Y/N)"
				FOR l_idx = 1 TO l_arr_rec_loadparms.getlength() 
					IF l_arr_rec_loadparms[l_idx].scroll_flag = "*" THEN 
						DELETE FROM loadparms 
						WHERE load_ind = l_arr_rec_loadparms[l_idx].load_ind 
						AND module_code = 'AR' 
						AND cmpy_code = glob_rec_kandoouser.cmpy_code 
					END IF 
				END FOR 
			END IF 

			CALL select_ldparms(filter_query_off) RETURNING l_arr_rec_loadparms 

			#      ON KEY(F2)  --Delete - classic - SET delete marker for later removal
			#
			#      IF l_del_cnt > 0 THEN

			#         IF kandoomsg("A",8014,l_del_cnt) = "Y" THEN #8014 Confirm TO Delete ",l_del_cnt," Load Indicator(s)? (Y/N)"
			#            FOR l_idx = 1 TO arr_count()
			#               IF l_arr_rec_loadparms[l_idx].scroll_flag = "*" THEN
			#                  DELETE FROM loadparms
			#                    WHERE load_ind = l_arr_rec_loadparms[l_idx].load_ind
			#                      AND module_code = 'AR'
			#                      AND cmpy_code = glob_rec_kandoouser.cmpy_code
			#               END IF
			#            END FOR
			#         END IF
			#      END IF


			{
			         IF l_arr_rec_loadparms[l_idx].scroll_flag IS NULL THEN
			            LET l_arr_rec_loadparms[l_idx].scroll_flag = "*"
			            LET l_del_cnt = l_del_cnt + 1
			         ELSE
			            LET l_arr_rec_loadparms[l_idx].scroll_flag = NULL
			            LET l_del_cnt = l_del_cnt - 1
			         END IF
			}
			NEXT FIELD scroll_flag 

			#AFTER ROW
			#DISPLAY l_arr_rec_loadparms[l_idx].*
			#     TO sr_loadparms[scrn].*



	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN 2 --exit 
		#	ELSE
		#      IF l_del_cnt > 0 THEN
		#         ERROR kandoomsg2("A",8014,l_del_cnt)		#         #8014 Confirm TO Delete ",l_del_cnt," Load Indicator(s)? (Y/N)"
		#         IF kandoomsg("A",8014,l_del_cnt) = "Y" THEN
		#            FOR l_idx = 1 TO arr_count()
		#               IF l_arr_rec_loadparms[l_idx].scroll_flag = "*" THEN
		#                  DELETE FROM loadparms
		#                    WHERE load_ind = l_arr_rec_loadparms[l_idx].load_ind
		#                      AND module_code = 'AR'
		#                      AND cmpy_code = glob_rec_kandoouser.cmpy_code
		#               END IF
		#            END FOR
		#         END IF
		#      END IF
		#
	END IF 

END FUNCTION 

##################################################################
# FUNCTION edit_loadparms(l_load_ind,l_mode)
#
#
##################################################################
FUNCTION edit_loadparms(l_load_ind,l_mode) 
	DEFINE l_rec_s_loadparms RECORD LIKE loadparms.* 
	DEFINE l_rec_loadparms RECORD LIKE loadparms.* 
	DEFINE l_load_ind LIKE loadparms.load_ind 
	DEFINE l_mode CHAR(1) 

	OPEN WINDOW A628 with FORM "A628" 
	CALL windecoration_a("A628") 

	IF l_mode = "U" THEN {update} 
		SELECT * 
		INTO l_rec_loadparms.* 
		FROM loadparms 
		WHERE load_ind = l_load_ind 
		AND module_code = 'AR' 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 
		DISPLAY BY NAME l_rec_loadparms.load_num, 
		l_rec_loadparms.load_date, 
		l_rec_loadparms.seq_num 

	ELSE 
		INITIALIZE l_rec_loadparms.* TO NULL 
		LET l_rec_loadparms.cmpy_code = glob_rec_kandoouser.cmpy_code 
		LET l_rec_loadparms.seq_num = 0 
		LET l_rec_loadparms.entry1_flag = "N" 
		LET l_rec_loadparms.entry2_flag = "N" 
		LET l_rec_loadparms.entry3_flag = "N" 
		LET l_rec_loadparms.module_code = "AR" 
	END IF 
	
	LET l_rec_s_loadparms.* = l_rec_loadparms.* 
	MESSAGE kandoomsg2("A",1052,"") 	#1052" Enter Load Details - Esc TO continue
	DISPLAY BY NAME l_rec_loadparms.load_ind 


	#HuHo Is this really required TO be displayed TO the console ?   13.08.2019 HuHo I'll comment it
	#DISPLAY "l_rec_loadparms.entry1_flag=", l_rec_loadparms.entry1_flag
	#DISPLAY "l_rec_loadparms.entry2_flag=", l_rec_loadparms.entry2_flag
	#DISPLAY "l_rec_loadparms.entry3_flag=", l_rec_loadparms.entry3_flag


	INPUT BY NAME 
		l_rec_loadparms.load_ind, 
		l_rec_loadparms.desc_text, 
		l_rec_loadparms.file_text, 
		l_rec_loadparms.path_text, 
		l_rec_loadparms.format_ind, 
		l_rec_loadparms.prmpt1_text, 
		l_rec_loadparms.ref1_text, 
		l_rec_loadparms.entry1_flag, 
		l_rec_loadparms.prmpt2_text, 
		l_rec_loadparms.ref2_text, 
		l_rec_loadparms.entry2_flag, 
		l_rec_loadparms.prmpt3_text, 
		l_rec_loadparms.ref3_text, 
		l_rec_loadparms.entry3_flag WITHOUT DEFAULTS

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","AZI","inp-loadparms") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 

		BEFORE FIELD load_ind 
			IF l_mode = "U" THEN 
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD load_ind 
			IF l_rec_loadparms.load_ind IS NULL THEN 
				ERROR kandoomsg2("A",9205,"") 				#A9205 Load Indicator must be entered.
				NEXT FIELD load_ind 
			END IF 

		AFTER FIELD desc_text 
			IF l_rec_loadparms.desc_text IS NULL THEN 
				ERROR kandoomsg2("A",9208,"") 				#9208  Description must be entered
				NEXT FIELD desc_text 
			END IF 

		AFTER FIELD format_ind 
			IF l_rec_loadparms.format_ind IS NULL THEN 
				ERROR kandoomsg2("E",9114,"") 				#E9114  Format Indicator must be entered.
				NEXT FIELD format_ind 
			END IF 

		AFTER INPUT 
			IF NOT (int_flag OR quit_flag) THEN 
				IF l_rec_loadparms.load_ind IS NULL THEN 
					ERROR kandoomsg2("A",9208,"") 					#9208 " Load Indicator must be entered
					NEXT FIELD load_ind 
				END IF 
				IF l_rec_loadparms.desc_text IS NULL THEN 
					ERROR kandoomsg2("A",9212,"") 					#9212 Description must be entered
					NEXT FIELD desc_text 
				END IF 
				IF l_rec_loadparms.format_ind IS NULL THEN 
					ERROR kandoomsg2("E",9114,"") 					#E9114  Format Indicator must be entered.
					NEXT FIELD format_ind 
				END IF 
			END IF 

	END INPUT 

	#DISPLAY "l_rec_loadparms.entry1_flag=", l_rec_loadparms.entry1_flag
	#DISPLAY "l_rec_loadparms.entry2_flag=", l_rec_loadparms.entry2_flag
	#DISPLAY "l_rec_loadparms.entry3_flag=", l_rec_loadparms.entry3_flag


	IF int_flag OR quit_flag THEN 
		LET quit_flag = false 
		LET int_flag = false 
		CLOSE WINDOW A628 
		RETURN false 
	END IF 

	CASE l_mode 
		WHEN "U" 
			UPDATE loadparms 
			SET * = l_rec_loadparms.* 
			WHERE load_ind = l_load_ind 
			AND module_code = 'AR' 
			AND cmpy_code = glob_rec_kandoouser.cmpy_code 
			CLOSE WINDOW A628 
			RETURN sqlca.sqlerrd[3] 

		WHEN "A" 
			INSERT INTO loadparms 
			VALUES (l_rec_loadparms.*) 
			CLOSE WINDOW A628 
			RETURN sqlca.sqlerrd[6] 

		OTHERWISE 
			ERROR "Logic ERROR " 
			CLOSE WINDOW A628 
			RETURN false 
	END CASE 

END FUNCTION 


