##################################################################################
# GLOBAL Scope Variables
##################################################################################
GLOBALS "../common/glob_GLOBALS.4gl" 

############################################################
#
# !!! DB table etc... For later 
# Settings options need to got into the database like kandoooption
#
############################################################

##################################################################################
# FUNCTION set_settings_logPath(p_logPath)
#
# If argument is NULL, read from environment, if still NULL, use the default log path
##################################################################################
FUNCTION set_settings_logPath(p_logPath) 
	DEFINE p_logPath STRING 
	DEFINE l_msg STRING
	
	IF (glob_rec_settings.logPath IS NOT NULL) AND (p_logPath IS NULL) THEN
		RETURN --LogFile Path should not be overwritten with the default value, if it was already set prior
	END IF
	
	LET glob_rec_settings.logPath = p_logPath
	
	IF glob_rec_settings.logPath IS NULL THEN
		LET glob_rec_settings.logPath = fgl_getenv("KANDOO_LOG_PATH")
	END IF
	
	IF glob_rec_settings.logPath IS NULL THEN 
		LET glob_rec_settings.logPath = "data/log" --"data/log" 
	END IF
	
	IF NOT os.path.exists(glob_rec_settings.logPath) THEN
		IF os.Path.mkdir(glob_rec_settings.logPath) THEN
			MESSAGE "Created Log File Path: ", glob_rec_settings.logPath
		ELSE
			LET l_msg = "Could not create Log File Path: ", glob_rec_settings.logPath 
			CALL fgl_winmessage("Log File Error!",l_msg,"ERROR")
			EXIT PROGRAM
		END IF
	END IF

	IF NOT os.path.exists(glob_rec_settings.logPath) THEN 
		LET l_msg = "Invalid Report output path ", trim(glob_rec_settings.logPath)," detected in the environment logPath!\nCould not create the path (Access Permission?)" --alch it's prohibited TO INITIALIZE WINDOW BEFORE the CALL ui.Interface.setType("container")
		CALL fgl_winmessage("Log File Error",l_msg,"ERROR") 
		EXIT PROGRAM
	END IF 

	IF NOT os.path.readable(glob_rec_settings.logPath) THEN 
		LET l_msg = "Invalid Report output path Permission (Read) for log files: ", trim(glob_rec_settings.logPath), "\n Environment Variable: KANDOO_LOG_PATH"
		CALL fgl_winmessage("Log File Access Error", l_msg, "Error")
		EXIT PROGRAM 
	END IF 

	IF NOT os.path.writable(glob_rec_settings.logPath) THEN 
		LET l_msg = "Invalid Report output path Permission (Write) for log files: ", trim(glob_rec_settings.logPath), "\n Environment Variable: KANDOO_LOG_PATH"
		CALL fgl_winmessage("Log File Access Error", l_msg, "Error")
		EXIT PROGRAM 
	END IF 	 
	 
END FUNCTION 
##################################################################################
# END FUNCTION set_settings_logPath(p_logPath)
##################################################################################



##################################################################################
# FUNCTION get_settings_logPath() 
#
#
##################################################################################
FUNCTION get_settings_logPath() 
	RETURN glob_rec_settings.logPath
END FUNCTION 
##################################################################################
# END FUNCTION get_settings_logPath() 
##################################################################################

----------------------------------------------------------------------------------

##################################################################################
# FUNCTION get_settings_logPath_forFile(p_filename) 
#
#
##################################################################################
FUNCTION get_settings_logPath_forFile(p_filename)
	DEFINE p_filename STRING
	DEFINE l_msg STRING

	IF p_filename IS NULL THEN	
		LET l_msg = "FUNCTION get_settings_logPath_forFile(p_filename) called with invalid NULL arg!\n"
		LET l_msg = l_msg CLIPPED, "FUNCTION get_settings_logPath_forFile(", trim(p_filename), ")"
		CALL fgl_winmessage("Internal 4gl Error",l_msg,"ERROR")
		LET p_filename =  "Unknown_Log_File.txt"
	ELSE
		LET p_filename = glob_rec_settings.logPath CLIPPED,"/",trim(p_filename)
	END IF
	RETURN p_filename
END FUNCTION 
##################################################################################
# END FUNCTION get_settings_logPath_forFile(p_filename) 
##################################################################################

----------------------------------------------------------------------------------

##################################################################################
# FUNCTION set_settings_logFile(p_logFile)
#
#
##################################################################################
FUNCTION set_settings_logFile(p_logFile) 
	DEFINE p_logFile STRING 
	DEFINE l_msg STRING
	
	IF (glob_rec_settings.logFile IS NOT NULL) AND (p_logFile IS NULL) THEN
		RETURN --LogFile File should not be overwritten with the default value, if it was already set prior
	END IF
	
	
	IF p_logFile IS NULL THEN
		LET p_logFile = fgl_getenv("KANDOO_LOG_FILE")
	END IF

	IF p_logFile IS NULL THEN  #no argument and no environment - use default file name
		LET p_logFile = "kandoolog.log" #default if nothing is specified or set
	END IF

	#add path	
	LET glob_rec_settings.logFile = trim(get_settings_logPath()), "/", trim(p_logFile),".log" 

	#Start the log file
	CALL startlog(glob_rec_settings.logFile)

	#The empty base file is created OR does still exist from previous sessions
	#check if we can read and write to it
	IF NOT os.path.readable(glob_rec_settings.logFile) THEN 
		LET l_msg = "Invalid LogFile Permission (Read) for log files: ", trim(glob_rec_settings.logFile), "\n Environment Variable: KANDOO_LOG_PATH"
		CALL fgl_winmessage("Log File Access Error", l_msg, "Error")
		EXIT PROGRAM 
	END IF 

	IF NOT os.path.writable(glob_rec_settings.logFile) THEN 
		LET l_msg = "Invalid LogFile Permission (Write) for log files: ", trim(glob_rec_settings.logFile), "\n Environment Variable: KANDOO_LOG_PATH"
		CALL fgl_winmessage("Log File Access Error", l_msg, "Error")
		EXIT PROGRAM 
	END IF 	 
	 
END FUNCTION 
##################################################################################
# END FUNCTION set_settings_logFile(p_logFile)
##################################################################################


##################################################################################
# FUNCTION get_settings_logFile() 
#
#
##################################################################################
FUNCTION get_settings_logFile() 
	RETURN glob_rec_settings.logFile
END FUNCTION 
##################################################################################
# END FUNCTION get_settings_logFile() 
##################################################################################

----------------------------------------------------------------------------------

############################################################
# FUNCTION set_settings_reportPath(p_reportPath)
#
# If argument is NULL, read from environment, if still NULL, use the default report path
############################################################
FUNCTION set_settings_reportPath(p_reportPath) 
	DEFINE p_reportPath STRING 
	DEFINE l_msg STRING

	IF (glob_rec_settings.reportPath IS NOT NULL) AND (p_reportPath IS NULL) THEN
		RETURN --LogFile Path should not be overwritten with the default value, if it was already set prior
	END IF
		
	LET glob_rec_settings.reportPath = p_reportPath
	
	IF glob_rec_settings.reportPath IS NULL THEN
		LET glob_rec_settings.reportPath = fgl_getenv("KANDOO_REPORT_PATH")
	END IF
	
	IF glob_rec_settings.reportPath IS NULL THEN 
		LET glob_rec_settings.reportPath = "data/report"  
	END IF
	
	IF NOT os.path.exists(glob_rec_settings.reportPath) THEN
		IF os.Path.mkdir(glob_rec_settings.reportPath) THEN
			MESSAGE "Created Report File Path: ", glob_rec_settings.reportPath
		ELSE
			LET l_msg = "Could not create Report File Path: ", glob_rec_settings.reportPath 
			CALL fgl_winmessage("Report File Error!",l_msg,"ERROR")
			EXIT PROGRAM
		END IF
	END IF

	IF NOT os.path.exists(glob_rec_settings.reportPath) THEN 
		LET l_msg = "Invalid Report output path ", trim(glob_rec_settings.reportPath)," detected in the environment reportPath!\nCould not create the path (Access Permission?)" 
		CALL fgl_winmessage("Report File Error",l_msg,"ERROR") 
		EXIT PROGRAM
	END IF 

	IF NOT os.path.readable(glob_rec_settings.reportPath) THEN 
		LET l_msg = "Invalid Report output path Permission (Read) for report files: ", trim(glob_rec_settings.reportPath), "\n Environment Variable: KANDOO_REPORT_PATH"
		CALL fgl_winmessage("Report File Access Error", l_msg, "Error")
		EXIT PROGRAM 
	END IF 

	IF NOT os.path.writable(glob_rec_settings.reportPath) THEN 
		LET l_msg = "Invalid Report output path Permission (Write) for report files: ", trim(glob_rec_settings.reportPath), "\n Environment Variable: KANDOO_REPORT_PATH"
		CALL fgl_winmessage("Report File Access Error", l_msg, "Error")
		EXIT PROGRAM 
	END IF 	 
	 
END FUNCTION 
############################################################
# END FUNCTION set_settings_reportPath(p_reportPath)
############################################################


##################################################################################
# FUNCTION get_settings_reportPath() 
#
#
##################################################################################
FUNCTION get_settings_reportPath() 
	RETURN glob_rec_settings.reportpath
END FUNCTION 
##################################################################################
# END FUNCTION get_settings_reportPath() 
##################################################################################

----------------------------------------------------------------------------------



############################################################
# FUNCTION set_settings_dataPath(p_dataPath)
#
# If argument is NULL, read from environment, if still NULL, use the default Data path
############################################################
FUNCTION set_settings_dataPath(p_dataPath) 
	DEFINE p_dataPath STRING 
	DEFINE l_msg STRING

	#for NULL argument - default path 
	IF (glob_rec_settings.dataPath IS NOT NULL) AND (p_dataPath IS NULL) THEN
		RETURN --Path should not be overwritten with the default value, if it was already set prior
	END IF
		
	LET glob_rec_settings.dataPath = p_dataPath
	
	IF glob_rec_settings.dataPath IS NULL THEN
		LET glob_rec_settings.dataPath = fgl_getenv("KANDOO_DATA_PATH")
	END IF
	
	IF glob_rec_settings.dataPath IS NULL THEN 
		LET glob_rec_settings.dataPath = "data"  
	END IF
	
	IF NOT os.path.exists(glob_rec_settings.dataPath) THEN
		IF os.Path.mkdir(glob_rec_settings.dataPath) THEN
			MESSAGE "Created Data File Path: ", glob_rec_settings.dataPath
		ELSE
			LET l_msg = "Could not create Data File Path: ", glob_rec_settings.dataPath 
			CALL fgl_winmessage("Data File Error!",l_msg,"ERROR")
			EXIT PROGRAM
		END IF
	END IF

	IF NOT os.path.exists(glob_rec_settings.dataPath) THEN 
		LET l_msg = "Invalid Data output path ", trim(glob_rec_settings.dataPath)," detected in the environment dataPath!\nCould not create the path (Access Permission?)" 
		CALL fgl_winmessage("Data File Error",l_msg,"ERROR") 
		EXIT PROGRAM
	END IF 

	IF NOT os.path.readable(glob_rec_settings.dataPath) THEN 
		LET l_msg = "Invalid Data output path Permission (Read) for Data files: ", trim(glob_rec_settings.dataPath), "\n Environment Variable: KANDOO_DATA_PATH"
		CALL fgl_winmessage("Data File Access Error", l_msg, "Error")
		EXIT PROGRAM 
	END IF 

	IF NOT os.path.writable(glob_rec_settings.dataPath) THEN 
		LET l_msg = "Invalid Data output path Permission (Write) for Data files: ", trim(glob_rec_settings.dataPath), "\n Environment Variable: KANDOO_DATA_PATH"
		CALL fgl_winmessage("Data File Access Error", l_msg, "Error")
		EXIT PROGRAM 
	END IF 	 
	 
END FUNCTION 
############################################################
# END FUNCTION set_settings_dataPath(p_dataPath)
############################################################


##################################################################################
# FUNCTION get_settings_dataPath() 
#
#
##################################################################################
FUNCTION get_settings_dataPath() 
	RETURN glob_rec_settings.dataPath
END FUNCTION 
##################################################################################
# END FUNCTION get_settings_dataPath() 
##################################################################################

----------------------------------------------------------------------------------


############################################################
# FUNCTION set_settings_saveUnbalancedBatch(p_saveUnbalancedBatch)
#
#
############################################################
FUNCTION set_settings_saveUnbalancedBatch(p_saveunbalancedbatch) 
	DEFINE p_saveunbalancedbatch boolean 

	IF p_saveunbalancedbatch IS NULL THEN 
		LET glob_rec_settings.saveunbalancedbatch = false 
	ELSE 
		LET glob_rec_settings.saveunbalancedbatch = p_saveunbalancedbatch 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION set_settings_saveUnbalancedBatch(p_saveUnbalancedBatch)
############################################################


############################################################
# FUNCTION get_settings_saveUnbalancedBatch()
#
#
############################################################
FUNCTION get_settings_saveUnbalancedBatch() 
	DEFINE l_saveunbalancedbatch boolean 

	IF glob_rec_settings.saveunbalancedbatch IS NOT NULL THEN 
		LET l_saveunbalancedbatch = glob_rec_settings.saveunbalancedbatch 
	ELSE 
		IF fgl_getenv("SAVEUNBALANCEDBATCH") IS NOT NULL THEN 
			LET glob_rec_settings.saveunbalancedbatch = fgl_getenv("SAVEUNBALANCEDBATCH") 
			LET l_saveunbalancedbatch = glob_rec_settings.saveunbalancedbatch 
		ELSE 
			LET glob_rec_settings.saveunbalancedbatch = true #default path 
			LET l_saveunbalancedbatch = glob_rec_settings.saveunbalancedbatch 
			CALL fgl_setenv("SAVEUNBALANCEDBATCH",l_saveUnbalancedBatch) 
		END IF 
	END IF 

	RETURN l_saveunbalancedbatch 
END FUNCTION 

----------------------------------------------------------------------------------

############################################################
# FUNCTION set_settings_maxListArraySizeSwitch(p_maxListArraySizeSwitch)
#
#
############################################################
FUNCTION set_settings_maxListArraySizeSwitch(p_maxListArraySizeSwitch) 
	DEFINE p_maxListArraySizeSwitch INTEGER

	IF (p_maxListArraySizeSwitch IS null) OR (p_maxListArraySizeSwitch = 0) THEN 
		LET glob_rec_settings.maxListArraySizeSwitch = 500 
	ELSE 
		LET glob_rec_settings.maxListArraySizeSwitch = p_maxListArraySizeSwitch 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION set_settings_maxListArraySizeSwitch(p_maxListArraySizeSwitch)
############################################################


############################################################
# FUNCTION get_settings_maxListArraySizeSwitch()
#
#
############################################################
FUNCTION get_settings_maxListArraySizeSwitch() 
	DEFINE l_maxlistArraySizeSwitch INTEGER 

	IF (glob_rec_settings.maxListArraySizeSwitch != 0) THEN 
		LET l_maxlistArraySizeSwitch = glob_rec_settings.maxListArraySizeSwitch 
	ELSE 
		IF fgl_getenv("maxListArraySizeSwitch") IS NOT NULL THEN 
			LET glob_rec_settings.maxListArraySizeSwitch = fgl_getenv("maxListArraySizeSwitch") 
			LET l_maxlistArraySizeSwitch = glob_rec_settings.maxListArraySizeSwitch 
		ELSE 
			LET glob_rec_settings.maxListArraySizeSwitch = 1000 #default size 
			LET l_maxlistArraySizeSwitch = glob_rec_settings.maxListArraySizeSwitch 
			CALL fgl_setenv("maxListArraySizeSwitch",l_maxListArraySizeSwitch) 
		END IF 
	END IF 

	RETURN l_maxlistArraySizeSwitch 
END FUNCTION 
############################################################
# END FUNCTION get_settings_maxListArraySizeSwitch(p_maxListArraySize)
############################################################


############################################################
# FUNCTION set_settings_maxListArraySize(p_maxListArraySize)
#
#
############################################################
FUNCTION set_settings_maxListArraySize(p_maxlistarraysize) 
	DEFINE p_maxlistarraysize INTEGER 

	IF (p_maxlistarraysize IS null) OR (p_maxlistarraysize = 0) THEN 
		LET glob_rec_settings.maxListArraySize = 1000 
	ELSE 
		LET glob_rec_settings.maxListArraySize = p_maxlistarraysize 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION set_settings_maxListArraySize(p_maxListArraySize)
############################################################


############################################################
# FUNCTION get_settings_maxListArraySize()
#
#
############################################################
FUNCTION get_settings_maxListArraySize() 
	DEFINE l_maxlistarraysize INTEGER 

	IF (glob_rec_settings.maxListArraySize IS NOT null) AND (glob_rec_settings.maxListArraySize != 0) THEN 
		LET l_maxlistarraysize = glob_rec_settings.maxListArraySize 
	ELSE 
		IF fgl_getenv("maxListArraySize") IS NOT NULL THEN 
			LET glob_rec_settings.maxListArraySize = fgl_getenv("maxListArraySize") 
			LET l_maxlistarraysize = glob_rec_settings.maxListArraySize 
		ELSE 
			LET glob_rec_settings.maxListArraySize = 1000 #default size 
			LET l_maxlistarraysize = glob_rec_settings.maxListArraySize 
			CALL fgl_setenv("maxListArraySize",l_maxListArraySize) 
		END IF 
	END IF 

	RETURN l_maxlistarraysize 
END FUNCTION 
############################################################
# END FUNCTION get_settings_maxListArraySize(p_maxListArraySize)
############################################################


----------------------------------------------------------------------------------

############################################################
# FUNCTION set_settings_maxRmsrepsHistorySize(p_maxRmsrepsHistorySize)
#
#
############################################################
FUNCTION set_settings_maxRmsrepsHistorySize(p_maxRmsrepsHistorySize) 
	DEFINE p_maxRmsrepsHistorySize INTEGER 

	IF (p_maxRmsrepsHistorySize IS null) OR (p_maxRmsrepsHistorySize = 0) THEN 
		LET glob_rec_settings.maxReportHistorySize = 99999000 
	ELSE 
		LET glob_rec_settings.maxReportHistorySize = p_maxRmsrepsHistorySize 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION set_settings_maxRmsrepsHistorySize(p_maxRmsrepsHistorySize)
############################################################


############################################################
# FUNCTION get_settings_maxRmsrepsHistorySize()
#
#
############################################################
FUNCTION get_settings_maxRmsrepsHistorySize() 
	DEFINE l_maxRmsrepsHistorySize INTEGER 

	IF (glob_rec_settings.maxReportHistorySize IS NOT null) AND (glob_rec_settings.maxReportHistorySize != 0) THEN 
		LET l_maxRmsrepsHistorySize = glob_rec_settings.maxReportHistorySize 
	ELSE 
		IF fgl_getenv("maxReportHistorySize") IS NOT NULL THEN 
			LET glob_rec_settings.maxReportHistorySize = fgl_getenv("maxReportHistorySize") 
			LET l_maxRmsrepsHistorySize = glob_rec_settings.maxReportHistorySize 
		ELSE 
			LET glob_rec_settings.maxReportHistorySize = 99999000 #default size 
			LET l_maxRmsrepsHistorySize = glob_rec_settings.maxReportHistorySize 
			CALL fgl_setenv("maxReportHistorySize",l_maxRmsrepsHistorySize) 
		END IF 
	END IF 

	RETURN l_maxRmsrepsHistorySize 
END FUNCTION 
############################################################
# END FUNCTION get_settings_maxRmsrepsHistorySize()
############################################################

----------------------------------------------------------------------------------

############################################################
# FUNCTION set_settings_maxChildLaunch(p_maxChildLaunch)
#
#
############################################################
FUNCTION set_settings_maxchildlaunch(p_maxchildlaunch) 
	DEFINE p_maxchildlaunch SMALLINT 

	IF (p_maxchildlaunch IS null) OR (p_maxchildlaunch = 0) THEN 
		LET glob_rec_settings.maxchildlaunch = 10 
	ELSE 
		LET glob_rec_settings.maxchildlaunch = p_maxchildlaunch 
	END IF 

END FUNCTION 
############################################################
# END FUNCTION set_settings_maxChildLaunch(p_maxChildLaunch)
############################################################


############################################################
# FUNCTION get_settings_maxChildLaunch()
#
#
############################################################
FUNCTION get_settings_maxchildlaunch() 
	DEFINE r_maxchildlaunch SMALLINT 

	IF (glob_rec_settings.maxchildlaunch IS NOT null) AND (glob_rec_settings.maxchildlaunch != 0) THEN 
		LET r_maxchildlaunch = glob_rec_settings.maxchildlaunch 
	ELSE 
		IF fgl_getenv("MAX_CHILD") IS NOT NULL THEN 
			LET glob_rec_settings.maxchildlaunch = fgl_getenv("MAX_CHILD") 
			LET r_maxchildlaunch = glob_rec_settings.maxchildlaunch 
		ELSE 
			LET glob_rec_settings.maxchildlaunch = 10 #default size 
			LET r_maxchildlaunch = glob_rec_settings.maxchildlaunch 
			CALL fgl_setenv("MAX_CHILD",r_maxchildlaunch) 
		END IF 
	END IF 

	RETURN r_maxchildlaunch 
END FUNCTION 
############################################################
# END FUNCTION get_settings_maxChildLaunch()
############################################################

----------------------------------------------------------------------------------

############################################################
# FUNCTION set_default_country_code(p_country_code)
#
#
############################################################
FUNCTION set_default_country_code(p_country_code)
	DEFINE p_country_code LIKE country.country_code

	IF p_country_code IS NOT NULL THEN
		LET glob_rec_settings.default_country_code = p_country_code
	ELSE
		LET glob_rec_settings.default_country_code = glob_rec_kandoouser.country_code
	END IF
END FUNCTION
############################################################
# END FUNCTION set_default_country_code(p_country_code)
############################################################


############################################################
# FUNCTION get_default_country_code()
#
#
############################################################
FUNCTION get_default_country_code()

	RETURN glob_rec_settings.default_country_code

END FUNCTION
############################################################
# END FUNCTION get_default_country_code()
############################################################

----------------------------------------------------------------------------------

############################################################
# FUNCTION set_default_currency_code(p_currency_code)
#
#
############################################################
FUNCTION set_default_currency_code(p_currency_code)
	DEFINE p_currency_code LIKE currency.currency_code

	IF p_currency_code IS NOT NULL THEN
		LET glob_rec_settings.default_currency_code = p_currency_code
	ELSE
		LET glob_rec_settings.default_currency_code = glob_rec_company.curr_code
	END IF
END FUNCTION
############################################################
# END FUNCTION set_default_currency_code(p_currency_code)
############################################################


############################################################
# FUNCTION get_default_currency_code()
#
#
############################################################
FUNCTION get_default_currency_code()

	RETURN glob_rec_settings.default_currency_code

END FUNCTION
############################################################
# END FUNCTION get_default_currency_code()
############################################################

----------------------------------------------------------------------------------

############################################################
# FUNCTION set_default_hideDeletedCustomers(p_hideDeletedCustomers)
############################################################
FUNCTION set_default_hideDeletedCustomers(p_hideDeletedCustomers)
	DEFINE p_hideDeletedCustomers BOOLEAN

	IF p_hideDeletedCustomers IS NOT NULL THEN
		LET glob_rec_settings.hideDeletedCustomers = p_hideDeletedCustomers
	ELSE
		LET glob_rec_settings.hideDeletedCustomers = FALSE
	END IF
END FUNCTION
############################################################
# END FUNCTION set_default_hideDeletedCustomers(p_hideDeletedCustomers)
############################################################

############################################################
# FUNCTION get_default_hideDeletedCustomers()
############################################################

FUNCTION get_default_hideDeletedCustomers()

	RETURN glob_rec_settings.hideDeletedCustomers

END FUNCTION
############################################################
# END FUNCTION get_default_hideDeletedCustomers()
############################################################