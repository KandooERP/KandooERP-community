GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getDangerClassCount()
# FUNCTION dangerclassLookupFilterDataSourceCursor(pRecDangerClassFilter)
# FUNCTION dangerclassLookupSearchDataSourceCursor(p_RecDangerClassSearch)
# FUNCTION DangerClassLookupFilterDataSource(pRecDangerClassFilter)
# FUNCTION dangerclassLookup_filter(pDangerClassCode)
# FUNCTION import_dangerclass()
# FUNCTION exist_dangerclassRec(p_cmpy_code, p_class_code)
# FUNCTION delete_dangerclass_all()
# FUNCTION vendorGroupMenu()						-- Offer different OPTIONS of this library via a menu

# DangerClass record types
	DEFINE t_recDangerClass  
		TYPE AS RECORD
			class_code LIKE dangerclass.class_code,
			desc_text LIKE dangerclass.desc_text
		END RECORD 

	DEFINE t_recDangerClassFilter  
		TYPE AS RECORD
			filter_class_code LIKE dangerclass.class_code,
			filter_desc_text LIKE dangerclass.desc_text
		END RECORD 

	DEFINE t_recDangerClassSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recDangerClass_noCmpyId 
		TYPE AS RECORD 
    class_code LIKE dangerclass.class_code,
    desc_text LIKE dangerclass.desc_text

	END RECORD	

	
########################################################################################
# FUNCTION vendorGroupMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION dangerClassMenu()
	MENU
		ON ACTION "Import"
			CALL import_dangerclass()
		ON ACTION "Export"
			CALL unload_dangerclass()
		#ON ACTION "Import"
		#	CALL import_dangerclass()
		ON ACTION "Delete All"
			CALL delete_dangerclass_all()
		ON ACTION "Count"
			CALL getDangerClassCount() --Count all dangerclass rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getDangerClassCount()
#-------------------------------------------------------
# Returns the number of DangerClass entries for the current company
########################################################################################
FUNCTION getDangerClassCount()
	DEFINE ret_DangerClassCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_DangerClass CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM DangerClass "
#									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_DangerClass.DECLARE(sqlQuery) #CURSOR FOR getDangerClass
	CALL c_DangerClass.SetResults(ret_DangerClassCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_DangerClass.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_DangerClassCount = -1
	ELSE
		CALL c_DangerClass.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Vendor Group:", trim(ret_DangerClassCount) #,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Vendor Group Count", tempMsg,"info") 	
	END IF

	RETURN ret_DangerClassCount
END FUNCTION

########################################################################################
# FUNCTION dangerclassLookupFilterDataSourceCursor(pRecDangerClassFilter)
#-------------------------------------------------------
# Returns the DangerClass CURSOR for the lookup query
########################################################################################
FUNCTION dangerclassLookupFilterDataSourceCursor(pRecDangerClassFilter)
	DEFINE pRecDangerClassFilter OF t_recDangerClassFilter
	DEFINE sqlQuery STRING
	DEFINE c_DangerClass CURSOR
	
	LET sqlQuery =	"SELECT ",
									"dangerclass.class_code, ", 
									"dangerclass.desc_text ",
									"FROM dangerclass "
									#"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecDangerClassFilter.filter_class_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND class_code LIKE '", pRecDangerClassFilter.filter_class_code CLIPPED, "%' "  
	END IF									

	IF pRecDangerClassFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecDangerClassFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY class_code"

	CALL c_dangerclass.DECLARE(sqlQuery)
		
	RETURN c_dangerclass
END FUNCTION



########################################################################################
# dangerclassLookupSearchDataSourceCursor(p_RecDangerClassSearch)
#-------------------------------------------------------
# Returns the DangerClass CURSOR for the lookup query
########################################################################################
FUNCTION dangerclassLookupSearchDataSourceCursor(p_RecDangerClassSearch)
	DEFINE p_RecDangerClassSearch OF t_recDangerClassSearch  
	DEFINE sqlQuery STRING
	DEFINE c_DangerClass CURSOR
	
	LET sqlQuery =	"SELECT ",
									"dangerclass.class_code, ", 
									"dangerclass.desc_text ",
 
									"FROM dangerclass "
									#"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecDangerClassSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((class_code LIKE '", p_RecDangerClassSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecDangerClassSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecDangerClassSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY class_code"

	CALL c_dangerclass.DECLARE(sqlQuery) #CURSOR FOR dangerclass
	
	RETURN c_dangerclass
END FUNCTION


########################################################################################
# FUNCTION DangerClassLookupFilterDataSource(pRecDangerClassFilter)
#-------------------------------------------------------
# CALLS DangerClassLookupFilterDataSourceCursor(pRecDangerClassFilter) with the DangerClassFilter data TO get a CURSOR
# Returns the DangerClass list array arrDangerClassList
########################################################################################
FUNCTION DangerClassLookupFilterDataSource(pRecDangerClassFilter)
	DEFINE pRecDangerClassFilter OF t_recDangerClassFilter
	DEFINE recDangerClass OF t_recDangerClass
	DEFINE arrDangerClassList DYNAMIC ARRAY OF t_recDangerClass 
	DEFINE c_DangerClass CURSOR
	DEFINE retError SMALLINT
		
	CALL DangerClassLookupFilterDataSourceCursor(pRecDangerClassFilter.*) RETURNING c_DangerClass
	
	CALL arrDangerClassList.CLEAR()

	CALL c_DangerClass.SetResults(recDangerClass.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_DangerClass.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_DangerClass.FetchNext()=0)
		CALL arrDangerClassList.append([recDangerClass.class_code, recDangerClass.desc_text])
	END WHILE	

	END IF
	
	IF arrDangerClassList.getSize() = 0 THEN
		ERROR "No dangerclass's found with the specified filter criteria"
	END IF
	
	RETURN arrDangerClassList
END FUNCTION	

########################################################################################
# FUNCTION DangerClassLookupSearchDataSource(pRecDangerClassFilter)
#-------------------------------------------------------
# CALLS DangerClassLookupSearchDataSourceCursor(pRecDangerClassFilter) with the DangerClassFilter data TO get a CURSOR
# Returns the DangerClass list array arrDangerClassList
########################################################################################
FUNCTION DangerClassLookupSearchDataSource(p_recDangerClassSearch)
	DEFINE p_recDangerClassSearch OF t_recDangerClassSearch	
	DEFINE recDangerClass OF t_recDangerClass
	DEFINE arrDangerClassList DYNAMIC ARRAY OF t_recDangerClass 
	DEFINE c_DangerClass CURSOR
	DEFINE retError SMALLINT	
	CALL DangerClassLookupSearchDataSourceCursor(p_recDangerClassSearch) RETURNING c_DangerClass
	
	CALL arrDangerClassList.CLEAR()

	CALL c_DangerClass.SetResults(recDangerClass.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_DangerClass.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_DangerClass.FetchNext()=0)
		CALL arrDangerClassList.append([recDangerClass.class_code, recDangerClass.desc_text])
	END WHILE	

	END IF
	
	IF arrDangerClassList.getSize() = 0 THEN
		ERROR "No dangerclass's found with the specified filter criteria"
	END IF
	
	RETURN arrDangerClassList
END FUNCTION


########################################################################################
# FUNCTION dangerclassLookup_filter(pDangerClassCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required DangerClass code class_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL DangerClassLookupFilterDataSource(recDangerClassFilter.*) RETURNING arrDangerClassList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the DangerClass Code class_code
#
# Example:
# 			LET pr_DangerClass.class_code = DangerClassLookup(pr_DangerClass.class_code)
########################################################################################
FUNCTION dangerclassLookup_filter(pDangerClassCode)
	DEFINE pDangerClassCode LIKE DangerClass.class_code
	DEFINE arrDangerClassList DYNAMIC ARRAY OF t_recDangerClass
	DEFINE recDangerClassFilter OF t_recDangerClassFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wDangerClassLookup WITH FORM "DangerClassLookup_filter"


	CALL DangerClassLookupFilterDataSource(recDangerClassFilter.*) RETURNING arrDangerClassList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recDangerClassFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL DangerClassLookupFilterDataSource(recDangerClassFilter.*) RETURNING arrDangerClassList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrDangerClassList TO scDangerClassList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pDangerClassCode = arrDangerClassList[idx].class_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recDangerClassFilter.filter_class_code IS NOT NULL
			OR recDangerClassFilter.filter_desc_text IS NOT NULL

		THEN
			LET recDangerClassFilter.filter_class_code = NULL
			LET recDangerClassFilter.filter_desc_text = NULL

			CALL DangerClassLookupFilterDataSource(recDangerClassFilter.*) RETURNING arrDangerClassList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_class_code"
		IF recDangerClassFilter.filter_class_code IS NOT NULL THEN
			LET recDangerClassFilter.filter_class_code = NULL
			CALL DangerClassLookupFilterDataSource(recDangerClassFilter.*) RETURNING arrDangerClassList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recDangerClassFilter.filter_desc_text IS NOT NULL THEN
			LET recDangerClassFilter.filter_desc_text = NULL
			CALL DangerClassLookupFilterDataSource(recDangerClassFilter.*) RETURNING arrDangerClassList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wDangerClassLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pDangerClassCode	
END FUNCTION				
		

########################################################################################
# FUNCTION dangerclassLookup(pDangerClassCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required DangerClass code class_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL DangerClassLookupSearchDataSource(recDangerClassFilter.*) RETURNING arrDangerClassList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the DangerClass Code class_code
#
# Example:
# 			LET pr_DangerClass.class_code = DangerClassLookup(pr_DangerClass.class_code)
########################################################################################
FUNCTION dangerclassLookup(pDangerClassCode)
	DEFINE pDangerClassCode LIKE DangerClass.class_code
	DEFINE arrDangerClassList DYNAMIC ARRAY OF t_recDangerClass
	DEFINE recDangerClassSearch OF t_recDangerClassSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wDangerClassLookup WITH FORM "dangerclassLookup"

	CALL DangerClassLookupSearchDataSource(recDangerClassSearch.*) RETURNING arrDangerClassList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recDangerClassSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL DangerClassLookupSearchDataSource(recDangerClassSearch.*) RETURNING arrDangerClassList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrDangerClassList TO scDangerClassList.* 
		BEFORE ROW
			IF arrDangerClassList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pDangerClassCode = arrDangerClassList[idx].class_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recDangerClassSearch.filter_any_field IS NOT NULL

		THEN
			LET recDangerClassSearch.filter_any_field = NULL

			CALL DangerClassLookupSearchDataSource(recDangerClassSearch.*) RETURNING arrDangerClassList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_class_code"
		IF recDangerClassSearch.filter_any_field IS NOT NULL THEN
			LET recDangerClassSearch.filter_any_field = NULL
			CALL DangerClassLookupSearchDataSource(recDangerClassSearch.*) RETURNING arrDangerClassList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wDangerClassLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pDangerClassCode	
END FUNCTION				

############################################
# FUNCTION import_dangerclass()
############################################
FUNCTION import_dangerclass()
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
	 
	#DEFINE cmpy_code_provided BOOLEAN
	DEFINE p_desc_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_dangerclass OF t_recDangerClass_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wDangerClassImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Vendor Group List Data (table: dangerclass)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_dangerclass
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_dangerclass(
	    class_code CHAR(4),
	    desc_text CHAR(30)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_dangerclass	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
{	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_desc_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
}
--------------------------------------------------------------- before ---------------------------------------------------------------------
	
	IF gl_setupRec.silentMode = 0 THEN	
	#	OPEN WINDOW wDangerClassImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	{
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_desc_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_desc_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wDangerClassImport
					RETURN
					
				END IF

			END IF

	
		END IF
		}	
	END IF
	
	LET load_file = "unl/dangerclass-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_dangerclass
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_dangerclass
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_dangerclass
			LET importReport = importReport, "Code:", trim(rec_dangerclass.class_code) , "     -     Desc:", trim(rec_dangerclass.desc_text), "\n"
					
			INSERT INTO dangerclass VALUES(
			rec_dangerclass.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_dangerclass.class_code) , "     -     Desc:", trim(rec_dangerclass.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wDangerClassImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_dangerclassRec(p_cmpy_code, p_class_code)
########################################################
FUNCTION exist_dangerclassRec(p_class_code)
	#DEFINE p_cmpy_code LIKE dangerclass.cmpy_code
	DEFINE p_class_code LIKE dangerclass.class_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM dangerclass 
     #WHERE cmpy_code = p_cmpy_code
     WHERE class_code = p_class_code

	DROP TABLE temp_dangerclass
	CLOSE WINDOW wDangerClassImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_dangerclass()
###############################################################
FUNCTION unload_dangerclass(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/dangerclass-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM dangerclass ORDER BY class_code ASC
	
	LET tmpMsg = "All dangerclass data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("dangerclass Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_dangerclass_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_dangerclass_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE dangerclass.cmpy_code

	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wdangerclassImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Vendor Group (dangerclass) Delete" TO header_text
	END IF

	{
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		IF NOT exist_company(gl_setupRec_default_company.cmpy_code) THEN  --company code comp_code does NOT exist
			LET msgString = "Company code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			RETURN
		END IF
			LET cmpy_code_provided = TRUE
	ELSE
			LET cmpy_code_provided = FALSE				

	END IF
}
#	IF cmpy_code_provided = FALSE THEN
#
#		INPUT gl_setupRec_default_company.cmpy_code WITHOUT DEFAULTS FROM cmpy_code 
#		END INPUT
#
#	ELSE
#
#		IF gl_setupRec.silentMode = 0 THEN 	
#			DISPLAY gl_setupRec_default_company.cmpy_code TO cmpy_code
#		END IF	
#	END IF

	
	IF gl_setupRec.silentMode = 0 THEN --no ui
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing dangerclass table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM dangerclass
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table dangerclass!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table dangerclass where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wDangerClassImport		
END FUNCTION	