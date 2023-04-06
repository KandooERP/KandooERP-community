############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
# MODULE Scope Variables
############################################################
DEFINE modu_rec_toolbarmanageruser LIKE qxt_toolbar.tb_mod_user --used TO remember the user FOR the inline/jit toolbar manager RUN 

############################################################
# FUNCTION setupToolbar()
#
#
############################################################
FUNCTION setuptoolbar() 
	DEFINE l_runstatement STRING 
	DEFINE l_ret SMALLINT 
	DEFINE l_filenamecheck STRING 
	DEFINE l_msg STRING 
	DEFINE l_program_is_valid SMALLINT 

	LET l_ret = 0 
	IF modu_rec_toolbarmanageruser IS NULL THEN 
		OPEN WINDOW wtoolbarmanageruser with FORM "form/toolbar/_qxt_toolbar2_manager_user" attribute(BORDER) 
		WHILE modu_rec_toolbarmanageruser IS NULL 
			INPUT modu_rec_toolbarmanageruser FROM glcurrentuser 
				ON ACTION "CANCEL" 
					LET l_ret = -1 
					EXIT WHILE 
				AFTER INPUT 
					LET l_ret = 1 
			END INPUT 
		END WHILE 
		IF int_flag = true THEN 
			LET int_flag = false 
			CLOSE WINDOW wtoolbarmanageruser 
			RETURN -1 
		END IF 
		CLOSE WINDOW wtoolbarmanageruser 
	END IF 

	LET l_program_is_valid = false #if file exists AND IS executable, we will SET it TO true 

	#------ File format for Windows OS --------------------------------
	IF fgl_arch() = "nt" THEN 
		LET l_filenamecheck = "qxt_toolbar2_manager",".exe" 
		LET l_filenamecheck = trim(l_filenamecheck) 

		#check if file exists
		IF NOT os.path.exists(l_filenamecheck) THEN 
			LET l_msg = "The program file ", trim(l_filenamecheck), " does NOT exist on your application server!" 
			CALL fgl_winmessage("Program does NOT exist",l_msg,"error") 

		ELSE 
			#check if file IS executable
			IF NOT os.path.executable(l_filenamecheck) THEN 
				LET l_msg = "The program file ", trim(l_filenamecheck), " IS NOT executable ! Check your user/file permissions!" 
				CALL fgl_winmessage("Program does NOT executable",l_msg,"error") 

			ELSE 
				#Format & populate run statement
				LET l_program_is_valid = true 
				LET l_filenamecheck = l_fileNameCheck," ", "TB_PROJECT_NAME", "=", trim(get_lasttoolbar_proj_id()), " ", "TB_MODULE_NAME", "=", trim(get_lasttoolbar_prog_id()), " ", "TB_MENU_NAME", "=", trim(downshift(get_lastToolbar_menu_id()))," ", "TB_USER_NAME", "=" , trim(modu_rec_toolbarmanageruser), " " 
				LET l_runstatement = "SET KANDOO_SIGN_ON_CODE=", trim(get_ku_sign_on_code()), " && SET KANDOO_PASSWORD_TEXT=", trim(get_ku_password_text()), " && SET KANDOODB=", trim(get_ku_database_name()), " && ", trim(l_filenamecheck) 
			END IF 

		END IF 

		#------ File format for Linux OS --------------------------------
	ELSE --linux/unix 
		LET l_filenamecheck = trim("qxt_toolbar2_manager") 
		#check if file exists
		IF NOT os.path.exists(l_filenamecheck) THEN 
			LET l_msg = "The program file ", trim(l_filenamecheck), " does NOT exist on your application server!" 
			CALL fgl_winmessage("Program does NOT exist",l_msg,"error") 
		ELSE 
			#check if file IS executable
			IF NOT os.path.executable(l_filenamecheck) THEN 
				LET l_msg = "The program file ", trim(l_filenamecheck), " IS NOT executable ! Check your user/file permissions!" 
				CALL fgl_winmessage("Program does NOT executable",l_msg,"error") 
			ELSE 
				LET l_program_is_valid = true 
				LET l_filenamecheck = l_fileNameCheck," ", "TB_PROJECT_NAME", "=", trim(downshift(get_lasttoolbar_proj_id())), " ", "TB_MODULE_NAME", "=", trim(get_lasttoolbar_prog_id()), " ", "TB_MENU_NAME", "=", trim(downshift(get_lastToolbar_menu_id()))," ", "TB_USER_NAME", "=" , trim(modu_rec_toolbarmanageruser), " " 
				LET l_runstatement = "export KANDOO_SIGN_ON_CODE=", trim(get_ku_sign_on_code()), " && export KANDOO_PASSWORD_TEXT=", trim(get_ku_password_text()), " && export KANDOODB=", trim(get_ku_database_name()), " && ", trim(l_filenamecheck) 
			END IF 
		END IF 
	END IF 
	IF l_program_is_valid THEN 
		#LET l_status = 0
		IF get_debug() THEN 
			DISPLAY "---------------- 270----" 
			DISPLAY "->", trim(l_runStatement), "<-" 
			DISPLAY "get_ku_sign_on_code() = ", get_ku_sign_on_code() #GL_LOGIN_NAME 
			DISPLAY "get_ku_password_text() = ", get_ku_password_text() #GL_LOGIN_PASSWORD 
			DISPLAY "TB_PROJECT_NAME", "=", trim(downshift(get_lasttoolbar_proj_id())) 
			DISPLAY "TB_MODULE_NAME", "=", trim(get_lasttoolbar_prog_id()) 
			DISPLAY "TB_MENU_NAME", "=", trim(downshift(get_lasttoolbar_menu_id())) 
		END IF 

		#CALL run_prog("P91",glob_rec_vendor.vend_code,"","","")
		RUN trim(l_runStatement) 
		# TODO add status validation --alch
	END IF 
END FUNCTION 
############################################################
# END FUNCTION setupToolbar()
############################################################