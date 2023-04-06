GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getWareGrpCount()
# FUNCTION waregrpLookupFilterDataSourceCursor(pRecWareGrpFilter)
# FUNCTION waregrpLookupSearchDataSourceCursor(p_RecWareGrpSearch)
# FUNCTION WareGrpLookupFilterDataSource(pRecWareGrpFilter)
# FUNCTION waregrpLookup_filter(pWareGrpCode)
# FUNCTION import_waregrp()
# FUNCTION exist_waregrpRec(p_cmpy_code, p_waregrp_code)
# FUNCTION delete_waregrp_all()
# FUNCTION wareGrpMenu()						-- Offer different OPTIONS of this library via a menu

# WareGrp record types
	DEFINE t_recWareGrp  
		TYPE AS RECORD
			waregrp_code LIKE waregrp.waregrp_code,
			name_text LIKE waregrp.name_text
		END RECORD 

	DEFINE t_recWareGrpFilter  
		TYPE AS RECORD
			filter_waregrp_code LIKE waregrp.waregrp_code,
			filter_name_text LIKE waregrp.name_text
		END RECORD 

	DEFINE t_recWareGrpSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recWareGrp_noCmpyId 
		TYPE AS RECORD 
    waregrp_code LIKE wareGrp.waregrp_code,
    name_text LIKE wareGrp.name_text,    
    cartage_ind LIKE wareGrp.cartage_ind,
    conv_uom_ind LIKE wareGrp.conv_uom_ind,
    cmpy1_text LIKE wareGrp.cmpy1_text,
    cmpy2_text LIKE wareGrp.cmpy2_text,
    cmpy3_text LIKE wareGrp.cmpy3_text
	END RECORD	


	
########################################################################################
# FUNCTION wareGrpMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION wareGrpMenu()
	MENU
		ON ACTION "Import"
			CALL import_waregrp()
		ON ACTION "Export"
			CALL unload_waregrp()
		#ON ACTION "Import"
		#	CALL import_waregrp()
		ON ACTION "Delete All"
			CALL delete_waregrp_all()
		ON ACTION "Count"
			CALL getWareGrpCount() --Count all waregrp rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getWareGrpCount()
#-------------------------------------------------------
# Returns the number of WareGrp entries for the current company
########################################################################################
FUNCTION getWareGrpCount()
	DEFINE ret_WareGrpCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_WareGrp CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM WareGrp ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_WareGrp.DECLARE(sqlQuery) #CURSOR FOR getWareGrp
	CALL c_WareGrp.SetResults(ret_WareGrpCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_WareGrp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_WareGrpCount = -1
	ELSE
		CALL c_WareGrp.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Warehouse Groups:", trim(ret_WareGrpCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Warehouse Group Count", tempMsg,"info") 	
	END IF

	RETURN ret_WareGrpCount
END FUNCTION

########################################################################################
# FUNCTION waregrpLookupFilterDataSourceCursor(pRecWareGrpFilter)
#-------------------------------------------------------
# Returns the WareGrp CURSOR for the lookup query
########################################################################################
FUNCTION waregrpLookupFilterDataSourceCursor(pRecWareGrpFilter)
	DEFINE pRecWareGrpFilter OF t_recWareGrpFilter
	DEFINE sqlQuery STRING
	DEFINE c_WareGrp CURSOR
	
	LET sqlQuery =	"SELECT ",
									"waregrp.waregrp_code, ", 
									"waregrp.name_text ",
									"FROM waregrp ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecWareGrpFilter.filter_waregrp_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND waregrp_code LIKE '", pRecWareGrpFilter.filter_waregrp_code CLIPPED, "%' "  
	END IF									

	IF pRecWareGrpFilter.filter_name_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND name_text LIKE '", pRecWareGrpFilter.filter_name_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY waregrp_code"

	CALL c_waregrp.DECLARE(sqlQuery)
		
	RETURN c_waregrp
END FUNCTION



########################################################################################
# waregrpLookupSearchDataSourceCursor(p_RecWareGrpSearch)
#-------------------------------------------------------
# Returns the WareGrp CURSOR for the lookup query
########################################################################################
FUNCTION waregrpLookupSearchDataSourceCursor(p_RecWareGrpSearch)
	DEFINE p_RecWareGrpSearch OF t_recWareGrpSearch  
	DEFINE sqlQuery STRING
	DEFINE c_WareGrp CURSOR
	
	LET sqlQuery =	"SELECT ",
									"waregrp.waregrp_code, ", 
									"waregrp.name_text ",
 
									"FROM waregrp ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecWareGrpSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((waregrp_code LIKE '", p_RecWareGrpSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR name_text LIKE '",   p_RecWareGrpSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecWareGrpSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY waregrp_code"

	CALL c_waregrp.DECLARE(sqlQuery) #CURSOR FOR waregrp
	
	RETURN c_waregrp
END FUNCTION


########################################################################################
# FUNCTION WareGrpLookupFilterDataSource(pRecWareGrpFilter)
#-------------------------------------------------------
# CALLS WareGrpLookupFilterDataSourceCursor(pRecWareGrpFilter) with the WareGrpFilter data TO get a CURSOR
# Returns the WareGrp list array arrWareGrpList
########################################################################################
FUNCTION WareGrpLookupFilterDataSource(pRecWareGrpFilter)
	DEFINE pRecWareGrpFilter OF t_recWareGrpFilter
	DEFINE recWareGrp OF t_recWareGrp
	DEFINE arrWareGrpList DYNAMIC ARRAY OF t_recWareGrp 
	DEFINE c_WareGrp CURSOR
	DEFINE retError SMALLINT
		
	CALL WareGrpLookupFilterDataSourceCursor(pRecWareGrpFilter.*) RETURNING c_WareGrp
	
	CALL arrWareGrpList.CLEAR()

	CALL c_WareGrp.SetResults(recWareGrp.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_WareGrp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_WareGrp.FetchNext()=0)
		CALL arrWareGrpList.append([recWareGrp.waregrp_code, recWareGrp.name_text])
	END WHILE	

	END IF
	
	IF arrWareGrpList.getSize() = 0 THEN
		ERROR "No waregrp's found with the specified filter criteria"
	END IF
	
	RETURN arrWareGrpList
END FUNCTION	

########################################################################################
# FUNCTION WareGrpLookupSearchDataSource(pRecWareGrpFilter)
#-------------------------------------------------------
# CALLS WareGrpLookupSearchDataSourceCursor(pRecWareGrpFilter) with the WareGrpFilter data TO get a CURSOR
# Returns the WareGrp list array arrWareGrpList
########################################################################################
FUNCTION WareGrpLookupSearchDataSource(p_recWareGrpSearch)
	DEFINE p_recWareGrpSearch OF t_recWareGrpSearch	
	DEFINE recWareGrp OF t_recWareGrp
	DEFINE arrWareGrpList DYNAMIC ARRAY OF t_recWareGrp 
	DEFINE c_WareGrp CURSOR
	DEFINE retError SMALLINT	
	CALL WareGrpLookupSearchDataSourceCursor(p_recWareGrpSearch) RETURNING c_WareGrp
	
	CALL arrWareGrpList.CLEAR()

	CALL c_WareGrp.SetResults(recWareGrp.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_WareGrp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_WareGrp.FetchNext()=0)
		CALL arrWareGrpList.append([recWareGrp.waregrp_code, recWareGrp.name_text])
	END WHILE	

	END IF
	
	IF arrWareGrpList.getSize() = 0 THEN
		ERROR "No waregrp's found with the specified filter criteria"
	END IF
	
	RETURN arrWareGrpList
END FUNCTION


########################################################################################
# FUNCTION waregrpLookup_filter(pWareGrpCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required WareGrp code waregrp_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL WareGrpLookupFilterDataSource(recWareGrpFilter.*) RETURNING arrWareGrpList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the WareGrp Code waregrp_code
#
# Example:
# 			LET pr_WareGrp.waregrp_code = WareGrpLookup(pr_WareGrp.waregrp_code)
########################################################################################
FUNCTION waregrpLookup_filter(pWareGrpCode)
	DEFINE pWareGrpCode LIKE WareGrp.waregrp_code
	DEFINE arrWareGrpList DYNAMIC ARRAY OF t_recWareGrp
	DEFINE recWareGrpFilter OF t_recWareGrpFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wWareGrpLookup WITH FORM "WareGrpLookup_filter"


	CALL WareGrpLookupFilterDataSource(recWareGrpFilter.*) RETURNING arrWareGrpList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recWareGrpFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL WareGrpLookupFilterDataSource(recWareGrpFilter.*) RETURNING arrWareGrpList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrWareGrpList TO scWareGrpList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pWareGrpCode = arrWareGrpList[idx].waregrp_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recWareGrpFilter.filter_waregrp_code IS NOT NULL
			OR recWareGrpFilter.filter_name_text IS NOT NULL

		THEN
			LET recWareGrpFilter.filter_waregrp_code = NULL
			LET recWareGrpFilter.filter_name_text = NULL

			CALL WareGrpLookupFilterDataSource(recWareGrpFilter.*) RETURNING arrWareGrpList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_waregrp_code"
		IF recWareGrpFilter.filter_waregrp_code IS NOT NULL THEN
			LET recWareGrpFilter.filter_waregrp_code = NULL
			CALL WareGrpLookupFilterDataSource(recWareGrpFilter.*) RETURNING arrWareGrpList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_name_text"
		IF recWareGrpFilter.filter_name_text IS NOT NULL THEN
			LET recWareGrpFilter.filter_name_text = NULL
			CALL WareGrpLookupFilterDataSource(recWareGrpFilter.*) RETURNING arrWareGrpList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wWareGrpLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pWareGrpCode	
END FUNCTION				
		

########################################################################################
# FUNCTION waregrpLookup(pWareGrpCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required WareGrp code waregrp_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL WareGrpLookupSearchDataSource(recWareGrpFilter.*) RETURNING arrWareGrpList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the WareGrp Code waregrp_code
#
# Example:
# 			LET pr_WareGrp.waregrp_code = WareGrpLookup(pr_WareGrp.waregrp_code)
########################################################################################
FUNCTION waregrpLookup(pWareGrpCode)
	DEFINE pWareGrpCode LIKE WareGrp.waregrp_code
	DEFINE arrWareGrpList DYNAMIC ARRAY OF t_recWareGrp
	DEFINE recWareGrpSearch OF t_recWareGrpSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wWareGrpLookup WITH FORM "waregrpLookup"

	CALL WareGrpLookupSearchDataSource(recWareGrpSearch.*) RETURNING arrWareGrpList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recWareGrpSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL WareGrpLookupSearchDataSource(recWareGrpSearch.*) RETURNING arrWareGrpList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrWareGrpList TO scWareGrpList.* 
		BEFORE ROW
			IF arrWareGrpList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pWareGrpCode = arrWareGrpList[idx].waregrp_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recWareGrpSearch.filter_any_field IS NOT NULL

		THEN
			LET recWareGrpSearch.filter_any_field = NULL

			CALL WareGrpLookupSearchDataSource(recWareGrpSearch.*) RETURNING arrWareGrpList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_waregrp_code"
		IF recWareGrpSearch.filter_any_field IS NOT NULL THEN
			LET recWareGrpSearch.filter_any_field = NULL
			CALL WareGrpLookupSearchDataSource(recWareGrpSearch.*) RETURNING arrWareGrpList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wWareGrpLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pWareGrpCode	
END FUNCTION				

############################################
# FUNCTION import_waregrp()
############################################
FUNCTION import_waregrp()
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
	
	DEFINE rec_waregrp OF t_recWareGrp_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wWareGrpImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Warehouse Group List Data (table: waregrp)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_waregrp
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_waregrp(	    
	    waregrp_code CHAR(8),
	    name_text CHAR(40),
	    cartage_ind CHAR(1),
	    conv_uom_ind CHAR(1),
	    cmpy1_text CHAR(60),
	    cmpy2_text CHAR(60),
	    cmpy3_text CHAR(60)	
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_waregrp	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wWareGrpImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wWareGrpImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/waregrp-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_waregrp
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_waregrp
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_waregrp
			LET importReport = importReport, "Code:", trim(rec_waregrp.waregrp_code) , "     -     Desc:", trim(rec_waregrp.name_text), "\n"
					
			INSERT INTO waregrp VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_waregrp.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_waregrp.waregrp_code) , "     -     Desc:", trim(rec_waregrp.name_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wWareGrpImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_waregrpRec(p_cmpy_code, p_waregrp_code)
########################################################
FUNCTION exist_waregrpRec(p_cmpy_code, p_waregrp_code)
	DEFINE p_cmpy_code LIKE waregrp.cmpy_code
	DEFINE p_waregrp_code LIKE waregrp.waregrp_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM waregrp 
     WHERE cmpy_code = p_cmpy_code
     AND waregrp_code = p_waregrp_code

	DROP TABLE temp_waregrp
	CLOSE WINDOW wWareGrpImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_waregrp()
###############################################################
FUNCTION unload_waregrp(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/waregrp-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM waregrp ORDER BY cmpy_code, waregrp_code ASC
	
	LET tmpMsg = "All waregrp data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("waregrp Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_waregrp_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_waregrp_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE waregrp.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wwaregrpImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "waregrp Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing waregrp table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM waregrp
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table waregrp!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table waregrp where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wWareGrpImport		
END FUNCTION	