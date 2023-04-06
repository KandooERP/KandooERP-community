###################################################################################
# GLOBALS
###################################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

DEFINE modu_newsessionid LIKE qxt_log_login.session_id 
DEFINE modu_logindt DATETIME year TO second 
##############################################################################
FUNCTION lib_login_whenever_sqlerror ()
    # this code instanciates the default sql errors handling for all the code lines below this function
    # it is a compiler preprocessor instruction. It is not necessary to execute that function
    WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
END FUNCTION


###################################################################################
# FUNCTION login_rec_kandoouser()
#
#
###################################################################################
FUNCTION login_rec_kandoouser() 
	--DEFINE l_cl_co SMALLINT HuHo 24.09.2020: not used 
	--DEFINE l_count INTEGER HuHo 24.09.2020: not used
	--DEFINE l_catpass CHAR(20) HuHo 24.09.2020: not used 
	DEFINE l_rec_kandoouser RECORD LIKE kandoouser.* 
	DEFINE l_record_found SMALLINT 
	--DEFINE l_msg STRING HuHo 24.09.2020: not used 
	DEFINE l_listboxuser STRING --for lazy login 
	--DEFINE l_language VARCHAR(20) HuHo 24.09.2020: not used 

	INITIALIZE l_rec_kandoouser.* TO NULL 
	OPEN WINDOW kandoo_login with FORM "form/kandoo_login" attribute (BORDER,STYLE="full-SCREEN") #, FORM line 1, MESSAGE line 1, PROMPT line 1) 
	#CALL fgl_settitle("Login") 
	# Add some default user authentication VALUES TO make it simpler FOR ANY testers	/ REMOVE IT LATER
	LET l_rec_kandoouser.sign_on_code = "Guest" 
	LET l_rec_kandoouser.password_text = "Guest" 
	LET l_listboxuser = "Guest" 
	# CALL PopulateLangCombo()   #huho currently NOT really used.. we need TO decide if we let the user choose the language as it would be a big translation job

	INPUT
		l_rec_kandoouser.sign_on_code, 
		l_rec_kandoouser.password_text,
		l_listboxuser WITHOUT DEFAULTS 
	FROM 
		users.username, 
		users.password,
		listboxuser	ATTRIBUTE(UNBUFFERED) 
	
		ON CHANGE listboxuser #NOTE: Lazy login requires PW = Login name
			LET l_rec_kandoouser.sign_on_code = l_listboxuser 
			LET l_rec_kandoouser.password_text = l_listboxuser
			 
		ON ACTION actlazylogin 
			LET l_rec_kandoouser.sign_on_code = l_listboxuser 
			LET l_rec_kandoouser.password_text = l_listboxuser 
			
		ON ACTION "CANCEL" 
			#CALL fgl_winmessage("Exit","User abborted authentication","ERROR")
			EXIT program 
			
		AFTER INPUT 
			IF int_flag = true THEN 
				CALL fgl_winmessage("Exit Application","User selected CANCEL in login dialog","info") 
				EXIT program 
			ELSE 
				IF main_authenticated_kandoouser_and_set_globals(l_rec_kandoouser.sign_on_code, l_rec_kandoouser.password_text) <= 0 THEN 
					CONTINUE INPUT 
				ELSE 
					IF NOT init_kandoouser_environment() THEN
						CONTINUE INPUT
					END IF 
				END IF 
			END IF 
	END INPUT #---------------------------------------- 
	
	IF int_flag = true THEN 
		RETURN false 
	END IF
	 
	CLOSE WINDOW kandoo_login
	 
	IF get_debug() = true THEN 
		DISPLAY "--------------------------- login_rec_kandoouser() RETURN TRUE ----------------------------------------" 
		DISPLAY "l_rec_kandoouser.sign_on_code: ", trim(l_rec_kandoouser.sign_on_code) 
		DISPLAY "l_rec_kandoouser.password_text: ", trim(l_rec_kandoouser.password_text) 
	END IF 

	RETURN true 
END FUNCTION 
###################################################################################
# END login_rec_kandoouser()
#
#
###################################################################################


###################################################################################
#FUNCTION registerLoginData()
#
###################################################################################
FUNCTION registerlogindata() 
	DEFINE chan_obj base.channel 
	DEFINE ostype STRING 
	DEFINE logrec RECORD LIKE qxt_log_login.* 
	DEFINE input_pipe CHAR(20) 

	#	DISPLAY "registerLoginData()"
	INITIALIZE logrec.* TO NULL 
	
	LET logrec.session_id=0 
	LET logrec.sign_on_code = get_ku_sign_on_code() 
	LET logrec.logindt = CURRENT day TO second 
	LET modu_logindt = logrec.logindt 
	LET chan_obj = base.channel.create() 

	CALL ui.Interface.frontCall("standard", "feinfo", "ostype", ostype) --get operating system 

	IF get_debug() = true THEN 
		DISPLAY "---------------------------584--------------------------------------------" 
		DISPLAY "registerlogindata() - channel" 
		DISPLAY "BEFORE CHANNEL" 
		DISPLAY "-----------------------------------------------------------------------" 
		DISPLAY "sign_on_code=", trim(get_ku_sign_on_code()) 
		DISPLAY "osType =", trim(osType) 
		DISPLAY "logRec.session_id =", logrec.session_id 
		DISPLAY "logRec.sign_on_code =", logrec.sign_on_code 
		DISPLAY "logRec.logindt =", logrec.logindt 
		DISPLAY "logRec.logoutdt =", logrec.logoutdt 
		DISPLAY "logRec.client_host_name =", logrec.client_host_name 
		DISPLAY "logRec.client_host_ip_address =", logrec.client_host_ip_address 
		DISPLAY "logRec.server_session_id =", logrec.server_session_id 
		CALL debuginformation() 
	END IF 

	LET ostype = ostype.touppercase() 

	IF ostype = "WINDOWS" THEN 
		LET input_pipe = "hostname" 

		CALL chan_obj.openpipe(input_pipe , "r") 
		CALL chan_obj.read(logrec.client_host_name) #crash here 
		CALL chan_obj.openFile("stream","w") 
		CALL chan_obj.write(logrec.client_host_name) 
		CALL chan_obj.close() 

	ELSE 

		# running on Unix/Linux
		LET input_pipe = "uname -n" 
		CALL chan_obj.openpipe(input_pipe, "r") 
		CALL chan_obj.read(logrec.client_host_name) 
		CALL chan_obj.openFile("stream","w") 
		CALL chan_obj.write(logrec.client_host_name) 
		CALL chan_obj.close() 
	END IF 

	IF get_debug() = true THEN 
		DISPLAY "---------------------------632--------------------------------------------" 
		DISPLAY "registerlogindata() - channel" 
		DISPLAY "AFTER CHANNEL" 
		DISPLAY "-----------------------------------------------------------------------" 
		DISPLAY "osType =", trim(osType) 
		DISPLAY "logRec.session_id =", logrec.session_id 
		DISPLAY "logRec.sign_on_code =", logrec.sign_on_code 
		DISPLAY "logRec.logindt =", logrec.logindt 
		DISPLAY "logRec.logoutdt =", logrec.logoutdt 
		DISPLAY "logRec.client_host_name =", logrec.client_host_name 
		DISPLAY "logRec.client_host_ip_address =", logrec.client_host_ip_address 
		DISPLAY "logRec.server_session_id =", logrec.server_session_id 
		CALL debuginformation() 
	END IF 

	# Get client pc IP address FOR qxt_log_login.client_host_ip_address
	LET logrec.client_host_ip_address = fgl_getenv("QX_CLIENT_IP") 
	# get data FOR qxt_log_login.server_session_id
	LET logrec.server_session_id = fgl_getenv("QX_SESSION_ID") 
	# Check on existent session ID

	SELECT 1 FROM qxt_log_login WHERE server_session_id = logrec.server_session_id 
	WHENEVER ERROR CONTINUE 
	INSERT INTO qxt_log_login VALUES (logRec.*) 
	WHENEVER ERROR stop 
	LET modu_newsessionid = sqlca.sqlerrd[2] --serial id OF the new RECORD in qxt_log_login TABLE 

	# Also update user record last login date
	IF glob_rec_kandoouser.cmpy_code != "99" THEN 

		WHENEVER ERROR CONTINUE 

		UPDATE kandoouser 
		SET sign_on_date = today() 
		WHERE sign_on_code = glob_rec_kandoouser.sign_on_code 
		AND cmpy_code = glob_rec_kandoouser.cmpy_code 

		WHENEVER ERROR stop 

		IF status < 0 THEN 
			ERROR "Could not update login date in kandoouser table" 
		END IF 
	END IF 

	RETURN true 
END FUNCTION 
###################################################################################
#END FUNCTION registerLoginData()
####################################################################################


####################################################################################
#FUNCTION registerprogramm(recmenuitem) 
#
#Register run program
####################################################################################
FUNCTION registerprogramm(recmenuitem) 
	DEFINE recmenuitem RECORD LIKE qxt_menu_item.* 

	INSERT INTO qxt_log_run VALUES (
		0,
		modu_newsessionid,
		recMenuItem.mb_id,
		GL_LOGIN_USER_ID,
		current year TO fraction) 
END FUNCTION 
####################################################################################
#END FUNCTION registerprogramm(recmenuitem) 
####################################################################################


####################################################################################
# FUNCTION debugInformation()
#
#
####################################################################################
FUNCTION debuginformation() 
	DISPLAY "##################### DEBUG INFORMATION #####################" 
	DISPLAY "sign_on_code = ", get_ku_sign_on_code() 
	DISPLAY "password_text = ", get_ku_password_text() 
	DISPLAY "name_text = ", get_ku_name_text() 
	DISPLAY "group_code = ", get_ku_group_code() 
	#DISPLAY "menu_group_code =",
END FUNCTION 
####################################################################################
# END FUNCTION debugInformation()
####################################################################################


####################################################################################
# FUNCTION db_session_info()
#
#
####################################################################################
FUNCTION db_session_info() 
	DEFINE l_db_type CHAR(3) 
	DEFINE l_session_info RECORD 
		sid INTEGER, # informix session id
		user_name char(32),	# username of the session
 		pid INTEGER, # app server process id 
		login_timestamp DATETIME year TO second ,	# timestamp at which the session started
		database_name CHAR(128)		# current database name
	END RECORD 

	# set the flag continue_program_on_error to false: if the error handler fires, the program cannot continue
	LET continue_program_on_error = false
	LET l_db_type = db_get_database_type() 

	CASE l_db_type 
		WHEN "IFX" 
			#"Informix Database"
			# take the informix session number AND main session information
			SELECT dbinfo('sessionid') 
			INTO l_session_info.sid 
			FROM systables 
			WHERE tabid = 1 
			--IF l_session_info.sid <> 0 THEN
				SELECT username,pid,dbinfo("utc_to_datetime",connected) 
				INTO l_session_info.user_name,l_session_info.pid,l_session_info.login_timestamp 
				FROM sysmaster:syssessions 
				WHERE sid = l_session_info.sid 
				
				SELECT odb_dbname INTO l_session_info.database_name
				FROM sysmaster:sysopendb
				WHERE odb_sessionid = l_session_info.sid
				AND odb_dbname NOT MATCHES "sys*"
				LET session_info.* = l_session_info.*
			--END IF
		WHEN "ORA" 
			#"Oracle Database"
		WHEN "MSV" 
			#"MS-SQL Server Database"
		WHEN "DB2" 
			#"DB2 Database"
		WHEN "MYS" 
			#"My SQL Database"
		WHEN "PGS" 
			#"PostgreSQL Database"
		WHEN "PEV" 
			#"Pervasive Database"
		WHEN "MDB" 
			#"MAXDB (SAP-MySQL) Database"
		WHEN "SYB" 
			#"Sybase Database"
		WHEN "FIB" 
			#"Firebird Database"
		WHEN "ADB" 
			#"Adabase Database"
		OTHERWISE 
			#"Unknown"
	END CASE 

END FUNCTION 
####################################################################################
# END FUNCTION db_session_info()
####################################################################################