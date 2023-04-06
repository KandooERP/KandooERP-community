##############################################################################################
#TABLE rmsreps
##############################################################################################

##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"

############################################################
# FUNCTION db_rmsreps_pk_exists(p_ui,p_report_code)
#
# Validate PK - Unique
############################################################
#	CONSTANT UI_OFF SMALLINT = 0
#	CONSTANT UI_ON SMALLINT = 1
#	CONSTANT UI_FK SMALLINT = 2
#	CONSTANT UI_PK SMALLINT = 3
############################################################
FUNCTION db_rmsreps_pk_exists(p_ui,p_report_code)
	DEFINE p_ui SMALLINT
	DEFINE p_report_code LIKE rmsreps.report_code #INT
	DEFINE msgStr STRING
	DEFINE l_count INT
	DEFINE l_ret_exists BOOLEAN
	
	IF p_report_code IS NULL THEN
		IF p_ui != UI_OFF THEN
			ERROR "Report Code (rmsreps.report_code) Code can not be empty"
		END IF
		RETURN FALSE
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT count(*) 
	INTO l_count 
	FROM rmsreps
	WHERE cmpy_code = glob_rec_kandoouser.cmpy_code 
	AND rmsreps.report_code = p_report_code

	IF l_count <> 0 THEN
		LET l_ret_exists = TRUE	
		IF p_ui = UI_ON THEN
			MESSAGE "Report Code (rmsreps.report_code) Code exists! (", trim(p_report_code), ")"
		END IF
		IF p_ui = UI_PK THEN
			MESSAGE "Report Code (rmsreps.report_code) Code already exists! (", trim(p_report_code), ")"
		END IF
	ELSE
		LET l_ret_exists = FALSE	
		IF p_ui = UI_FK THEN
			MESSAGE "Report Code (rmsreps.report_code) Code does not exists! (", trim(p_report_code), ")"
		END IF
	END IF
	
	RETURN l_ret_exists
END FUNCTION
############################################################
# FUNCTION db_rmsreps_pk_exists(p_ui,p_report_code)
############################################################


############################################################
# FUNCTION db_rmsreps_get_rec(p_ui_mode,p_report_code)
# RETURN l_rec_rmsreps.*
# Get rmsreps record
############################################################
FUNCTION db_rmsreps_get_rec(p_ui_mode,p_report_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE rmsreps.report_code
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.*

	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record with empty rmsreps code"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT *
	INTO l_rec_rmsreps.*
	FROM rmsreps
	WHERE report_code = p_report_code
	AND cmpy_code = glob_rec_company.cmpy_code

	IF sqlca.sqlcode != 0 THEN 
		INITIALIZE l_rec_rmsreps.* TO NULL
		    
		IF p_ui_mode != UI_OFF THEN
			ERROR "Can not retrieve record! rmsreps record with report_code ", trim(p_report_code), " not found."
		END IF
	END IF 

	RETURN l_rec_rmsreps.* 
END FUNCTION 
############################################################
# END FUNCTION db_rmsreps_get_rec(p_ui_mode,p_report_code)
############################################################


############################################################
# FUNCTION db_rmsreps_get_exec_ind(p_ui_mode,p_report_code)
# RETURN l_ret_desc_text 
#
# Get exec_ind of report rmsreps record
############################################################
FUNCTION db_rmsreps_get_exec_ind(p_ui_mode,p_report_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE rmsreps.report_code
	DEFINE l_ret_exec_ind LIKE rmsreps.exec_ind
	DEFINE l_ret_status BOOLEAN
	
	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT exec_ind 
	INTO l_ret_exec_ind
	FROM rmsreps 
	WHERE rmsreps.report_code = p_report_code
	AND cmpy_code = glob_rec_company.cmpy_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report with reference report_code ",trim(p_report_code),  " NOT found"
		END IF
		INITIALIZE l_ret_exec_ind TO NULL
	END IF	

	RETURN l_ret_exec_ind	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_rmsreps_get_exec_ind(p_ui_mode,p_report_code)
############################################################


############################################################
# FUNCTION db_rmsreps_get_ref1_ind(p_ui_mode,p_report_code)
# RETURN l_ret_desc_text 
#
# Get ref1_ind of report rmsreps record
############################################################
FUNCTION db_rmsreps_get_ref1_ind(p_ui_mode,p_report_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE rmsreps.report_code
	DEFINE l_ret_ref1_ind LIKE rmsreps.ref1_ind
	DEFINE l_ret_status BOOLEAN
	
	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler
	SELECT ref1_ind 
	INTO l_ret_ref1_ind
	FROM rmsreps 
	WHERE rmsreps.report_code = p_report_code
	AND cmpy_code = glob_rec_company.cmpy_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report with reference report_code ",trim(p_report_code),  " NOT found"
		END IF
		INITIALIZE l_ret_ref1_ind TO NULL
	END IF	

	RETURN l_ret_ref1_ind	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_rmsreps_get_ref1_ind(p_ui_mode,p_report_code)
############################################################


############################################################
# FUNCTION db_rmsreps_get_ref2_ind(p_ui_mode,p_report_code)
# RETURN l_ret_desc_text 
#
# Get ref2_ind of report rmsreps record
############################################################
FUNCTION db_rmsreps_get_ref2_ind(p_ui_mode,p_report_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE rmsreps.report_code
	DEFINE l_ret_ref2_ind LIKE rmsreps.ref2_ind
	DEFINE l_ret_status BOOLEAN
	
	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT ref2_ind 
	INTO l_ret_ref2_ind
	FROM rmsreps 
	WHERE rmsreps.report_code = p_report_code
	AND cmpy_code = glob_rec_company.cmpy_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report with reference report_code ",trim(p_report_code),  " NOT found"
		END IF
		INITIALIZE l_ret_ref2_ind TO NULL
	END IF	

	RETURN l_ret_ref2_ind	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_rmsreps_get_ref2_ind(p_ui_mode,p_report_code)
############################################################


############################################################
# FUNCTION db_rmsreps_get_ref1_code(p_ui_mode,p_report_code)
# RETURN l_ret_desc_text 
#
# Get ref1_code of report rmsreps record
############################################################
FUNCTION db_rmsreps_get_ref1_code(p_ui_mode,p_report_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE rmsreps.report_code
	DEFINE l_ret_ref1_code LIKE rmsreps.ref1_code
	DEFINE l_ret_status BOOLEAN
	
	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT ref1_code 
	INTO l_ret_ref1_code
	FROM rmsreps 
	WHERE rmsreps.report_code = p_report_code
	AND cmpy_code = glob_rec_company.cmpy_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report with reference report_code ",trim(p_report_code),  " NOT found"
		END IF
		INITIALIZE l_ret_ref1_code TO NULL
	END IF	

	RETURN l_ret_ref1_code	                                                                                                
END FUNCTION
############################################################
# FUNCTION db_rmsreps_get_ref1_code(p_ui_mode,p_report_code)
############################################################


############################################################
# FUNCTION db_rmsreps_get_ref2_code(p_ui_mode,p_report_code)
# RETURN l_ret_desc_text 
#
# Get ref2_code of report rmsreps record
############################################################
FUNCTION db_rmsreps_get_ref2_code(p_ui_mode,p_report_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE rmsreps.report_code
	DEFINE l_ret_ref2_code LIKE rmsreps.ref2_code
	DEFINE l_ret_status BOOLEAN
	
	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	SELECT ref2_code 
	INTO l_ret_ref2_code
	FROM rmsreps 
	WHERE rmsreps.report_code = p_report_code
	AND cmpy_code = glob_rec_company.cmpy_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report with reference report_code ",trim(p_report_code),  " NOT found"
		END IF
		INITIALIZE l_ret_ref2_code TO NULL
	END IF	

	RETURN l_ret_ref2_code	                                                                                                
END FUNCTION
############################################################
# FUNCTION db_rmsreps_get_ref2_code(p_ui_mode,p_report_code)
############################################################


############################################################
# FUNCTION db_rmsreps_get_status_ind(p_ui_mode,p_report_code)
# RETURN l_ret_desc_text 
#
# Get status_ind of report rmsreps record
############################################################
FUNCTION db_rmsreps_get_status_ind(p_ui_mode,p_report_code)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE rmsreps.report_code
	DEFINE l_ret_status_ind LIKE rmsreps.status_ind
	DEFINE l_ret_status BOOLEAN
	
	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Code can NOT be empty"
		END IF
		RETURN NULL
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

			SELECT status_ind 
			INTO l_ret_status_ind
			FROM rmsreps 
			WHERE rmsreps.report_code = p_report_code
			AND cmpy_code = glob_rec_company.cmpy_code  		
	
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report with reference report_code ",trim(p_report_code),  " NOT found"
		END IF
		INITIALIZE l_ret_status_ind TO NULL
	END IF	

	RETURN l_ret_status_ind	                                                                                                
END FUNCTION
############################################################
# END FUNCTION db_rmsreps_get_status_ind(p_ui_mode,p_report_code)
############################################################


############################################################
# FUNCTION db_rmsreps_set_status_text(p_ui_mode,p_report_code,p_status_text)
# RETURN l_ret_status	 
#
# Set the status_text in the DB 
############################################################
FUNCTION db_rmsreps_set_status_text(p_ui_mode,p_report_code,p_status_text)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE rmsreps.report_code
	DEFINE p_status_text LIKE rmsreps.status_text
	DEFINE l_ret_status BOOLEAN
	
	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Code can NOT be empty"
		END IF
		RETURN FALSE
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

		UPDATE rmsreps 
		SET status_text = p_status_text 
		WHERE report_code = p_report_code 
		AND cmpy_code = glob_rec_company.cmpy_code 
		
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Could not update report record rmsreps ",trim(p_report_code), " and p_status_text=", p_status_text
		END IF
		LET l_ret_status = FALSE
	ELSE
		LET l_ret_status = TRUE
		#LET glob_rec_rmsreps.status_text = p_status_text
	END IF	

	RETURN l_ret_status	                                                                                                
END FUNCTION	
############################################################
# END FUNCTION db_rmsreps_set_status_text(p_ui_mode,p_report_code,p_status_text)
############################################################


############################################################
# FUNCTION db_rmsreps_set_status_text_and_status_ind(p_ui_mode,p_report_code,p_status_text,p_status_ind)
# RETURN l_ret_status	 
#
# Set the status_text AND status_ind in the DB 
############################################################
FUNCTION db_rmsreps_set_status_text_and_status_ind(p_ui_mode,p_report_code,p_status_text,p_status_ind)
	DEFINE p_ui_mode SMALLINT
	DEFINE p_report_code LIKE rmsreps.report_code
	DEFINE p_status_text LIKE rmsreps.status_text
	DEFINE p_status_ind  LIKE rmsreps.status_ind
	DEFINE l_ret_status BOOLEAN
	
	IF p_report_code IS NULL THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Report Code can NOT be empty"
		END IF
		RETURN FALSE
	END IF

	WHENEVER SQL ERROR CALL kandoo_sql_errors_handler

	UPDATE rmsreps 
	SET status_text = p_status_text, status_ind = p_status_ind 
	WHERE report_code = p_report_code 
	AND cmpy_code = glob_rec_company.cmpy_code 
		
	IF sqlca.sqlcode != 0 THEN
		IF p_ui_mode != UI_OFF THEN		
			ERROR "Could not update report record rmsreps ",trim(p_report_code), "with p_status_ind=",p_status_ind, " and p_status_text=", p_status_text
		END IF
		LET l_ret_status = FALSE
	ELSE
		LET l_ret_status = TRUE
		#LET glob_rec_rmsreps.status_text = p_status_text
		#LET glob_rec_rmsreps.status_ind = p_status_ind
	END IF	

	RETURN l_ret_status	                                                                                                
END FUNCTION		
############################################################
# END FUNCTION db_rmsreps_set_status_text_and_status_ind(p_ui_mode,p_report_code,p_status_text,p_status_ind)
############################################################


############################################################
# FUNCTION db_rmsreps_show_record(p_report_code)
# RETURN VOID
#
# Just for debugging purpose
#
# Set the status_text AND status_ind in the DB and glob record
############################################################
FUNCTION db_rmsreps_show_record(p_report_code)
	DEFINE p_report_code LIKE rmsreps.report_code
	DEFINE l_rec_rmsreps RECORD LIKE rmsreps.*

	CALL db_rmsreps_get_rec(UI_ON,p_report_code) RETURNING l_rec_rmsreps.*
	#DEBUG for developer
	IF get_kandoooption_feature_state("GW","DV") = "Y" THEN
	--IF l_rec_rmsreps.exec_ind = 1 THEN #Only show this debug information if we are NOT in unattended mode 		
		OPEN WINDOW w_rmsreps_debug WITH FORM "U701-rmsreps_record"
		CALL ui.interface.refresh()
		INPUT BY NAME l_rec_rmsreps.* WITHOUT DEFAULTS
		#DISPLAY BY NAME l_rec_rmsreps.*
		#CALL doneprompt("Close","Close","ACCEPT")
		CLOSE WINDOW w_rmsreps_debug
	END IF	
END FUNCTION
############################################################
# END FUNCTION db_rmsreps_show_record(p_report_code)
############################################################