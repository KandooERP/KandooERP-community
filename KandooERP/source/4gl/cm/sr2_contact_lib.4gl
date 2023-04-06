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

	 $Id$
}


{**
 *
 * Library of common functions
 *
 * @author: Andrej Falout
 *
 *}

############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 
GLOBALS "../cm/sr2_contact_GLOBALS.4gl" 


################################
FUNCTION func_name(calling_func) 
	################################
	DEFINE 
	calling_func 
	CHAR (50) 

	#  CALL FUNC_NAME("FUNC_NAME")
	#THIS FUNCTION MUST NOT HAVE THIS CALL

	LET ex_funcname3 = ex_funcname2 
	LET ex_funcname2 = ex_funcname1 
	LET ex_funcname1 = ex_funcname 
	LET ex_funcname = this_funcname 
	LET this_funcname = calling_func 

	#		EX_FUNCNAME3,       #FUNCTION THAT CALLED EX_FUNCNAME2
	#		EX_FUNCNAME2,       #FUNCTION THAT CALLED EX_FUNCNAME1
	#		EX_FUNCNAME1,       #FUNCTION THAT CALLED EX_FUNCNAME
	#		EX_FUNCNAME,       	#FUNCTION THAT CALLED THIS_FUNCNAME
	#    	THIS_FUNCNAME       #CURRENT FUNCTION NAME

END FUNCTION #func_name() 


#################
FUNCTION trap() 
	#################
	DEFINE 
	l_status, 
	l_isam, 
	l_4gl 
	SMALLINT, 
	l_error_codes, 
	response 
	CHAR (70) 

	LET l_status = status 
	LET l_isam = sqlca.sqlerrd[2] 
	LET l_4gl = sqlca.sqlcode 

	LET sqlca.sqlerrd[2] = 0 
	LET sqlca.sqlcode = 0 
	LET status = 0 


	IF l_status = (-2000) THEN # channel:: cannot OPEN file 
		LET g_trap_status = l_status 
		RETURN 
	END IF 


	LET l_error_codes = 
	"Status = ", l_status, 
	" ISAM = ", l_isam, 
	" 4GL = ", l_4gl 

	OPTIONS MESSAGE line LAST 

	MESSAGE l_error_codes attribute (red) 


	IF 
	d4gl 
	THEN 
		LET g_msg = 
		l_error_codes clipped , "\n", 
		"Do you want TO continue ?" 

		LET response = WinQuerstion("Error:",g_msg,"", "ok|cancel", "exclamation") 

		IF response = "cancel" THEN 
			EXIT program 
		END IF 

	ELSE 
		MENU "Error" 

			BEFORE MENU 
				CALL publish_toolbar("kandoo","contact_lib","menu-Error-1") -- albo kd-513 

			ON ACTION "WEB-HELP" -- albo 
				CALL onlinehelp(getmoduleid(),null) 

			COMMAND "Continue" 
				EXIT MENU 

			COMMAND "Exit" 
				EXIT program 
		END MENU 
	END IF 

	OPTIONS MESSAGE line FIRST + 1 


END FUNCTION #trap() 

######################
FUNCTION msg(msg_text) 
	######################
	DEFINE 
	msg_text 
	CHAR (80) 

	OPTIONS MESSAGE line LAST 
	MESSAGE msg_text clipped attribute (red) 
	OPTIONS MESSAGE line FIRST + 1 

END FUNCTION #msg() 

##################
FUNCTION clr_msg() 
	##################

	OPTIONS MESSAGE line LAST 
	MESSAGE "" 
	OPTIONS MESSAGE line FIRST + 1 

END FUNCTION #msg() 

####################################################
FUNCTION disp_info(buttons) 
	####################################################
	DEFINE 
	result, 
	l_cnt 
	SMALLINT, 
	text_line 
	CHAR(80), 
	buttons 
	CHAR(5) 

	#window with menu will be OPEN at:
	#        AT 19,29
	#            with 2 rows, 15 columns #hight x width
	{
	    OPEN WINDOW w_info_prompt
	        AT 10, 10
	            with 13 rows, 52 columns
	#            WITH FORM "grid"
	                attribute
					    (border, green,
					    menu line last - 1,
						form line first)


		OPEN FORM f_grid FROM "grid"
	    DISPLAY form f_grid
	}
	OPEN WINDOW w_info_prompt with FORM "grid" 
	CALL winDecoration("grid") -- albo kd-766 

	###################
	FOR l_cnt = 1 TO 10 
		###################

		IF length(ga_grid[l_cnt]) > 0 THEN 
			DISPLAY ga_grid[l_cnt] TO grid_d[l_cnt].text 
		END IF 
		#######
	END FOR 
	#######

	CASE buttons 
		WHEN "OK" 
			LET result = ok_window() 
		WHEN "YESNO" 
			LET result = yesno_window() 
		WHEN "OKCAN" 
			LET result = okcan_window() 
		OTHERWISE 
			ERROR "Non existant option:", buttons 
			LET result = okcan_window() 
	END CASE 

	CLOSE WINDOW w_info_prompt 

	RETURN result 

END FUNCTION #disp_info 

####################
FUNCTION ok_window() 
	####################
	{
	    OPEN WINDOW w_ok  -- albo  KD-766
	        AT 19, 33
	            with 2 rows, 5 columns #hight x width
	                attribute
					    (menu line first + 1)
	}
	MENU "" 
		COMMAND "OK " 
			EXIT MENU 
	END MENU 

	--    CLOSE WINDOW w_ok  -- albo  KD-766

	RETURN true 

END FUNCTION #ok_window 


###############################
FUNCTION ask_yes_no(used_lines) 
	###############################
	DEFINE 
	used_lines, 
	cnt 
	SMALLINT 


	IF 
	d4gl 
	THEN 
		# \n stands FOR new line

		INITIALIZE g_msg TO NULL 

		#######################
		FOR cnt = 1 TO used_lines 
			#######################

			LET g_msg = g_msg clipped, #we can also add centering here 
			ga_grid[cnt] clipped, "\n" 

			#######
		END FOR 
		#######

		LET yes = winyesno(g_msg) 
	ELSE 
		CALL clear_grid(used_lines + 1) 
		#	        LET yes = disp_info("YESNO")
		LET yes = yesno_window() 
	END IF 

	RETURN yes 

END FUNCTION #ask_yes_no() 

#######################
FUNCTION yesno_window() 
	#######################
	DEFINE 
	result 
	SMALLINT 
	{
	    OPEN WINDOW w_ok  -- albo  KD-766
	        AT 10, 10
	            with 3 rows, 55 columns #hight x width
	                attribute
					    (border, green, menu line first + 1)
	}
	MENU "Do you want TO EXIT this CMS program ?" 
		COMMAND "YES " 
			LET result = true 
			EXIT MENU 

		COMMAND "NO " 
			LET result = false 
			EXIT MENU 
	END MENU 

	--    CLOSE WINDOW w_ok  -- albo  KD-766

	RETURN result 

END FUNCTION #yesno_window 


#######################
FUNCTION okcan_window() 
	#######################
	DEFINE 
	result 
	SMALLINT 
	WHENEVER ERROR stop 
	{
	    OPEN WINDOW w_ok  -- albo  KD-766
	        AT 19, 33
	            with 2 rows, 5 columns #hight x width
	                attribute
					    (menu line first + 1)
	}
	MENU "" 
		COMMAND "OK " 
			LET result = true 
			EXIT MENU 

		COMMAND "CANCEL " 
			LET result = false 
			EXIT MENU 
	END MENU 

	--    CLOSE WINDOW w_ok  -- albo  KD-766

	RETURN result 

END FUNCTION #okcan_window 


##############################
FUNCTION clear_grid(from_line) 
	##############################
	DEFINE 
	from_line, 
	l_cnt 
	SMALLINT 

	###########################
	FOR l_cnt = from_line TO 10 
		###########################

		LET ga_grid[l_cnt] = "" 

		#######
	END FOR 
	#######

END FUNCTION #clear_grid() 


##############################################
FUNCTION monthacsii2monthnum(tmp_month_ascii) 
	##############################################
	DEFINE 
	tmp_month_ascii 
	CHAR(3), 
	tmp_month_num 
	SMALLINT 

	CASE tmp_month_ascii 
		WHEN "Jan" 
			LET tmp_month_num = 1 
		WHEN "Feb" 
			LET tmp_month_num = 2 
		WHEN "Mar" 
			LET tmp_month_num = 3 
		WHEN "Apr" 
			LET tmp_month_num = 4 
		WHEN "May" 
			LET tmp_month_num = 5 
		WHEN "Jun" 
			LET tmp_month_num = 6 
		WHEN "Jul" 
			LET tmp_month_num = 7 
		WHEN "Aug" 
			LET tmp_month_num = 8 
		WHEN "Sep" 
			LET tmp_month_num = 9 
		WHEN "Oct" 
			LET tmp_month_num = 10 
		WHEN "Nov" 
			LET tmp_month_num = 11 
		WHEN "Dec" 
			LET tmp_month_num = 12 

		OTHERWISE 
			LET g_msg = "Cannot convert month TO num :", tmp_month_ascii clipped 
			#error G_msg
			IF do_debug THEN 

				CALL errorlog (g_msg) 
			END IF 
			LET tmp_month_num = 0 
			#sleep 5
	END CASE 

	RETURN tmp_month_num 

END FUNCTION #monthacsii2monthnum() 


########################
FUNCTION open_database() 
	########################
	DEFINE 
	current_min, 
	start_min, 
	commitsok, #this should be global 
	beginsok 
	SMALLINT, 
	start_time, 
	current_time 
	CHAR(5), 
	prep_stmt 
	CHAR (100), 
	dbname 
	CHAR (16) 


	LET dbname = fgl_getenv("CM_DB") 
	IF dbname IS NULL 
	OR length (dbname) < 2 THEN 
		DATABASE cm 
	ELSE 
		DATABASE dbname 
	END IF 


	# this must be Immediately AFTER the DATABASE OR CONNECT statement:

	        {

	        something IS wrong with this:

			IF
				sqlca.sqlwarn.sqlawarn[1] = "W" #database has logging

	Modification of the sqlca structure
	-----------------------------------
	Informix Dynamic 4GL 2.01 modifies the way the sqlca structure IS handled. This
	IS required because the methods FOR accessing the sqlca fields changed with
	Informix ESQL/C 7.2x.

	Versions of ESQL/C prior TO 7.2x on Windows NT employed the sqlca structure as a
	simple C structure. ESQL/C versions 7.2x AND later use sqlca as a pointer TO a
	FUNCTION call.  This change may have caused VALUES returned by fields accessed
	through the expression "sqlca.*" TO be unpredictable with runners built
	using Dynamic 4GL 2.00 AND ESQL/C 7.2x on Windows NT.

	Below IS a summary of the changes:
	  + access TO the sqlca structure IS replaced by a FUNCTION call
	  + access TO all members of the sqlca structure IS supported FOR most situations:
	    - SQLCODE INT
	    - SQLERRD ARRAY[6] of INT
	    - SQLWARN CHAR(8)
	    - SQLERRM CHAR(71)
	    - SQLERRP CHAR(7)
	  + known unsupported usages are as follows:

	Description                          | Example
	-------------------------------------+---------------------------------
	SUBSTRINGS of SQLERRM AND SQLERRD    | LET xx=SQLERRM[10]
	access TO the full RECORD SQLCA      | LET t.* = sqlca.*
	INIT / INIT LIKE of all members      | INITIALIZE sqlca.code
	CALL FUNCTION RETURNING ...          | CALL d() RETURNING sqlca.code

	Note that the application must be recompiled IF you want TO implement this
	change. IF you do NOT plan TO execute your application on Windows NT using
	ESQL/C 7.2x, you do NOT need TO recompile your p-code applications.



			THEN
			    LET CommitsOK = TRUE
			ELSE
			    LET CommitsOK = FALSE
			END IF

			IF
				sqlca.sqlwarn.sqlawarn[2] <> "W" #ANSI mode database AND BEGIN WORK IS NOT permitted
			THEN
			    LET BeginsOK = TRUE
			ELSE
			    LET BeginsOK = FALSE
			END IF
	        }
	        {

			 IF
			 	sqlca.sqlawarn[4] = "W"
				AND
			    sqlca.sqlawarn[2] = "W"
				AND
			    sqlca.sqlawarn[3] <> "W"
			 THEN
			    LET P_logging = TRUE
			 ELSE
			    LET P_logging = FALSE
			 END IF

	        }

END FUNCTION #open_database() 


##########################################################################
#
#       D4GL - <Suse> specific functions
#
##########################################################################

#################### channel functions ###################################


####################################################
FUNCTION openfile(file_handle, file_name, open_mode) 
	####################################################
	{
	channel::open_file(handle, filename, oflag)
		 CALL channel::set_delimiter("pipe",",")
		 CALL channel::open_file("stream", "fglprofile", "r")

	handle 		CHAR(xx) Unique identifier FOR the specified filename
	filename 	CHAR(xx) Name of the file you want TO OPEN
	oflag 		CHAR(1)
					r Read mode (standard INPUT IF the filename IS empty)
					w Write mode (standard OUTPUT IF the filename IS empty)
					a Append mode: writes AT the END of the file (standard
						OUTPUT IF the filename IS empty)
					u Reads standard read/write on standard INPUT (filename
						must be empty)
	Returns 	None
	}

	DEFINE 
	file_handle, 
	file_name 
	CHAR(100), 
	open_mode 
	CHAR(1) 

	#@huho channel func CALL replacement
	# CALL channel::set_delimiter(file_handle,"")    #no delimiter
	# CALL channel::open_file(file_handle, file_name, open_mode)
	CALL fgl_channel_set_delimiter(file_handle,"") #no delimiter 
	CALL fgl_channel_open_file(file_handle, file_name, open_mode) 

	RETURN channelstatus(STATUS) 

END FUNCTION 


######################################################
FUNCTION openpipe(pipe_handle, exec_string, open_mode) 
	######################################################
	{
	channel::open_pipe(pipe_handle, command, oflag)
	CALL channel::open_pipe("pipe", "ls -l", "r")

	pipe_handle 	CHAR(xx) Unique identifier FOR the specified command
	command 		CHAR(xx) Name of the command you want TO execute
	oflag 			CHAR(1)
						r Read mode
						w Write mode
						a Append mode: writes AT the END of the file
						u Read AND write FROM command (only
							available FOR the UNIX system)
	Returns: 		None
	}

	DEFINE 
	pipe_handle, 
	exec_string 
	CHAR(100), 
	open_mode 
	CHAR(1) 

	#@huho channel func CALL replacement
	# CALL channel::open_pipe(pipe_handle, exec_string, open_mode)
	CALL fgl_channel_open_pipe(pipe_handle, exec_string, open_mode) 

	RETURN channelstatus(STATUS) 

END FUNCTION 




################################
FUNCTION readchanel(handle) 
	################################
	{
	channel::read(handle, buffer-list)

	handle 			CHAR(xx) Unique identifier FOR OPEN channel
	buffer-list 	List of variables, IF you use more than one
					variable, you must enclose the list in brackets
					([ ])
	Returns 		SMALLINT
					TRUE IF data has been read FROM handle;
					FALSE IF an error occurs


	To single var:
		DEFINE buffer CHAR(128)
		LET success = channel::read("pipe_handle", buffer)


	To array:
		DEFINE buffer ARRAY[1024] of CHAR(128)
		DEFINE I INTEGER
		LET I = 1
		WHILE channel::read("pipe_handle", buffer[I])
			LET I = I + 1
		END WHILE
	    IF I > 1 THEN LET success = TRUE ELSE LET success = FALSE END IF

	To record:
		DEFINE buffer RECORD
		Buff1 CHAR(128),
		Buff2 CHAR(128),
		Buff3 INTEGER
		END RECORD
		LET success = channel::read("handle", [buffer.Buff1, buffer.Buff2,
		buffer.Buff3])

	}

	DEFINE 
	handle 
	CHAR(100), 
	success 
	SMALLINT 

	RETURN success 

END FUNCTION 

###########################################
FUNCTION writechannel(handle, write_string) 
	###########################################
	{
	channel::write(handle, buffer_list)

	handle 			CHAR(xx) Unique identifier FOR OPEN channel
	buffer_list 	List of variables; IF you use more than one
					variable, you must enclose the list in brackets
					([ ])
	Returns 		None
	}

	DEFINE 
	handle, 
	write_string 
	CHAR (100) 

	#@huho channel func CALL replacement
	# CALL channel::write(handle, write_string)
	CALL fgl_channel_write(handle, write_string) 

	RETURN channelstatus(STATUS) 

END FUNCTION 

#############################
FUNCTION closechannel(handle) 
	#############################
	DEFINE 
	handle 
	CHAR (100) 
	#@huho channel func CALL replacement
	# CALL channel::close(handle)
	CALL fgl_channel_close(handle) 

	RETURN channelstatus(STATUS) 

END FUNCTION 

##################################
FUNCTION channelstatus(tmp_status) 
	##################################
	DEFINE 
	success, 
	tmp_status 
	SMALLINT 

	CASE tmp_status 
		WHEN (-2000) # cannot OPEN file. 
			LET success = false 
		WHEN (-2001) # unsupported MODE FOR 'open file'. 
			LET success = false 
		WHEN (-2002) # cannot OPEN pipe. 
			LET success = false 
		WHEN (-2003) # unsupported MODE FOR 'open pipe'. 
			LET success = false 
		WHEN (-2004) # cannot write TO unopened file OR pipe. 
			LET success = false 
		WHEN (-2005) # channel write error. 
			LET success = false 
		WHEN (-2006) # cannot read FROM unopened file OR pipe. 
			LET success = false 
		WHEN 0 # no ERROR 
			LET success = true 
		OTHERWISE # some other ERROR !! 
			LET success = false 
	END CASE 

	RETURN success 

END FUNCTION 


########################### END Channel ##################################

########################### Prompt / menu ################################


#############################################################
FUNCTION winquerstion(title, question,default_option, qoptions, icon) 
	#############################################################
	#fgl_winquestion(title, text, default_value, possible_values, icon, danger)
	#LET answer = fgl_winquestion ("Title of the dialog box",
	#		"Question Text", "Yes", "Yes|No|Cancel", "question",1 )
	#icons: Info Exclamation Question Stop

	#Valid OPTIONS:
	#Ok OR
	#Yes|No|Cancel
	#Yes|No
	#Ok|Cancel
	#Ok|Interrupt
	#Abort|Retry|Ignore
	#Retry|Cancel




	DEFINE 
	title, 
	question, 
	qoptions, 
	tmp_qoptions 
	CHAR(100), 

	l_msg 
	CHAR (200), 
	default_option, 
	icon, 
	answer 
	CHAR (20) 

	    {
		LET l_msg = title clipped, " - ",
					question clipped, " - ",
					default_option clipped , " - ",
					Qoptions clipped, " - ",
					icon clipped
	    if do_debug THEN
			CALL errorlog (l_msg)
	    END IF
	    }
	{
	Error - asdlifjiasdf
	 What do you want TO do ? - Ok - Ok|Interrupt - Exclamation

	Error - asdlifjiasdf
	 What do you want TO do ? - Ok - Ok|Interrupt - Exclamation

	Interrupt

	Interrupt
	}


	IF 
	icon IS NULL 
	THEN 
		LET icon = "question" 
	END IF 

	LET icon = downshift(icon) 

	IF title IS NULL THEN 
		LET title = "Question:" 
	END IF 

	IF default_option IS NULL THEN 
		LET default_option = "Yes" 
	END IF 

	IF qoptions IS NULL THEN 
		LET qoptions = "Yes|No" 
	END IF 

	LET tmp_qoptions = downshift (qoptions) 


	IF tmp_qoptions <> "ok" 
	AND tmp_qoptions <> "yes|no|cancel" 
	AND tmp_qoptions <> "yes|no" 
	AND tmp_qoptions <> "ok|cancel" 
	AND tmp_qoptions <> "ok|interrupt" 
	AND tmp_qoptions <> "abort|retry|ignore" 
	AND tmp_qoptions <> "retry|cancel" THEN 
		#ERROR "Non - standard OPTIONS: WinButton" sleep 5
		LET answer = 
		fgl_winbutton (title, question, default_option, qoptions, icon, 1) 
	ELSE 
		#ERROR "Standard OPTIONS: Winquestion" sleep 5
		LET answer = 
		fgl_winquestion (title, question,default_option, qoptions, icon,1 ) 
	END IF 

		{
		LET g_msg = title clipped, " - ",
					question clipped, " - ",
					default_option clipped , " - ",
					Qoptions clipped, " - ",
					icon clipped

	    if do_debug THEN
			CALL errorlog (l_msg)
			CALL errorlog (answer)
	    END IF
	    }

	RETURN answer 

END FUNCTION 


###########################
FUNCTION winyesno(question) 
	###########################
	DEFINE 
	question 
	CHAR (800), 
	answer 
	CHAR (10) 

	LET answer = WinQuerstion("", question,"", "", "") 

	IF answer = "Yes" THEN 
		RETURN true 
	ELSE 
		RETURN false 
	END IF 


END FUNCTION 

####################################
FUNCTION winmessage(title,text,icon) 
	####################################
	# fgl_winmessage (title, text, icon)
	# CALL fgl_winmessage("Title of the MESSAGE", "Text OR variable", "info")

	DEFINE 
	title 
	CHAR(100), 
	text 
	CHAR (200), 
	icon 
	CHAR (10) 

	IF icon IS NULL THEN 
		LET icon = "info" 
	END IF 


	IF title IS NULL THEN 
		LET title = "Information" 
	END IF 

	CALL fgl_winmessage(title,text,icon) 


END FUNCTION 


########################################################
FUNCTION winprompt(x,y,prompt,answer_length,answer_type) 
	########################################################
	{
	fgl_winprompt (x, y, text, default_option, length, type)
	LET answer = fgl_winprompt(5, 2, "your name please", "", 10, 0)


	x, y 		Position of the prompt window
	text 		Text of the question
	default_option 	Not used currently
	length 		Length of the entry
	type 		Type of variable:
					0 CHAR
					1 SMALLINT
					2 INTEGER
					7 INTEGER
	Returns 	Entered value
	}
	DEFINE 
	x, 
	y, 
	answer_type 
	SMALLINT, 
	prompt, 
	answer_length 
	CHAR (100), 
	answer 
	CHAR (20), 
	default_option 
	CHAR(1) 

	IF x IS NULL THEN 
		LET x = 5 
	END IF 

	IF y IS NULL THEN 
		LET y = 2 
	END IF 

	IF answer_type IS NULL THEN 
		LET answer_type = 0 
	END IF 

	IF answer_length IS NULL THEN 
		LET answer_length = 20 
	END IF 

	LET default_option = "" 


	LET answer = 
	fgl_winprompt(x,y,prompt,default_option,answer_length,answer_type) 

	RETURN answer 

END FUNCTION 



########################### END Prompt / menu ############################


######################################
FUNCTION runwinprog(prog,path,do_wait) 
	######################################
	DEFINE 
	prog, 
	path 
	CHAR (100), 
	exec_string 
	CHAR (200), 
	success, 
	do_wait 
	SMALLINT 

	#"\\\\PROGRA~1\\\\INTERN~1\\\\IEXPLORE"
	LET exec_string = #"C:\\\\EXCEL\\\\EXCEL.EXE" 
	path clipped, 
	"/", 
	prog clipped 

	IF 
	do_wait 
	THEN 
		LET success = winexecwait(exec_string) 
	ELSE 
		LET success = winexec(exec_string) 
	END IF 

	RETURN success 


END FUNCTION 


############################
FUNCTION closedbconnection() 
	############################
	{
	This IS FROM manual, but gives syntax error:

		CALL sql:
		sqlexit()

	This also:

		 CALL sql:sqlexit()
	}
	#User Manual
	#Warning: This FUNCTION IS specific TO IBM Informix databases AND should
	#NOT be used FOR portability reasons. Four J’s strongly recommends using the
	#CLOSE DATABASE OR DISCONNECT instructions instead.
	#@huho changed TO DISCONNECT
	# CALL sql::sqlexit()
	CLOSE DATABASE 

END FUNCTION 


###################
FUNCTION ddetest() 
	###################
	DEFINE 
	success 
	SMALLINT, 
	response 
	CHAR (200) 

	#AND can successfully connect:
	LET success = DDEConnect("IEXPLORE","system") 

	#but various types of communication all fail:

	LET success = DDEPoke("IEXPLORE","system","www_OpenURL","http://www.fgss.com") 

	LET response = DDEPeek("IEXPLORE","system","www_GetWindowInfo") 

END FUNCTION 

{

The following IS an example WHERE the 4gl application creates a
connection TO word97 thru DDE. The FUNCTION letter() writes data FROM
two global records, p_custom AND p_user TO ms-word TO create the start
AND ending of a standard letter. The FUNCTION word_exe() IS the FUNCTION
that sends the data TO ms-word. Remark the CALL TO FUNCTION
fgl_strtosend() before calling the DDE FUNCTION.
}

#################
FUNCTION letter() 
	#################
	DEFINE wordstr CHAR(512), 
	language CHAR(10), 
	winwordpath, 
	err_mess CHAR(100) 

	DEFINE ms_insert_text CHAR(10), 
	ms_right_para CHAR(40), 
	ms_left_para CHAR(40), 
	ms_insert_date CHAR(50), 
	ms_normal_font CHAR(30), 
	ms_bold_font CHAR(30), 
	result SMALLINT 


	LET winwordpath = "C:\\\\Progam Files\\\\Microsoft Office\\\\Office\\\\Winword.exe" 
	LET language = "en_us" 

	IF language = "en_us" THEN 
		LET ms_insert_text = "INSERT" 
		LET ms_insert_date = "insertDateTime" 
		LET ms_right_para = "formatParagraph .alignment=2" 
		LET ms_left_para = "formatParagraph .alignment=0" 
		LET ms_bold_font = "formatFont .bold=1" 
		LET ms_normal_font = "formatFont .bold=0" 
	END IF 
	IF language = "da_dk" THEN 
		LET ms_insert_text = "indst" # @huho here were code PAGE issues 
		LET ms_insert_date = "indstDatoTid .datoTidFormat=\" d. MMMMyyyy\"" 
		LET ms_right_para = "hjreAfsnit" 
		LET ms_left_para = "venstreAfsnit" 
		LET ms_bold_font = "formatSkrifttype .fed=1" 
		LET ms_normal_font = "formatSkrifttype .fed=0" 
	END IF 

	LET result = winexec(winwordpath) 
	IF NOT result THEN 
		CALL fgl_winmessage("MS Word Start Up Error", "MS Word could NOT be started.\nMaybe wrong path?", "stop") 
		RETURN 
	END IF 

	LET result = DDEConnect("WINWORD", "System") 
	IF NOT result THEN 
		ERROR "DDEConnect: ", err_mess 
		CALL fgl_winmessage("MS Word DDE Connect Error", err_mess, "stop") 
		RETURN 
	END IF 

	{ commented out because undefined variables:

	-- write customer name AND adress in upper left corner
	  CALL word_exe(ms_insert_text, p_custom.name, 1)
	  IF p_firmaopl.afdeling IS NOT NULL THEN
	    CALL word_exe(ms_insert_text, p_custom.dept, 1)
	  END IF
	  CALL word_exe(ms_insert_text, p_custom.street, 1)
	  LET wordstr = p_firmaopl.postnr clipped, "  ", p_custom.zipcode clipped
	  CALL word_exe(ms_insert_text, wordstr, 2)
	  CALL word_exe(ms_bold_font,"",0)
	  LET wordstr = "Att.: ", p_custom.contact clipped
	  CALL word_exe(ms_insert_text, wordstr, 1)
	  CALL word_exe(ms_normal_font,"",0)
	-- write today's date right aligned
	  CALL word_exe(ms_insert_text, "",1)
	  CALL word_exe(ms_right_para,"",0)
	  CALL word_exe(ms_insert_date, "",0)
	  CALL word_exe(ms_insert_text, "",1)
	  LET wordstr = "Our ref: ", p_user.initials clipped
	  CALL word_exe(ms_insert_text,wordstr,1)
	  CALL word_exe(ms_insert_text, "",1)
	-- back TO left aligned text
	  CALL word_exe(ms_left_para,"",0)
	  CALL word_exe(ms_insert_text, "",5)
	  CALL word_exe(ms_insert_text, "Best regards",1)
	  CALL word_exe(ms_insert_text, "Avenir Danmark A/S",4)
	  CALL word_exe(ms_insert_text, p_user.name, 1)
	  CALL word_exe(ms_insert_text, p_user.titel, 1)

	}


END FUNCTION 


########################################
FUNCTION word_exe(cmd, txt, nl) 
	########################################
	DEFINE cmd CHAR(80), 
	txt CHAR(512), 
	str CHAR(512), 
	nl SMALLINT, 
	err_mess CHAR (50), 
	result SMALLINT 

	LET str = cmd clipped 
	IF txt IS NOT NULL OR nl > 0 THEN 
		LET str = str clipped, " \"", txt clipped 
		WHILE nl > 0 
			LET str = str clipped, ascii 13 
			LET nl = nl - 1 
		END WHILE 
		LET str = str clipped, "\"" 
	END IF 

	#@huho - I can only guess what this legacy bds FUNCTION does
	#cound NOT find any information via google OR bds docs
	# CALL fgl_strtosend(str) returning str
	{
	#Le's assume it does some string cleaning ??? trim ? no idea..
		 CALL fgl_winmessage(str,"fgl_strtosend(str)\unknown functions - needs checking what it should do","info")
	   LET str = trim(str) #fgl_strtosend(str) returning str

	}
	LET result = DDEexecute("WINWORD", "System", str) 
	IF NOT result THEN 
		MESSAGE "DDEexecute: ", err_mess 
		RETURN 
	END IF 
END FUNCTION 



#This example puts an image button in the RH corner:
#WHEN you click on the button, it will generate
#a F35 key event.
#However, as far as I know, the bitmaps are NOT scaleable.
#So you will need TO adjust bitmap TO correct size.
#(And don't change your font size!).
#Take a look AT menuicon.per

##############################
FUNCTION logo() 
	##############################

	### DISPLAY Web Logo ###
	#    IF g_GUI
	#    THEN
	OPEN WINDOW w_icon with FORM "menuicon" 
	CALL winDecoration("menuicon") -- albo kd-766 
	DISPLAY "!" TO www 
	CURRENT WINDOW IS screen 
	#    END IF
END FUNCTION 



#________________________________________________________________


####################		FOR EXCEL :
FUNCTION for_excel() 
	####################

	DEFINE err_flag SMALLINT 
	DEFINE p_text CHAR(128) 



	#TO  OPEN Excel :
	CALL WinExec("C:\\\\MSOffice\\\\EXCEL.EXE") RETURNING err_flag 
	#Evidemment, il faut mettre le chemin exact ou se trouve EXCEL sur sa machine...
	#put the exact path TO excel on your machine

	#Pour ouvrir Excel avec un fichier existant :
	#FOR opening excel with an existing file :
	CALL WinExec("C:\\\\MSOffice\\\\EXCEL.EXE c:\\\\Files\\\\test.xls") RETURNING err_flag 

	IF NOT err_flag THEN 
		DISPLAY "WinExec : '", err_flag clipped, "'" 
		EXIT program 
	END IF 

	#Pour se connecter au serveur DDE :

	CALL DDEConnect("EXCEL","Feuil1") RETURNING err_flag 
	#Feuil1 represente le nom de la feuille du classeur EXCEL dans laquelle on travaille.
	#Feuil1 IS the name of the cell WHERE you are working

	IF NOT err_flag THEN 
		DISPLAY "DDEConnect : '", err_flag clipped, "'" 
		EXIT program 
	END IF 

	#Cet exemple permet de remplir des cases EXCEL en colonne (si ces cases etaient contigues, il aurait fallu utiliser des \t (tabulations) au lieu des \n (retour chariot)) :
	LET p_text = "12\\n13\\n14\\n15" 
	LET err_flag = DDEPoke("EXCEL", "Feuil1", "L12C2:L15C2", p_text) 
	#Update it FOR the german Excel
	IF NOT err_flag THEN 
		DISPLAY "DDEPoke : '", err_flag clipped, "'" 
		LET p_text="" 
		LET p_text = ddegeterror() 
		DISPLAY "Erreur : ", p_text clipped 
		EXIT program 
	END IF 
	#Note : dans une version anglaise du pack office, il aurait fallu taper R12:C2:R15C2 au lieu de L12C2:L15C2. (L = Ligne, R = Row...).

	CALL ddefinishall() 

END FUNCTION 



####################	FOR WINWORD :
FUNCTION for_word() 
	####################

	DEFINE err_flag SMALLINT 
	DEFINE p_text CHAR(128) 


	#TO  OPEN WORD :
	LET err_flag = WinExec("C:\\\\MSOffice\\\\WINWORD.EXE") 
	IF NOT err_flag THEN 
		DISPLAY "WinExec : '", err_flag clipped, "'" 
		EXIT program 
	END IF 

	#Pour se connecter au serveur DDE :
	LET err_flag = DDEConnect("WINWORD","system") 
	IF NOT err_flag THEN 
		DISPLAY "DDEConnect : '", err_flag CLIPPED,"'" 
		EXIT program 
	END IF 

	#TO  OPEN a  new doc WORD :
	LET p_text = "FileNew" 
	LET err_flag = DDEExecute("WINWORD", "system", p_text clipped) 
	IF NOT err_flag THEN 
		DISPLAY "DDEExecute : '", err_flag CLIPPED,"'" 
		EXIT program 
	END IF 

	LET p_text = "Insert \\\"This IS a little test TO SHOW how you can add text in an existing word file USING the dde. \\\"" 
	LET err_flag = DDEExecute("WINWORD", "system", p_text clipped) 
	IF NOT err_flag THEN 
		DISPLAY "DDEExecute : '", err_flag CLIPPED,"'" 
		EXIT program 
	END IF 

	#Pour ouvrir un document existant :
	#TO OPEN an existing file :
	LET p_text = "FileOpen Name:=\\\"C:\\\\Home\\\\BDL\\\\Temp\\\\FOURJDDE.doc\\\"" 
	LET err_flag = DDEExecute("WINWORD", "system", p_text) 
	IF NOT err_flag THEN 
		DISPLAY "DDEExecute : '", err_flag CLIPPED,"'" 
		EXIT program 
	END IF 

	CALL ddefinishall() 

END FUNCTION 


{
I SET out below an example of a program that opens a named MS Word
document AND passes three characters strings TO 3 seperate bookmarks in
the opened Word document.

Strings containing characters such as \ need TO be passed through
fgl_strtosend() as this re-formats them so that MS Word will see the
correct sring.

There are numerous examples of how TO poke data INTO Excel that are easy
TO SET up so I won't mention this here, other than TO say the same
principles as poking data INTO Word apply except you reference cells of
the worksheet rather than bookmarks.

John Rooke
Director
L&P Systems Limited
john.rooke@lpsystems.com

}

##### EXAMPLE DDE CODE FOR MS WORD #####
######################
FUNCTION dde_example() 
	######################
	DEFINE 
	run_cmd CHAR( 100 ), 
	progname CHAR( 500 ), 
	topic CHAR( 500 ), 
	fileopen CHAR( 500 ), 
	var CHAR( 100 ), 
	dde_timeout SMALLINT, 
	counter SMALLINT, 
	result SMALLINT 




	LET progname = "winword" 
	LET topic = "g:\\john\\test.doc" 
	LET dde_timeout = 10 

	# IF Word IS NOT already running, start it up now...
	LET result = ddeconnect( progname, "System" ) 

	IF result = false THEN 
		LET run_cmd = "OpenDoc winword" 
		RUN run_cmd 
	END IF 

	# Close the initial DDE channel TO Word as we will need it again later
	LET var = ddefinish( progname, "System" ) 

	# DEFINE the mail-merge template file TO OPEN using WordBasic TO maintain compatibility
	# between MS Office versions...
	LET fileopen = 'fileopen .Name="g:\\john\\test.doc"' 

	# Parse the string INTO FORMAT required FOR DDE
	#@huho fgl_strtosend() NOT supported
	# LET fileopen = fgl_strtosend( fileopen )
	CALL fgl_winmessage("fgl_strtosend()","fgl_strtosend()","info") 
	LET fileopen = trim(fileopen ) 
	# Open up the file in Word

	LET counter = 0 

	WHILE ddeconnect( progname, "System" ) = false 
		IF counter > dde_timeout THEN 
			ERROR "Timeout on initiation of DDE conversation with Microsoft Word. Contact your System Administrator." 
			RETURN 
		END IF 

		LET counter = counter + 1 
		SLEEP 1 
	END WHILE 

	LET var = ddeexecute( progname, "System", fileopen clipped ) 
	LET var = ddefinish( progname, "System" ) 

	# Parse the DDE topic string INTO FORMAT required FOR DDE
	#@huho fgl_strtosend() NOT supported
	#	 LET topic = fgl_strtosend( topic )
	CALL fgl_winmessage("fgl_strtosend()","fgl_strtosend()","info") 
	LET topic = trim( topic ) 

	# Pass parameters TO Word. These will be inserted in the appropriate
	# bookmark fields in Word.
	LET var = ddeconnect( progname clipped, topic clipped ) 
	LET var = ddepoke( progname, topic, "listitems", "String_1" ) 
	LET var = ddepoke( progname, topic, "test", "String_2" ) 
	LET var = ddepoke( progname, topic, "test1", "String_3" ) 
	LET var = ddefinish( progname, topic ) 

END FUNCTION 

########################
FUNCTION client_type() 
	########################
	{
	> Is there a way FOR me TO determine AT runtime the client version I am
	running
	> AND the version of server TO which I am connecting?

	Yes (assuming your server IS 7.x)
	}

	DEFINE str CHAR (2000) 

	LET str = 
	"SELECT dbinfo( 'version', 'full' ) server, ", 
	"scb_feversion client ", 
	" FROM sysmaster:syssqscb ", 
	" WHERE scb_sessionid = dbinfo( 'sessionid' );" 

	#PREPARE soq FROM str
	EXECUTE immediate str 



END FUNCTION 


##########################
FUNCTION server_version() 
	##########################
	DEFINE str CHAR (2000) 

	SELECT owner FROM systables WHERE tabname = ' version'; 
	#(Note that there IS a blank before VERSION).
	#Does anyone know IF you can use a sql statement TO get the version of the
	#informix server that IS running?


	LET str = 
	"SELECT owner FROM sysmaster:systables WHERE tabid = 99;" 
	EXECUTE immediate str 

	#This should work as the owner of table 99 (tabname: " VERSION")
	#contains the version (minus the platform letter: U, T, F) that created
	#the database AND the creator of the SYSMASTER database IS always the
	#current version.

	#OR:
	#Try dbinfo FUNCTION FOR getting Informix version. I do NOT know that in
	#all the version it's supported OR NOT but 7.31 does. I read in release
	#notes of 7.31



END FUNCTION 

#calculate the square root of a number
{bad !
FUNCTION sq_root(x)

DEFINE
 x		float,
 number 	float, 	# number TO find sqrt of
 guess 		float, 	# contains answer AT end
 variance 	float 	# How close are we variable


LET number = x

 LET guess = 1 	# initial guess
 LET variance = 1	# big initial variance
 WHILE variance > .0000001
 	LET variance = (guess * guess) - number
 	IF variance < 0 THEN
 		LET variance = variance * -1 # make positive
	END IF
	LET guess = (guess + (number / guess)) / 2
 END WHILE

 RETURN guess

END FUNCTION
}



{
MAIN

     DEFINE d FLOAT
     DEFINE r FLOAT
     DEFINE s FLOAT

     LET d = 1e-30
     WHILE d < 1e+30
         LET r = sq_root(d)
         LET s = r * r
         DISPLAY "value = ", d, ", root = ", r, ", sqr = ", s
         LET d = d * 1.0001e5
     END WHILE

 END MAIN
}


########################
FUNCTION sq_root(x) 
	########################

	DEFINE 
	x FLOAT, 
	number FLOAT, # number TO find sqrt OF 
	guess FLOAT, # contains answer at END 
	variance FLOAT # how CLOSE are we variable 

	LET number = x 

	LET guess = 1 # initial guess 
	LET variance = (guess * guess) - number # initial variance 
	IF variance < 0 THEN 
		LET variance = -variance # make positive 
	END IF 

	WHILE variance / number > 0.0000001 
		IF variance < 0 THEN 
			LET variance = -variance # make positive 
		END IF 
		LET guess = (guess + (number / guess)) / 2 
		LET variance = (guess * guess) - number 
	END WHILE 

	RETURN guess 
END FUNCTION 





################################################################### EOF

