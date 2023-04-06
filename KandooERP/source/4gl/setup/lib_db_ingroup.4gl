GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getInGroupCount()
# FUNCTION ingroupLookupFilterDataSourceCursor(pRecInGroupFilter)
# FUNCTION ingroupLookupSearchDataSourceCursor(p_RecInGroupSearch)
# FUNCTION InGroupLookupFilterDataSource(pRecInGroupFilter)
# FUNCTION ingroupLookup_filter(pInGroupCode)
# FUNCTION import_ingroup()
# FUNCTION exist_ingroupRec(p_cmpy_code, p_ingroup_code)
# FUNCTION delete_ingroup_all()
# FUNCTION inGroupMenu()						-- Offer different OPTIONS of this library via a menu

# InGroup record types
	DEFINE t_recInGroup  
		TYPE AS RECORD
			ingroup_code LIKE ingroup.ingroup_code,
			desc_text LIKE ingroup.desc_text
		END RECORD 

	DEFINE t_recInGroupFilter  
		TYPE AS RECORD
			filter_ingroup_code LIKE ingroup.ingroup_code,
			filter_desc_text LIKE ingroup.desc_text
		END RECORD 

	DEFINE t_recInGroupSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recInGroup_noCmpyId 
		TYPE AS RECORD 
	    type_ind LIKE ingroup.type_ind,
	    ingroup_code LIKE ingroup.ingroup_code,
	    desc_text LIKE ingroup.desc_text
    

        
	END RECORD	


	
########################################################################################
# FUNCTION inGroupMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION inGroupMenu()
	MENU
		ON ACTION "Import"
			CALL import_ingroup()
		ON ACTION "Export"
			CALL unload_ingroup()
		#ON ACTION "Import"
		#	CALL import_ingroup()
		ON ACTION "Delete All"
			CALL delete_ingroup_all()
		ON ACTION "Count"
			CALL getInGroupCount() --Count all ingroup rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getInGroupCount()
#-------------------------------------------------------
# Returns the number of InGroup entries for the current company
########################################################################################
FUNCTION getInGroupCount()
	DEFINE ret_InGroupCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_InGroup CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM InGroup ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_InGroup.DECLARE(sqlQuery) #CURSOR FOR getInGroup
	CALL c_InGroup.SetResults(ret_InGroupCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_InGroup.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_InGroupCount = -1
	ELSE
		CALL c_InGroup.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Cart Areas:", trim(ret_InGroupCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Cart Area Count", tempMsg,"info") 	
	END IF

	RETURN ret_InGroupCount
END FUNCTION

########################################################################################
# FUNCTION ingroupLookupFilterDataSourceCursor(pRecInGroupFilter)
#-------------------------------------------------------
# Returns the InGroup CURSOR for the lookup query
########################################################################################
FUNCTION ingroupLookupFilterDataSourceCursor(pRecInGroupFilter)
	DEFINE pRecInGroupFilter OF t_recInGroupFilter
	DEFINE sqlQuery STRING
	DEFINE c_InGroup CURSOR
	
	LET sqlQuery =	"SELECT ",
									"ingroup.ingroup_code, ", 
									"ingroup.desc_text ",
									"FROM ingroup ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecInGroupFilter.filter_ingroup_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ingroup_code LIKE '", pRecInGroupFilter.filter_ingroup_code CLIPPED, "%' "  
	END IF									

	IF pRecInGroupFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecInGroupFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY ingroup_code"

	CALL c_ingroup.DECLARE(sqlQuery)
		
	RETURN c_ingroup
END FUNCTION



########################################################################################
# ingroupLookupSearchDataSourceCursor(p_RecInGroupSearch)
#-------------------------------------------------------
# Returns the InGroup CURSOR for the lookup query
########################################################################################
FUNCTION ingroupLookupSearchDataSourceCursor(p_RecInGroupSearch)
	DEFINE p_RecInGroupSearch OF t_recInGroupSearch  
	DEFINE sqlQuery STRING
	DEFINE c_InGroup CURSOR
	
	LET sqlQuery =	"SELECT ",
									"ingroup.ingroup_code, ", 
									"ingroup.desc_text ",
 
									"FROM ingroup ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecInGroupSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((ingroup_code LIKE '", p_RecInGroupSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecInGroupSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecInGroupSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY ingroup_code"

	CALL c_ingroup.DECLARE(sqlQuery) #CURSOR FOR ingroup
	
	RETURN c_ingroup
END FUNCTION


########################################################################################
# FUNCTION InGroupLookupFilterDataSource(pRecInGroupFilter)
#-------------------------------------------------------
# CALLS InGroupLookupFilterDataSourceCursor(pRecInGroupFilter) with the InGroupFilter data TO get a CURSOR
# Returns the InGroup list array arrInGroupList
########################################################################################
FUNCTION InGroupLookupFilterDataSource(pRecInGroupFilter)
	DEFINE pRecInGroupFilter OF t_recInGroupFilter
	DEFINE recInGroup OF t_recInGroup
	DEFINE arrInGroupList DYNAMIC ARRAY OF t_recInGroup 
	DEFINE c_InGroup CURSOR
	DEFINE retError SMALLINT
		
	CALL InGroupLookupFilterDataSourceCursor(pRecInGroupFilter.*) RETURNING c_InGroup
	
	CALL arrInGroupList.CLEAR()

	CALL c_InGroup.SetResults(recInGroup.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_InGroup.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_InGroup.FetchNext()=0)
		CALL arrInGroupList.append([recInGroup.ingroup_code, recInGroup.desc_text])
	END WHILE	

	END IF
	
	IF arrInGroupList.getSize() = 0 THEN
		ERROR "No ingroup's found with the specified filter criteria"
	END IF
	
	RETURN arrInGroupList
END FUNCTION	

########################################################################################
# FUNCTION InGroupLookupSearchDataSource(pRecInGroupFilter)
#-------------------------------------------------------
# CALLS InGroupLookupSearchDataSourceCursor(pRecInGroupFilter) with the InGroupFilter data TO get a CURSOR
# Returns the InGroup list array arrInGroupList
########################################################################################
FUNCTION InGroupLookupSearchDataSource(p_recInGroupSearch)
	DEFINE p_recInGroupSearch OF t_recInGroupSearch	
	DEFINE recInGroup OF t_recInGroup
	DEFINE arrInGroupList DYNAMIC ARRAY OF t_recInGroup 
	DEFINE c_InGroup CURSOR
	DEFINE retError SMALLINT	
	CALL InGroupLookupSearchDataSourceCursor(p_recInGroupSearch) RETURNING c_InGroup
	
	CALL arrInGroupList.CLEAR()

	CALL c_InGroup.SetResults(recInGroup.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_InGroup.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_InGroup.FetchNext()=0)
		CALL arrInGroupList.append([recInGroup.ingroup_code, recInGroup.desc_text])
	END WHILE	

	END IF
	
	IF arrInGroupList.getSize() = 0 THEN
		ERROR "No ingroup's found with the specified filter criteria"
	END IF
	
	RETURN arrInGroupList
END FUNCTION


########################################################################################
# FUNCTION ingroupLookup_filter(pInGroupCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required InGroup code ingroup_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL InGroupLookupFilterDataSource(recInGroupFilter.*) RETURNING arrInGroupList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the InGroup Code ingroup_code
#
# Example:
# 			LET pr_InGroup.ingroup_code = InGroupLookup(pr_InGroup.ingroup_code)
########################################################################################
FUNCTION ingroupLookup_filter(pInGroupCode)
	DEFINE pInGroupCode LIKE InGroup.ingroup_code
	DEFINE arrInGroupList DYNAMIC ARRAY OF t_recInGroup
	DEFINE recInGroupFilter OF t_recInGroupFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wInGroupLookup WITH FORM "InGroupLookup_filter"


	CALL InGroupLookupFilterDataSource(recInGroupFilter.*) RETURNING arrInGroupList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recInGroupFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL InGroupLookupFilterDataSource(recInGroupFilter.*) RETURNING arrInGroupList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrInGroupList TO scInGroupList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pInGroupCode = arrInGroupList[idx].ingroup_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recInGroupFilter.filter_ingroup_code IS NOT NULL
			OR recInGroupFilter.filter_desc_text IS NOT NULL

		THEN
			LET recInGroupFilter.filter_ingroup_code = NULL
			LET recInGroupFilter.filter_desc_text = NULL

			CALL InGroupLookupFilterDataSource(recInGroupFilter.*) RETURNING arrInGroupList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_ingroup_code"
		IF recInGroupFilter.filter_ingroup_code IS NOT NULL THEN
			LET recInGroupFilter.filter_ingroup_code = NULL
			CALL InGroupLookupFilterDataSource(recInGroupFilter.*) RETURNING arrInGroupList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recInGroupFilter.filter_desc_text IS NOT NULL THEN
			LET recInGroupFilter.filter_desc_text = NULL
			CALL InGroupLookupFilterDataSource(recInGroupFilter.*) RETURNING arrInGroupList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wInGroupLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pInGroupCode	
END FUNCTION				
		

########################################################################################
# FUNCTION ingroupLookup(pInGroupCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required InGroup code ingroup_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL InGroupLookupSearchDataSource(recInGroupFilter.*) RETURNING arrInGroupList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the InGroup Code ingroup_code
#
# Example:
# 			LET pr_InGroup.ingroup_code = InGroupLookup(pr_InGroup.ingroup_code)
########################################################################################
FUNCTION ingroupLookup(pInGroupCode)
	DEFINE pInGroupCode LIKE InGroup.ingroup_code
	DEFINE arrInGroupList DYNAMIC ARRAY OF t_recInGroup
	DEFINE recInGroupSearch OF t_recInGroupSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wInGroupLookup WITH FORM "ingroupLookup"

	CALL InGroupLookupSearchDataSource(recInGroupSearch.*) RETURNING arrInGroupList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recInGroupSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL InGroupLookupSearchDataSource(recInGroupSearch.*) RETURNING arrInGroupList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrInGroupList TO scInGroupList.* 
		BEFORE ROW
			IF arrInGroupList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pInGroupCode = arrInGroupList[idx].ingroup_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recInGroupSearch.filter_any_field IS NOT NULL

		THEN
			LET recInGroupSearch.filter_any_field = NULL

			CALL InGroupLookupSearchDataSource(recInGroupSearch.*) RETURNING arrInGroupList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_ingroup_code"
		IF recInGroupSearch.filter_any_field IS NOT NULL THEN
			LET recInGroupSearch.filter_any_field = NULL
			CALL InGroupLookupSearchDataSource(recInGroupSearch.*) RETURNING arrInGroupList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wInGroupLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pInGroupCode	
END FUNCTION				

############################################
# FUNCTION import_ingroup()
############################################
FUNCTION import_ingroup()
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
	
	DEFINE rec_ingroup OF t_recInGroup_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wInGroupImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Cart Area List Data (table: ingroup)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_ingroup
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_ingroup(	    
	    type_ind CHAR(1),
	    ingroup_code CHAR(15),
	    desc_text CHAR(40)
    
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_ingroup	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wInGroupImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wInGroupImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/ingroup-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_ingroup
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_ingroup
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_ingroup
			LET importReport = importReport, "Code:", trim(rec_ingroup.ingroup_code) , "     -     Desc:", trim(rec_ingroup.desc_text), "\n"
					
			INSERT INTO ingroup VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_ingroup.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_ingroup.ingroup_code) , "     -     Desc:", trim(rec_ingroup.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wInGroupImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_ingroupRec(p_cmpy_code, p_ingroup_code)
########################################################
FUNCTION exist_ingroupRec(p_cmpy_code, p_ingroup_code)
	DEFINE p_cmpy_code LIKE ingroup.cmpy_code
	DEFINE p_ingroup_code LIKE ingroup.ingroup_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM ingroup 
     WHERE cmpy_code = p_cmpy_code
     AND ingroup_code = p_ingroup_code

	DROP TABLE temp_ingroup
	CLOSE WINDOW wInGroupImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_ingroup()
###############################################################
FUNCTION unload_ingroup(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/ingroup-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM ingroup ORDER BY cmpy_code, ingroup_code ASC
	
	LET tmpMsg = "All ingroup data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("ingroup Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_ingroup_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_ingroup_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE ingroup.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wingroupImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "ingroup Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing ingroup table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM ingroup
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table ingroup!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table ingroup where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wInGroupImport		
END FUNCTION	