GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getLoadParmsCount()
# FUNCTION loadparmsLookupFilterDataSourceCursor(pRecLoadParmsFilter)
# FUNCTION loadparmsLookupSearchDataSourceCursor(p_RecLoadParmsSearch)
# FUNCTION LoadParmsLookupFilterDataSource(pRecLoadParmsFilter)
# FUNCTION loadparmsLookup_filter(pLoadParmsCode)
# FUNCTION import_loadparms()
# FUNCTION exist_loadparmsRec(p_cmpy_code, p_load_ind)
# FUNCTION delete_loadparms_all()
# FUNCTION loadParmsMenu()						-- Offer different OPTIONS of this library via a menu

# LoadParms record types
	DEFINE t_recLoadParms  
		TYPE AS RECORD
			load_ind LIKE loadparms.load_ind,
			desc_text LIKE loadparms.desc_text
		END RECORD 

	DEFINE t_recLoadParmsFilter  
		TYPE AS RECORD
			filter_load_ind LIKE loadparms.load_ind,
			filter_desc_text LIKE loadparms.desc_text
		END RECORD 

	DEFINE t_recLoadParmsSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recLoadParms_noCmpyId 
		TYPE AS RECORD 
    load_ind LIKE loadparms.load_ind,
    desc_text LIKE loadparms.desc_text,
    format_ind LIKE loadparms.format_ind,
    path_text LIKE loadparms.path_text,
    file_text LIKE loadparms.file_text,
    load_date LIKE loadparms.load_date,
    load_num LIKE loadparms.load_num,
    seq_num LIKE loadparms.seq_num,
    prmpt1_text LIKE loadparms.prmpt1_text,
    ref1_text LIKE loadparms.ref1_text,
    entry1_flag LIKE loadparms.entry1_flag,
    prmpt2_text LIKE loadparms.prmpt2_text,
    ref2_text LIKE loadparms.ref2_text,
    entry2_flag LIKE loadparms.entry2_flag,
    prmpt3_text LIKE loadparms.prmpt3_text,
    ref3_text LIKE loadparms.ref3_text,
    entry3_flag LIKE loadparms.entry3_flag,
    module_code LIKE loadparms.module_code
	END RECORD	

	
########################################################################################
# FUNCTION loadParmsMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION loadParmsMenu()
	MENU
		ON ACTION "Import"
			CALL import_loadparms()
		ON ACTION "Export"
			CALL unload_loadparms()
		#ON ACTION "Import"
		#	CALL import_loadparms()
		ON ACTION "Delete All"
			CALL delete_loadparms_all()
		ON ACTION "Count"
			CALL getLoadParmsCount() --Count all loadparms rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getLoadParmsCount()
#-------------------------------------------------------
# Returns the number of LoadParms entries for the current company
########################################################################################
FUNCTION getLoadParmsCount()
	DEFINE ret_LoadParmsCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_LoadParms CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM LoadParms ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_LoadParms.DECLARE(sqlQuery) #CURSOR FOR getLoadParms
	CALL c_LoadParms.SetResults(ret_LoadParmsCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_LoadParms.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_LoadParmsCount = -1
	ELSE
		CALL c_LoadParms.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Load Parameters:", trim(ret_LoadParmsCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Load Parameters Count", tempMsg,"info") 	
	END IF

	RETURN ret_LoadParmsCount
END FUNCTION

########################################################################################
# FUNCTION loadparmsLookupFilterDataSourceCursor(pRecLoadParmsFilter)
#-------------------------------------------------------
# Returns the LoadParms CURSOR for the lookup query
########################################################################################
FUNCTION loadparmsLookupFilterDataSourceCursor(pRecLoadParmsFilter)
	DEFINE pRecLoadParmsFilter OF t_recLoadParmsFilter
	DEFINE sqlQuery STRING
	DEFINE c_LoadParms CURSOR
	
	LET sqlQuery =	"SELECT ",
									"loadparms.load_ind, ", 
									"loadparms.desc_text ",
									"FROM loadparms ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecLoadParmsFilter.filter_load_ind IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND load_ind LIKE '", pRecLoadParmsFilter.filter_load_ind CLIPPED, "%' "  
	END IF									

	IF pRecLoadParmsFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecLoadParmsFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY load_ind"

	CALL c_loadparms.DECLARE(sqlQuery)
		
	RETURN c_loadparms
END FUNCTION



########################################################################################
# loadparmsLookupSearchDataSourceCursor(p_RecLoadParmsSearch)
#-------------------------------------------------------
# Returns the LoadParms CURSOR for the lookup query
########################################################################################
FUNCTION loadparmsLookupSearchDataSourceCursor(p_RecLoadParmsSearch)
	DEFINE p_RecLoadParmsSearch OF t_recLoadParmsSearch  
	DEFINE sqlQuery STRING
	DEFINE c_LoadParms CURSOR
	
	LET sqlQuery =	"SELECT ",
									"loadparms.load_ind, ", 
									"loadparms.desc_text ",
 
									"FROM loadparms ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecLoadParmsSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((load_ind LIKE '", p_RecLoadParmsSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecLoadParmsSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecLoadParmsSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY load_ind"

	CALL c_loadparms.DECLARE(sqlQuery) #CURSOR FOR loadparms
	
	RETURN c_loadparms
END FUNCTION


########################################################################################
# FUNCTION LoadParmsLookupFilterDataSource(pRecLoadParmsFilter)
#-------------------------------------------------------
# CALLS LoadParmsLookupFilterDataSourceCursor(pRecLoadParmsFilter) with the LoadParmsFilter data TO get a CURSOR
# Returns the LoadParms list array arrLoadParmsList
########################################################################################
FUNCTION LoadParmsLookupFilterDataSource(pRecLoadParmsFilter)
	DEFINE pRecLoadParmsFilter OF t_recLoadParmsFilter
	DEFINE recLoadParms OF t_recLoadParms
	DEFINE arrLoadParmsList DYNAMIC ARRAY OF t_recLoadParms 
	DEFINE c_LoadParms CURSOR
	DEFINE retError SMALLINT
		
	CALL LoadParmsLookupFilterDataSourceCursor(pRecLoadParmsFilter.*) RETURNING c_LoadParms
	
	CALL arrLoadParmsList.CLEAR()

	CALL c_LoadParms.SetResults(recLoadParms.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_LoadParms.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_LoadParms.FetchNext()=0)
		CALL arrLoadParmsList.append([recLoadParms.load_ind, recLoadParms.desc_text])
	END WHILE	

	END IF
	
	IF arrLoadParmsList.getSize() = 0 THEN
		ERROR "No loadparms's found with the specified filter criteria"
	END IF
	
	RETURN arrLoadParmsList
END FUNCTION	

########################################################################################
# FUNCTION LoadParmsLookupSearchDataSource(pRecLoadParmsFilter)
#-------------------------------------------------------
# CALLS LoadParmsLookupSearchDataSourceCursor(pRecLoadParmsFilter) with the LoadParmsFilter data TO get a CURSOR
# Returns the LoadParms list array arrLoadParmsList
########################################################################################
FUNCTION LoadParmsLookupSearchDataSource(p_recLoadParmsSearch)
	DEFINE p_recLoadParmsSearch OF t_recLoadParmsSearch	
	DEFINE recLoadParms OF t_recLoadParms
	DEFINE arrLoadParmsList DYNAMIC ARRAY OF t_recLoadParms 
	DEFINE c_LoadParms CURSOR
	DEFINE retError SMALLINT	
	CALL LoadParmsLookupSearchDataSourceCursor(p_recLoadParmsSearch) RETURNING c_LoadParms
	
	CALL arrLoadParmsList.CLEAR()

	CALL c_LoadParms.SetResults(recLoadParms.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_LoadParms.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_LoadParms.FetchNext()=0)
		CALL arrLoadParmsList.append([recLoadParms.load_ind, recLoadParms.desc_text])
	END WHILE	

	END IF
	
	IF arrLoadParmsList.getSize() = 0 THEN
		ERROR "No loadparms's found with the specified filter criteria"
	END IF
	
	RETURN arrLoadParmsList
END FUNCTION


########################################################################################
# FUNCTION loadparmsLookup_filter(pLoadParmsCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required LoadParms code load_ind
# DateSoure AND Cursor are managed in other functions which are called
# CALL LoadParmsLookupFilterDataSource(recLoadParmsFilter.*) RETURNING arrLoadParmsList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the LoadParms Code load_ind
#
# Example:
# 			LET pr_LoadParms.load_ind = LoadParmsLookup(pr_LoadParms.load_ind)
########################################################################################
FUNCTION loadparmsLookup_filter(pLoadParmsCode)
	DEFINE pLoadParmsCode LIKE LoadParms.load_ind
	DEFINE arrLoadParmsList DYNAMIC ARRAY OF t_recLoadParms
	DEFINE recLoadParmsFilter OF t_recLoadParmsFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wLoadParmsLookup WITH FORM "LoadParmsLookup_filter"


	CALL LoadParmsLookupFilterDataSource(recLoadParmsFilter.*) RETURNING arrLoadParmsList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recLoadParmsFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL LoadParmsLookupFilterDataSource(recLoadParmsFilter.*) RETURNING arrLoadParmsList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrLoadParmsList TO scLoadParmsList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pLoadParmsCode = arrLoadParmsList[idx].load_ind
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recLoadParmsFilter.filter_load_ind IS NOT NULL
			OR recLoadParmsFilter.filter_desc_text IS NOT NULL

		THEN
			LET recLoadParmsFilter.filter_load_ind = NULL
			LET recLoadParmsFilter.filter_desc_text = NULL

			CALL LoadParmsLookupFilterDataSource(recLoadParmsFilter.*) RETURNING arrLoadParmsList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_load_ind"
		IF recLoadParmsFilter.filter_load_ind IS NOT NULL THEN
			LET recLoadParmsFilter.filter_load_ind = NULL
			CALL LoadParmsLookupFilterDataSource(recLoadParmsFilter.*) RETURNING arrLoadParmsList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recLoadParmsFilter.filter_desc_text IS NOT NULL THEN
			LET recLoadParmsFilter.filter_desc_text = NULL
			CALL LoadParmsLookupFilterDataSource(recLoadParmsFilter.*) RETURNING arrLoadParmsList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wLoadParmsLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pLoadParmsCode	
END FUNCTION				
		

########################################################################################
# FUNCTION loadparmsLookup(pLoadParmsCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required LoadParms code load_ind
# DateSoure AND Cursor are managed in other functions which are called
# CALL LoadParmsLookupSearchDataSource(recLoadParmsFilter.*) RETURNING arrLoadParmsList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the LoadParms Code load_ind
#
# Example:
# 			LET pr_LoadParms.load_ind = LoadParmsLookup(pr_LoadParms.load_ind)
########################################################################################
FUNCTION loadparmsLookup(pLoadParmsCode)
	DEFINE pLoadParmsCode LIKE LoadParms.load_ind
	DEFINE arrLoadParmsList DYNAMIC ARRAY OF t_recLoadParms
	DEFINE recLoadParmsSearch OF t_recLoadParmsSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wLoadParmsLookup WITH FORM "loadparmsLookup"

	CALL LoadParmsLookupSearchDataSource(recLoadParmsSearch.*) RETURNING arrLoadParmsList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recLoadParmsSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL LoadParmsLookupSearchDataSource(recLoadParmsSearch.*) RETURNING arrLoadParmsList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrLoadParmsList TO scLoadParmsList.* 
		BEFORE ROW
			IF arrLoadParmsList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pLoadParmsCode = arrLoadParmsList[idx].load_ind
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recLoadParmsSearch.filter_any_field IS NOT NULL

		THEN
			LET recLoadParmsSearch.filter_any_field = NULL

			CALL LoadParmsLookupSearchDataSource(recLoadParmsSearch.*) RETURNING arrLoadParmsList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_load_ind"
		IF recLoadParmsSearch.filter_any_field IS NOT NULL THEN
			LET recLoadParmsSearch.filter_any_field = NULL
			CALL LoadParmsLookupSearchDataSource(recLoadParmsSearch.*) RETURNING arrLoadParmsList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wLoadParmsLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pLoadParmsCode	
END FUNCTION				

############################################
# FUNCTION import_loadparms()
############################################
FUNCTION import_loadparms()
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
	DEFINE p_desc_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_loadparms OF t_recLoadParms_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wLoadParmsImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Load Parameters List Data (table: loadparms)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_loadparms
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_loadparms(
	    load_ind CHAR(3),
	    desc_text CHAR(30),
	    format_ind CHAR(2),
	    path_text CHAR(60),
	    file_text CHAR(20),
	    load_date DATE,
	    load_num INTEGER,
	    seq_num INTEGER,
	    prmpt1_text CHAR(15),
	    ref1_text CHAR(20),
	    entry1_flag CHAR(1),
	    prmpt2_text CHAR(15),
	    ref2_text CHAR(20),
	    entry2_flag CHAR(1),
	    prmpt3_text CHAR(15),
	    ref3_text CHAR(20),
	    entry3_flag CHAR(1),
	    module_code CHAR(2)	
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_loadparms	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
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

--------------------------------------------------------------- before ---------------------------------------------------------------------
	
	IF gl_setupRec.silentMode = 0 THEN	
	#	OPEN WINDOW wLoadParmsImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
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
					CLOSE WINDOW wLoadParmsImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/loadparms-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_loadparms
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_loadparms
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_loadparms
			LET importReport = importReport, "Code:", trim(rec_loadparms.load_ind) , "     -     Desc:", trim(rec_loadparms.desc_text), "\n"
					
			INSERT INTO loadparms VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_loadparms.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_loadparms.load_ind) , "     -     Desc:", trim(rec_loadparms.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wLoadParmsImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_loadparmsRec(p_cmpy_code, p_load_ind)
########################################################
FUNCTION exist_loadparmsRec(p_cmpy_code, p_load_ind)
	DEFINE p_cmpy_code LIKE loadparms.cmpy_code
	DEFINE p_load_ind LIKE loadparms.load_ind
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM loadparms 
     WHERE cmpy_code = p_cmpy_code
     AND load_ind = p_load_ind

	DROP TABLE temp_loadparms
	CLOSE WINDOW wLoadParmsImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_loadparms()
###############################################################
FUNCTION unload_loadparms(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/loadparms-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM loadparms ORDER BY cmpy_code, load_ind ASC
	
	LET tmpMsg = "All loadparms data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("loadparms Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_loadparms_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_loadparms_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE loadparms.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wloadparmsImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Load Parameters (loadparms) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing loadparms table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM loadparms
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table loadparms!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table loadparms where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wLoadParmsImport		
END FUNCTION	