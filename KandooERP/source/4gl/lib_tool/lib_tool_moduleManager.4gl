###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
 
###########################################################################
# MODULE Scope Variables
############################################################
DEFINE modu_module_id STRING --module/program NAME 
DEFINE modu_prog_id STRING #first program sub-module-id when the program was launched (set by the very first set_module_id(xxx) call usually done in main()
###########################################################################

###########################################################################
# FUNCTION setModuleId(p_moduleId)
#
# this IS called for each program. The moduleId IS CURRENTLY the program name without file extension i.e. A11
# Reason TO do it in this way, that there are plans TO change the program names TO more understanding FORMAT
# If/When this IS done later, one would need TO change the code for teh 1500 programs as arg() would no loner help use here
#
###########################################################################
# Module ID/Name Accessor
FUNCTION setmoduleid(p_moduleid) 
	DEFINE p_moduleid STRING 
	DEFINE msg STRING 
	DEFINE i SMALLINT 
	DEFINE log_file STRING
	DEFINE log_dir STRING

	IF p_moduleid IS NULL THEN 
		LET msg = "Invalid Argument passed TO FUNCTION setModuleId() - p_moduleID = ", p_moduleid 
		CALL fgl_winmessage("Internal Error - Invalid argument in setModuleId()",msg,"ERROR") 
	ELSE 
		LET modu_module_id = p_moduleid
		LET glob_rec_prog.module_id = trim(p_moduleid) 
		#		# take the informix session number AND main session information
		#		SELECT DBINFO('sessionid')
		#		INTO session_info.sid
		#		FROM systables
		#		WHERE tabid = 1
		#
		#		SELECT pid,dbinfo("utc_to_datetime",connected)
		#		INTO session_info.pid,session_info.login_timestamp
		#		FROM sysmaster:syssessions
		#		WHERE sid = session_info.sid
	END IF 

	#CALL displaymoduletitle(NULL) can not be done here.. in most cases, the window/form is not open at this time


	#Also set the parent module id if not already set.
	#NOTE: kandoo menu (kandooerp.exe) is never counted as a parent! 
	IF modu_prog_id IS NULL THEN
		LET modu_prog_id = modu_module_id
		LET glob_rec_prog.prog_id = trim(glob_rec_prog.module_id) 
	END IF
	
	#Example : RUN "PA0 CHILD_RUN_ONCE=TRUE MODULE_CHILD=PA2"
	#Example 2: RUN "PA0" -> will show the menu PA0 and the user can select any of the PA reports to generate
	CASE #CHILD_RUN_ONCE=TRUE  AND MODULE_CHILD=PA2 (example)
		WHEN (get_url_child_run_once_only() = TRUE) AND (get_url_module_child() IS NOT NULL) 
-- 			CALL interface.setText(getmenuitemlabel(getmoduleid()))
 			CALL ui.Interface.setText(getmenuitemlabel(getmoduleid()))
 	END CASE 
 		
--	 LET log_dir = fgl_getenv("KANDOO_LOG_PATH")
--	 LET log_file = log_dir,"/",glob_rec_prog.prog_id,".log"
--	 --CALL startlog(get_settings_logPath_forFile(log_file)) 
--	 CALL startlog(set_settings_logPath(log_file))

END FUNCTION 
###########################################################################
# END FUNCTION setModuleId(p_moduleId)
###########################################################################


###########################################################################
# FUNCTION get_prog_id() / FUNCTION set_parent_module_id() 
#
# Accessor Methods for glob_moduleId
# Program name without file extension
# DEFINE glob_moduleId STRING --Module/Program Name
###########################################################################
FUNCTION get_prog_id() 

	RETURN modu_prog_id 
END FUNCTION 
###########################################################################
# END FUNCTION get_prog_id() / FUNCTION set_parent_module_id() 
###########################################################################
 

###########################################################################
# FUNCTION get_glob_moduleId() / set_glob_moduleId()
#
# Accessor Methods for glob_moduleId
# Program name without file extension
# DEFINE glob_moduleId STRING --Module/Program Name
###########################################################################
FUNCTION get_module_id() #replaces getmoduleid()

	RETURN modu_module_id 
END FUNCTION

FUNCTION getmoduleid() #will be dropped 

	RETURN modu_module_id 

END FUNCTION 
###########################################################################
# END FUNCTION get_glob_moduleId() / set_glob_moduleId()
###########################################################################


###########################################################################
# FUNCTION getModuleState(p_module)
#
# Validates, if the module group is enabled for this company "1st LETTER of the module name defines the module group"
###########################################################################
FUNCTION getmodulestate(p_module) 
	DEFINE p_module CHAR(1) 
	DEFINE l_module_string STRING 
	DEFINE i SMALLINT 
	DEFINE ret boolean 

	LET l_module_string = glob_rec_company.module_text 
	LET ret = false 
	FOR i = 1 TO l_module_string.getlength() 
		IF l_module_string[i] = p_module THEN 
			LET ret = true 
			EXIT FOR 
		END IF 
	END FOR 

	RETURN ret 
END FUNCTION 
###############################################################
# END FUNCTION getModuleState(p_module)
###############################################################


###############################################################
# FUNCTION initDatabaseConnection()
###############################################################
FUNCTION initdatabaseconnection() 

	# 1. Program Argument
	# 2. Environment
	# 3. Default

	IF fgl_getenv("KANDOODB") IS NOT NULL THEN 
		CALL set_db(fgl_getenv("KANDOODB")) 
		MESSAGE "Environment kandoodb - DB Database: " , trim(get_db()) 
		CALL qxt_connectdbtool(get_db()) 
	ELSE 
		CALL set_db("kandoodb") --default DATABASE 
		MESSAGE "Default kandoodb - DB Database: " , trim(get_db()) 
		CALL qxt_connectdbtool(get_db()) 
	END IF 

END FUNCTION 
###############################################################
# FUNCTION initDatabaseConnection()
###############################################################


###############################################################
# FUNCTION qxt_connectDb(p_dbName)
###############################################################
FUNCTION qxt_connectdb(p_dbname) 
	DEFINE p_dbname CHAR(64), 
	l_sqlr SMALLINT, 
	l_retval SMALLINT, 
	l_retmsg VARCHAR(200) 

	WHENEVER ERROR CONTINUE 
	DATABASE p_dbname 
	LET l_retval = status 
	LET l_sqlr = sqlca.sqlcode 

	IF l_sqlr = 0 
	THEN LET l_retmsg = "DB Connection Succesful" 
	ELSE LET l_retmsg = err_get(l_sqlr) 
	END IF 

	WHENEVER ERROR stop 
	RETURN l_retval, l_sqlr, l_retmsg 

END FUNCTION 
###############################################################
# FUNCTION initDatabaseConnection()
###############################################################


###############################################################
# FUNCTION qxt_connect_db_tool(p_dbName)
###############################################################
FUNCTION qxt_connectdbtool(p_dbname) 
	DEFINE 
	p_dbname VARCHAR(18), 
	l_yesno CHAR(64), 
	l_askretry SMALLINT, 
	l_testconn SMALLINT, 
	l_retval SMALLINT, 
	l_sqltype INTEGER, 
	l_sqllen INTEGER 

	IF p_dbname IS NULL THEN 
		LET p_dbname = fgl_getenv("KANDOODB") 
		MESSAGE "Environment kandoodb - DB SET toDatabase: " , trim(p_dbName) 
		IF p_dbname IS NULL THEN 
			LET p_dbname = "kandoodb" 
			MESSAGE "DB SET TO Default Database: " , trim(p_dbName) 
		END IF 
	END IF 

	WHENEVER ERROR CONTINUE 
	CALL qxt_connectdb(p_dbname) RETURNING l_retval 
	WHENEVER ERROR stop 

	IF l_retval < 0 THEN 
		ERROR "Connection failed" 

		WHILE l_retval < 0 
			PROMPT "Enter database name: " FOR p_dbname 

				ON KEY (INTERRUPT) 
					EXIT WHILE 
					END PROMPT 

					IF length(p_dbname)=0 THEN 
						#CONTINUE WHILE
					END IF 

					DISPLAY "Enter database name: ",p_dbName clipped at 4, 1 
					DISPLAY "Connecting TO database '",p_dbName CLIPPED,"'..." at 6, 3 

					WHENEVER ERROR CONTINUE 
				
					CALL qxt_connectdb(p_dbname) RETURNING l_retval 

					WHENEVER ERROR stop 

					IF l_retval > 0 THEN 
						MESSAGE "Connection successful" 
						EXIT WHILE 
					ELSE 
						ERROR "Connection failed" 
					END IF 

		END WHILE 

	ELSE 
		MESSAGE "Connection successful" 
	END IF 

END FUNCTION 
###############################################################
# FUNCTION qxt_connect_db_tool(p_dbName)
###############################################################


##############################################################
# FUNCTION transmod(pr_mod)
#
# Moved FROM secufunc.4gl
##############################################################
FUNCTION transmod(pr_mod) 
	DEFINE pr_mod CHAR(1) 
	DEFINE pr_name CHAR(8) 
	CASE 
		WHEN pr_mod = "A" 
			LET pr_name = ERP_MODULE_AR_A 
		WHEN pr_mod = "D" 
			LET pr_name = ERP_MODULE_DD_D 
		WHEN pr_mod = "E" 
			LET pr_name = ERP_MODULE_EO_E 
		WHEN pr_mod = "F" 
			LET pr_name = ERP_MODULE_FA_F 
		WHEN pr_mod = "G" 
			LET pr_name = ERP_MODULE_GL_G 
		WHEN pr_mod = "H" 
			LET pr_name = ERP_MODULE_MA_H 
		WHEN pr_mod = "I" 
			LET pr_name = ERP_MODULE_IN_I 
		WHEN pr_mod = "J" 
			LET pr_name = ERP_MODULE_JM_J 
		WHEN pr_mod = "K" 
			LET pr_name = ERP_MODULE_SS_K 
		WHEN pr_mod = "L" 
			LET pr_name = ERP_MODULE_LC_L 
		WHEN pr_mod = "M" 
			LET pr_name = ERP_MODULE_MN_M 
		WHEN pr_mod = "N" 
			LET pr_name = ERP_MODULE_RE_N 
		WHEN pr_mod = "P" 
			LET pr_name = ERP_MODULE_AP_P 
		WHEN pr_mod = "Q" 
			LET pr_name = ERP_MODULE_QE_Q 
		WHEN pr_mod = "R" 
			LET pr_name = ERP_MODULE_PU_R 
		WHEN pr_mod = "S" OR pr_mod = "s" 
			LET pr_name = ERP_MODULE_PO_S #was "pos" 
		WHEN pr_mod = "W" 
			LET pr_name = ERP_MODULE_WO_W 
		OTHERWISE 
			LET pr_name = ERP_MODULE_MA_H #was "main" 
	END CASE 
	
	RETURN pr_name 
END FUNCTION 
##############################################################
# END FUNCTION transmod(pr_mod)
##############################################################