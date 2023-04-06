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

	Source code beautified by beautify.pl on 2020-01-03 18:54:41	$Id: $
}
#     U18.4gl  General purpose SQL program FOR sites without SQL
#
############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../common/glob_GLOBALS_report.4gl"
GLOBALS "../utility/U_UT_GLOBALS.4gl" 
GLOBALS 
	DEFINE pa_command array[200] OF CHAR(1258) # ARRAY OF SQL commands 
	DEFINE pr_cmd_cnt SMALLINT # no. OF commands in COMMAND ARRAY 
	DEFINE pr_path_text CHAR(32) # CURRENT SQL filename 
	DEFINE pr_temp_text CHAR(256) 
END GLOBALS 


###################################################################
# MAIN
#
#
###################################################################
MAIN 
	DEFINE 
	idx SMALLINT, 
	pr_verbose_ind CHAR(1) 
	DEFINE l_msgresp LIKE language.yes_flag
	
	CALL setModuleId("U18") 
	CALL ui_init(0) #initial ui init 

	DEFER quit 
	DEFER interrupt 

	CALL authenticate(getmoduleid()) #authenticate 
	CALL init_u_ut() #init utility module 

	LET pr_cmd_cnt = 1 
	CREATE temp TABLE t_commands (sql_text CHAR(1024)) 
	OPEN WINDOW u124 at 2,3 with FORM "U124" 
	CALL windecoration_u("U124") 

	LET l_msgresp=kandoomsg("U",1005,"") 
	#1005 Please wait
	IF num_args() > 0 THEN 
		IF arg_val(1) = "-f" THEN 
			IF file_exists(arg_val(2)) THEN 
				IF import_file(arg_val(2)) THEN 
					FOR idx = 1 TO pr_cmd_cnt 
						CALL disp_count(idx) 
						IF NOT execute_sql(idx,3) THEN 
							EXIT FOR 
						END IF 
					END FOR 
				END IF 
			ELSE 
				LET l_msgresp=kandoomsg("U",7011,arg_val(2)) 
				#U 7011 " Pathname does NOT exist OR has invalid file permissions"
			END IF 
		END IF 
	ELSE 
		MENU " SQL" 
			BEFORE MENU 
				CALL publish_toolbar("kandoo","U18","menu-sql") 

			ON ACTION "WEB-HELP" 
				CALL onlinehelp(getmoduleid(),null) 
				
			ON ACTION "actToolbarManager" 
				CALL setuptoolbar() 


			COMMAND "Commands" " Enter/Edit SQL command(s)" 
				IF input_command(1) THEN 
					NEXT option "Run" 
				END IF 
				
			COMMAND KEY("L",control-b) "Lookup" 				" Query table AND COLUMN definitions" 
				LET pr_temp_text = show_tables() 
				
			COMMAND "New" " Erase all SQL commands" 
				FOR idx = 1 TO pr_cmd_cnt 
					INITIALIZE pa_command[idx] TO NULL 
				END FOR 
				LET pr_cmd_cnt = 1 
				IF input_command(1) THEN 
					NEXT option "Run" 
				END IF 
				
			COMMAND "Run" " Execute SQL commands " 

				MENU "Run SQL" 
					BEFORE MENU 
						IF pr_cmd_cnt = 1 THEN 
							HIDE option "Silent" 
						END IF 
						CALL publish_toolbar("kandoo","U18","menu-run") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 
						
					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 
						
					COMMAND "Each" "Run each command with confirmation" 
						LET pr_verbose_ind = "1" 
						EXIT MENU 
						
					COMMAND "All" "Run each command without confirmation" 
						LET pr_verbose_ind = "2" 
						EXIT MENU 
						
					COMMAND "Silent" "Run each command silently" 
						LET pr_verbose_ind = "3" 
						EXIT MENU 
						
					COMMAND "Exit" "Exit SQL execution" 
						LET quit_flag = true 
						EXIT MENU 


				END MENU 
				
				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
				ELSE 
					FOR idx = 1 TO pr_cmd_cnt 
						CALL disp_count(idx) 
						IF NOT execute_sql(idx,pr_verbose_ind) THEN 
							EXIT FOR 
						END IF 
					END FOR 
				END IF 
				NEXT option "Commands" 
				
			COMMAND "Open" " Load SQL commands FROM text file" 
				IF import_file(enter_file("R")) THEN 
					CALL disp_count(1) 
					NEXT option "Run" 
				END IF 
				
			COMMAND "Save" " Save SQL commands in text file" 
				IF export_file(enter_file("W")) THEN 
					CALL disp_count(1) 
					NEXT option "Exit" 
				END IF 
				
			COMMAND "Go TO" " Edit specific SQL command" 
				LET idx = 1 
				OPTIONS INPUT no wrap 

				INPUT idx WITHOUT DEFAULTS FROM pr_count 
					BEFORE INPUT 
						CALL publish_toolbar("kandoo","U18","input-idx") 
					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 
					ON ACTION "actToolbarManager" 
						CALL setuptoolbar() 
				END INPUT 


				IF int_flag OR quit_flag THEN 
					LET int_flag = false 
					LET quit_flag = false 
					LET idx = 1 
				ELSE 
					IF idx < 1 THEN LET idx = 1 END IF 
						IF idx > pr_cmd_cnt THEN LET idx = pr_cmd_cnt END IF 
							IF input_command(idx) THEN 
								NEXT option "Run" 
							END IF 
						END IF 

			ON ACTION "Print Manager"	#COMMAND KEY ("P",f11) "Print" " Print OR View using RMS "
				CALL run_prog("URS","","","","") 

			COMMAND KEY("!") 
				CALL unix_command() 

			ON ACTION "CANCEL" #COMMAND KEY("E",interrupt) "Exit" " RETURN TO menu" 
				IF promptTF("",kandoomsg2("U",8002,""),1)	THEN
					EXIT MENU 
				END IF 
		END MENU 
		
	END IF 
	CLOSE WINDOW U124 
END MAIN 


FUNCTION unix_command() 
	DEFINE 
	unix_text CHAR(80) 

	--   prompt "Enter Unix Command (OR DEL):"  -- albo
	--      FOR unix_text
	LET unix_text = promptInput("Enter Unix Command (OR BREAK):","",80) -- albo 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
	ELSE 
		RUN unix_text 
		CALL eventsuspend() # LET l_msgresp = kandoomsg("U",1,"") 
		# "RETURN TO Continue"
	END IF 
END FUNCTION 


FUNCTION input_command(idx) 
	DEFINE 
	idx SMALLINT, 
	sql_text CHAR(1078), 
	i SMALLINT 
	DEFINE l_msgresp LIKE language.yes_flag
	
	LET l_msgresp=kandoomsg("U",1012,"") 
	#U1012 " Enter SQL statement ESC FOR menu, F10 TO execute
	OPTIONS INPUT wrap 
	INPUT BY NAME sql_text WITHOUT DEFAULTS 
		BEFORE INPUT 
			CALL publish_toolbar("kandoo","U18","input-sql_text") 
		ON ACTION "WEB-HELP" 
			CALL onlinehelp(getmoduleid(),null) 
		ON ACTION "actToolbarManager" 
			CALL setuptoolbar() 


		ON KEY (control-b) 
			OPTIONS INPUT no wrap 
			LET pr_temp_text = show_tables() 
			OPTIONS INPUT wrap 
			IF pr_temp_text IS NOT NULL THEN 
				LET sql_text = get_fldbuf(sql_text) 
				IF length(sql_text) = 0 THEN 
					LET pa_command[idx] = "SELECT ",pr_temp_text clipped 
				ELSE 
					LET pa_command[idx] = sql_text clipped," ",pr_temp_text clipped 
				END IF 
				NEXT FIELD sql_text 
			END IF 
		ON KEY (F1) # add a COMMAND 
			IF pr_cmd_cnt = 200 THEN 
				LET l_msgresp = kandoomsg("U",9031,"") 
				#9031 The limit has been reached
			ELSE 
				LET pa_command[idx] = get_fldbuf(sql_text) 
				FOR i = pr_cmd_cnt TO idx step -1 
					LET pa_command[i+1] = pa_command[i] 
				END FOR 
				LET pr_cmd_cnt = pr_cmd_cnt + 1 
				LET pa_command[idx] = NULL 
				NEXT FIELD sql_text 
			END IF 
		ON KEY (F2) # DELETE a COMMAND 
			IF pr_cmd_cnt = 1 THEN 
				LET pa_command[1] = NULL 
			ELSE 
				FOR i = idx TO pr_cmd_cnt-1 
					LET pa_command[i] = pa_command[i+1] 
				END FOR 
				LET pa_command[pr_cmd_cnt] = NULL 
				LET pr_cmd_cnt = pr_cmd_cnt - 1 
			END IF 
			NEXT FIELD sql_text 
		ON KEY (F3) # NEXT COMMAND 
			IF idx = 200 THEN 
				LET l_msgresp = kandoomsg("U",9001,"") 
			ELSE 
				LET pa_command[idx] = get_fldbuf(sql_text) 
				LET idx = idx + 1 
				NEXT FIELD sql_text 
			END IF 
		ON KEY (F4) # previous COMMAND 
			IF idx = 1 THEN 
				LET l_msgresp = kandoomsg("U",9001,"") 
			ELSE 
				LET pa_command[idx] = get_fldbuf(sql_text) 
				LET idx = idx - 1 
				NEXT FIELD sql_text 
			END IF 
		ON KEY (F10) # directly EXECUTE CURRENT COMMAND only 
			LET pa_command[idx] = get_fldbuf(sql_text) 
			IF execute_sql(idx,1) THEN 
			END IF 
			NEXT FIELD sql_text 
		AFTER FIELD sql_text 
			LET pa_command[idx] = get_fldbuf(sql_text) 
		BEFORE FIELD sql_text 
			LET sql_text = pa_command[idx] 
			CALL disp_count(idx) 
		ON KEY (control-w) 
			CALL kandoohelp("") 
	END INPUT 
	CALL disp_count(idx) 
	IF int_flag OR quit_flag THEN 
		LET int_flag = false 
		LET quit_flag = false 
		RETURN false 
	ELSE 
		RETURN true 
	END IF 
END FUNCTION 


FUNCTION execute_sql(idx,pr_verbose_ind) 
	DEFINE 
	idx SMALLINT, 
	pr_verbose_ind CHAR(1), 
	pr_cmd_text CHAR(10), 
	pr_status INTEGER 
	DEFINE l_msgresp LIKE language.yes_flag
	
	LET l_msgresp=kandoomsg("U",1013,"") 
	#U1013 Executing command - Please Wait
	LET pr_cmd_text = extract_word(idx,1) 
	CASE 
	WHEN pr_cmd_text IS NULL 
    WHEN pr_cmd_text matches "{*"
    WHEN pr_cmd_text matches "#*"
    WHEN pr_cmd_text = MODE_CLASSIC_SELECT
       CASE
          WHEN(pa_command[idx]
               matches "*[Ii][Nn][Tt][Oo]*[Tt][Ee][Mm][Pp]*")
             LET pr_status = run_update(idx,MODE_CLASSIC_SELECT,pr_verbose_ind)
          WHEN(pr_verbose_ind = "3")
             LET pr_status = run_select(idx,"R","A",1,999)
          OTHERWISE
             menu "SELECT OUTPUT"
    	BEFORE MENU
    	 	CALL publish_toolbar("kandoo","U18","menu-select_output")

			ON ACTION "WEB-HELP"
		CALL onlineHelp(getModuleId(),NULL)
		ON ACTION "actToolbarManager"
			 	CALL setupToolbar()


                COMMAND "Screen" "DISPLAY selected rows TO SCREEN"
                   LET pr_status = screen_select(idx)
                   EXIT MENU
                COMMAND "Report" "Print selected rows via RMS"
                   LET pr_status = report_select(idx)
                   EXIT MENU
                COMMAND KEY("E",interrupt) "Exit" "Exit this command"
                   LET int_flag = FALSE
                   LET quit_flag = FALSE
                   LET pr_status = TRUE
                   EXIT MENU
                COMMAND KEY (control-w)
                   CALL kandoohelp("")
             END MENU
       END CASE
    WHEN pr_cmd_text = "load"
       LET pr_status = run_load(idx,pr_cmd_text,pr_verbose_ind)
    WHEN pr_cmd_text = "unload"
         LET pr_status = run_unload(idx,pr_cmd_text,pr_verbose_ind)
      OTHERWISE
         LET pr_status = run_update(idx,pr_cmd_text,pr_verbose_ind)
   END CASE
   IF int_flag OR quit_flag THEN
      LET int_flag = FALSE
      LET quit_flag = FALSE
      LET pr_status = FALSE
   END IF
   RETURN pr_status
label recovery:
   CALL err_print(STATUS)
   RETURN FALSE
END FUNCTION


FUNCTION extract_word(idx,pr_word_num)
## FUNCTION IS passed a pointer TO a string
## AND a required word number within that string.
## FUNCTION returns the nominated word (strip of any quotes)
 DEFINE
    idx SMALLINT,
    pr_word_num SMALLINT,
    pr_cmd_text CHAR(1000),
    pr_temp_text CHAR(30),
    x,y,z SMALLINT

 LET pr_cmd_text = pa_command[idx]
 LET y = 1
 LET x = 1
 LET z = length(pr_cmd_text)
 FOR idx = 1 TO pr_word_num
    LET x = y ## Moves TO next word
    WHILE(pr_cmd_text[x,x] = " ")
       LET x = x + 1
       IF x >= z THEN
          EXIT WHILE
       END IF
    END WHILE
    LET y = x
    WHILE(pr_cmd_text[y,y] != " ")
       LET y = y + 1
       IF y > z THEN
          EXIT WHILE
       END IF
    END WHILE
    IF y <= 1 THEN
       LET y = 1
       LET pr_temp_text = pr_cmd_text[x,y]
    ELSE
       IF (y-1)<x THEN
          LET pr_temp_text = pr_cmd_text[x,y]
       ELSE
          LET pr_temp_text = pr_cmd_text[x,y-1]
       END IF
    END IF
 END FOR
 IF pr_temp_text[1,1] = "'" OR pr_temp_text[1,1] = '"' THEN
    LET y = length(pr_temp_text)
    IF pr_temp_text[y,y] = "'" OR pr_temp_text[y,y] = '"' THEN
         LET y = y - 1
      END IF
      LET pr_temp_text = pr_temp_text[2,y]
   END IF
   RETURN pr_temp_text
END FUNCTION


FUNCTION screen_select(idx)
   DEFINE
      idx SMALLINT,
      pr_status INTEGER

   CURRENT WINDOW IS SCREEN  #use maximum area of display
 DISPLAY "1------------------ ",
         "2---------------------------- ",
         "3-------- ",
         "4-------- ",
         "5-------- " AT 3,1
 menu "Display"
    BEFORE MENU
       LET pr_status = run_select(idx,"S","F",1,20)

    	 	CALL publish_toolbar("kandoo","U18","menu-display")

			ON ACTION "WEB-HELP"
		CALL onlineHelp(getModuleId(),NULL)
		ON ACTION "actToolbarManager"
			 	CALL setupToolbar()


    COMMAND KEY ("N",f21) "Next" "DISPLAY next 20 rows"
       LET pr_status = run_select(idx,"S","N",1,20)
    COMMAND KEY ("P",f19) "Previous" "DISPLAY previous 20 rows"
       LET pr_status = run_select(idx,"S","R",1,20)
    COMMAND KEY ("F",f18) "First" "DISPLAY first 20 rows"
       LET pr_status = run_select(idx,"S","A",1,20)
       NEXT OPTION "Next"
    COMMAND "Lookup" "Query table AND COLUMN definitions"
       LET pr_temp_text = show_tables()
    COMMAND "Report" "Print selected rows"
       LET pr_status = report_select(idx)
       NEXT OPTION "Exit"
    COMMAND KEY("E","interrupt") "Exit" "RETURN TO menu"
       LET int_flag = FALSE
       LET quit_flag = FALSE
       EXIT MENU
    COMMAND KEY (control-w)
       CALL kandoohelp("")
   END MENU
   CLEAR SCREEN
   CURRENT WINDOW IS U124
   RETURN pr_status
END FUNCTION


FUNCTION report_select(idx)
   DEFINE
      idx SMALLINT,
      pr_first_num,
      pr_end_num INTEGER

   OPEN WINDOW U142 AT 7,5 WITH FORM "U142"
CALL windecoration_u("U142")

 OPTIONS INPUT no wrap
 INPUT BY NAME pr_first_num, pr_end_num
	BEFORE INPUT
	  CALL publish_toolbar("kandoo","U18","input-first_end_num")
	ON ACTION "WEB-HELP"
		CALL onlineHelp(getModuleId(),NULL)
		ON ACTION "actToolbarManager"
	 	CALL setupToolbar()

END INPUT

 CLOSE WINDOW U142
 IF int_flag OR quit_flag THEN
    LET int_flag = FALSE
    LET quit_flag = FALSE
    RETURN FALSE
 ELSE
    RETURN(run_select(idx,"R","A",pr_first_num,pr_end_num))
   END IF
END FUNCTION


FUNCTION run_select(idx,pr_stdout_ind,pr_cursor_ind,pr_first_num,pr_end_num)
	DEFINE l_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
   DEFINE
      pr_stdout_ind CHAR(1),## R=REPORT S=SCREEN
    pr_cursor_ind CHAR(1),## A=absolute S=first N=Next
    pr_first_num, pr_end_num, x, pr_line_num INTEGER,
    glob_rpt_output CHAR(25),
    field1_text CHAR(20),
    field2_text CHAR(30),
    field3_text CHAR(10),
    field4_text CHAR(10),
    field5_text CHAR(10),
    idx SMALLINT

 LET pr_line_num = 0
 WHENEVER ERROR GOTO recovery
 IF pr_stdout_ind = "R" THEN## Report

	#------------------------------------------------------------
	LET l_rpt_idx = rpt_start(getmoduleid(),"U18_rpt_list_rows","N/A", RPT_SHOW_RMS_DIALOG)
	IF l_rpt_idx = 0 THEN #User pressed CANCEL
		RETURN FALSE
	END IF	
	START REPORT U18_rpt_list_rows TO rpt_get_report_file_with_path2(l_rpt_idx)
	WITH PAGE LENGTH = glob_arr_rec_rpt_rmsreps[l_rpt_idx].page_length_num , 
	TOP MARGIN = 0, 
	BOTTOM MARGIN = 0, 
	LEFT MARGIN = 0, 
	RIGHT MARGIN = glob_arr_rec_rpt_rmsreps[l_rpt_idx].report_width_num
	#------------------------------------------------------------

 END IF
 IF pr_cursor_ind != "N" AND pr_cursor_ind != "R" THEN
    PREPARE s_select FROM pa_command[idx]
    DECLARE c_select scroll CURSOR FOR s_select
    OPEN c_select
 END IF
 CASE pr_cursor_ind
    WHEN "A"
       FETCH absolute pr_first_num c_select INTO field1_text,
                                                 field2_text,
                                                 field3_text,
                                                 field4_text,
                                                 field5_text
    WHEN "F"
       FETCH first c_select INTO field1_text,
                                 field2_text,
                                 field3_text,
                                 field4_text,
                                 field5_text
    WHEN "R"
       FETCH relative -41 c_select INTO field1_text,
                                        field2_text,
                                        field3_text,
                                        field4_text,
                                        field5_text
    WHEN "N"
## do nothing
 END CASE
 FOR x = pr_first_num TO pr_end_num
    IF field1_text IS NULL THEN LET field1_text = "  " END IF
    IF field2_text IS NULL THEN LET field2_text = "  " END IF
    IF field3_text IS NULL THEN LET field3_text = "  " END IF
    IF field4_text IS NULL THEN LET field4_text = "  " END IF
    IF field5_text IS NULL THEN LET field5_text = "  " END IF
    IF pr_stdout_ind = "S" THEN ## Screen OUTPUT
       LET pr_line_num = x + 3
       DISPLAY field1_text,
               field2_text,
               field3_text,
               field4_text,
               field5_text AT pr_line_num, 1
    ELSE ## Report OUTPUT
       IF sqlca.sqlcode = NOTFOUND THEN
          EXIT FOR
       END IF
       LET pr_line_num = pr_line_num + 1

			#---------------------------------------------------------
			OUTPUT TO REPORT U18_rpt_list_rows(l_rpt_idx,
			field1_text,
			field2_text,
			field3_text,
			field4_text,
			field5_text)
			#---------------------------------------------------------			
    END IF
    LET field1_text = "  "
    LET field2_text = "  "
    LET field3_text = "  "
    LET field4_text = "  "
    LET field5_text = "  "
    FETCH next c_select INTO field1_text,
                             field2_text,
                             field3_text,
                             field4_text,
                             field5_text
 END FOR
 IF pr_stdout_ind = "R" THEN## Report
		

			#---------------------------------------------------------
			OUTPUT TO REPORT U18_rpt_list_rows(l_rpt_idx,
			"  ", "  ", "  ", "  ", "  ")
			#---------------------------------------------------------			


			#------------------------------------------------------------
			FINISH REPORT U18_rpt_list_rows
			CALL rpt_finish("U18_rpt_list_rows")
			#------------------------------------------------------------
		   END IF
		   WHENEVER ERROR STOP
		   RETURN TRUE
		label recovery:
		   CALL err_print(STATUS)
		   RETURN FALSE
		END FUNCTION


		FUNCTION run_update(idx,pr_cmd_text,pr_verbose_ind)
		   DEFINE
		      idx SMALLINT,
		      rows_num INTEGER,
		      interrupt_flag INTEGER,
		      pr_cmd_text CHAR(10),
		      pr_verbose_ind CHAR(1),
		      action_text CHAR(8)
DEFINE l_msgresp LIKE language.yes_flag

		   WHENEVER ERROR GOTO recovery
		   PREPARE s_update FROM pa_command[idx]
		   LET interrupt_flag = FALSE
		   CASE pr_verbose_ind
		      WHEN "1"
       IF pr_cmd_text = MODE_CLASSIC_UPDATE
       OR pr_cmd_text = MODE_CLASSIC_DELETE
       OR pr_cmd_text = "drop" THEN
          LET l_msgresp = kandoomsg("U",7019,"")
       END IF
       IF kandoomsg("U",8010,pr_cmd_text) = "Y" THEN
          execute s_update
          IF int_flag OR quit_flag THEN
             LET interrupt_flag = TRUE
          END IF
          IF pr_cmd_text = MODE_CLASSIC_UPDATE
          OR pr_cmd_text = MODE_CLASSIC_DELETE
          OR pr_cmd_text = MODE_CLASSIC_SELECT
          OR pr_cmd_text = MODE_CLASSIC_INSERT THEN
             LET l_msgresp = kandoomsg("U",7010,sqlca.sqlerrd[3])
#U 7010 No. of rows processed 21
          ELSE
             LET l_msgresp = kandoomsg("U",7012,pr_cmd_text)
#U 7012 SQL command UPDATE successfull
          END IF
       END IF
    WHEN "2"
       execute s_update
       IF int_flag OR quit_flag THEN
          LET interrupt_flag = TRUE
       END IF
       IF pr_cmd_text = MODE_CLASSIC_UPDATE
       OR pr_cmd_text = MODE_CLASSIC_DELETE
       OR pr_cmd_text = MODE_CLASSIC_SELECT
       OR pr_cmd_text = MODE_CLASSIC_INSERT THEN
          LET l_msgresp = kandoomsg("U",6010,sqlca.sqlerrd[3])
#U 6010 No. of rows processed 21
       ELSE
          LET l_msgresp = kandoomsg("U",6011,pr_cmd_text)
#U 6011 SQL command UPDATE successfull
       END IF
    WHEN "3"
         execute s_update
         IF int_flag OR quit_flag THEN
            LET interrupt_flag = TRUE
         END IF
   END CASE
   WHENEVER ERROR STOP
   IF interrupt_flag THEN
      RETURN FALSE
   ELSE
      RETURN TRUE
   END IF
   RETURN TRUE
label recovery:
   CALL err_print(STATUS)
   RETURN FALSE
END FUNCTION


FUNCTION run_load(idx,pr_cmd_text,pr_verbose_ind)
   DEFINE
      idx SMALLINT,
      pr_cmd_text CHAR(10),
      pr_verbose_ind CHAR(1),
      query_text CHAR(200),
#pr_tablename LIKE systables.tabname,
#tabname              varchar(128,0)
			  pr_tablename CHAR (128),
		      pr_filename CHAR(50),
		      pr_delimiter CHAR(1)
DEFINE l_msgresp LIKE language.yes_flag

		   WHENEVER ERROR CONTINUE
		IF fgl_find_table("t_load") THEN
			DROP TABLE t_load 
		END IF
		   

		   WHENEVER ERROR STOP
		   IF downshift(extract_word(idx,2)) != "FROM" THEN
    LET STATUS = -201
    GOTO recovery
 END IF
 LET pr_filename = extract_word(idx,3)
 IF NOT file_exists(pr_filename) THEN
    LET STATUS = -463
    GOTO recovery
 END IF
 IF downshift(extract_word(idx,4)) = "delimiter" THEN
    LET pr_delimiter = downshift(extract_word(idx,5))
    LET pr_tablename = downshift(extract_word(idx,8))
 ELSE
    LET pr_delimiter = "|"
    LET pr_tablename = downshift(extract_word(idx,6))
 END IF
 SELECT unique 1 FROM systables WHERE tabname = pr_tablename
 IF STATUS = NOTFOUND THEN
    LET STATUS = -206
    GOTO recovery
 END IF
 LET query_text ="SELECT * FROM ",pr_tablename," WHERE 1!=1 INTO temp t_load"
   PREPARE s1_t_load FROM query_text
   execute s1_t_load
   WHENEVER ERROR GOTO recovery

DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with DELIMITER"
DISPLAY "see utility/U18.4gl"
EXIT PROGRAM (1)


#   load FROM pr_filename delimiter pr_delimiter INSERT INTO t_load
 LET query_text = "INSERT INTO ",pr_tablename," SELECT * FROM t_load"
 PREPARE s2_t_load FROM query_text
 CASE pr_verbose_ind
    WHEN "1"
       IF kandoomsg("U",8010,pr_cmd_text) = "Y" THEN
          execute s2_t_load
          LET l_msgresp = kandoomsg("U",7010,sqlca.sqlerrd[3])
#U 7010 No. of rows processed 21
       END IF
    WHEN "2"
       execute s2_t_load
       LET l_msgresp = kandoomsg("U",7010,sqlca.sqlerrd[3])
#U 6010 No. of rows processed 21
    WHEN "3"
		         execute s2_t_load
		   END CASE
		   WHENEVER ERROR STOP
		   RETURN TRUE
		label recovery:
		   CALL err_print(STATUS)
		   RETURN FALSE
		END FUNCTION


		FUNCTION run_unload(idx,pr_cmd_text,pr_verbose_ind)
		   DEFINE
		      idx SMALLINT,
		      pr_cmd_text CHAR(10),
		      pr_verbose_ind CHAR(1),
		      pr_temp_text CHAR(1000),
		      pr_filename CHAR(50),
		      pr_delimiter CHAR(1),
		      i,j SMALLINT
DEFINE l_msgresp LIKE language.yes_flag

		   WHENEVER ERROR CONTINUE
		IF fgl_find_table("t_unload") THEN
			DROP TABLE t_unload 
		END IF		   
		   WHENEVER ERROR STOP
		   IF downshift(extract_word(idx,2)) != "TO" THEN
    LET STATUS = -201
    GOTO recovery
 END IF
 LET pr_filename = extract_word(idx,3)
 IF downshift(extract_word(idx,4)) = "delimiter" THEN
    LET pr_delimiter = downshift(extract_word(idx,5))
    IF downshift(extract_word(idx,6)) != MODE_CLASSIC_SELECT THEN
       LET STATUS = -201
       GOTO recovery
    END IF
 ELSE
    LET pr_delimiter = "|"
    IF downshift(extract_word(idx,4)) != MODE_CLASSIC_SELECT THEN
       LET STATUS = -201
       GOTO recovery
    END IF
 END IF
 LET pr_temp_text = pa_command[idx]
 LET j = length(pr_temp_text)
 FOR i = 1 TO j
    IF downshift(pr_temp_text[i,i+5]) = MODE_CLASSIC_SELECT THEN
       LET pr_temp_text = pr_temp_text[i,j]," INTO temp t_unload"
       EXIT FOR
    END IF
 END FOR
 WHENEVER ERROR GOTO recovery
 PREPARE s1_t_unload FROM pr_temp_text
 CASE pr_verbose_ind
    WHEN "1"
       IF kandoomsg("U",8010,pr_cmd_text) = "Y" THEN
            execute s1_t_unload
DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with DELIMITER"
DISPLAY "see utility/U18.4gl"
EXIT PROGRAM (1)

#            unload TO pr_filename delimiter pr_delimiter
              SELECT * FROM t_unload
          LET l_msgresp = kandoomsg("U",7010,sqlca.sqlerrd[3])
#U 7010 No. of rows processed 21
       END IF
    WHEN "2"
         execute s1_t_unload
DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with DELIMITER"
DISPLAY "see utility/U18.4gl"
EXIT PROGRAM (1)

#         unload TO pr_filename delimiter pr_delimiter SELECT * FROM t_unload
       LET l_msgresp = kandoomsg("U",7010,sqlca.sqlerrd[3])
#U 6010 No. of rows processed 21
    WHEN "3"
         execute s1_t_unload
DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with DELIMITER"
DISPLAY "see utility/U18.4gl"
EXIT PROGRAM (1)

#         unload TO pr_filename delimiter pr_delimiter SELECT * FROM t_unload
		   END CASE
		   WHENEVER ERROR STOP
		   RETURN TRUE
		label recovery:
		   CALL err_print(STATUS)
		   RETURN FALSE
		END FUNCTION


		FUNCTION import_file(pr_file_text)
		   DEFINE
		      pr_file_text CHAR(100),
		      idx SMALLINT
DEFINE l_msgresp LIKE language.yes_flag

		   IF pr_file_text IS NULL THEN
		      RETURN FALSE
		   ELSE
		      LET l_msgresp=kandoomsg("U",1005,"")
#U 1005 " Please wait!"
      DELETE FROM t_commands
      WHENEVER ERROR GOTO recovery
DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with DELIMITER"
DISPLAY "see utility/U18.4gl"
EXIT PROGRAM (1)

#      load FROM pr_file_text delimiter ";" INSERT INTO t_commands(sql_text)
    WHENEVER ERROR STOP
    DECLARE c_t_commands CURSOR FOR
       SELECT sql_text FROM t_commands
    LET idx = 1
    FOREACH c_t_commands INTO pa_command[idx]
       IF pa_command[idx] IS NOT NULL THEN
          LET pr_cmd_cnt = idx
          CALL disp_count(idx)
          IF idx < 200 THEN
             LET idx = idx + 1
          ELSE
             LET l_msgresp = kandoomsg("U",9031,"")
		               EXIT FOREACH
		            END IF
		         END IF
		      END FOREACH
		      CALL disp_count(1)
		      RETURN TRUE
		   END IF
		label recovery:
		   CALL err_print(STATUS)
		   RETURN FALSE
		END FUNCTION


		FUNCTION export_file(pr_file_text)
		   DEFINE
		      pr_file_text CHAR(100),
		      idx SMALLINT
DEFINE l_msgresp LIKE language.yes_flag

		   IF pr_file_text IS NULL THEN
		      RETURN FALSE
		   ELSE
		      LET l_msgresp=kandoomsg("U",1010,"")
#U 1010 " Updating DB -Please wait!"
    DELETE FROM t_commands
    FOR idx = 1 TO pr_cmd_cnt
       CALL disp_count(idx)
       IF length(pa_command[idx] clipped) > 1024 THEN
          LET l_msgresp = kandoomsg("U",9032,"")
         END IF
         INSERT INTO t_commands(sql_text) VALUES(pa_command[idx])
      END FOR
      WHENEVER ERROR GOTO recovery
DISPLAY "EXIT: disabled code because of <Anton Dickinson> ecp issue with DELIMITER"
DISPLAY "see utility/U18.4gl"
EXIT PROGRAM (1)

#      unload TO pr_file_text delimiter ";" SELECT t.sql_text FROM t_commands t
		      WHENEVER ERROR STOP
		      RETURN TRUE
		   END IF
		label recovery:
		   RETURN FALSE
		END FUNCTION


		FUNCTION enter_file(pr_readwrite_ind)
		   DEFINE
		      pr_readwrite_ind CHAR(1),
		      runner CHAR(80)
DEFINE l_msgresp LIKE language.yes_flag

		   IF pr_path_text IS NULL THEN
		      LET pr_path_text = fgl_getenv("HOME"), "/*.sql"
 END IF

 OPTIONS INPUT no wrap

 INPUT BY NAME pr_path_text WITHOUT DEFAULTS
	BEFORE INPUT
	  CALL publish_toolbar("kandoo","U18","input-path_text")

	ON ACTION "WEB-HELP"
		CALL onlineHelp(getModuleId(),NULL)

		ON ACTION "actToolbarManager"
	 	CALL setupToolbar()


    ON KEY(control-b)
       LET pr_path_text = get_fldbuf(pr_path_text)
       LET runner = "ls -l ",pr_path_text clipped," | pg -c"

       run runner
       CALL eventSuspend()  # LET l_msgresp = kandoomsg("U",1,"")
# "RETURN TO Continue"

    AFTER FIELD pr_path_text
       CASE
          WHEN pr_path_text IS NULL
             NEXT FIELD pr_path_text
          WHEN pr_path_text NOT matches "*.sql"
               LET l_msgresp = kandoomsg("U",9033,"")
             LET pr_path_text = pr_path_text clipped,".sql"
             NEXT FIELD pr_path_text
          WHEN pr_readwrite_ind = "W"
             IF file_exists(pr_path_text) THEN
                IF kandoomsg("U",8011,"") = "N" THEN
#U8011 " File Exists. Overwrite (Y/N)?"
                   NEXT FIELD pr_path_text
                END IF
             END IF
          WHEN pr_readwrite_ind = "R"
             IF NOT file_exists(pr_path_text) THEN
                LET l_msgresp = kandoomsg("U",9034,"")
                NEXT FIELD pr_path_text
             END IF
       END CASE

    ON KEY (control-w)
       CALL kandoohelp("")

 END INPUT

 IF int_flag OR quit_flag THEN
    LET int_flag = FALSE
    LET quit_flag = FALSE
    RETURN ""
   ELSE
      RETURN pr_path_text
   END IF

END FUNCTION


FUNCTION disp_count(pr_count)
   DEFINE
      pr_count SMALLINT

   IF pr_cmd_cnt <= pr_count THEN
      LET pr_cmd_cnt = pr_count
   END IF
   LET pa_command[pr_cmd_cnt] = pa_command[pr_cmd_cnt] clipped

   WHILE pa_command[pr_cmd_cnt] = " "
      IF pr_cmd_cnt = pr_count THEN
         EXIT WHILE
      ELSE
         LET pr_cmd_cnt = pr_cmd_cnt - 1
         LET pa_command[pr_cmd_cnt] = pa_command[pr_cmd_cnt] clipped
      END IF
   END WHILE
   DISPLAY pa_command[pr_count] TO sql_text

   DISPLAY BY NAME pr_count,
                   pr_cmd_cnt

END FUNCTION



FUNCTION file_exists(pr_filename)
   DEFINE
      pr_filename CHAR(50),
      ret_code INTEGER,
      runner CHAR(100)

	IF os.Path.writable(pr_filename) THEN  --huho using os.path() methods BUT strange reversed RETURN value IS required
	RETURN FALSE
ELSE
	RETURN TRUE
END IF

# LET runner = " [ -w ",pr_filename clipped," ] 2>>", trim(get_settings_logFile()) 
# run runner returning ret_code
# IF ret_code THEN
#    RETURN FALSE
# ELSE
#    RETURN TRUE
# END IF
END FUNCTION



REPORT U18_rpt_list_rows(p_rpt_idx,field1_text,field2_text,field3_text,field4_text,field5_text)
	DEFINE p_rpt_idx SMALLINT #array index for glob_arr_rmsreps[p_rpt_idx]	
   DEFINE
      field1_text CHAR(20),
      field2_text CHAR(30),
      field3_text CHAR(10),
      field4_text CHAR(10),
      field5_text CHAR(10)

   OUTPUT 
   --left margin 0
   --       right margin 80
   FORMAT
   PAGE HEADER
			CALL rpt_set_page_num(p_rpt_idx,pageno) #update page number and report header line 1
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_1 #was l_arr_line[1] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_2 #wasl_arr_line[2] 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3]  
			#PRINT COLUMN 01, glob_arr_rec_rpt_kandooreport[p_rpt_idx].line1_text 
			#PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].header_3 #wasl_arr_line[3] 
		
		   
   ON EVERY ROW
      PRINT COLUMN 1, field1_text,
            COLUMN 21,field2_text,
            COLUMN 51,field3_text,
            COLUMN 61,field4_text,
            COLUMN 71,field5_text

		ON LAST ROW 
			NEED 4 LINES 
			#End Of Report
			IF glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_flag = "Y" THEN 
				PRINT COLUMN 01,"Selection Criteria:" 
				PRINT COLUMN 10, glob_arr_rec_rpt_rmsreps[p_rpt_idx].sel_text clipped wordwrap right margin 100 
			END IF 
			PRINT COLUMN 01, glob_arr_rec_rpt_header_footer[p_rpt_idx].end_of_report #was l_arr_line[4] 	

            
END REPORT
