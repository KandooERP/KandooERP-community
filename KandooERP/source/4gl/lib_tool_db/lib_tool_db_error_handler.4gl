#----------------------------
# !!! BY ERIC !!!
#----------------------------

#----------------------------------------------------------------------------
#
# lib_tool_db_errors_handler.4gl sql errors handler, to be called at the beginning on all programs 
# unless there is a specific procedure
#
#----------------------------------------------------------------------------

###########################################################################
# GLOBAL Scope Variables
###########################################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS
	DEFINE show_errors SMALLINT
END GLOBALS

###########################################################################
# MODULE Scope Variables
###########################################################################
CONSTANT cons_lock_errors_list STRING = "-233,-244,-245,-246,-263,-346" 
CONSTANT cons_object_missing_errors_list STRING = "-206,-217"
CONSTANT cons_cannot_open_errors_list STRING = "-259,-266,-271"
CONSTANT cons_cnst_violation_errors_list STRING = "-239,-268,-284,-690,-691,-692"

###########################################################################
# FUNCTION kandoo_sql_errors_handler()
#
#
###########################################################################
FUNCTION kandoo_sql_errors_handler()
	DEFINE kandoo_logdir STRING
	DEFINE log_filename STRING 	 
	DEFINE error_context RECORD
		timestamp DATETIME YEAR TO SECOND,
		server_host STRING,
		informixserver STRING,
		database_name STRING,
		client_host STRING,
		login STRING,
		db_user CHAR(32),   # LIKE sysmaster:syssessions.username,
		session_id INTEGER,
		client_pid INTEGER,
		session_start DATETIME YEAR TO SECOND,
		progname STRING,
		lycia_program STRING,
		module_name STRING,
		line_number SMALLINT,
		function_name STRING,	
		stacktrace STRING,
		sql_errcode INTEGER,
		isam_errcode INTEGER,
		error_offset INTEGER,
		sqlerrMESSAGE STRING,
		error_class STRING,
		error_severity SMALLINT,
		error_text STRING,
		isam_text STRING,
		sql_statement STRING
	END RECORD

	DEFINE locked_object DYNAMIC ARRAY OF RECORD
		tabname CHAR(128),  # LIKE sysmaster:syslocks.tabname,
		rowidlk BIGINT,     # LIKE sysmaster:syslocks.rowidlk,
		owner BIGINT,  	   # LIKE sysmaster:syslocks.waiter,
		username CHAR(32),  #LIKE sysmaster:syssessions.username,
		pid INTEGER,        # LIKE sysmaster:syssessions.pid,
		hostname CHAR(256), # LIKE sysmaster:syssessions.hostname,
		feprogram CHAR(256)#LIKE sysmaster:syssessions.feprogram
	END RECORD

	DEFINE failed_sql_statement CHAR(200)
	DEFINE errorlog base.Channel
	DEFINE msg STRING
	DEFINE error_max_retry,attempt_intvl,obj SMALLINT

	DEFINE status_tmp STRING
	
	LET status_tmp = STATUS
# Official Informix 4GL doc says that WHENEVER SQLERROR can also be triggered by "screen/form interaction statements"
# So we must exit this function if there is no sql error
	
#TODO: replace this code block when scope for real SQLERROR event will be added
	IF sqlca.sqlcode = 0 OR sqlca.sqlcode = 100 THEN
		LET msg = status_tmp, "\n", err_get(status_tmp)
		CALL fgl_winmessage("Form problem, stopping program",msg,"error")
		--RETURN
		EXIT PROGRAM
	END IF
	
	LET error_max_retry = fgl_getenv("ERR_MAX_RETRY")

	IF error_max_retry IS NULL THEN
		LET error_max_retry = 3
	END IF
	LET attempt_intvl = fgl_getenv("ERR_ATTEMPT_INTVL")

	IF attempt_intvl IS NULL THEN
		LET attempt_intvl = 1
	END IF


#--- reset number of attempts
#	IF error_context.error_severity = 0 THEN
#		LET error_retry_nbr = 0
#	END IF

#--- After N calls of the function without resetting the STATUS, the 
#    the error IS promoted TO 9: critical
	IF error_retry_nbr > error_max_retry THEN
		CALL err_print(error_context.sql_errcode)
		SLEEP 2
		LET error_context.error_severity = 9
		LET error_retry_nbr = 0
	END IF
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
	# Documentation of the error
	#- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
 
	LET error_context.timestamp = CURRENT YEAR TO SECOND
	LET error_context.client_host = fgl_getproperty("gui","system.network","hostname")
	LET error_context.server_host = fgl_getproperty("server","system.network","hostname")
	LET error_context.informixserver = fgl_getenv("INFORMIXSERVER") 
	LET error_context.progname = base.Application.getProgramName()
	LET error_context.session_id = session_info.sid
	LET error_context.database_name = session_info.database_name
	LET error_context.db_user = session_info.user_name
	LET error_context.client_pid = session_info.pid
	LET error_context.session_start = session_info.login_timestamp
	LET error_context.stacktrace = base.Application.getStackTrace()
	LET error_context.login  = fgl_username()
	LET error_context.sql_errcode = sqlca.sqlcode
	LET error_context.error_text = err_get(error_context.sql_errcode)
	LET error_context.isam_errcode = sqlca.sqlerrd[2]
	LET error_context.error_offset = sqlca.sqlerrd[5]
	LET error_context.isam_text = err_get(error_context.isam_errcode)
	LET error_context.sqlerrMESSAGE = sqlerrMESSAGE
	--SELECT username,pid INTO error_context.db_user,error_context.client_pid 
	--FROM sysmaster:syssessions WHERE sid = error_context.session_id
	CALL decode_sqlerrmessage (error_context.sqlerrMESSAGE) 
	RETURNING error_context.lycia_program,error_context.module_name,error_context.line_number,error_context.function_name,error_context.error_text
		
	
	OPEN WINDOW bad1 with FORM "U998" 
	IF custom_error_message IS NOT NULL THEN
		DISPLAY BY NAME custom_error_message
	END IF
	--CALL winDecoration("U998")
	
	
	# one log file per day, that will be copied TO the DB server
	LET kandoo_logdir = fgl_getenv("KANDOO_LOG_PATH")
	LET log_filename = kandoo_logdir,"/",error_context.progname,".",error_context.client_pid USING "<<<<<<<<",".",current using "YYYYMMDD_HHMMSS",".err"
	
	#********************************************************************************
	# We handle 4 main types of errors (severity):
	#
	# 0) Errors that can be ignored AND skipped with any harmful consequence
	#
	# 1) Expected errors on locked records that may be unlocked in seconds, with a max number of read attempts
	#
	# 2) Unexpected identified errors requiring TO stop the current program
	# 
	#*********************************************************************************

	CASE error_context.sql_errcode
	
	#--------------------#
	# ERRORS  SEVERITY 0 #
	#--------------------#
	WHEN -256
		#"Transactions NOT available"
		LET error_context.error_severity = 0

	WHEN -535
		# Already in Transactions
		LET error_context.error_severity = 0

	#---------------------#
	# ERRORS  SEVERITY  1 #
	#---------------------#
	WHEN -233
		# "Could NOT read record locked by another"
	 LET error_context.error_severity = 1
	 LET error_context.error_class = "LOCK"
	 LET error_retry_nbr = error_retry_nbr + 1

	WHEN -244
		# "Could NOT do a physical-ORDER read TO FETCH next row"
		LET error_context.error_class = "LOCK"
		LET error_context.error_severity = 2
		LET error_retry_nbr = error_retry_nbr + 1

	WHEN -245
		# "Could NOT position within a file via an index"
		LET error_context.error_class = "LOCK"
		LET error_context.error_severity = 2
		LET error_retry_nbr = error_retry_nbr + 1

	WHEN -246
		# "Could NOT do an indexed read TO get next row"
		# (ou table lockee en "share mode")
		LET error_context.error_class = "LOCK"
		LET error_context.error_severity = 2
		LET error_retry_nbr = error_retry_nbr + 1

	WHEN -263
		# "Could NOT lock row for UPDATE"
		LET error_context.error_class = "LOCK"
		LET error_context.error_severity = 1
		LET error_retry_nbr = error_retry_nbr + 1

	WHEN -346
		# "Could NOT UPDATE a row in the table"
		LET error_context.error_class = "LOCK"
		LET error_context.error_severity = 1
		LET error_retry_nbr = error_retry_nbr + 1

	#---------------------#
	# ERRORS  SEVERITY 2  #
	#---------------------#
	WHEN -201
		# Syntax Error
		LET error_context.error_severity = 2
		LET error_context.error_class = "SQL SYNTAX"

	WHEN -236
		#  Number of columns in INSERT does not match number of VALUES
		LET error_context.error_severity = 2
		LET error_context.error_class = "SQL SYNTAX"

	WHEN -206
		# The specified table <table-name> IS NOT in the database
		LET error_context.error_severity = 2
		LET error_context.error_class = "SQL OBJECT"
		
	WHEN -217
		# Column COLUMN-name NOT found in any table in the query
		LET error_context.error_severity = 2
		LET error_context.error_class = "SQL OBJECT"
		
	WHEN -259
		# "Cursor NOT OPEN"
		LET error_context.error_severity = 2
		LET error_context.error_class = "SQL OBJECT"

	WHEN -266
		# "There IS no current row for UPDATE/DELETE CURSOR"
	  	LET error_context.error_severity = 2
	  	LET error_context.error_class = "SQL OBJECT"

	WHEN -271
		# "Could NOT INSERT new row INTO the table"
	 	LET error_context.error_severity = 2
	 	LET error_context.error_class = "SQL OBJECT"

	WHEN -239
		# could NOT INSERT new row - duplicate value
		LET error_context.error_class = "CONSTRAINT VIOL."
		LET error_context.error_severity = 2

	WHEN -268
		# unique constraint ... violated
		LET error_context.error_class = "CONSTRAINT VIOL."
		LET error_context.error_severity = 2

	WHEN -284
		# A subquery has returned NOT exactly one row
		LET error_context.error_class = "CONSTRAINT VIOL."
		LET error_context.error_severity = 2

	WHEN -690
		# cannot read keys FROM referencing table ...
		LET error_context.error_class = "CONSTRAINT VIOL."
		LET error_context.error_severity = 2

	WHEN -691
		# missing key in referenced table for constraint ...
		LET error_context.error_class = "CONSTRAINT VIOL."
		LET error_context.error_severity = 2

	WHEN -692
		# key value for constraint ... IS still referenced
		LET error_context.error_class = "CONSTRAINT VIOL."
		LET error_context.error_severity = 2

	WHEN -1262
		# Datetime or interval contains non numeric character.
		LET error_context.error_class = "DATA MAPPING"
		LET error_context.error_severity = 2
	# Data mapping to be continued
	
	WHEN -458
		# long transaction aborted
		LET error_context.error_class = "LONG TRANSACTION"
		LET error_context.error_severity = 9
		
	WHEN -407
		# "Error number zero received FROM the sqlexec process"
		LET error_context.error_class = "CONNECTIVITY"
		LET error_context.error_severity = 9

	WHEN -408
		# "Invalid MESSAGE received FROM the sqlexec process"
		LET error_context.error_class = "CONNECTIVITY"
		LET error_context.error_severity = 9

	WHEN -25555	
		# Server server-name is not listed as a dbserver name in sqlhosts.
		LET error_context.error_class = "CONNECTIVITY"
		LET error_context.error_severity = 9
		
	WHEN -25580
		# "System error occurred in network function."
		LET error_context.error_class = "CONNECTIVITY"
		LET error_context.error_severity = 9

	WHEN -25582
		# "Network connection is broken."
		LET error_context.error_class = "CONNECTIVITY"
		LET error_context.error_severity = 9
	

	OTHERWISE
		CALL err_print(error_context.sql_errcode)
		SLEEP 2
		LET error_context.error_severity = 9
	END CASE
	#--------------------------------------------------------------

	# Store the sql statement if possible
	#SELECT sqs_statement
	#INTO error_context.sql_statement
	#FROM sysmaster:syssqlstat
	#WHERE sqs_sessionid = error_context.session_id
	#AND sqs_sqlerror = error_context.sql_errcode
			
	IF error_context.error_class = "LOCK" AND error_retry_nbr <= error_max_retry THEN
		DECLARE crs_get_lockers CURSOR FOR
		SELECT tabname,rowidlk,owner,username,pid,hostname,feprogram
		FROM sysmaster:syslocks l,sysmaster:syssessions s
		where l.owner = s.sid
		AND type = "X"
		and tabname not matches "sys*"
		and dbsname = "kandoodb"
		LET obj=1

		FOREACH crs_get_lockers INTO locked_object[obj].*
			LET obj=obj + 1
		END FOREACH

		LET obj=obj - 1

		IF obj > 0 THEN
			DISPLAY ARRAY locked_object TO arr_locked_object.*
				BEFORE ROW
					EXIT DISPLAY
			END DISPLAY
		END IF
		#IF sqlca.sqlcode = 0 THEN
		#	LET msg = "Lock detected in table ",error_retry_nbr," / ",error_max_retry,locked_object.tabname,"(",locked_object.rowidlk,") waiting for session #",locked_object.owner
		#ELSE
		#	LET msg = "Lock detected, retrying ",error_retry_nbr," / ",error_max_retry
		#END IF
#		CALL fgl_winmessage("Lock conflict, OK to retry",msg,"warning")
#		SLEEP attempt_intvl
	END IF
	
	IF error_context.error_severity > 1 OR error_retry_nbr > error_max_retry THEN
		LET errorlog = base.Channel.Create()

		CALL errorlog.openFile(log_filename, "a")
		CALL errorlog.setDelimiter("	")  
		CALL errorlog.write([error_context.*])
		CALL errorlog.Close()
		 
		DISPLAY BY NAME 
			error_context.timestamp,
			error_context.server_host,
			error_context.informixserver,
			error_context.database_name,
			error_context.client_host,
			error_context.login,
			error_context.db_user,
			error_context.session_id,
			error_context.client_pid,
			error_context.session_start,
			error_context.progname,
			error_context.lycia_program,
			error_context.module_name,
			error_context.line_number,
			error_context.function_name,
			error_context.stacktrace,
			error_context.sql_errcode,
			error_context.error_text,
			error_context.isam_errcode,
			error_context.isam_text,
			error_context.sqlerrMESSAGE,
			error_context.error_class,
			error_context.error_severity
			
			#error_context.sql_statement
				
		CASE error_context.error_class
			WHEN "CONSTRAINT VIOL."
				#CALL fgl_winmessage("Constraint violation Problem,stopping program",msg,"error")
				LET msg = "Session # ",session_info.sid," Constraint can't be resolved,stopping program!"
				CALL doneprompt("Constraint violation",msg,"error")
			WHEN "LOCK"
				#--- After N calls of the function without resetting the STATUS, the 
				#    the error IS promoted TO 9: critical
				LET msg = " Data access conflict can't be resolved,stopping program!"
				CALL doneprompt("Lock conflict, OK to retry",msg,"error")
				LET error_retry_nbr = 0

			WHEN "CONNECTIVITY"
				LET msg = "Session # ",session_info.sid," DB server NOT reachable,stopping program!"
				CALL doneprompt("DB Connection problem",msg,"error")

			WHEN "SQL OBJECT"
				LET msg = "Session # ",session_info.sid," DB object missing in query,stopping program!"
				CALL doneprompt("Missing db object",msg,"error")

			OTHERWISE
				LET msg = "Session # ",session_info.sid," unclassifed error,stopping program!"
				--CALL doneprompt("Unclassified",msg,"error")
		END CASE
	END IF

	MENU "What next?"
		BEFORE MENU
			IF obj = 0 THEN
				HIDE OPTION "Check locks"
			END IF
			IF continue_program_on_error = FALSE THEN
				HIDE OPTION "Continue Program"
			END IF

		COMMAND "Continue Program" "This error is not critical, program can continue"
			LET continue_program_on_error = true
			EXIT MENU

		COMMAND "Call Tech Support"
			DISPLAY "Please keep the information of this form visible"
			LET continue_program_on_error = false
			
		COMMAND "Check locks"
			DISPLAY ARRAY locked_object TO arr_locked_object.*

		COMMAND "EXIT PROGRAM"
			LET continue_program_on_error = false
			EXIT MENU
		END MENU
		
		# reset continue_program_on_error and rollback
		IF continue_program_on_error = false THEN
			WHENEVER ERROR CONTINUE
			ROLLBACK WORK
			WHENEVER ERROR CALL kandoo_sql_errors_handler
			EXIT PROGRAM
		END IF

		LET continue_program_on_error = false
		LET custom_error_message = NULL

		CLOSE WINDOW bad1
END FUNCTION
###########################################################################
# FUNCTION kandoo_sql_errors_handler()
###########################################################################


###########################################################################
# FUNCTION display_db_error(p_msg)
#
#
###########################################################################
FUNCTION display_db_error(p_msg)
	DEFINE p_msg STRING
	DEFINE l_error_MESSAGE STRING		                                                                                             	

	CALL Errorlog(sqlerrMESSAGE)		                                                                                            

	LET l_error_MESSAGE = p_msg clipped, " ",sqlca.sqlcode," ",sqlca.sqlerrd[2]," ",sqlca.sqlerrm clipped

	CALL doneprompt("Type OK TO continue",l_error_MESSAGE,"error")
END FUNCTION
###########################################################################
# END FUNCTION display_db_error(p_msg)
###########################################################################


###########################################################################
# FUNCTION display_error_and_decide(p_program_context,p_sqlerrmessage,p_allowed_errors_list)
#
#
###########################################################################
FUNCTION display_error_and_decide(p_program_context,p_sqlerrmessage,p_allowed_errors_list) 
	DEFINE p_program_context STRING				# Program context so that user identifies what he/she is doing
	DEFINE p_sqlerrmessage STRING 				# the full sqlerrmessage string
	DEFINE p_allowed_errors_list STRING			# one can list error numbers that are considered as acceptable, separated by ',' or use a generic list name (see top of this module)
	DEFINE p_allowed_errors_regex STRING
	DEFINE l_severity SMALLINT					# 1 => error (cannot continue) , 0 expected error, can continue
	DEFINE l_error_message STRING
	DEFINE l_program_name STRING				
	DEFINE l_module_name STRING
	DEFINE l_line_number SMALLINT
	DEFINE l_function_name STRING
	DEFINE l_error_number SMALLINT
	DEFINE l_error_shortmessage STRING
	DEFINE l_custom_title STRING
	DEFINE l_custom_message STRING
	DEFINE l_reply STRING
	DEFINE regexp util.regex 
	DEFINE l_suffix STRING
	DEFINE l_match_result util.match_results 
	DEFINE l_lock_errors_list STRING
	
	# Predefine set of allowed errors under a generic name
	IF p_allowed_errors_list matches "*locks*" THEN
		LET p_allowed_errors_list = cons_lock_errors_list
	END IF 
	# 
	CALL decode_sqlerrmessage (p_sqlerrmessage) 
	RETURNING l_program_name,l_module_name,l_line_number,l_function_name,l_error_number,l_error_shortmessage
	 
	# Check if the detected error is within the authorized list 
	LET p_allowed_errors_regex = util.REGEX.replace(p_allowed_errors_list,/,/g,"|")
	IF util.regex.match(l_error_number,p_allowed_errors_regex) THEN 
		LET l_custom_title = "WARNING ",l_program_name
		LET l_severity = 0
	ELSE	
		LET l_custom_title = "ERROR ",l_program_name
		LET l_severity = 1
	END IF

	LET l_custom_message = "Context ",p_program_context,"\nError: ",l_error_shortmessage ,"\nError number", l_error_number
	
	CASE l_severity
		WHEN 1 
			CALL fgl_winbutton(l_custom_title, l_custom_message, "Exit Program","See Details|Exit Program", "error", 1)
			RETURNING l_reply
		WHEN 0
			CALL fgl_winbutton(l_custom_title, l_custom_message, "Continue","Continue|See Details|Exit Program", "exclamation", 1)
			RETURNING l_reply
	END CASE

	CASE l_reply
		WHEN "Exit Program"
			EXIT PROGRAM
		WHEN "Continue"
			# Return to the original program, just after the error location
			RETURN 1
		WHEN "See Details"
			CALL kandoo_sql_errors_handler ()
	END CASE
END FUNCTION 	# display_error_and_decide
###########################################################################
# END FUNCTION display_error_and_decide(p_program_context,p_sqlerrmessage,p_allowed_errors_list)
###########################################################################


###########################################################################
# FUNCTION decode_sqlerrmessage (p_sqlerrmessage)
#
#
###########################################################################
FUNCTION decode_sqlerrmessage (p_sqlerrmessage)
# This functions parses the long sql error messages and returns all relevant info about this error
	DEFINE p_sqlerrmessage STRING 				# the full sqlerrmessage string
	DEFINE l_error_message STRING
	DEFINE l_program_name STRING				
	DEFINE l_module_name STRING
	DEFINE l_line_number SMALLINT
	DEFINE l_function_name STRING
	DEFINE l_error_number SMALLINT
	DEFINE l_error_shortmessage STRING
	DEFINE regexp util.regex 
	DEFINE l_suffix STRING
	DEFINE l_match_result util.match_results 

	# 1) decode the sqlerrmessage string
	LET l_match_result = util.regex.search(p_sqlerrmessage,/Module:\s+(\w+).*File:\s+(\w+\.4gl).*line\s+(\d+).*Function:\s+(\w+)/s)
	LET l_program_name = l_match_result.str(1)
	LET l_module_name = l_match_result.str(2)
	LET l_line_number = l_match_result.str(3)
	LET l_function_name = l_match_result.str(4)
	
	# Other regexp to catch error number and short errmessage
	LET l_match_result = util.regex.search(p_sqlerrmessage,/The error code \((\-\d+)\) was received\.\s+(\w+)/s)
	LET l_error_number = l_match_result.str(1)

	# Catch the next line in the suffix which is the short error message
	LET l_suffix = l_match_result.suffix()
	LET l_match_result = util.regex.search(l_suffix,/\s+([\w\s]+)\./s)
	LET l_error_shortmessage = l_match_result.str(1)
	RETURN l_program_name,l_module_name,l_line_number,l_function_name,l_error_number,l_error_shortmessage
END FUNCTION
###########################################################################
# END FUNCTION decode_sqlerrmessage (p_sqlerrmessage)
###########################################################################