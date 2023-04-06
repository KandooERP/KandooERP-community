GLOBALS "lib_db_globals.4gl"

# Banktype record types
	DEFINE t_recBanktype  
		TYPE AS RECORD
			type_code LIKE banktype.type_code,
			type_text LIKE banktype.type_text,
			eft_format_ind LIKE banktype.eft_format_ind,
			eft_path_text LIKE banktype.eft_path_text,
			eft_file_text LIKE banktype.eft_file_text,
			stmt_format_ind LIKE banktype.stmt_format_ind,
			stmt_path_text LIKE banktype.stmt_path_text,
			stmt_file_text LIKE banktype.stmt_file_text
    			
		END RECORD 

	DEFINE t_recBanktypeFilter  
		TYPE AS RECORD
			filter_type_code LIKE banktype.type_code,
			filter_type_text LIKE banktype.type_text
		END RECORD 

	DEFINE t_recBanktypeSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

########################################################################################
# FUNCTION bankTypeMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION bankTypeMenu()
	DEFINE tempMsg STRING
	MENU
		ON ACTION "Import"
			CALL import_bankType()
		ON ACTION "Export"
			CALL unload_bankType(FALSE,"exp")
		ON ACTION "Delete All"
			CALL delete_bankType_all()
		ON ACTION "Count"
			IF gl_setupRec.silentMode = 0 THEN
				LET tempMsg = "Number of Customer Types:", trim(getbankTypeCount()) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
				CALL fgl_winmessage("Customer Count", tempMsg,"info") 	
			END IF
			
			#CALL getbankTypeCount() --Count all bankType rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION

########################################################################################
# FUNCTION getBanktypeCount()
#-------------------------------------------------------
# Returns the number of Banktype entries for the current company
########################################################################################
FUNCTION getBanktypeCount()
	DEFINE ret_BanktypeCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Banktype CURSOR
	DEFINE retError SMALLINT
	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM banktype "

	CALL c_Banktype.DECLARE(sqlQuery) #CURSOR FOR getBanktype
	CALL c_Banktype.SetResults(ret_BanktypeCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_banktype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_banktypeCount = -1
	ELSE
		CALL c_banktype.FetchNext()
	END IF

	RETURN ret_banktypeCount
END FUNCTION

########################################################################################
# FUNCTION banktypeLookupFilterDataSourceCursor(pRecBanktypeFilter)
#-------------------------------------------------------
# Returns the Banktype CURSOR for the lookup query
########################################################################################
FUNCTION banktypeLookupFilterDataSourceCursor(pRecBanktypeFilter)
	DEFINE pRecBanktypeFilter OF t_recBanktypeFilter
	DEFINE sqlQuery STRING
	DEFINE c_Banktype CURSOR
	
	LET sqlQuery =	"SELECT ",
									"banktype.type_code, ", 
									"banktype.type_text ",
									"FROM banktype "
									
	IF pRecBanktypeFilter.filter_type_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND type_code LIKE '", pRecBanktypeFilter.filter_type_code CLIPPED, "%' "  
	END IF									

	IF pRecBanktypeFilter.filter_type_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND type_text LIKE '", pRecBanktypeFilter.filter_type_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY type_code"

	CALL c_banktype.DECLARE(sqlQuery)
		
	RETURN c_banktype
END FUNCTION



########################################################################################
# FUNCTION banktypeLookupSearchDataSourceCursor(p_RecBanktypeSearch)
#-------------------------------------------------------
# Returns the Banktype CURSOR for the lookup query
########################################################################################
FUNCTION banktypeLookupSearchDataSourceCursor(p_RecBanktypeSearch)
	DEFINE p_RecBanktypeSearch OF t_recBanktypeSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Banktype CURSOR
	
	LET sqlQuery =	"SELECT ",
									"banktype.type_code, ", 
									"banktype.type_text ",
 
									"FROM banktype "
	
	IF p_RecBanktypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((type_code LIKE '", p_RecBanktypeSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR type_text LIKE '",   p_RecBanktypeSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecBanktypeSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY type_code"

	CALL c_banktype.DECLARE(sqlQuery) #CURSOR FOR COA
	
	RETURN c_banktype
END FUNCTION


########################################################################################
# FUNCTION BanktypeLookupFilterDataSource(pRecBanktypeFilter)
#-------------------------------------------------------
# CALLS BanktypeLookupFilterDataSourceCursor(pRecBanktypeFilter) with the BanktypeFilter data TO get a CURSOR
# Returns the Banktype list array arrBanktypeList
########################################################################################
FUNCTION BanktypeLookupFilterDataSource(pRecBanktypeFilter)
	DEFINE pRecBanktypeFilter OF t_recBanktypeFilter
	DEFINE recBanktype OF t_recBanktype
	DEFINE arrBanktypeList DYNAMIC ARRAY OF t_recBanktype 
	DEFINE c_Banktype CURSOR
	DEFINE retError SMALLINT
		
	CALL BanktypeLookupFilterDataSourceCursor(pRecBanktypeFilter.*) RETURNING c_Banktype
	
	CALL arrBanktypeList.CLEAR()

	CALL c_Banktype.SetResults(recBanktype.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Banktype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Banktype.FetchNext()=0)
		CALL arrBanktypeList.append([recBanktype.type_code, recBanktype.type_text])
	END WHILE	

	END IF
	
	IF arrBanktypeList.getSize() = 0 THEN
		ERROR "No COA's found with the specified filter criteria"
	END IF
	
	RETURN arrBanktypeList
END FUNCTION	

########################################################################################
# FUNCTION BanktypeLookupSearchDataSource(pRecBanktypeFilter)
#-------------------------------------------------------
# CALLS BanktypeLookupSearchDataSourceCursor(pRecBanktypeFilter) with the BanktypeFilter data TO get a CURSOR
# Returns the Banktype list array arrBanktypeList
########################################################################################
FUNCTION BanktypeLookupSearchDataSource(p_recBanktypeSearch)
	DEFINE p_recBanktypeSearch OF t_recBanktypeSearch	
	DEFINE recBanktype OF t_recBanktype
	DEFINE arrBanktypeList DYNAMIC ARRAY OF t_recBanktype 
	DEFINE c_Banktype CURSOR
	DEFINE retError SMALLINT	
	CALL BanktypeLookupSearchDataSourceCursor(p_recBanktypeSearch) RETURNING c_Banktype
	
	CALL arrBanktypeList.CLEAR()

	CALL c_Banktype.SetResults(recBanktype.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Banktype.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Banktype.FetchNext()=0)
		CALL arrBanktypeList.append([recBanktype.type_code, recBanktype.type_text])
	END WHILE	

	END IF
	
	IF arrBanktypeList.getSize() = 0 THEN
		ERROR "No COA's found with the specified filter criteria"
	END IF
	
	RETURN arrBanktypeList
END FUNCTION


########################################################################################
# FUNCTION banktypeLookup_filter(pBanktypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Banktype code type_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL BanktypeLookupFilterDataSource(recBanktypeFilter.*) RETURNING arrBanktypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Banktype Code type_code
#
# Example:
# 			LET pr_Banktype.type_code = BanktypeLookup(pr_Banktype.type_code)
########################################################################################
FUNCTION banktypeLookup_filter(pBanktypeCode)
	DEFINE pBanktypeCode LIKE Banktype.type_code
	DEFINE arrBanktypeList DYNAMIC ARRAY OF t_recBanktype
	DEFINE recBanktypeFilter OF t_recBanktypeFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wBanktypeLookup WITH FORM "BanktypeLookup_filter"


	CALL BanktypeLookupFilterDataSource(recBanktypeFilter.*) RETURNING arrBanktypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recBanktypeFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL BanktypeLookupFilterDataSource(recBanktypeFilter.*) RETURNING arrBanktypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrBanktypeList TO scBanktypeList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pBanktypeCode = arrBanktypeList[idx].type_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recBanktypeFilter.filter_type_code IS NOT NULL
			OR recBanktypeFilter.filter_type_text IS NOT NULL

		THEN
			LET recBanktypeFilter.filter_type_code = NULL
			LET recBanktypeFilter.filter_type_text = NULL

			CALL BanktypeLookupFilterDataSource(recBanktypeFilter.*) RETURNING arrBanktypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_type_code"
		IF recBanktypeFilter.filter_type_code IS NOT NULL THEN
			LET recBanktypeFilter.filter_type_code = NULL
			CALL BanktypeLookupFilterDataSource(recBanktypeFilter.*) RETURNING arrBanktypeList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_type_text"
		IF recBanktypeFilter.filter_type_text IS NOT NULL THEN
			LET recBanktypeFilter.filter_type_text = NULL
			CALL BanktypeLookupFilterDataSource(recBanktypeFilter.*) RETURNING arrBanktypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wBanktypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pBanktypeCode	
END FUNCTION				
		

########################################################################################
# FUNCTION banktypeLookup(pBanktypeCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Banktype code type_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL BanktypeLookupSearchDataSource(recBanktypeFilter.*) RETURNING arrBanktypeList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Banktype Code type_code
#
# Example:
# 			LET pr_Banktype.type_code = BanktypeLookup(pr_Banktype.type_code)
########################################################################################
FUNCTION banktypeLookup(pBanktypeCode)
	DEFINE pBanktypeCode LIKE Banktype.type_code
	DEFINE arrBanktypeList DYNAMIC ARRAY OF t_recBanktype
	DEFINE recBanktypeSearch OF t_recBanktypeSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wBanktypeLookup WITH FORM "banktypeLookup"

	CALL BanktypeLookupSearchDataSource(recBanktypeSearch.*) RETURNING arrBanktypeList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recBanktypeSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL BanktypeLookupSearchDataSource(recBanktypeSearch.*) RETURNING arrBanktypeList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrBanktypeList TO scBanktypeList.* 
		BEFORE ROW
			IF arrBanktypeList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pBanktypeCode = arrBanktypeList[idx].type_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recBanktypeSearch.filter_any_field IS NOT NULL

		THEN
			LET recBanktypeSearch.filter_any_field = NULL

			CALL BanktypeLookupSearchDataSource(recBanktypeSearch.*) RETURNING arrBanktypeList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_type_code"
		IF recBanktypeSearch.filter_any_field IS NOT NULL THEN
			LET recBanktypeSearch.filter_any_field = NULL
			CALL BanktypeLookupSearchDataSource(recBanktypeSearch.*) RETURNING arrBanktypeList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wBanktypeLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pBanktypeCode	
END FUNCTION				

############################################
# FUNCTION import_banktype()
############################################
FUNCTION import_banktype()  --(p_silentMode,p_country_code)
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
	 

	DEFINE p_type_text LIKE company.name_text
	#DEFINE p_country_code LIKE country.country_code
	DEFINE p_country_text LIKE country.country_text
	#DEFINE p_language_code LIKE company.language_code
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_banktype RECORD 
    type_code CHAR(8),
    type_text CHAR(40),
    eft_format_ind SMALLINT,
    eft_path_text CHAR(40),
    eft_file_text CHAR(20),
    stmt_format_ind SMALLINT,
    stmt_path_text CHAR(40),
    stmt_file_text CHAR(20)
	END RECORD	

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_banktype
		IF STATUS = -206 THEN  --table does NOT exist
			CREATE TEMP TABLE temp_banktype(
		    type_code CHAR(8),
		    type_text CHAR(40),
		    eft_format_ind SMALLINT,
		    eft_path_text CHAR(40),
		    eft_file_text CHAR(20),
		    stmt_format_ind SMALLINT,
		    stmt_path_text CHAR(40),
		    stmt_file_text CHAR(20)
			)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_banktype	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------	

	
	


--------------------------------------------------------------- before ---------------------------------------------------------------------
	
	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wBanktypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Bank Type Import" TO header_text
	END IF


	let load_file = "unl/banktype-",gl_setupRec_default_company.country_code CLIPPED,".unl"
	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ", gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Banktype Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_banktype
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_banktype
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_banktype
			LET importReport = importReport, "Code:", trim(rec_banktype.type_code) , "     -     Desc:", trim(rec_banktype.type_text), "\n"
					
			INSERT INTO banktype VALUES(
			rec_banktype.type_code,
			rec_banktype.type_text,
			rec_banktype.eft_format_ind,
			rec_banktype.eft_path_text,
			rec_banktype.eft_file_text,
			rec_banktype.stmt_format_ind,
			rec_banktype.stmt_path_text,
			rec_banktype.stmt_file_text
						
			)
			CASE
			WHEN STATUS =0
				LET count_rows_inserted = count_rows_inserted + 1
			WHEN STATUS = -268 OR STATUS = -239
				LET importReport = importReport, "Code:", trim(rec_banktype.type_code) , "     -     Desc:", trim(rec_banktype.type_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wBanktypeImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION

##################################################
# FUNCTION exist_banktypeRec(p_type_code)
##################################################
FUNCTION exist_banktypeRec(p_type_code)

	DEFINE p_type_code LIKE banktype.type_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM banktype 
     WHERE type_code = p_type_code

	DROP TABLE temp_banktype
	CLOSE WINDOW wBanktypeImport
	
	RETURN recCount

END FUNCTION



###############################################################
# FUNCTION delete_banktypeAll  NOTE: Delete ALL
###############################################################
FUNCTION delete_banktypeAll()

	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING
	
	IF gl_setupRec.silentMode = 0 THEN --no ui
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing table banktype data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM banktype
		WHENEVER ERROR STOP
	END IF	
		
		
	IF sqlca.sqlcode <> 0 THEN
		LET tmpMsg = "Error when trying TO delete all data in the table journal!"
		CALL fgl_winmessage("Error",tmpMsg,"error")
	ELSE
		LET tmpMsg = "All data in the table journal where deleted"
			
		IF gl_setupRec.silentMode = 0 THEN --no ui					
			CALL fgl_winmessage("Success",tmpMsg,"info")
		END IF						
	END IF		
			
END FUNCTION	


###############################################################
# FUNCTION unload_bankType()
###############################################################
FUNCTION unload_bankType(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)

	LET currentCompany = getCurrentUser_cmpy_code()		
	LET unloadFile = "unl/banktype-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 

	LET unloadFile1 = unloadFile CLIPPED, "_", getCurrentUser_cmpy_code()
	UNLOAD TO unloadFile1
		SELECT  
			type_code,
			type_text,
			eft_format_ind,
			eft_path_text,
			eft_file_text,
			stmt_format_ind,
			stmt_path_text,
			stmt_file_text
		FROM banktype
		WHERE cmpy_code = currentCompany
		ORDER BY type_code ASC

	LET unloadFile2 = 	unloadFile CLIPPED , "_all"
	UNLOAD TO unloadFile2 
		SELECT *  
		FROM banktype ORDER BY cmpy_code, type_code ASC
	
	LET tmpMsg = "All bankType data were exported/written TO:\n", unloadFile1, " AND ", unloadFile2
	CALL fgl_winmessage("bankType Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION


###############################################################
# FUNCTION delete_bankType_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_bankType_all()
	DEFINE p_silentMode BOOLEAN
	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wBankTypeImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Bank Types (bankType) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing bankType table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM banktype
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table banktype!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table banktype where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wBankTypeImport		
END FUNCTION	