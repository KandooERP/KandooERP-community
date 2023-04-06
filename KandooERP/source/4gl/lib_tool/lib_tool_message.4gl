###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
###########################################################################
# MODULE SCOPE Variables
###########################################################################
DEFINE ml_msgresp LIKE language.yes_flag --originaly, it was a project global glob_msgresp 

###########################################################################
# FUNCTION displaymoduletitle(p_title_str)
#
#
###########################################################################
FUNCTION displaymoduletitle(p_title_str) 
	DEFINE p_title_str STRING
	DEFINE wo ui.Window
	DEFINE l_msg STRING
	IF p_title_str IS NULL THEN
		--WHENEVER ERROR CONTINUE 
		#@ToDo: insure all forms use the same identifier for it's title text
		--DISPLAY getmenuitemlabel(getmoduleid()) TO lbtitle 
		DISPLAY LSTR(getmenuitemlabel(getmoduleid())) TO header_text
		
		LET wo = ui.Window.getCurrent()
		CALL wo.setText(LSTR(getmenuitemlabel(getmoduleid())))
		
		#Display company name in the statusbar
		#LET l_msg = "User ", trim(glob_rec_kandoouser.name_text), " Logged in to company ", trim(glob_rec_kandoouser.cmpy_code), " / " , db_company_get_name_text(UI_OFF,glob_rec_kandoouser.cmpy_code)
		#CALL displaystatus(l_msg) 

		--WHENEVER ERROR stop
	ELSE
		DISPLAY LSTR(p_title_str) TO header_text
	END IF 

END FUNCTION 
#############################################################
# END FUNCTION displaymoduletitle(p_title_str)
#############################################################


#############################################################
# FUNCTION displaytitle(argtitle) 
#
#
#############################################################
FUNCTION displaytitle(argtitle) 
	DEFINE argtitle STRING 

	IF argtitle IS NOT NULL THEN 
		--WHENEVER ERROR CONTINUE 
		--DISPLAY argtitle TO lbtitle 
		DISPLAY argtitle TO header_text 
		--WHENEVER ERROR stop 
	END IF 

END FUNCTION 
#############################################################
# END FUNCTION displaytitle(argtitle) 
#############################################################


#############################################################
# FUNCTION displayUsage(p_arg_msg)
#
# !!! Kandidate for removal !!!
#############################################################
FUNCTION displayusage(p_arg_msg) 
	DEFINE p_arg_msg STRING 

	--WHENEVER ERROR CONTINUE --huho - old/original/none modernized forms have no titlebar/footer bar container/labels 
	DISPLAY trim(p_arg_msg) TO lbinfo1 --use trim in CASE OF preceeding spaces 
	--WHENEVER ERROR stop 

	IF p_arg_msg IS NOT NULL THEN 
		MESSAGE p_arg_msg 
	END IF 

	CALL ui.interface.refresh() 
END FUNCTION 
#############################################################
# END FUNCTION displayUsage(p_arg_msg)
#############################################################


#############################################################
# FUNCTION displayStatus(p_msg)
#
#
#############################################################
FUNCTION displaystatus(p_msg) 
	DEFINE p_msg STRING 

	--WHENEVER ERROR CONTINUE --huho - old/original/none modernized forms have no titlebar/footer bar container/labels 
	MESSAGE p_msg 
	DISPLAY trim(p_msg) TO lbinfo1 --use trim in CASE OF preceeding spaces 
	--WHENEVER ERROR stop 

	IF p_msg IS NOT NULL THEN 
		MESSAGE p_msg 
	END IF 

	CALL ui.interface.refresh() 

END FUNCTION 


#############################################################
# FUNCTION displayCurrentToolbar(p_tb_prog_id,p_tb_menu_id )
#
#
#############################################################
FUNCTION displaycurrenttoolbar(p_tb_prog_id,p_tb_menu_id ) 
	DEFINE p_tb_prog_id STRING 
	DEFINE p_tb_menu_id STRING 
	DEFINE l_toolbar_info_str STRING 
	DEFINE l_msg STRING


	IF p_tb_menu_id <> "global" THEN 

		#Display company name in the statusbar
		LET l_toolbar_info_str = 
			"User: ", trim(glob_rec_kandoouser.name_text), " ", 
			"Company: ", trim(glob_rec_kandoouser.cmpy_code), "-" , trim(db_company_get_name_text(UI_OFF,glob_rec_kandoouser.cmpy_code)), " ",
			"ProgID: ", p_tb_prog_id clipped, " ", 
			"MenuID: ", p_tb_menu_id clipped
		#CALL displaystatus(l_msg) 


		--WHENEVER ERROR CONTINUE --huho - old/original/none modernized forms have no titlebar/footer bar container/labels 
		DISPLAY l_toolbar_info_str TO lbinfo2 
		--WHENEVER ERROR stop 

	END IF 

END FUNCTION 
#############################################################
# END FUNCTION displayStatus(p_msg)
#############################################################


##############################################################
# FUNCTION kandoomsg2(p_source_ind, p_msg_num, p_extra_text)
# This is derived from kandoomsg()
# Difference is, it only returns the message string
# 
# RETURN l_ret_msg
##############################################################
FUNCTION kandoomsg2(p_source_ind, p_msg_num, p_extra_text) 
	DEFINE p_source_ind LIKE kandoomsg.source_ind 
	DEFINE p_msg_num LIKE kandoomsg.msg_num 
	DEFINE p_extra_text CHAR(60) 
	DEFINE l_rec_kandoomsg RECORD LIKE kandoomsg.*
	DEFINE l_spaces STRING
	DEFINE l_ret_msg VARCHAR(200)
	DEFINE l_ret_msg_end VARCHAR(200)
	
	#Query for message string
	SELECT msg1_text,msg2_text INTO l_ret_msg,l_ret_msg_end FROM kandoomsg 
	WHERE source_ind = p_source_ind 
	AND msg_num = p_msg_num 
	AND language_code = glob_rec_kandoouser.language_code 

	#IF not found, query again by using ENGlish
	IF status = notfound THEN 
		SELECT msg1_text,msg2_text INTO l_ret_msg,l_ret_msg_end FROM kandoomsg 
		WHERE source_ind = p_source_ind 
		AND msg_num = p_msg_num 
		AND language_code = "ENG" 

		IF status = notfound THEN 
			LET l_spaces = "Missing Message Number ", trim(p_source_ind), "/",trim(glob_rec_kandoouser.language_code), " in Program ", getmoduleid() 
			CALL errorlog(l_spaces) 
			CALL fgl_winmessage("Missing kandoomsg string",l_spaces,"error")
		END IF 
	END IF 
	
	LET l_ret_msg = trim(l_ret_msg), " ", trim(p_extra_text), " ", trim(l_ret_msg_end)
	RETURN l_ret_msg
END FUNCTION
##############################################################
# END FUNCTION kandoomsg2(p_source_ind, p_msg_num, p_extra_text)
##############################################################


##############################################################
# FUNCTION kandooDialog2(p_source_ind, p_msg_num, p_extra_text)
# This is derived from kandooDialog()
# Difference is, it only returns the message string
# 
# RETURN l_sql_msg
##############################################################
FUNCTION kandooDialog2(p_source_ind, p_msg_num, p_extra_text) 
	DEFINE p_source_ind LIKE kandoomsg.source_ind 
	DEFINE p_msg_num LIKE kandoomsg.msg_num 
	DEFINE p_extra_text CHAR(60) 
	DEFINE l_title_msg STRING
	DEFINE l_icon STRING
--	DEFINE l_rec_kandoomsg RECORD LIKE kandoomsg.*
	DEFINE l_spaces STRING
	DEFINE l_sql_msg VARCHAR(200)
	DEFINE l_pre_choice BOOLEAN 
	DEFINE l_pre_choice_btn_text STRING
	DEFINE l_ret STRING 
	
	#kandooDialog was made to have compatible kandoomsg() dialog function. ONLY retrieves the message from the DB and offer a Yes/No dialog
	LET l_title_msg = ""
	LET l_icon = "QUESTION"
			
	#Query for message string
	SELECT msg1_text INTO l_sql_msg FROM kandoomsg 
	WHERE source_ind = p_source_ind 
	AND msg_num = p_msg_num 
	AND language_code = glob_rec_kandoouser.language_code 

	#IF not found, query again by using ENGlish
	IF status = notfound THEN 
		SELECT msg1_text INTO l_sql_msg FROM kandoomsg 
		WHERE source_ind = p_source_ind 
		AND msg_num = p_msg_num 
		AND language_code = "ENG" 

		IF status = notfound THEN 
			LET l_spaces = "Missing Message Number ", trim(p_source_ind), "/",trim(glob_rec_kandoouser.language_code), " in Program ", getmoduleid() 
			CALL errorlog(l_spaces) 
			CALL fgl_winmessage("Missing kandoomsg string",l_spaces,"error")
		END IF 
	END IF 
	
	LET l_sql_msg = trim(l_sql_msg), p_extra_text

	CASE l_pre_choice 
		WHEN 1 
			LET l_pre_choice_btn_text = "Yes" 
		OTHERWISE 
			LET l_pre_choice_btn_text = "No" 
	END CASE 

	LET l_ret = fgl_winbutton(l_title_msg,l_sql_msg,l_pre_choice_btn_text,"Yes|No",l_icon,1) 

	CASE l_ret 
		WHEN "Yes" 
			RETURN "Y" 
		OTHERWISE 
			RETURN "N" 
	END CASE 	

END FUNCTION
##############################################################
# END FUNCTION kandooDialog2(p_source_ind, p_msg_num, p_extra_text)
##############################################################


##############################################################
# FUNCTION kandooDialog(p_source_ind, p_msg_num, p_extra_text,p_default,p_title_msg,p_icon)
# This is derived from kandooDialog()
# Difference is, it only returns the message string
# 
# RETURN TRUE/FALSE
##############################################################
FUNCTION kandooDialog(p_source_ind, p_msg_num, p_extra_text,p_default,p_title_msg,p_icon) 
	DEFINE p_source_ind LIKE kandoomsg.source_ind 
	DEFINE p_msg_num LIKE kandoomsg.msg_num 
	DEFINE p_extra_text CHAR(60) 
	DEFINE p_default BOOLEAN
	DEFINE p_title_msg STRING
	DEFINE p_icon STRING
--	DEFINE l_rec_kandoomsg RECORD LIKE kandoomsg.*
	DEFINE l_spaces STRING
	DEFINE l_sql_msg VARCHAR(200)

	DEFINE l_pre_choice_btn_text STRING
	DEFINE l_ret STRING 
	
	#Query for message string
	SELECT msg1_text INTO l_sql_msg FROM kandoomsg 
	WHERE source_ind = p_source_ind 
	AND msg_num = p_msg_num 
	AND language_code = glob_rec_kandoouser.language_code 

	#IF not found, query again by using ENGlish
	IF status = notfound THEN 
		SELECT msg1_text INTO l_sql_msg FROM kandoomsg 
		WHERE source_ind = p_source_ind 
		AND msg_num = p_msg_num 
		AND language_code = "ENG" 

		IF status = notfound THEN 
			LET l_spaces = "Missing Message Number ", trim(p_source_ind), "/",trim(glob_rec_kandoouser.language_code), " in Program ", getmoduleid() 
			CALL errorlog(l_spaces) 
			CALL fgl_winmessage("Missing kandoomsg string",l_spaces,"error")
		END IF 
	END IF 
	
	LET l_sql_msg = trim(l_sql_msg), p_extra_text
	

	CASE p_default 
		WHEN TRUE 
			LET l_pre_choice_btn_text = "Yes" 
		OTHERWISE 
			LET l_pre_choice_btn_text = "No" 
	END CASE 

	IF p_icon IS NULL THEN
		LET p_icon = "QUESTION"
	ELSE
		LET p_icon = p_icon.toUpperCase()
		IF	(p_icon != "INFO") AND
				(p_icon != "EXCLAMATION") AND 
				(p_icon != "QUESTION") AND 
				(p_icon != "STOP") AND
				(p_icon != "ERROR") AND
				(p_icon != "WARNING") THEN  
			LET p_icon = "QUESTION"
		END IF 
	END IF
	
	LET l_ret = fgl_winbutton(p_title_msg,l_sql_msg,l_pre_choice_btn_text,"Yes|No",p_icon,1) 

	CASE l_ret 
		WHEN "Yes" 
			RETURN TRUE 
		OTHERWISE 
			RETURN FALSE 
	END CASE 	

END FUNCTION
##############################################################
# END FUNCTION kandooDialog(p_source_ind, p_msg_num, p_extra_text,p_default,p_title_msg,p_icon)
##############################################################


##############################################################
# FUNCTION kandoomsg(p_source_ind, p_msg_num, p_extra_text)
# # Moved FROM secufunc.4gl
##############################################################
FUNCTION kandoomsg(p_source_ind, p_msg_num, p_extra_text) 
	DEFINE p_source_ind LIKE kandoomsg.source_ind 
	DEFINE p_msg_num LIKE kandoomsg.msg_num 
	DEFINE p_extra_text CHAR(60) 

	DEFINE l_msg1_text LIKE kandoomsg.msg1_text #moved FROM GLOBALS 
	DEFINE l_msg2_text LIKE kandoomsg.msg1_text #moved FROM GLOBALS 

	DEFINE l_rec_kandoomsg RECORD LIKE kandoomsg.* 
	DEFINE l_winmsg CHAR(100) 
	DEFINE l_line1 LIKE kandoomsg.msg1_text 
	DEFINE l_line2 LIKE kandoomsg.msg1_text 
	DEFINE l_line3 LIKE kandoomsg.msg1_text 
	DEFINE l_spaces CHAR(240) 
	DEFINE l_ans LIKE language.yes_flag #char(1), 
	DEFINE l_word1 CHAR(20) 
	DEFINE l_word2 CHAR(20) 

	DEFINE l_windcode CHAR(10) 
	DEFINE j SMALLINT 
	DEFINE i SMALLINT 
	#DEFINE l_rows_num SMALLINT
	#DEFINE l_cols_num SMALLINT
	DEFINE x SMALLINT 
	DEFINE l_tmpmsg STRING 

	--CALL ui.interface.refresh() 

	LET l_windcode = p_source_ind, p_msg_num USING "<<<<<<<<" 

	--IF get_debug() = TRUE THEN
	--   DISPLAY "Message:"
	--   DISPLAY "p_source_ind:", p_source_ind
	--   DISPLAY "p_msg_num:", p_msg_num
	--   DISPLAY "glob_rec_kandoouser.language_code:", glob_rec_kandoouser.language_code
	--   WHENEVER ERROR STOP  #@huho debug
	--END IF

	SELECT * INTO l_rec_kandoomsg.* FROM kandoomsg 
	WHERE source_ind = p_source_ind 
	AND msg_num = p_msg_num 
	AND language_code = glob_rec_kandoouser.language_code 

	--IF get_debug() = TRUE THEN
	--	DISPLAY "   SELECT * INTO l_rec_kandoomsg.* FROM kandoomsg
	--WHERE source_ind = p_source_ind
	--  AND msg_num = p_msg_num
	--  AND language_code = glob_rec_kandoouser.language_code"
	--	DISPLAY "STATUS=", STATUS
	--  DISPLAY "p_source_ind=", p_source_ind
	--  DISPLAY "p_msg_num=", p_msg_num
	--  DISPLAY "glob_rec_kandoouser.language_code=", glob_rec_kandoouser.language_code
	--  DISPLAY "l_rec_kandoomsg.*=", l_rec_kandoomsg.*
	--   DISPLAY "NOTFOUND=", NOTFOUND
	--END IF

	IF status = notfound THEN 
		SELECT * INTO l_rec_kandoomsg.* FROM kandoomsg 
		WHERE source_ind = p_source_ind 
		AND msg_num = p_msg_num 
		AND language_code = "ENG" 

		IF status = notfound THEN 
			LET l_spaces = "Missing Message Number ", 
			l_windcode clipped, 
			" in Program ", 
			getmoduleid() 
			CALL errorlog(l_spaces) 

			#IF stop_on_missing_msg THEN
			LET l_tmpmsg = "Message Library Error - See logfile ", l_windcode 
			ERROR l_tmpmsg 
			--CALL fgl_winmessage("Error",l_tmpMsg,"error") #took it out for a demo.. needs to be included again later (who ever reads this)

			#ELSE

			#fi
		END IF 
	END IF 

	--IF get_debug() = TRUE THEN
	--	DISPLAY "p_extra_text=", p_extra_text  #@huho
	--END IF

	IF p_extra_text IS NOT NULL THEN 

		CASE 

			WHEN l_rec_kandoomsg.format_ind="9" #display best possible fit. amend lines. 
				IF length(l_rec_kandoomsg.msg2_text) = 1 THEN 
					LET l_spaces = l_rec_kandoomsg.msg1_text clipped," ", 
					p_extra_text clipped," ", 
					l_rec_kandoomsg.msg2_text clipped 
				ELSE 
					LET l_spaces = l_rec_kandoomsg.msg1_text clipped," ", 
					p_extra_text clipped," ", 
					l_rec_kandoomsg.msg2_text clipped 
				END IF 

				IF length(l_spaces) > 70 THEN ##### manual wordwrap 
					LET x = length(l_spaces) 
					LET l_line2 = l_spaces[70,x] 
					FOR x = 69 TO 55 step -1 
						IF l_spaces[x,x] = " " THEN 
							EXIT FOR 
						ELSE 
							LET l_line2 = l_spaces[x,x],l_line2 clipped 
						END IF 
					END FOR 
					LET l_line1 = l_spaces[1,x] #
				ELSE 
					LET l_line1 = l_spaces clipped 
				END IF 

			WHEN l_rec_kandoomsg.format_ind = "1" #display ***** at START line 1 
				LET l_spaces = p_extra_text clipped," ", 
				l_rec_kandoomsg.msg1_text clipped 
				LET l_line1 = l_spaces 
				LET l_line2 = l_rec_kandoomsg.msg2_text clipped 

			WHEN l_rec_kandoomsg.format_ind = "2" # DISPLAY ***** at END line 1 
				LET l_spaces = l_rec_kandoomsg.msg1_text clipped," ", 
				p_extra_text clipped 
				LET l_line1 = l_spaces 
				LET l_line2 = l_rec_kandoomsg.msg2_text 

			WHEN l_rec_kandoomsg.format_ind = "3" # DISPLAY *** at START line 2 
				LET l_line1 = l_rec_kandoomsg.msg1_text 
				LET l_spaces = p_extra_text clipped," ", 
				l_rec_kandoomsg.msg2_text clipped 
				LET l_line2 = l_spaces 

			WHEN l_rec_kandoomsg.format_ind = "4" ## DISPLAY ***** at END line 2 
				LET l_line1 = l_rec_kandoomsg.msg1_text 
				LET l_spaces = l_rec_kandoomsg.msg2_text clipped," ", 
				p_extra_text clipped 
				LET l_line2 = l_spaces 

			OTHERWISE 
				LET l_line1 = l_rec_kandoomsg.msg1_text clipped 
				LET l_line2 = l_rec_kandoomsg.msg2_text clipped 

		END CASE 

	ELSE 

		LET l_line1 = l_rec_kandoomsg.msg1_text clipped 
		LET l_line2 = l_rec_kandoomsg.msg2_text clipped 
	END IF 

	LET l_line1 = l_line1 clipped 
	LET l_line2 = l_line2 clipped 

	LET l_msg1_text = l_line1 #huho... glob_msg1_text ... this IS NOT used anywhere (local nor global..) 
	LET l_msg2_text = l_line2 #huho... l_msg2_text ... this IS NOT used anywhere (local nor global..) 
	LET l_spaces = NULL 


	CASE 
		WHEN l_rec_kandoomsg.msg_ind = "9" 
			#ERROR l_line1 clipped  #huho I'm not happy with showing normal information i.e. number of found rows in form of error... 
			MESSAGE l_line1 clipped
		WHEN l_rec_kandoomsg.msg_ind = "1" 


			IF length(l_line2) > 0 THEN 
				LET l_winmsg = l_line1 clipped, " ",l_line2 
				CALL set_fkeys(l_rec_kandoomsg.*) 
				OPTIONS MESSAGE line 1 
				MESSAGE l_line1 
				OPTIONS MESSAGE line 2 
				MESSAGE l_line2 
			ELSE 
				OPTIONS MESSAGE line 2 
				LET l_winmsg = l_line1 clipped 
				CALL set_fkeys(l_rec_kandoomsg.*) 
				MESSAGE l_winmsg 
				#huho - redirecting usage insruction string TO common FUNCTION
				CALL displayusage(l_winmsg) 

			END IF 


		WHEN l_rec_kandoomsg.msg_ind = "2" 

			IF length(l_line2) > 0 THEN 
				OPTIONS MESSAGE line 1 
				MESSAGE l_line1 
				OPTIONS MESSAGE line 2 
				MESSAGE l_line2 

			ELSE 

				OPTIONS MESSAGE line 2 
				MESSAGE l_line1 
			END IF 



		WHEN l_rec_kandoomsg.msg_ind = "3" #press any KEY TO CONTINUE 

			LET l_spaces = l_line1 clipped,"\n",l_line2 clipped 
			#             CALL fgl_winmessage(glob_title_desc,l_spaces,"info")
			#huho 23.02.2019
			CALL fgl_winmessage("",l_spaces,"info") 



		WHEN l_rec_kandoomsg.msg_ind = "4" #one/other answer 
			LET j = length(p_extra_text) 
			LET l_word1 = "Yes" 
			LET l_word2 = "No" 

			FOR i = 1 TO length(p_extra_text) 
				IF p_extra_text[i] = "|" THEN 
					LET l_word1 = p_extra_text[1,i-1] 
					LET l_word2 = p_extra_text[i+1,j] 
					EXIT FOR 
				END IF 
			END FOR 

			#we are always in gui

			LET l_spaces = l_line1 clipped,"\n",l_line2 clipped 
			LET l_ans = fgl_winbutton("", #glob_title_desc, 
			l_spaces, 
			l_word1, 
			p_extra_text, 
			"question",0) 


		WHEN l_rec_kandoomsg.msg_ind = "5" #diplay MESSAGE FOR 2 seconds 


			LET l_tmpmsg = trim(l_line1), "\n",trim(l_line2) 

			MESSAGE l_tmpMsg 
			#LET l_tmpMsg = glob_title_desc, "\n", l_tmpMsg #HuHO changed it TO ERROR based on Alexey Feedback
			#ERROR l_tmpmsg 
			--CALL fgl_winmessage("Error",l_tmpMsg,"error") 


		WHEN l_rec_kandoomsg.msg_ind = "6" # ERROR requiring acknowledgement 


			LET l_spaces = l_line1 clipped,"\n",l_line2 clipped 
			ERROR l_spaces 


		WHEN l_rec_kandoomsg.msg_ind = "7" #warning window, press any KEY TO EXIT 

			LET l_spaces = l_line1 clipped,"\n",l_line2 clipped 

			IF length(l_spaces) < 3 THEN 

				MENU "programmenu" #glob_callingprog getmoduleid() 

					COMMAND KEY(accept, interrupt,"C")"Continue" "" 
						EXIT MENU 

					COMMAND KEY (control-w) 
						CALL kandoohelp("") 

					ON ACTION "WEB-HELP" 
						CALL onlinehelp(getmoduleid(),null) 

				END MENU 

			ELSE 
				MESSAGE l_spaces
				--CALL fgl_winmessage("",l_spaces,"info") #exclamation 

			END IF 

		WHEN l_rec_kandoomsg.msg_ind = "8" #yes OR no 

			LET l_spaces = l_line1 clipped,"\n",l_line2 clipped 
			LET l_ans = fgl_winquestion("", 
			l_spaces, 
			"Yes", 
			"Yes|No", 
			"question",1) 

	END CASE 

	LET int_flag = false 
	LET quit_flag = false  

	#RETURN xlate_to(l_ans)
	RETURN l_ans # modif ericv, if language oher than ENU, this never works... 

END FUNCTION 
##############################################################
# END FUNCTION kandoomsg(p_source_ind, p_msg_num, p_extra_text)
##############################################################


##############################################################
# FUNCTION kandoomsg_coords(p_x,p_y,p_z)
# Moved FROM secufunc.4gl
##############################################################
FUNCTION kandoomsg_coords(p_x,p_y,p_z) 
	## FUNCTION returns window dimensions dependant on line lengths
	DEFINE p_x SMALLINT 
	DEFINE p_y SMALLINT 
	DEFINE p_z SMALLINT 

	DEFINE l_rows_num SMALLINT 
	DEFINE l_cols_num SMALLINT 
	DEFINE l_arr_linelength array[3] OF SMALLINT 

	LET l_arr_linelength[1] = p_x 
	LET l_arr_linelength[2] = p_y 
	LET l_arr_linelength[3] = p_z 
	LET l_rows_num = 0 
	LET l_cols_num = 0 

	FOR p_x = 1 TO 3 
		IF l_arr_linelength[p_x] > 0 THEN 
			LET l_rows_num = l_rows_num + 1 
			IF l_arr_linelength[p_x] > l_cols_num THEN 
				LET l_cols_num = l_arr_linelength[p_x] 
			END IF 
		END IF 
	END FOR 

	LET l_cols_num = l_cols_num + 4 

	RETURN l_rows_num, 
	l_cols_num 
END FUNCTION 
##############################################################
# END FUNCTION kandoomsg_coords(p_x,p_y,p_z)
##############################################################


######################################################################################################
############################################################
# ACCESSOR ml_msgresp
#
# FUNCTION get_msgresp()
# FUNCTION set_msgresp(p_char)
# Was originally a GLOBALS variable glob_msgresp LIKE language.yes_flag,
############################################################
######################################################################################################

##############################################################
# FUNCTION get_msgresp()
##############################################################
FUNCTION get_msgresp() 
	RETURN ml_msgresp 
END FUNCTION 
##############################################################
# END FUNCTION get_msgresp()
##############################################################

##############################################################
# FUNCTION set_msgresp(p_char)
#
#
##############################################################
FUNCTION set_msgresp(p_char) 
	DEFINE p_char CHAR(1) 

	LET ml_msgresp = p_char 
END FUNCTION 
##############################################################
# END FUNCTION set_msgresp(p_char)
##############################################################