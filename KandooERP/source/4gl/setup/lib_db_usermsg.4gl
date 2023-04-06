GLOBALS "lib_db_globals.4gl"

# HUHO 08.05.2018 Created   (for setup)

	DEFINE t_recUserMsg_noCmpyId 
		TYPE AS RECORD 
	    #cmpy_code LIKE usermsg.cmpy_code,
	    line1_text LIKE usermsg.line1_text,
	    line2_text LIKE usermsg.line2_text
	END RECORD	

	
########################################################################################
# FUNCTION userMsgMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION userMsgMenu()
	MENU
		ON ACTION "Import"
			CALL import_userMsg()
		ON ACTION "Export"
			CALL unload_userMsg(FALSE,"exp")
		ON ACTION "Delete All"
			CALL delete_userMsg_all()
		ON ACTION "Count"
			CALL getUserMsgCount() --Count all userMsg rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getUserMsgCount()
#-------------------------------------------------------
# Returns the number of UserMsg entries for the current company
########################################################################################
FUNCTION getUserMsgCount()
	DEFINE ret_UserMsgCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_UserMsg CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM usermsg ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_UserMsg.DECLARE(sqlQuery) #CURSOR FOR getUserMsg
	CALL c_UserMsg.SetResults(ret_UserMsgCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_UserMsg.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_UserMsgCount = -1
	ELSE
		CALL c_UserMsg.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of UserMsg Types:", trim(ret_UserMsgCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("UserMsg Count", tempMsg,"info") 	
	END IF

	RETURN ret_UserMsgCount
END FUNCTION

############################################
# FUNCTION import_userMsg()
############################################
FUNCTION import_userMsg()
	DEFINE recCount SMALLINT
	
	DEFINE msgString STRING
	DEFINE importReport STRING
		
  DEFINE driver_error  STRING
  DEFINE native_error  STRING
  DEFINE native_code  INTEGER
	
	DEFINE count_rows_processed INT
	DEFINE count_rows_inserted INT
	DEFINE count_insert_errors INT
	DEFINE count_already_exist INT
	 
	DEFINE cmpy_code_provided BOOLEAN
	DEFINE p_name_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_userMsg OF t_recUserMsg_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wUserMsgImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import UserMsg List Data (table: usermsg)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_usermsg
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_usermsg(
	    #cmpy_code CHAR(2),
	    line1_text CHAR(60),
	    line2_text CHAR(60)


		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_usermsg	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_name_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

		CASE 
			WHEN gl_setupRec_default_company.country_code = "NUL"
				LET msgString = "Company's country code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
				CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
				LET cmpy_code_provided = FALSE
				RETURN		
			WHEN gl_setupRec_default_company.country_code = "0"
				--company code comp_code does NOT exist
				LET msgString = "Company code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
				CALL fgl_winmessage("Company does NOT exist",msgString,"error")
				LET cmpy_code_provided = FALSE
				RETURN
			OTHERWISE
				LET cmpy_code_provided = TRUE
		END CASE				

	END IF

--------------------------------------------------------------- before ---------------------------------------------------------------------
	
	IF gl_setupRec.silentMode = 0 THEN	
	#	OPEN WINDOW wUserMsgImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_name_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

					CASE 
						WHEN gl_setupRec_default_company.country_code = "NUL"
							LET msgString = "Company's country code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
							CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
							LET cmpy_code_provided = FALSE
							RETURN		
						WHEN gl_setupRec_default_company.country_code = "0"
							--company code comp_code does NOT exist
							LET msgString = "Company code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
							CALL fgl_winmessage("Company does NOT exist",msgString,"error")
							LET cmpy_code_provided = FALSE
							RETURN
						OTHERWISE
							LET cmpy_code_provided = TRUE
							DISPLAY p_name_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
							TO company.name_text,country_code,country_text,language_code,language_text
					END CASE 
			END INPUT

		ELSE
			IF gl_setupRec.silentMode = FALSE THEN	
				DISPLAY gl_setupRec_default_company.cmpy_code TO cmpy_code

				INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code
					WITHOUT DEFAULTS 
					FROM inputRec3.*  
				END INPUT
				
				IF int_flag THEN
					LET int_flag = FALSE
					CLOSE WINDOW wUserMsgImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/usermsg-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_usermsg
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_usermsg
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_userMsg
			LET importReport = importReport, "Code:", trim(rec_userMsg.line1_text) , "     -     Desc:", trim(rec_userMsg.line1_text), "\n"
					
			INSERT INTO usermsg VALUES(
				gl_setupRec_default_company.cmpy_code,
				rec_userMsg.*
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_userMsg.line1_text) , "     -     Desc:", trim(rec_userMsg.line1_text), " ->DUPLICATE = Ignored !\n"
					LET count_already_exist = count_already_exist +1
				OTHERWISE	
					LET count_insert_errors = count_insert_errors +1
				 	LET driver_error = fgl_driver_error()
				 	LET native_error = fgl_native_error()
				 	LET native_code = fgl_native_code()
				
					LET importReport = importReport, "ERROR STATUS:\t", trim(STATUS), "\n"
					LET importReport = importReport, "sqlca.sqlcode:\t",trim(sqlca.sqlcode), "\n" 
					LET importReport = importReport, "driver_error:\t", trim(driver_error), "\n"
					LET importReport = importReport, "native_error:\t", trim(native_error), "\n"
					LET importReport = importReport, "native_code:\t",  trim(native_code), "\n"					
			END CASE
			
			LET count_rows_processed= count_rows_processed + 1
		
		END FOREACH

	END IF

	WHENEVER ERROR STOP

	IF gl_setupRec.silentMode = FALSE THEN
			
		DISPLAY BY NAME count_rows_processed
		DISPLAY BY NAME count_rows_inserted
		DISPLAY BY NAME count_insert_errors
		DISPLAY BY NAME count_already_exist
		
		INPUT BY NAME importReport WITHOUT DEFAULTS
			ON ACTION "Done"
				EXIT INPUT
		END INPUT
		
		CLOSE WINDOW wUserMsgImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_userMsgRec(p_cmpy_code, p_line1_text)
########################################################
FUNCTION exist_userMsgRec(p_cmpy_code, p_line1_text)
	DEFINE p_cmpy_code LIKE usermsg.cmpy_code
	DEFINE p_line1_text LIKE usermsg.line1_text
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM usermsg 
     WHERE cmpy_code = p_cmpy_code
     #AND line1_text = p_line1_text

	DROP TABLE temp_usermsg
	CLOSE WINDOW wUserMsgImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_userMsg()
###############################################################
FUNCTION unload_userMsg(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)

	LET currentCompany = getCurrentUser_cmpy_code()	
	LET unloadFile = "unl/usermsg-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 

	LET unloadFile1 = unloadFile CLIPPED, "_", getCurrentUser_cmpy_code()
	UNLOAD TO unloadFile1
		SELECT  
    #cmpy_code CHAR(2),
    line1_text,
    line2_text

		FROM usermsg
		WHERE cmpy_code = currentCompany
		ORDER BY line1_text ASC
		
	LET unloadFile2 = 	unloadFile CLIPPED , "_all"
	UNLOAD TO unloadFile2 
	SELECT * FROM usermsg ORDER BY cmpy_code,line1_text ASC	
		
	
	LET tmpMsg = "All userMsg (ORDER processing parameters) data were exported/written TO:\n", unloadFile1, " AND ", unloadFile2
	CALL fgl_winmessage("usermsg Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_userMsg_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_userMsg_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE usermsg.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wuserMsgImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "usermsg (Order Processing Parameters) Delete" TO header_text
	END IF

	
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		IF NOT db_company_pk_exists(UI_OFF,gl_setupRec_default_company.cmpy_code) THEN	
		#IF NOT exist_company(gl_setupRec_default_company.cmpy_code) THEN  --company code comp_code does NOT exist
			LET msgString = "Company code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			RETURN
		END IF
			LET cmpy_code_provided = TRUE
	ELSE
			LET cmpy_code_provided = FALSE				

	END IF

	IF cmpy_code_provided = FALSE THEN

		INPUT gl_setupRec_default_company.cmpy_code WITHOUT DEFAULTS FROM cmpy_code 
		END INPUT

	ELSE

		IF gl_setupRec.silentMode = 0 THEN 	
			DISPLAY gl_setupRec_default_company.cmpy_code TO cmpy_code
		END IF	
	END IF

	
	IF gl_setupRec.silentMode = 0 THEN --no ui
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing userMsg table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM usermsg
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table usermsg!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table usermsg where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wUserMsgImport		
END FUNCTION	