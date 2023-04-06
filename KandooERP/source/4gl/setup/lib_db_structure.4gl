GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getStructureCount()
# FUNCTION structureLookupFilterDataSourceCursor(pRecStructureFilter)
# FUNCTION structureLookupSearchDataSourceCursor(p_RecStructureSearch)
# FUNCTION StructureLookupFilterDataSource(pRecStructureFilter)
# FUNCTION structureLookup_filter(pStructureCode)
# FUNCTION import_structure()
# FUNCTION exist_structureRec(p_cmpy_code, p_start_num)
# FUNCTION delete_structure_all()
# FUNCTION structureMenu()						-- Offer different OPTIONS of this library via a menu

# Structure record types
	DEFINE t_recStructure  
		TYPE AS RECORD
			start_num LIKE structure.start_num,
			desc_text LIKE structure.desc_text
		END RECORD 

	DEFINE t_recStructureFilter  
		TYPE AS RECORD
			filter_start_num LIKE structure.start_num,
			filter_desc_text LIKE structure.desc_text
		END RECORD 

	DEFINE t_recStructureSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recStructure_noCmpyId 
		TYPE AS RECORD 
    start_num LIKE structure.start_num,
    length_num LIKE structure.length_num,
    desc_text LIKE structure.desc_text,
    default_text LIKE structure.default_text,
    type_ind LIKE structure.type_ind
	END RECORD	


	
########################################################################################
# FUNCTION structureMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION structureMenu()
	#Default company structure
	IF gl_setupRec_admin_rec_kandoouser.acct_mask_code IS NULL THEN
		LET gl_setupRec_admin_rec_kandoouser.acct_mask_code = "??.????"
	END IF

	
	MENU
		ON ACTION "GL-Structure"
			OPEN WINDOW wStructureImport WITH FORM "per/setup/lib_db_data_import_01"
			INPUT BY NAME gl_setupRec_admin_rec_kandoouser.acct_mask_code WITHOUT DEFAULTS ATTRIBUTE(UNBUFFERED)
			END INPUT		
			CLOSE WINDOW wStructureImport
		ON ACTION "Import"
			CALL import_structure()
		
		ON ACTION "Export"
			CALL unload_structure()
		#ON ACTION "Import"
		#	CALL import_structure()

		ON ACTION "Delete All"
			CALL delete_structure_all()
			
		ON ACTION "Count"
			CALL getStructureCount() --Count all structure rows FROM the current company

		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getStructureCount()
#-------------------------------------------------------
# Returns the number of Structure entries for the current company
########################################################################################
FUNCTION getStructureCount()
	DEFINE ret_StructureCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Structure CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Structure ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Structure.DECLARE(sqlQuery) #CURSOR FOR getStructure
	CALL c_Structure.SetResults(ret_StructureCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Structure.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_StructureCount = -1
	ELSE
		CALL c_Structure.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of GL-Flex Structure Records:", trim(ret_StructureCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("GL Flex Structure Count", tempMsg,"info") 	
	END IF

	RETURN ret_StructureCount
END FUNCTION

########################################################################################
# FUNCTION structureLookupFilterDataSourceCursor(pRecStructureFilter)
#-------------------------------------------------------
# Returns the Structure CURSOR for the lookup query
########################################################################################
FUNCTION structureLookupFilterDataSourceCursor(pRecStructureFilter)
	DEFINE pRecStructureFilter OF t_recStructureFilter
	DEFINE sqlQuery STRING
	DEFINE c_Structure CURSOR
	
	LET sqlQuery =	"SELECT ",
									"structure.start_num, ", 
									"structure.desc_text ",
									"FROM structure ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecStructureFilter.filter_start_num IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND start_num LIKE '", pRecStructureFilter.filter_start_num CLIPPED, "%' "  
	END IF									

	IF pRecStructureFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecStructureFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY start_num"

	CALL c_structure.DECLARE(sqlQuery)
		
	RETURN c_structure
END FUNCTION



########################################################################################
# structureLookupSearchDataSourceCursor(p_RecStructureSearch)
#-------------------------------------------------------
# Returns the Structure CURSOR for the lookup query
########################################################################################
FUNCTION structureLookupSearchDataSourceCursor(p_RecStructureSearch)
	DEFINE p_RecStructureSearch OF t_recStructureSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Structure CURSOR
	
	LET sqlQuery =	"SELECT ",
									"structure.start_num, ", 
									"structure.desc_text ",
 
									"FROM structure ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecStructureSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((start_num LIKE '", p_RecStructureSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecStructureSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecStructureSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY start_num"

	CALL c_structure.DECLARE(sqlQuery) #CURSOR FOR structure
	
	RETURN c_structure
END FUNCTION


########################################################################################
# FUNCTION StructureLookupFilterDataSource(pRecStructureFilter)
#-------------------------------------------------------
# CALLS StructureLookupFilterDataSourceCursor(pRecStructureFilter) with the StructureFilter data TO get a CURSOR
# Returns the Structure list array arrStructureList
########################################################################################
FUNCTION StructureLookupFilterDataSource(pRecStructureFilter)
	DEFINE pRecStructureFilter OF t_recStructureFilter
	DEFINE recStructure OF t_recStructure
	DEFINE arrStructureList DYNAMIC ARRAY OF t_recStructure 
	DEFINE c_Structure CURSOR
	DEFINE retError SMALLINT
		
	CALL StructureLookupFilterDataSourceCursor(pRecStructureFilter.*) RETURNING c_Structure
	
	CALL arrStructureList.CLEAR()

	CALL c_Structure.SetResults(recStructure.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Structure.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Structure.FetchNext()=0)
		CALL arrStructureList.append([recStructure.start_num, recStructure.desc_text])
	END WHILE	

	END IF
	
	IF arrStructureList.getSize() = 0 THEN
		ERROR "No structure's found with the specified filter criteria"
	END IF
	
	RETURN arrStructureList
END FUNCTION	

########################################################################################
# FUNCTION StructureLookupSearchDataSource(pRecStructureFilter)
#-------------------------------------------------------
# CALLS StructureLookupSearchDataSourceCursor(pRecStructureFilter) with the StructureFilter data TO get a CURSOR
# Returns the Structure list array arrStructureList
########################################################################################
FUNCTION StructureLookupSearchDataSource(p_recStructureSearch)
	DEFINE p_recStructureSearch OF t_recStructureSearch	
	DEFINE recStructure OF t_recStructure
	DEFINE arrStructureList DYNAMIC ARRAY OF t_recStructure 
	DEFINE c_Structure CURSOR
	DEFINE retError SMALLINT	
	CALL StructureLookupSearchDataSourceCursor(p_recStructureSearch) RETURNING c_Structure
	
	CALL arrStructureList.CLEAR()

	CALL c_Structure.SetResults(recStructure.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Structure.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Structure.FetchNext()=0)
		CALL arrStructureList.append([recStructure.start_num, recStructure.desc_text])
	END WHILE	

	END IF
	
	IF arrStructureList.getSize() = 0 THEN
		ERROR "No structure's found with the specified filter criteria"
	END IF
	
	RETURN arrStructureList
END FUNCTION


########################################################################################
# FUNCTION structureLookup_filter(pStructureCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Structure code start_num
# DateSoure AND Cursor are managed in other functions which are called
# CALL StructureLookupFilterDataSource(recStructureFilter.*) RETURNING arrStructureList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Structure Code start_num
#
# Example:
# 			LET pr_Structure.start_num = StructureLookup(pr_Structure.start_num)
########################################################################################
FUNCTION structureLookup_filter(pStructureCode)
	DEFINE pStructureCode LIKE Structure.start_num
	DEFINE arrStructureList DYNAMIC ARRAY OF t_recStructure
	DEFINE recStructureFilter OF t_recStructureFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wStructureLookup WITH FORM "StructureLookup_filter"


	CALL StructureLookupFilterDataSource(recStructureFilter.*) RETURNING arrStructureList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recStructureFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL StructureLookupFilterDataSource(recStructureFilter.*) RETURNING arrStructureList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrStructureList TO scStructureList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pStructureCode = arrStructureList[idx].start_num
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recStructureFilter.filter_start_num IS NOT NULL
			OR recStructureFilter.filter_desc_text IS NOT NULL

		THEN
			LET recStructureFilter.filter_start_num = NULL
			LET recStructureFilter.filter_desc_text = NULL

			CALL StructureLookupFilterDataSource(recStructureFilter.*) RETURNING arrStructureList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_start_num"
		IF recStructureFilter.filter_start_num IS NOT NULL THEN
			LET recStructureFilter.filter_start_num = NULL
			CALL StructureLookupFilterDataSource(recStructureFilter.*) RETURNING arrStructureList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recStructureFilter.filter_desc_text IS NOT NULL THEN
			LET recStructureFilter.filter_desc_text = NULL
			CALL StructureLookupFilterDataSource(recStructureFilter.*) RETURNING arrStructureList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wStructureLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pStructureCode	
END FUNCTION				
		

########################################################################################
# FUNCTION structureLookup(pStructureCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Structure code start_num
# DateSoure AND Cursor are managed in other functions which are called
# CALL StructureLookupSearchDataSource(recStructureFilter.*) RETURNING arrStructureList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Structure Code start_num
#
# Example:
# 			LET pr_Structure.start_num = StructureLookup(pr_Structure.start_num)
########################################################################################
FUNCTION structureLookup(pStructureCode)
	DEFINE pStructureCode LIKE Structure.start_num
	DEFINE arrStructureList DYNAMIC ARRAY OF t_recStructure
	DEFINE recStructureSearch OF t_recStructureSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wStructureLookup WITH FORM "structureLookup"

	CALL StructureLookupSearchDataSource(recStructureSearch.*) RETURNING arrStructureList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recStructureSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL StructureLookupSearchDataSource(recStructureSearch.*) RETURNING arrStructureList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrStructureList TO scStructureList.* 
		BEFORE ROW
			IF arrStructureList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pStructureCode = arrStructureList[idx].start_num
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recStructureSearch.filter_any_field IS NOT NULL

		THEN
			LET recStructureSearch.filter_any_field = NULL

			CALL StructureLookupSearchDataSource(recStructureSearch.*) RETURNING arrStructureList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_start_num"
		IF recStructureSearch.filter_any_field IS NOT NULL THEN
			LET recStructureSearch.filter_any_field = NULL
			CALL StructureLookupSearchDataSource(recStructureSearch.*) RETURNING arrStructureList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wStructureLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pStructureCode	
END FUNCTION				

############################################
# FUNCTION import_structure()
############################################
FUNCTION import_structure()
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
	
	DEFINE rec_structure OF t_recStructure_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wStructureImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Company GL-Flex-Structure List Data (table: structure)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_structure
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_structure(	    
    start_num SMALLINT,
    length_num SMALLINT,
    desc_text CHAR(20),
    default_text CHAR(18),
    type_ind CHAR(1)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_structure	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wStructureImport WITH FORM "per/setup/lib_db_data_import_01"
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
							TO company.desc_text,country_code,country_text,language_code,language_text
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
					CLOSE WINDOW wStructureImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	
	#########################################
	# Depending on the company GL structure, 
	# we need TO use different UNL files (??.???? / ??.????.???? etc..)
	#
	# NOTE: This whole area of flex codes, structure etc.. IS still unclear
	# documentation doesn't help much either
	# So, let's see this as experimental until further notice
	#########################################
	CASE gl_setupRec_admin_rec_kandoouser.acct_mask_code
		WHEN "????"
			LET load_file = "unl/structure-1.unl"
		WHEN "??.????"
			LET load_file = "unl/structure-2.unl"
		WHEN "??.????.????"
			LET load_file = "unl/structure-3.unl"
		OTHERWISE
			LET load_file = "unl/structure-1.unl"
			
			
	END CASE
	
	

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_structure
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_structure
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_structure
			LET importReport = importReport, "Code:", trim(rec_structure.start_num) , "     -     Desc:", trim(rec_structure.desc_text), "\n"
					
			INSERT INTO structure VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_structure.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_structure.start_num) , "     -     Desc:", trim(rec_structure.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wStructureImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_structureRec(p_cmpy_code, p_start_num)
########################################################
FUNCTION exist_structureRec(p_cmpy_code, p_start_num)
	DEFINE p_cmpy_code LIKE structure.cmpy_code
	DEFINE p_start_num LIKE structure.start_num
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM structure 
     WHERE cmpy_code = p_cmpy_code
     AND start_num = p_start_num

	DROP TABLE temp_structure
	CLOSE WINDOW wStructureImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_structure()
###############################################################
FUNCTION unload_structure(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/structure-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM structure ORDER BY cmpy_code, start_num ASC
	
	LET tmpMsg = "All structure data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("structure Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_structure_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_structure_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE structure.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wstructureImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "structure Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing structure table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM structure
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table structure!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table structure where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wStructureImport		
END FUNCTION	