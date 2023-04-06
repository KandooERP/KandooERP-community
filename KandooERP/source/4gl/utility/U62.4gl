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
GLOBALS "../utility/U_UT_GLOBALS.4gl" 

GLOBALS 
	DEFINE glob_rec_statparms RECORD LIKE statparms.* 
END GLOBALS 


###################################################################
# MAIN
#
# U62 maintains statistic intervals
###################################################################
MAIN 
	DEFINE l_year_num SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	DEFER quit 
	DEFER interrupt 

	CALL setModuleId("U62") 
	CALL ui_init(0) #initial ui init 
	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	#Statistic Parameter record
	CALL db_statparms_get_rec(UI_ON,"1") RETURNING glob_rec_statparms.*
	
	IF NOT db_statparms_get_rec_exists("1") THEN
			CALL fgl_winmessage("ERROR",kandoomsg("E",5004,""),"ERROR") 
			EXIT program 
	END IF 
	
	OPEN WINDOW U215 with FORM "U215" 
	CALL windecoration_u("U215") 

	DISPLAY glob_rec_statparms.year_num TO year_num

	LET l_year_num = glob_rec_statparms.year_num

	WHILE TRUE 
		LET l_year_num = scan_int(l_year_num)
		IF int_flag THEN
			EXIT WHILE
		END IF
	END WHILE


{	WHILE true 
		DISPLAY glob_rec_statparms.year_num TO year_num

		IF U62_query_statistics_interval() THEN 
			LET l_year_num = glob_rec_statparms.year_num 
			WHILE l_year_num IS NOT NULL 
				LET l_year_num = scan_int(l_year_num) 
			END WHILE 
			CLEAR FORM 
		ELSE 
			EXIT WHILE 
		END IF 
	END WHILE
}
 
	CLOSE WINDOW U215 
END MAIN 


###################################################################
# FUNCTION U62_query_statistics_interval()
#
#
###################################################################
FUNCTION U62_query_statistics_interval(p_filter)
	DEFINE p_filter BOOLEAN 
	DEFINE l_query_text STRING 
	DEFINE l_where_text STRING 
	DEFINE l_idx SMALLINT
	DEFINE l_arr_rec_statint DYNAMIC ARRAY OF RECORD 
			scroll_flag CHAR(1), 
			type_code LIKE statint.type_code, 
			int_num LIKE statint.int_num, 
			int_text LIKE statint.int_text, 
			start_date LIKE statint.start_date, 
			end_date LIKE statint.end_date, 
			days_num SMALLINT, 
			salesdays_num LIKE statint.salesdays_num 
		END RECORD 
	DEFINE l_rec_statint RECORD LIKE statint.* 
				
	IF p_filter THEN

		MESSAGE kandoomsg2("E",1058,"") 
		#1058 Enter selection criteria - F8 SELECT Year - ESC TO continue
		CONSTRUCT BY NAME l_where_text ON type_code, 
		int_num, 
		int_text, 
		start_date, 
		end_date, 
		salesdays_num 
	
			BEFORE CONSTRUCT 
				CALL publish_toolbar("kandoo","U62","construct-satint") 
	
			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
	
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 
	
	
	
			ON ACTION "SET YEAR" #ON KEY (F8) 
				LET glob_rec_statparms.year_num = enter_year() 
				DISPLAY glob_rec_statparms.year_num  TO year_num
	
			ON ACTION "YEAR-1" #ON KEY (F9) 
				LET glob_rec_statparms.year_num = glob_rec_statparms.year_num - 1 
				DISPLAY glob_rec_statparms.year_num TO year_num
	
			ON ACTION "YEAR+1" #ON KEY (F10) 
				LET glob_rec_statparms.year_num = glob_rec_statparms.year_num + 1 
				DISPLAY glob_rec_statparms.year_num TO year_num
	
		END CONSTRUCT 
		
			IF int_flag OR quit_flag THEN 
				LET int_flag = false 
				LET quit_flag = false
				LET l_where_text = " 1=1 " 
			END IF

	ELSE	
		LET l_where_text = " 1=1 "
	END IF
	 
	MESSAGE kandoomsg2("E",1002,"")	#1002 Searching database - please wait
	LET l_query_text = "SELECT * FROM statint ", 
	"WHERE cmpy_code ='",glob_rec_kandoouser.cmpy_code,"' ", 
	"AND year_num = ? ", 
	"AND ",l_where_text clipped," ", 
	"ORDER BY cmpy_code,", 
	"type_code,", 
	"int_num" 
	PREPARE s_statint FROM l_query_text 
	DECLARE c_statint CURSOR FOR s_statint 

		OPEN c_statint USING glob_rec_statparms.year_num 
		FOREACH c_statint INTO l_rec_statint.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_statint[l_idx].scroll_flag = NULL 
			LET l_arr_rec_statint[l_idx].type_code = l_rec_statint.type_code 
			LET l_arr_rec_statint[l_idx].int_num = l_rec_statint.int_num 
			LET l_arr_rec_statint[l_idx].int_text = l_rec_statint.int_text 
			LET l_arr_rec_statint[l_idx].start_date = l_rec_statint.start_date 
			LET l_arr_rec_statint[l_idx].end_date = l_rec_statint.end_date 
			LET l_arr_rec_statint[l_idx].days_num = l_rec_statint.end_date - l_rec_statint.start_date + 1 
			LET l_arr_rec_statint[l_idx].salesdays_num = l_rec_statint.salesdays_num 
		END FOREACH 
 
	RETURN l_arr_rec_statint	
END FUNCTION 


###################################################################
# FUNCTION scan_int(p_year_num)
#
#
###################################################################
FUNCTION scan_int(p_year_num) 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_scroll_flag CHAR(1) 
	DEFINE l_arr_rec_statint DYNAMIC ARRAY OF #array[500] OF RECORD 
		RECORD 
			scroll_flag CHAR(1), 
			type_code LIKE statint.type_code, 
			int_num LIKE statint.int_num, 
			int_text LIKE statint.int_text, 
			start_date LIKE statint.start_date, 
			end_date LIKE statint.end_date, 
			days_num SMALLINT, 
			salesdays_num LIKE statint.salesdays_num 
		END RECORD 
		DEFINE pr_rowid INTEGER 
		DEFINE p_year_num SMALLINT 
		DEFINE l_idx SMALLINT 
		DEFINE l_del_cnt SMALLINT 
		DEFINE i SMALLINT 
		DEFINE j SMALLINT 
		DEFINE l_msgresp LIKE language.yes_flag 
		DEFINE l_msg STRING
		
		CLEAR FORM 
		LET glob_rec_statparms.year_num = p_year_num 
		DISPLAY glob_rec_statparms.year_num  TO year_num

		LET l_del_cnt = 0 

		CALL U62_query_statistics_interval(FALSE) RETURNING l_arr_rec_statint
		
{
		LET l_idx = 0 

		OPEN c_statint USING glob_rec_statparms.year_num 
		FOREACH c_statint INTO l_rec_statint.* 
			LET l_idx = l_idx + 1 
			LET l_arr_rec_statint[l_idx].scroll_flag = NULL 
			LET l_arr_rec_statint[l_idx].type_code = l_rec_statint.type_code 
			LET l_arr_rec_statint[l_idx].int_num = l_rec_statint.int_num 
			LET l_arr_rec_statint[l_idx].int_text = l_rec_statint.int_text 
			LET l_arr_rec_statint[l_idx].start_date = l_rec_statint.start_date 
			LET l_arr_rec_statint[l_idx].end_date = l_rec_statint.end_date 
			LET l_arr_rec_statint[l_idx].days_num = l_rec_statint.end_date 
			- l_rec_statint.start_date + 1 
			LET l_arr_rec_statint[l_idx].salesdays_num = l_rec_statint.salesdays_num 
			IF l_idx = 500 THEN 
				ERROR kandoomsg2("E",9200,"500") 
				#9200 " First ??? stats intervals selected only"
				EXIT FOREACH 
			END IF 
		END FOREACH 

		IF l_idx = 0 THEN 
			--LET l_idx = 1 
			--INITIALIZE l_arr_rec_statint[1].* TO NULL 
			ERROR kandoomsg2("E",9201,"") 
			#9201 " No intervals satisfied the selection criteria"
		END IF 
}
		OPTIONS INSERT KEY f1 
		#DELETE KEY f36 

--		CALL set_count(l_idx) 
		MESSAGE kandoomsg2("E",1059,"") 

		#1059 F1 Add-F2 Delete-F7 Generate-F8 SELECT Year-F9 Prv-F10 Nxt
		#INPUT ARRAY l_arr_rec_statint WITHOUT DEFAULTS FROM sr_statint.* ATTRIBUTE(UNBUFFERED,delete row = false, append row= false, auto append = false)
		DISPLAY ARRAY l_arr_rec_statint TO sr_statint.* ATTRIBUTE(UNBUFFERED)
			BEFORE DISPLAY 
				CALL publish_toolbar("kandoo","U62","input-arr-statint") 
				CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_statint.getSize())
				CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_statint.getSize())
				CALL dialog.setActionHidden("GENERATE",NOT l_arr_rec_statint.getSize())
				CALL dialog.setActionHidden("ACCEPT",TRUE)
				#CALL dialog.setActionHidden("DOUBLECLICK",TRUE) Used for Auto-Generate

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 

			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 

			ON ACTION "FILTER"
				CALL U62_query_statistics_interval(TRUE) RETURNING l_arr_rec_statint

			ON ACTION "REFRESH"
				CALL U62_query_statistics_interval(FALSE) RETURNING l_arr_rec_statint										

			BEFORE ROW
				LET l_idx = arr_curr()
				#HuHo: Had to add some strange row handling
				#l_idx was 0 but array had one row.. could not understand why and when this happens.
				IF l_idx = 0 AND l_arr_rec_statint.getSize() < 0 THEN
					LET l_idx = 1
				END IF
{
				
			BEFORE FIELD scroll_flag 
				LET l_idx = arr_curr() 
				#         LET scrn = scr_line()
				LET l_scroll_flag = l_arr_rec_statint[l_idx].scroll_flag 
				#         DISPLAY l_arr_rec_statint[l_idx].*
				#              TO sr_statint[scrn].*

--			AFTER FIELD scroll_flag 
--				LET l_arr_rec_statint[l_idx].scroll_flag = l_scroll_flag 
--				IF fgl_lastkey() = fgl_keyval("down") THEN 
--					IF arr_curr() >= arr_count() THEN 
--						LET l_msgresp = kandoomsg("E",9001,"") 
--						# There are no more rows in the direction you are going.
--						NEXT FIELD scroll_flag 
--					END IF 
--					IF l_arr_rec_statint[l_idx+1].type_code IS NULL THEN 
--						LET l_msgresp = kandoomsg("E",9001,"") 
--						# There are no more rows in the direction you are going.
--						NEXT FIELD scroll_flag 
--					END IF 
--				END IF 

			
			BEFORE FIELD type_code 
				IF edit_interval(l_arr_rec_statint[l_idx].type_code, 
				l_arr_rec_statint[l_idx].int_num) THEN 
					SELECT int_text, 
					end_date, 
					(end_date - start_date + 1), 
					salesdays_num 
					INTO l_arr_rec_statint[l_idx].int_text, 
					l_arr_rec_statint[l_idx].end_date, 
					l_arr_rec_statint[l_idx].days_num, 
					l_arr_rec_statint[l_idx].salesdays_num 
					FROM statint 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = glob_rec_statparms.year_num 
					AND type_code = l_arr_rec_statint[l_idx].type_code 
					AND int_num = l_arr_rec_statint[l_idx].int_num 
				END IF 
				NEXT FIELD scroll_flag 
}
			ON ACTION "ADD"
			#BEFORE INSERT 
--				IF arr_curr() < arr_count() THEN 
					LET pr_rowid = edit_interval(l_arr_rec_statint[l_idx+1].type_code,0) 
					CALL U62_query_statistics_interval(FALSE) RETURNING l_arr_rec_statint

					LET l_idx = arr_curr()
					#HuHo: Had to add some strange row handling
					#l_idx was 0 but array had one row.. could not understand why and when this happens.
					IF l_idx = 0 AND l_arr_rec_statint.getSize() < 0 THEN
						LET l_idx = 1
					END IF

					IF l_idx = 0 AND l_arr_rec_statint.getSize() < 0 THEN
						LET l_idx = 1
					END IF
					CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_statint.getSize())
					CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_statint.getSize())
					CALL dialog.setActionHidden("GENERATE",NOT l_arr_rec_statint.getSize())
{	
					SELECT type_code, 
					int_num, 
					int_text, 
					start_date, 
					end_date, 
					(end_date - start_date + 1), 
					salesdays_num 
					INTO l_arr_rec_statint[l_idx].type_code, 
					l_arr_rec_statint[l_idx].int_num, 
					l_arr_rec_statint[l_idx].int_text, 
					l_arr_rec_statint[l_idx].start_date, 
					l_arr_rec_statint[l_idx].end_date, 
					l_arr_rec_statint[l_idx].days_num, 
					l_arr_rec_statint[l_idx].salesdays_num 
					FROM statint 
					WHERE rowid = pr_rowid 

					IF status = notfound THEN 
						FOR i = arr_curr() TO arr_count() 
							LET l_arr_rec_statint[i].* = l_arr_rec_statint[i+1].* 
							IF l_arr_rec_statint[i].type_code IS NULL THEN 
								INITIALIZE l_arr_rec_statint[i].* TO NULL 
								### RECORD level INITIALIZE puts 31/12/99 in
								### date fields AND 0 in numeric fields
								LET l_arr_rec_statint[i].int_num = NULL 
								LET l_arr_rec_statint[i].start_date = NULL 
								LET l_arr_rec_statint[i].end_date = NULL 
								LET l_arr_rec_statint[i].days_num = NULL 
								LET l_arr_rec_statint[i].salesdays_num = NULL 
							END IF 
							#                  IF i > (l_idx-scrn) AND i <= (l_idx-scrn+13) THEN
							#                     LET j = i - l_idx + scrn
							#                     DISPLAY l_arr_rec_statint[i].*
							#                          TO sr_statint[j].*
							#
							#                  END IF
						END FOR 
					END IF 
--				END IF 
}

				#NEXT FIELD scroll_flag 

			ON ACTION "EDIT" --BEFORE FIELD type_code 
				IF edit_interval(l_arr_rec_statint[l_idx].type_code, 
				l_arr_rec_statint[l_idx].int_num) THEN 
					SELECT int_text, 
					end_date, 
					(end_date - start_date + 1), 
					salesdays_num 
					INTO l_arr_rec_statint[l_idx].int_text, 
					l_arr_rec_statint[l_idx].end_date, 
					l_arr_rec_statint[l_idx].days_num, 
					l_arr_rec_statint[l_idx].salesdays_num 
					FROM statint 
					WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
					AND year_num = glob_rec_statparms.year_num 
					AND type_code = l_arr_rec_statint[l_idx].type_code 
					AND int_num = l_arr_rec_statint[l_idx].int_num 
				END IF 
				NEXT FIELD scroll_flag 



			ON ACTION("DELETE") #ON KEY (F2) #DELETE
				IF l_idx > 0 THEN 
					IF del_interval(l_arr_rec_statint[l_idx].type_code,	l_arr_rec_statint[l_idx].int_num) THEN #checks, IF this statistical interval can be deleted or NOT (has been posted)
						LET l_msg = "Are you sure you want to delete/nall intervals beginning with the interval number ", trim(l_arr_rec_statint[l_idx].int_num), " ?"
						IF promptTF("Delete",l_msg,0) THEN  
							DELETE FROM statint 
							WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
							AND year_num = glob_rec_statparms.year_num 
							AND type_code = l_arr_rec_statint[l_idx].type_code 
							AND int_num >= l_arr_rec_statint[l_idx].int_num #NOTE: Deletes from currently selected interval to the last ">="
						END IF 
					END IF 
				END IF
				CALL U62_query_statistics_interval(FALSE) RETURNING l_arr_rec_statint
				EXIT DISPLAY
				
--				CALL U62_query_statistics_interval(FALSE) RETURNING l_arr_rec_statint				
--				CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_statint.getSize())
--				CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_statint.getSize())
--				CALL dialog.setActionHidden("GENERATE",NOT l_arr_rec_statint.getSize())
--

{							 
 
				LET l_arr_rec_statint[l_idx].scroll_flag = "*" 
				 
				IF l_arr_rec_statint[l_idx].scroll_flag IS NULL THEN 
					IF del_interval(l_arr_rec_statint[l_idx].type_code, 
					l_arr_rec_statint[l_idx].int_num) THEN 
						FOR i = 1 TO arr_count() 
							IF l_arr_rec_statint[i].type_code = l_arr_rec_statint[l_idx].type_code 
							AND l_arr_rec_statint[i].int_num >= l_arr_rec_statint[l_idx].int_num THEN 
								IF l_arr_rec_statint[i].scroll_flag IS NULL THEN 
									LET l_del_cnt = l_del_cnt + 1 
								END IF 
								LET l_arr_rec_statint[i].scroll_flag = "*" 
								#                     IF i > (l_idx-scrn) AND i <= (l_idx-scrn+13) THEN
								#                        LET j = i - l_idx + scrn
								#                        DISPLAY l_arr_rec_statint[i].*
								#                             TO sr_statint[j].*
								#
								#                     END IF
							END IF 
						END FOR 
					ELSE 
						ERROR kandoomsg2("E",7071,"") 			#7048 This statistical interval has been posted
					END IF 
				ELSE 
					LET l_arr_rec_statint[l_idx].scroll_flag = NULL 
					FOR i = 1 TO arr_count() 
						IF l_arr_rec_statint[i].type_code = l_arr_rec_statint[l_idx].type_code 
						AND l_arr_rec_statint[i].int_num <= l_arr_rec_statint[l_idx].int_num THEN 
							IF l_arr_rec_statint[i].scroll_flag IS NOT NULL THEN 
								LET l_del_cnt = l_del_cnt - 1 
							END IF 
							LET l_arr_rec_statint[i].scroll_flag = NULL 
							#                  IF i > (l_idx-scrn) AND i <= (l_idx-scrn+13) THEN
							#                     LET j = i - l_idx + scrn
							#                     DISPLAY l_arr_rec_statint[i].*
							#                          TO sr_statint[j].*
							#
							#                  END IF
						END IF 
					END FOR 
				END IF
}
				 
				#NEXT FIELD scroll_flag 

			ON ACTION ("DOUBLECLICK","GENERATE") #ON KEY (F7)
				IF l_idx > 0 THEN 
					IF generate_int(l_arr_rec_statint[l_idx].type_code) THEN 
						LET p_year_num = glob_rec_statparms.year_num 
						EXIT DISPLAY 
					END IF 
					CALL U62_query_statistics_interval(FALSE) RETURNING l_arr_rec_statint		
					CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_statint.getSize())
					CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_statint.getSize())
				END IF
								
			ON ACTION "SET YEAR" #ON KEY (F8) 
				LET p_year_num = enter_year() 
				
				IF p_year_num != glob_rec_statparms.year_num THEN 
					CALL U62_query_statistics_interval(FALSE) RETURNING l_arr_rec_statint		
	
					CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_statint.getSize())
					CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_statint.getSize())
					CALL dialog.setActionHidden("GENERATE",NOT l_arr_rec_statint.getSize())
					EXIT DISPLAY 
				END IF 

				CALL U62_query_statistics_interval(FALSE) RETURNING l_arr_rec_statint		
				CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_statint.getSize())
				CALL dialog.setActionHidden("GENERATE",NOT l_arr_rec_statint.getSize())
	
				LET l_idx = arr_curr()
				#HuHo: Had to add some strange row handling
				#l_idx was 0 but array had one row.. could not understand why and when this happens.
				IF l_idx = 0 AND l_arr_rec_statint.getSize() < 0 THEN
					LET l_idx = 1
				END IF


			ON ACTION "YEAR-1" #ON KEY (F9) 
				LET p_year_num = glob_rec_statparms.year_num - 1 
				CALL U62_query_statistics_interval(FALSE) RETURNING l_arr_rec_statint		

				CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_statint.getSize())
				CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_statint.getSize())
				CALL dialog.setActionHidden("GENERATE",NOT l_arr_rec_statint.getSize())
				
				DISPLAY p_year_num TO year_num
				
				EXIT DISPLAY

			ON ACTION "YEAR+1" #ON KEY (F10) 
				LET p_year_num = glob_rec_statparms.year_num + 1 
				CALL U62_query_statistics_interval(FALSE) RETURNING l_arr_rec_statint		
				CALL dialog.setActionHidden("DELETE",NOT l_arr_rec_statint.getSize())
				CALL dialog.setActionHidden("EDIT",NOT l_arr_rec_statint.getSize())
				CALL dialog.setActionHidden("GENERATE",NOT l_arr_rec_statint.getSize())
				DISPLAY p_year_num TO year_num
				EXIT DISPLAY
				#EXIT INPUT 

				#      AFTER ROW
				#         DISPLAY l_arr_rec_statint[l_idx].*
				#              TO sr_statint[scrn].*

--			--AFTER INPUT 
--				LET p_year_num = NULL 

				#      ON KEY (control-w)
				#         CALL kandoohelp("")

		END DISPLAY

		IF int_flag OR quit_flag THEN
			#NOTE: CANCEL/int_flag will exit program (will be validated in parent call)
			--LET int_flag = false 
			--LET quit_flag = false
			LET p_year_num = NULL 
			RETURN RETURN p_year_num
 
		ELSE 
			IF l_del_cnt > 0 THEN 
				IF kandoomsg("E",8024,l_del_cnt) = "Y" THEN 
					#8024 Confirm TO Delete statint(s)? (Y/N)"
					LET l_msgresp = kandoomsg("E",1005,"") 
					FOR l_idx = 1 TO arr_count() 
						IF l_arr_rec_statint[l_idx].scroll_flag = "*" THEN 
							IF del_interval(l_arr_rec_statint[l_idx].type_code, 
							l_arr_rec_statint[l_idx].int_num) THEN 
								DELETE FROM statint 
								WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
								AND year_num = glob_rec_statparms.year_num 
								AND type_code = l_arr_rec_statint[l_idx].type_code 
								AND int_num >= l_arr_rec_statint[l_idx].int_num 
							END IF 
						END IF 
					END FOR 
				END IF 
			END IF 
		END IF 

		RETURN p_year_num 
END FUNCTION 


###################################################################
# FUNCTION enter_year()
#
#
###################################################################
FUNCTION enter_year() 
	DEFINE l_year_num DECIMAL(4,0) 
	DEFINE l_msgresp LIKE language.yes_flag 

	LET l_year_num = glob_rec_statparms.year_num 

	INPUT l_year_num WITHOUT DEFAULTS FROM year_num 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U62","input-year_num") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_year_num IS NULL THEN 
					ERROR kandoomsg2("E",9210,"") 			#9210 Year number invalid
					LET l_year_num = glob_rec_statparms.year_num 
					NEXT FIELD year_num 
				END IF 
			END IF 

	END INPUT 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN glob_rec_statparms.year_num 
	ELSE 
		RETURN l_year_num 
	END IF 
END FUNCTION 


###################################################################
# FUNCTION edit_interval(p_type_code,p_int_num)
#
# FUNCTION adds an individual interval
###################################################################
FUNCTION edit_interval(p_type_code,p_int_num) 
	DEFINE p_type_code LIKE statint.type_code 
	DEFINE p_int_num LIKE statint.int_num 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_stattype RECORD LIKE stattype.* 
	DEFINE l_days_num SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW u216 with FORM "U216" 
	CALL windecoration_u("U216") 

	MESSAGE kandoomsg2("E",1060,"") #1060 Enter Interval Details - ESC TO Continue
	LET l_rec_statint.type_code = p_type_code 
	SELECT * INTO l_rec_statint.* 
	FROM statint 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND year_num = glob_rec_statparms.year_num 
	AND type_code = p_type_code 
	AND int_num = p_int_num 

	IF status = notfound THEN 
		LET l_rec_statint.int_num = NULL 
		LET l_rec_statint.int_text = NULL 
		LET l_rec_statint.start_date = NULL 
		LET l_rec_statint.end_date = NULL 
		LET l_rec_statint.salesdays_num = NULL 
		CALL int_defaults(l_rec_statint.*) 
		RETURNING l_rec_statint.* 
	END IF 

	LET l_days_num = l_rec_statint.end_date - l_rec_statint.start_date + 1 
	INPUT 
		l_rec_statint.year_num, 
		l_rec_statint.type_code, 
		l_rec_statint.int_num, 
		l_rec_statint.int_text, 
		l_rec_statint.start_date, 
		l_rec_statint.end_date, 
		l_days_num, 
		l_rec_statint.salesdays_num WITHOUT DEFAULTS 
		FROM
		year_num, 
		type_code, 
		int_num, 
		int_text, 
		start_date, 
		end_date, 
		days_num, 
		salesdays_num
				
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U62","input-statint-1") 

		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield (type_code) 
			LET l_rec_statint.type_code = show_inttype(glob_rec_kandoouser.cmpy_code,"") 
			NEXT FIELD type_code 

		BEFORE FIELD type_code 
			SELECT type_text INTO l_rec_stattype.type_text 
			FROM stattype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = l_rec_statint.type_code 
			IF status = 0 THEN 
				DISPLAY l_rec_stattype.type_text TO type_text

			END IF 
			IF p_int_num > 0 THEN 
				NEXT FIELD int_text 
			ELSE 
				LET p_type_code = l_rec_statint.type_code 
			END IF 

		AFTER FIELD type_code 
			CLEAR type_text 
			IF l_rec_statint.type_code IS NULL THEN 
				ERROR kandoomsg2("E",9197,"") 			#9197" Interval type must be entered "
				NEXT FIELD type_code 
			ELSE 
				SELECT type_text INTO l_rec_stattype.type_text 
				FROM stattype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = l_rec_statint.type_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("E",9202,"") 			#9202" Interval type NOT found - Try Window"
					NEXT FIELD type_code 
				ELSE 
					IF p_type_code != l_rec_statint.type_code 
					OR p_type_code IS NULL THEN 
						### Type has changed AFTER initial entry
						LET l_rec_statint.int_num = NULL 
						LET l_rec_statint.start_date = NULL 
						LET l_rec_statint.end_date = NULL 
						LET l_rec_statint.salesdays_num = NULL 
					END IF 
					CALL int_defaults(l_rec_statint.*) 
					RETURNING l_rec_statint.* 
				END IF 
				LET l_days_num = l_rec_statint.end_date - l_rec_statint.start_date + 1 
				DISPLAY l_rec_stattype.type_text TO type_text
				DISPLAY l_rec_statint.int_num TO int_num
				DISPLAY l_rec_statint.int_text TO int_text
				DISPLAY l_rec_statint.start_date TO start_date
				DISPLAY l_rec_statint.end_date TO end_date
				DISPLAY l_rec_statint.salesdays_num TO salesdays_num
				DISPLAY l_days_num TO days_num

			END IF 

		BEFORE FIELD start_date 
			SELECT unique 1 FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = l_rec_statint.type_code 
			AND year_num = glob_rec_statparms.year_num 
			IF status = 0 THEN 
				IF fgl_lastkey() = fgl_keyval("up") THEN 
					NEXT FIELD previous 
				ELSE 
					NEXT FIELD NEXT 
				END IF 
			END IF 

		AFTER FIELD start_date 
			IF l_rec_statint.start_date IS NULL THEN 
				ERROR kandoomsg2("E",9203,"") 			#9203" Interval start date must be entered
				NEXT FIELD int_num 
			END IF 
			CALL int_defaults(l_rec_statint.*) 
			RETURNING l_rec_statint.* 
			LET l_days_num = l_rec_statint.end_date	- l_rec_statint.start_date + 1 
			DISPLAY l_rec_statint.int_text TO int_text 
			DISPLAY l_rec_statint.end_date TO end_date 
			DISPLAY l_rec_statint.salesdays_num TO salesdays_num 
			DISPLAY l_days_num TO days_num 

		AFTER FIELD end_date 
			IF l_rec_statint.end_date IS NULL THEN 
				ERROR kandoomsg2("E",9204,"") 			#9204" Interval END date must be entered
				NEXT FIELD end_date 
			END IF 
			IF l_rec_statint.start_date > l_rec_statint.end_date THEN 
				ERROR kandoomsg2("E",9205,"") 	#9205" END date must NOT preceed starting date"
				NEXT FIELD start_date 
			END IF 
			LET l_days_num = l_rec_statint.end_date - l_rec_statint.start_date + 1 
			LET l_rec_statint.salesdays_num = weekday_cnt(l_rec_statint.start_date, 
			l_rec_statint.end_date) 
			DISPLAY l_days_num TO days_num 
			DISPLAY l_rec_statint.salesdays_num TO salesdays_num
			
		AFTER FIELD salesdays_num 
			CASE 
				WHEN l_rec_statint.salesdays_num IS NULL 
					LET l_rec_statint.salesdays_num = weekday_cnt(l_rec_statint.start_date, 
					l_rec_statint.end_date) 
					ERROR kandoomsg2("E",9206,"") 			#9206" No. of selling days must be entered"
					NEXT FIELD salesdays_num 
				WHEN l_rec_statint.salesdays_num < 0 
					LET l_rec_statint.salesdays_num = weekday_cnt(l_rec_statint.start_date, 
					l_rec_statint.end_date) 
					ERROR kandoomsg2("E",9207,"") 	#9207" No. of selling days must NOT be negative"
					NEXT FIELD salesdays_num 
				WHEN l_rec_statint.salesdays_num > l_days_num 
					LET l_rec_statint.salesdays_num = l_days_num 
					ERROR kandoomsg2("E",9208,"") 		#9208" No. of selling days cannot exceed total days"
					NEXT FIELD salesdays_num 
			END CASE 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_statint.start_date IS NULL THEN 
					ERROR kandoomsg2("E",9203,"") 				#9203" Interval start date must be entered "
					NEXT FIELD start_date 
				END IF 
				IF l_rec_statint.end_date IS NULL THEN 
					ERROR kandoomsg2("E",9204,"") 		#9204" Interval END date must be entered
					NEXT FIELD end_date 
				END IF 
				IF l_rec_statint.start_date > l_rec_statint.end_date THEN 
					ERROR kandoomsg2("E",9205,"") 			#9205" END date must preceed starting date"
					NEXT FIELD start_date 
				END IF 
				SELECT unique 1 FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = l_rec_statint.type_code 
				AND int_num != l_rec_statint.int_num 
				AND ((start_date <= l_rec_statint.start_date 
				AND end_date >= l_rec_statint.start_date) 
				OR (start_date >= l_rec_statint.start_date 
				AND end_date <= l_rec_statint.end_date) 
				OR (start_date <= l_rec_statint.end_date 
				AND end_date >= l_rec_statint.end_date)) 
				IF status = 0 THEN 
					ERROR kandoomsg2("E",9209,"") 				#9209" Interval dates overlap existing interval dates"
					NEXT FIELD start_date 
				END IF 
			END IF 

	END INPUT 

	CLOSE WINDOW U216 

--	OPTIONS INSERT KEY f1 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		IF p_int_num = 0 THEN 
			LET l_rec_statint.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_statint.updreq_flag = "N" 
			LET l_rec_statint.dist_flag = "N" 
			INSERT INTO statint VALUES (l_rec_statint.*) 
			RETURN sqlca.sqlerrd[6] 
		ELSE 
			UPDATE statint SET * = l_rec_statint.* 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = glob_rec_statparms.year_num 
			AND type_code = p_type_code 
			AND int_num = p_int_num 
			RETURN sqlca.sqlerrd[6] 
		END IF 
	END IF 

END FUNCTION 


###################################################################
# FUNCTION generate_int(p_type_code)
#
# FUNCTION generates intervals
###################################################################
FUNCTION generate_int(p_type_code) 
	DEFINE p_type_code LIKE statint.type_code 
	DEFINE l_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_t_statint RECORD LIKE statint.* 
	DEFINE l_rec_stattype RECORD LIKE stattype.* 
	DEFINE l_int_cnt SMALLINT 
	DEFINE x SMALLINT 

	DEFINE l_msgresp LIKE language.yes_flag 

	OPEN WINDOW U217 with FORM "U217" 
	CALL windecoration_u("U217") 

	MESSAGE kandoomsg2("E",1060,"") #1060 Enter Interval Details - ESC TO Continue
	LET l_rec_statint.type_code = p_type_code 
	LET l_rec_statint.start_date = NULL 
	LET l_rec_statint.end_date = NULL 
	LET l_rec_statint.int_num = NULL 
	LET l_rec_statint.salesdays_num = NULL 
	LET l_int_cnt = NULL 
	CALL int_defaults(l_rec_statint.*) 
	RETURNING l_rec_statint.* 

	INPUT 
		l_rec_statint.year_num, 
		l_rec_statint.type_code, 
		l_rec_statint.start_date, 
		l_rec_statint.end_date, 
		l_int_cnt WITHOUT DEFAULTS
	FROM  
		year_num, 
		type_code, 
		start_date, 
		end_date, 
		int_cnt 

		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U62","input-statint-2") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 

		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON ACTION "LOOKUP" infield (type_code) 
			LET l_rec_statint.type_code = show_inttype(glob_rec_kandoouser.cmpy_code,"") 
			NEXT FIELD type_code 


		BEFORE FIELD type_code 
			SELECT type_text INTO l_rec_stattype.type_text 
			FROM stattype 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND type_code = l_rec_statint.type_code 
			IF status = 0 THEN 
				DISPLAY l_rec_stattype.type_text TO type_text

			END IF 
			LET p_type_code = l_rec_statint.type_code 

		AFTER FIELD type_code 
			CLEAR type_text 
			IF l_rec_statint.type_code IS NULL THEN 
				ERROR kandoomsg2("E",9197,"") 		#9197" Interval type must be entered "
				NEXT FIELD type_code 
			ELSE 
				SELECT type_text INTO l_rec_stattype.type_text 
				FROM stattype 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = l_rec_statint.type_code 
				IF status = notfound THEN 
					ERROR kandoomsg2("E",9202,"") 		#9202" Interval type NOT found - Try Window"
					NEXT FIELD type_code 
				ELSE 
					IF p_type_code != l_rec_statint.type_code 
					OR p_type_code IS NULL THEN 
						### Type has changed AFTER initial entry
						LET l_rec_statint.start_date = NULL 
						LET l_rec_statint.end_date = NULL 
						LET l_rec_statint.salesdays_num = NULL 
						CALL int_defaults(l_rec_statint.*) 
						RETURNING l_rec_statint.* 
					END IF 
					DISPLAY l_rec_stattype.type_text TO type_text 
					DISPLAY l_rec_statint.start_date TO start_date 
					DISPLAY l_rec_statint.end_date TO end_date 

				END IF 
			END IF 

		AFTER FIELD start_date 
			IF l_rec_statint.start_date IS NULL THEN 
				ERROR kandoomsg2("E",9203,"") 			#9203" Interval start date must be entered
				NEXT FIELD start_date 
			END IF 
			CALL int_defaults(l_rec_statint.*) 
			RETURNING l_rec_statint.* 

		AFTER FIELD end_date 
			IF l_rec_statint.end_date IS NULL THEN 
				ERROR kandoomsg2("E",9204,"") 			#9204" Interval END date must be entered
				NEXT FIELD end_date 
			END IF 
			IF l_rec_statint.start_date > l_rec_statint.end_date THEN 
				ERROR kandoomsg2("E",9205,"") 		#9205" END date must NOT preceed starting date"
				NEXT FIELD start_date 
			END IF 

		BEFORE FIELD int_cnt 
			LET l_int_cnt = 1 
			LET l_rec_t_statint.* = l_rec_statint.* 
			LET l_rec_t_statint.end_date = NULL 
			LET l_rec_t_statint.salesdays_num = 1 ## reqd FOR 445 types 
			CALL int_defaults(l_rec_t_statint.*) 
			RETURNING l_rec_t_statint.* 

			WHILE l_rec_t_statint.end_date < l_rec_statint.end_date 
				LET l_int_cnt = l_int_cnt + 1 
				LET l_rec_t_statint.start_date = l_rec_t_statint.end_date + 1 
				LET l_rec_t_statint.end_date = NULL 
				LET l_rec_t_statint.salesdays_num = l_int_cnt ## reqd FOR 445 types 
				CALL int_defaults(l_rec_t_statint.*) 
				RETURNING l_rec_t_statint.* 
			END WHILE 

			LET l_rec_statint.end_date = l_rec_t_statint.end_date 
			DISPLAY l_rec_statint.end_date TO end_date

			LET x = l_int_cnt 

		AFTER FIELD int_cnt 
			CASE 
				WHEN l_int_cnt IS NULL 
					ERROR kandoomsg2("E",9211,"") 					#9211" Number of intervals TO generate invalid"
					LET l_int_cnt = x 
					NEXT FIELD int_cnt 
				WHEN l_int_cnt < 0 
					LET l_int_cnt = x 
					ERROR kandoomsg2("E",9211,"") 		#9211" Number of intervals TO generate invalid"
					NEXT FIELD int_cnt 
				WHEN l_int_cnt != x 
					LET l_rec_t_statint.* = l_rec_statint.* 
					FOR x = 1 TO l_int_cnt 
						LET l_rec_t_statint.end_date = NULL 
						LET l_rec_t_statint.salesdays_num = x ## reqd FOR 445 types 
						CALL int_defaults(l_rec_t_statint.*) 
						RETURNING l_rec_t_statint.* 
						LET l_rec_t_statint.start_date = l_rec_t_statint.end_date + 1 
					END FOR 
					LET l_rec_statint.end_date = l_rec_t_statint.end_date 
					DISPLAY l_rec_statint.end_date TO end_date

			END CASE 

		AFTER INPUT 
			IF not(int_flag OR quit_flag) THEN 
				IF l_rec_statint.start_date IS NULL THEN 
					ERROR kandoomsg2("E",9203,"") 		#9203" Interval start date must be entered "
					NEXT FIELD start_date 
				END IF 
				IF l_rec_statint.end_date IS NULL THEN 
					ERROR kandoomsg2("E",9204,"") 			#9204" Interval END date must be entered
					NEXT FIELD end_date 
				END IF 
				IF l_rec_statint.start_date > l_rec_statint.end_date THEN 
					ERROR kandoomsg2("E",9205,"") 			#9205" END date must preceed starting date"
					NEXT FIELD start_date 
				END IF 
				IF l_int_cnt IS NULL THEN 
					NEXT FIELD int_cnt 
				END IF 

				SELECT unique 1 FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = l_rec_statint.type_code 
				AND ((start_date <= l_rec_statint.start_date 
				AND end_date >= l_rec_statint.start_date) 
				OR (start_date >= l_rec_statint.start_date 
				AND end_date <= l_rec_statint.end_date) 
				OR (start_date <= l_rec_statint.end_date 
				AND end_date >= l_rec_statint.end_date)) 
				IF status = 0 THEN 
					ERROR kandoomsg2("E",9209,"") 				#9209" Interval dates overlap existing interval dates"
					NEXT FIELD start_date 
				END IF 
				LET l_msgresp=kandoomsg("E",8025,l_int_cnt) 		#8025 Confirm TO generate 2232 intervals. (Y/N)?
				IF l_msgresp != "Y" THEN 
					LET quit_flag = true 
				END IF 
			END IF 

			#      ON KEY (control-w)
			#         CALL kandoohelp("")

	END INPUT 

	CLOSE WINDOW u217 

	OPTIONS INSERT KEY f1 

	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		LET l_msgresp = kandoomsg("E",1005,"") 
		LET l_rec_t_statint.* = l_rec_statint.* 
		FOR x = 1 TO l_int_cnt 
			LET l_rec_t_statint.int_num = NULL 
			LET l_rec_t_statint.end_date = NULL 
			LET l_rec_t_statint.salesdays_num = x ## reqd FOR 445 types 
			CALL int_defaults(l_rec_t_statint.*) 
			RETURNING l_rec_t_statint.* 
			LET l_rec_t_statint.cmpy_code = glob_rec_kandoouser.cmpy_code 
			LET l_rec_statint.updreq_flag = "N" 
			LET l_rec_t_statint.dist_flag = "N" 
			INSERT INTO statint VALUES (l_rec_t_statint.*) 
			LET l_rec_t_statint.start_date = l_rec_t_statint.end_date + 1 
		END FOR 
		RETURN true 
	END IF 
END FUNCTION 


###################################################################
# FUNCTION del_interval(p_type_code,p_int_num)
#
# FUNCTION returns TRUE IF an interval IS deletable AND FALSE OTHERWISE
###################################################################
FUNCTION del_interval(p_type_code,p_int_num) 
	DEFINE p_type_code LIKE statint.type_code 
	DEFINE p_int_num LIKE statint.int_num 
	DEFINE l_table_text CHAR(128) 
	DEFINE l_query_text CHAR(200) 

	DECLARE c_systables CURSOR FOR 
	SELECT tabname FROM systables 
	WHERE tabname in ("statcust","statprod","statsale", 
	"statterr","statsper","statoffer","statcond") 

	FOREACH c_systables INTO l_table_text 
		LET l_query_text = "SELECT * FROM ",l_table_text clipped," ", 
		" WHERE cmpy_code = '",glob_rec_kandoouser.cmpy_code,"' ", 
		" AND year_num = ",glob_rec_statparms.year_num," ", 
		" AND type_code = '",p_type_code,"' ", 
		" AND int_num = ",p_int_num," " 
		PREPARE s1_statint FROM l_query_text 
		DECLARE c1_statint CURSOR FOR s1_statint 
		OPEN c1_statint 
		FETCH c1_statint 

		IF status = 0 THEN 
			CLOSE c1_statint 
			RETURN false 
		END IF 
		CLOSE c1_statint 
	END FOREACH 

	RETURN true 
END FUNCTION 



###################################################################
# FUNCTION int_defaults(p_rec_statint)
#
# FUNCTION sets up statint RECORD with appropriate default VALUES
###################################################################
FUNCTION int_defaults(p_rec_statint) 
	DEFINE p_rec_statint RECORD LIKE statint.* 
	DEFINE l_rec_stattype RECORD LIKE stattype.* 
	DEFINE l_rec_term RECORD LIKE term.* 
	DEFINE l_temp_date DATE 
	DEFINE l_temp_text CHAR(4) 
	DEFINE x SMALLINT 
	DEFINE y SMALLINT 

	SELECT * INTO l_rec_stattype.* 
	FROM stattype 
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND type_code = p_rec_statint.type_code 
	LET p_rec_statint.year_num = glob_rec_statparms.year_num 
	IF p_rec_statint.int_num IS NULL THEN 
		SELECT (max(int_num)+1) INTO p_rec_statint.int_num 
		FROM statint 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND year_num = p_rec_statint.year_num 
		AND type_code = p_rec_statint.type_code 
		IF p_rec_statint.int_num IS NULL THEN 
			LET p_rec_statint.int_num = 1 
		END IF 
	END IF 
	IF p_rec_statint.start_date IS NULL THEN 
		SELECT (max(end_date)+1) INTO p_rec_statint.start_date 
		FROM statint 
		WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
		AND year_num = p_rec_statint.year_num 
		AND type_code = p_rec_statint.type_code 
		IF p_rec_statint.start_date IS NULL THEN 
			SELECT (max(end_date)+1) INTO p_rec_statint.start_date 
			FROM statint 
			WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
			AND year_num = p_rec_statint.year_num-1 
			AND type_code = p_rec_statint.type_code 
		END IF 
	END IF 
	IF p_rec_statint.start_date IS NOT NULL 
	AND p_rec_statint.end_date IS NULL THEN 
		LET l_temp_text = glob_rec_statparms.year_num 
		LET l_temp_text = l_temp_text[3,4] 
		CASE l_rec_stattype.type_ind 
			WHEN "0" ### miscellaneous 
				LET p_rec_statint.end_date = p_rec_statint.start_date 
				LET p_rec_statint.int_text = l_temp_text clipped, 
				p_rec_statint.type_code, 
				p_rec_statint.int_num USING "<<<<<" 
			WHEN "1" ### daily 
				LET p_rec_statint.end_date = p_rec_statint.start_date 
				LET p_rec_statint.int_text = p_rec_statint.start_date USING "ddd","-", 
				p_rec_statint.start_date USING "ddmm", 
				l_temp_text clipped 
			WHEN "2" ### weekly 
				LET p_rec_statint.end_date = p_rec_statint.start_date + 6 
				LET p_rec_statint.int_text = l_temp_text clipped, 
				p_rec_statint.int_num USING "&&" 
			WHEN "3" ### fortnight 
				LET p_rec_statint.end_date = p_rec_statint.start_date + 13 
				LET p_rec_statint.int_text = l_temp_text clipped,"F", 
				p_rec_statint.int_num USING "&&" 
			WHEN "4" ### calender month 
				LET p_rec_statint.end_date = p_rec_statint.start_date + 1 units month 
				- 1 units day 
				LET l_temp_date = p_rec_statint.start_date + 14 
				LET p_rec_statint.int_text = l_temp_date USING "mmm", 
				l_temp_text clipped 
			WHEN "5" ### four-four-five month 
				SELECT (end_date-start_date), 
				start_date 
				INTO x, 
				l_temp_date 
				FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = p_rec_statint.type_code 
				AND end_date = (p_rec_statint.start_date - 1) 
				SELECT (end_date-start_date) INTO y 
				FROM statint 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND type_code = p_rec_statint.type_code 
				AND end_date = (l_temp_date - 1) 
				CASE 
					WHEN (x=27 AND y=27) 
						LET p_rec_statint.end_date = p_rec_statint.start_date + 34 
					WHEN (y=34) 
						LET p_rec_statint.end_date = p_rec_statint.start_date + 27 
					WHEN (y=27) 
						LET p_rec_statint.end_date = p_rec_statint.start_date + 27 
					OTHERWISE 
						### salesdays_num contains count of iterations
						LET x = p_rec_statint.salesdays_num mod 3 
						CASE x 
							WHEN 0 
								LET p_rec_statint.end_date = p_rec_statint.start_date + 34 
							WHEN 1 
								LET p_rec_statint.end_date = p_rec_statint.start_date + 27 
							WHEN 2 
								LET p_rec_statint.end_date = p_rec_statint.start_date + 27 
							OTHERWISE 
								LET p_rec_statint.end_date = p_rec_statint.start_date + 27 
						END CASE 
				END CASE 
				LET l_temp_date = p_rec_statint.start_date + 14 units day 
				LET p_rec_statint.int_text = l_temp_date USING "mmm", 
				l_temp_text clipped 
			WHEN "6" ### payment terms 
				SELECT * INTO l_rec_term.* 
				FROM term 
				WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
				AND term_code = p_rec_statint.type_code 
				IF status = 0 THEN 
					CALL get_due_and_discount_date(l_rec_term.*,p_rec_statint.start_date) 
					RETURNING p_rec_statint.end_date, 
					l_temp_date 
					LET p_rec_statint.int_text = l_temp_text clipped, 
					p_rec_statint.type_code, 
					p_rec_statint.int_num USING "&&&" 
				END IF 
			WHEN "7" ### three month quarters 
				LET p_rec_statint.end_date = p_rec_statint.start_date + 3 units month 
				- 1 units day 
				LET p_rec_statint.int_text = l_temp_text clipped,"Q", 
				p_rec_statint.int_num USING "&&" 
			WHEN "8" ### yearly 
				LET p_rec_statint.end_date = p_rec_statint.start_date + 1 units year 
				- 1 units day 
				LET p_rec_statint.int_text = p_rec_statint.year_num 
		END CASE 
		LET p_rec_statint.salesdays_num = weekday_cnt(p_rec_statint.start_date, 
		p_rec_statint.end_date) 
	END IF 

	LET p_rec_statint.int_text = upshift(p_rec_statint.int_text) 

	RETURN p_rec_statint.* 
END FUNCTION 



###################################################################
# FUNCTION weekday_cnt(p_start_date,p_end_date)
#
#
###################################################################
FUNCTION weekday_cnt(p_start_date,p_end_date) 
	DEFINE p_start_date DATE 
	DEFINE p_end_date DATE 

	DEFINE i SMALLINT 
	DEFINE j SMALLINT 
	DEFINE k SMALLINT 

	LET i = p_end_date - p_start_date 
	LET k = i + 1 
	IF i >= 0 THEN 
		FOR j = 0 TO i 
			IF weekday(p_start_date + j) = 0 
			OR weekday(p_start_date + j) = 6 THEN 
				LET k = k - 1 
			END IF 
		END FOR 
		RETURN k 
	ELSE 
		RETURN 0 
	END IF 

END FUNCTION 


