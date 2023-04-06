############################################################
# GLOBAL Scope Variables
############################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../gl/G_GL_GLOBALS.4gl"
GLOBALS "../setup/lib_db_setup_GLOBALS.4gl"

###############################################################
# Accessor Functions GroupInfo records
###############################################################

FUNCTION getGroupInfo_GroupName(p_cmpy_code, p_group_code)
	DEFINE p_cmpy_code LIKE groupInfo.cmpy_code
	DEFINE p_group_code LIKE groupInfo.group_code
	DEFINE l_group_name LIKE groupinfo.desc_text
	SELECT desc_text INTO l_group_name
	FROM groupInfo
	WHERE cmpy_code = p_cmpy_code
	AND group_code = p_group_code
	
	RETURN l_group_name

END FUNCTION


###############################################################
# FUNCTION countGroupInfo(p_cmpy_code, p_group_code)
###############################################################
FUNCTION countGroupInfo(p_cmpy_code, p_group_code)
	DEFINE p_cmpy_code LIKE groupinfo.cmpy_code
	DEFINE p_group_code LIKE groupinfo.group_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM groupinfo 
     WHERE cmpy_code = p_cmpy_code
     AND group_code = p_group_code

	RETURN recCount

END FUNCTION


###############################################################
# Import GroupInfo records
###############################################################
FUNCTION import_groupinfo(p_ui_mode, p_cmpy_code)
	DEFINE p_ui_mode SMALLINT 
	DEFINE p_cmpy_code LIKE company.cmpy_code
	DEFINE recCount SMALLINT	
	DEFINE msgString STRING
	DEFINE importReport STRING
	#DEFINE importReportLine VARCHAR(100)
			
	DEFINE driver_error  STRING
	DEFINE native_error  STRING
	DEFINE native_code  INTEGER
	DEFINE count_rows_processed INT
	DEFINE count_rows_inserted INT
	DEFINE count_insert_errors INT
	DEFINE count_already_exist INT
	
	DEFINE cmpy_code_provided BOOLEAN
 		
	DEFINE p_name_text LIKE company.name_text
	#DEFINE p_language_code LIKE company.language_code
	DEFINE p_language_text LIKE language.language_text

	DEFINE p_country_text LIKE country.country_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING

	DEFINE l_rec_groupinfo RECORD 
		cmpy_code            CHAR(2),
		group_code            CHAR(7),
		desc_text            CHAR(40)
	END RECORD	

	IF p_ui_mode IS NOT NULL THEN
		LET gl_setupRec.ui_mode = p_ui_mode
	END IF
	IF p_cmpy_code IS NOT NULL THEN
		LET glob_rec_setup_company.cmpy_code = p_cmpy_code	
	END IF
----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_groupinfo
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_groupinfo(
			cmpy_code            NCHAR(2),
			group_code            NCHAR(7),
			desc_text            NCHAR(40)
		)	
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_groupinfo	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------	


	
	#We do the company exist check only if the silent mode IS NOT active 
	#silent mode IS for the main setup/installer.. the company table IS empty in this case
	IF gl_setupRec.ui_mode = UI_ON THEN	
	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF glob_rec_setup_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (glob_rec_setup_company.cmpy_code) 
		RETURNING p_name_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text
		CASE 
		WHEN glob_rec_setup_company.country_code = "NUL"
			LET msgString = "Company's country code ->",trim(glob_rec_setup_company.cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
			LET cmpy_code_provided = FALSE
			RETURN		
		WHEN glob_rec_setup_company.country_code = "0"
			--company code comp_code does NOT exist
			LET msgString = "Company code ->",trim(glob_rec_setup_company.cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			LET cmpy_code_provided = FALSE
			RETURN
		OTHERWISE
			LET cmpy_code_provided = TRUE
			#DISPLAY p_name_text,p_country_code,p_country_text TO name_text,country_code,country_text
		END CASE				

		#OPEN WINDOW wtaxImport WITH FORM "per/setup/lib_db_data_import_01"
		#DISPLAY "tax Type Delete" TO header_text
	END IF
	END IF
	
	IF gl_setupRec.ui_mode = UI_ON THEN
		OPEN WINDOW wDataImport WITH FORM "per/setup/db_groupinfo_input"
		DISPLAY "Import Group Info / Table: groupinfo" TO header_text
		DISPLAY p_name_text,glob_rec_setup_company.country_code,p_country_text TO name_text,country_code,country_text

	
	IF cmpy_code_provided = FALSE THEN
		INPUT glob_rec_setup_company.cmpy_code,glob_rec_setup_company.country_code WITHOUT DEFAULTS 
		FROM inputRec.* 
			AFTER FIELD cmpy_code
				CALL get_company_info (glob_rec_setup_company.cmpy_code) 
				RETURNING p_name_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text
				CASE 
				WHEN glob_rec_setup_company.country_code = "NUL"
					LET msgString = "Company's country code ->",trim(glob_rec_setup_company.cmpy_code), "<-does NOT exist"
					CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
					LET cmpy_code_provided = FALSE
					RETURN		
				WHEN glob_rec_setup_company.country_code = "0"
					--company code comp_code does NOT exist
					LET msgString = "Company code ->",trim(glob_rec_setup_company.cmpy_code), "<-does NOT exist"
					CALL fgl_winmessage("Company does NOT exist",msgString,"error")
					LET cmpy_code_provided = FALSE
					RETURN
				OTHERWISE
					LET cmpy_code_provided = TRUE
					DISPLAY glob_rec_setup_company.cmpy_code,p_name_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text
					TO cmpy_code,name_text,country_code,country_text,language_code,language_text
				END CASE				
		END INPUT
	ELSE
		CALL get_company_info (glob_rec_setup_company.cmpy_code) 
		RETURNING p_name_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text
		IF gl_setupRec.ui_mode = UI_ON THEN
			DISPLAY glob_rec_setup_company.cmpy_code,p_name_text,glob_rec_setup_company.country_code,p_country_text,glob_rec_setup_company.language_code,p_language_text
			TO cmpy_code,name_text,country_code,country_text,language_code,language_text
		END IF	
	END IF
		
	END IF		

	


		IF gl_setupRec.ui_mode = UI_ON THEN	
	IF cmpy_code_provided = FALSE THEN
	
		INPUT glob_rec_setup_company.cmpy_code WITHOUT DEFAULTS FROM inputRec.*  
		END INPUT

	ELSE

			DISPLAY glob_rec_setup_company.cmpy_code TO cmpy_code
	END IF
		END IF


	LET load_file = "unl/groupinfo-",glob_rec_setup_company.country_code CLIPPED,".unl"
	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",glob_rec_setup_company.country_code
		CALL fgl_winmessage("Group Info Table Data load",tmpMsg ,"error")
	ELSE
		#CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_groupinfo
	
		DECLARE template_cur CURSOR FOR 
			SELECT *
			FROM temp_groupinfo
	
		WHENEVER ERROR CONTINUE		
						
	  LET count_rows_processed = 0
	  LET count_rows_inserted = 0
	  LET count_insert_errors = 0
	  LET count_already_exist = 0
	  
	  
	FOREACH template_cur INTO l_rec_groupinfo
	  	#DISPLAY l_rec_groupinfo.*  	
		LET importReport = importReport, "Code:", trim(l_rec_groupinfo.group_code) , "     -     Desc:", trim(l_rec_groupinfo.desc_text), "\n"
		INSERT INTO groupinfo VALUES(
		glob_rec_setup_company.cmpy_code,
		l_rec_groupinfo.group_code,
		l_rec_groupinfo.desc_text
		)
		CASE 
			WHEN STATUS = 0
				LET count_rows_inserted = count_rows_inserted + 1
			WHEN STATUS = -268 OR STATUS = -239
				# duplicate primary key OR unique key
				LET importReport = importReport, "Code:", trim(l_rec_groupinfo.group_code) , "     -     Desc:", trim(l_rec_groupinfo.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		IF gl_setupRec.ui_mode = UI_ON THEN
			DISPLAY BY NAME importReport
		END IF
		
	END FOREACH
	
	WHENEVER ERROR STOP

END IF
	
	IF gl_setupRec.ui_mode = UI_ON THEN	
		DISPLAY BY NAME count_rows_processed
		DISPLAY BY NAME count_rows_inserted
		DISPLAY BY NAME count_insert_errors
		DISPLAY BY NAME count_already_exist
		
		INPUT BY NAME importReport WITHOUT DEFAULTS
			ON ACTION "Done"
				EXIT INPUT
		END INPUT

	END IF
	
	DROP TABLE temp_groupinfo
		
	IF gl_setupRec.ui_mode = UI_ON THEN
		CLOSE WINDOW wDataImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION



###############################################################
# FUNCTION delete_groupinfo_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_groupinfo_all()

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING
	
	IF glob_rec_setup_company.cmpy_code IS NOT NULL THEN
		IF NOT db_company_pk_exists(UI_OFF,glob_rec_setup_company.cmpy_code) THEN
		#IF NOT exist_company(glob_rec_setup_company.cmpy_code) THEN  --company code comp_code does NOT exist
			LET msgString = "Company code ->",trim(glob_rec_setup_company.cmpy_code), "<-does NOT exist"
			
			IF gl_setupRec.ui_mode = UI_ON THEN
				CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			END IF
			
			RETURN
		END IF
		
		LET cmpy_code_provided = TRUE
	ELSE
		LET cmpy_code_provided = FALSE				

		IF gl_setupRec.ui_mode <> UI_ON AND cmpy_code_provided = FALSE THEN
			CALL fgl_winmessage("No valid cmpy_code argument","Function delete_groupinfo_all was called\nin silent mode without a cmpy_code argument","error")
			RETURN
		END IF

		IF gl_setupRec.ui_mode = UI_ON THEN
		
			OPEN WINDOW wgroupinfoImport WITH FORM "per/setup/lib_db_data_import_01"
			DISPLAY "groupinfo Delete" TO header_text
		END IF		
				
	END IF

	IF cmpy_code_provided = FALSE THEN

		INPUT glob_rec_setup_company.cmpy_code WITHOUT DEFAULTS FROM cmpy_code 
		END INPUT

	ELSE

		IF gl_setupRec.ui_mode = UI_ON THEN	
			DISPLAY glob_rec_setup_company.cmpy_code TO cmpy_code
		END IF	
	END IF

	
	IF gl_setupRec.ui_mode = UI_ON THEN --no ui
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing groupinfo table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM groupinfo
		WHENEVER ERROR STOP
	END IF	
		
	IF gl_setupRec.ui_mode = UI_ON THEN --no ui
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the groupinfo table!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			LET tmpMsg = "All data in the table groupinfo where deleted"		
			CALL fgl_winmessage("Success",tmpMsg,"info")					
		END IF		

	END IF

	IF gl_setupRec.ui_mode = UI_ON THEN
		CLOSE WINDOW wGroupinfoImport
	END IF
			
END FUNCTION	
