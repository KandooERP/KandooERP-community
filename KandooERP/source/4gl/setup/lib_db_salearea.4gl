GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getSaleAreaCount()
# FUNCTION saleareaLookupFilterDataSourceCursor(pRecSaleAreaFilter)
# FUNCTION saleareaLookupSearchDataSourceCursor(p_RecSaleAreaSearch)
# FUNCTION SaleAreaLookupFilterDataSource(pRecSaleAreaFilter)
# FUNCTION saleareaLookup_filter(pSaleAreaCode)
# FUNCTION import_salearea()
# FUNCTION exist_saleareaRec(p_cmpy_code, p_area_code)
# FUNCTION delete_salearea_all()
# FUNCTION saleAreaMenu()						-- Offer different OPTIONS of this library via a menu

# SaleArea record types
	DEFINE t_recSaleArea  
		TYPE AS RECORD
			area_code LIKE salearea.area_code,
			desc_text LIKE salearea.desc_text
		END RECORD 

	DEFINE t_recSaleAreaFilter  
		TYPE AS RECORD
			filter_area_code LIKE salearea.area_code,
			filter_desc_text LIKE salearea.desc_text
		END RECORD 

	DEFINE t_recSaleAreaSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recSaleArea_noCmpyId 
		TYPE AS RECORD 
    area_code LIKE salearea.area_code,
    desc_text LIKE salearea.desc_text,
    dept_text LIKE salearea.dept_text
	END RECORD	

	
########################################################################################
# FUNCTION saleAreaMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION saleAreaMenu()
	MENU
		ON ACTION "Import"
			CALL import_salearea()
		ON ACTION "Export"
			CALL unload_salearea(FALSE,"exp")
		#ON ACTION "Import"
		#	CALL import_salearea()
		ON ACTION "Delete All"
			CALL delete_salearea_all()
		ON ACTION "Count"
			CALL getSaleAreaCount() --Count all salearea rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getSaleAreaCount()
#-------------------------------------------------------
# Returns the number of SaleArea entries for the current company
########################################################################################
FUNCTION getSaleAreaCount()
	DEFINE ret_SaleAreaCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_SaleArea CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM SaleArea ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_SaleArea.DECLARE(sqlQuery) #CURSOR FOR getSaleArea
	CALL c_SaleArea.SetResults(ret_SaleAreaCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_SaleArea.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_SaleAreaCount = -1
	ELSE
		CALL c_SaleArea.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Sale Areas (salearea):", trim(ret_SaleAreaCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Sale Areas (salearea) Count", tempMsg,"info") 	
	END IF

	RETURN ret_SaleAreaCount
END FUNCTION

########################################################################################
# FUNCTION saleareaLookupFilterDataSourceCursor(pRecSaleAreaFilter)
#-------------------------------------------------------
# Returns the SaleArea CURSOR for the lookup query
########################################################################################
FUNCTION saleareaLookupFilterDataSourceCursor(pRecSaleAreaFilter)
	DEFINE pRecSaleAreaFilter OF t_recSaleAreaFilter
	DEFINE sqlQuery STRING
	DEFINE c_SaleArea CURSOR
	
	LET sqlQuery =	"SELECT ",
									"salearea.area_code, ", 
									"salearea.desc_text ",
									"FROM salearea ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecSaleAreaFilter.filter_area_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND area_code LIKE '", pRecSaleAreaFilter.filter_area_code CLIPPED, "%' "  
	END IF									

	IF pRecSaleAreaFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecSaleAreaFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY area_code"

	CALL c_salearea.DECLARE(sqlQuery)
		
	RETURN c_salearea
END FUNCTION



########################################################################################
# saleareaLookupSearchDataSourceCursor(p_RecSaleAreaSearch)
#-------------------------------------------------------
# Returns the SaleArea CURSOR for the lookup query
########################################################################################
FUNCTION saleareaLookupSearchDataSourceCursor(p_RecSaleAreaSearch)
	DEFINE p_RecSaleAreaSearch OF t_recSaleAreaSearch  
	DEFINE sqlQuery STRING
	DEFINE c_SaleArea CURSOR
	
	LET sqlQuery =	"SELECT ",
									"salearea.area_code, ", 
									"salearea.desc_text ",
 
									"FROM salearea ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecSaleAreaSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((area_code LIKE '", p_RecSaleAreaSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecSaleAreaSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecSaleAreaSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY area_code"

	CALL c_salearea.DECLARE(sqlQuery) #CURSOR FOR salearea
	
	RETURN c_salearea
END FUNCTION


########################################################################################
# FUNCTION SaleAreaLookupFilterDataSource(pRecSaleAreaFilter)
#-------------------------------------------------------
# CALLS SaleAreaLookupFilterDataSourceCursor(pRecSaleAreaFilter) with the SaleAreaFilter data TO get a CURSOR
# Returns the SaleArea list array arrSaleAreaList
########################################################################################
FUNCTION SaleAreaLookupFilterDataSource(pRecSaleAreaFilter)
	DEFINE pRecSaleAreaFilter OF t_recSaleAreaFilter
	DEFINE recSaleArea OF t_recSaleArea
	DEFINE arrSaleAreaList DYNAMIC ARRAY OF t_recSaleArea 
	DEFINE c_SaleArea CURSOR
	DEFINE retError SMALLINT
		
	CALL SaleAreaLookupFilterDataSourceCursor(pRecSaleAreaFilter.*) RETURNING c_SaleArea
	
	CALL arrSaleAreaList.CLEAR()

	CALL c_SaleArea.SetResults(recSaleArea.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_SaleArea.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_SaleArea.FetchNext()=0)
		CALL arrSaleAreaList.append([recSaleArea.area_code, recSaleArea.desc_text])
	END WHILE	

	END IF
	
	IF arrSaleAreaList.getSize() = 0 THEN
		ERROR "No salearea's found with the specified filter criteria"
	END IF
	
	RETURN arrSaleAreaList
END FUNCTION	

########################################################################################
# FUNCTION SaleAreaLookupSearchDataSource(pRecSaleAreaFilter)
#-------------------------------------------------------
# CALLS SaleAreaLookupSearchDataSourceCursor(pRecSaleAreaFilter) with the SaleAreaFilter data TO get a CURSOR
# Returns the SaleArea list array arrSaleAreaList
########################################################################################
FUNCTION SaleAreaLookupSearchDataSource(p_recSaleAreaSearch)
	DEFINE p_recSaleAreaSearch OF t_recSaleAreaSearch	
	DEFINE recSaleArea OF t_recSaleArea
	DEFINE arrSaleAreaList DYNAMIC ARRAY OF t_recSaleArea 
	DEFINE c_SaleArea CURSOR
	DEFINE retError SMALLINT	
	CALL SaleAreaLookupSearchDataSourceCursor(p_recSaleAreaSearch) RETURNING c_SaleArea
	
	CALL arrSaleAreaList.CLEAR()

	CALL c_SaleArea.SetResults(recSaleArea.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_SaleArea.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_SaleArea.FetchNext()=0)
		CALL arrSaleAreaList.append([recSaleArea.area_code, recSaleArea.desc_text])
	END WHILE	

	END IF
	
	IF arrSaleAreaList.getSize() = 0 THEN
		ERROR "No salearea's found with the specified filter criteria"
	END IF
	
	RETURN arrSaleAreaList
END FUNCTION


########################################################################################
# FUNCTION saleareaLookup_filter(pSaleAreaCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required SaleArea code area_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL SaleAreaLookupFilterDataSource(recSaleAreaFilter.*) RETURNING arrSaleAreaList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the SaleArea Code area_code
#
# Example:
# 			LET pr_SaleArea.area_code = SaleAreaLookup(pr_SaleArea.area_code)
########################################################################################
FUNCTION saleareaLookup_filter(pSaleAreaCode)
	DEFINE pSaleAreaCode LIKE SaleArea.area_code
	DEFINE arrSaleAreaList DYNAMIC ARRAY OF t_recSaleArea
	DEFINE recSaleAreaFilter OF t_recSaleAreaFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wSaleAreaLookup WITH FORM "SaleAreaLookup_filter"


	CALL SaleAreaLookupFilterDataSource(recSaleAreaFilter.*) RETURNING arrSaleAreaList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recSaleAreaFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL SaleAreaLookupFilterDataSource(recSaleAreaFilter.*) RETURNING arrSaleAreaList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrSaleAreaList TO scSaleAreaList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pSaleAreaCode = arrSaleAreaList[idx].area_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recSaleAreaFilter.filter_area_code IS NOT NULL
			OR recSaleAreaFilter.filter_desc_text IS NOT NULL

		THEN
			LET recSaleAreaFilter.filter_area_code = NULL
			LET recSaleAreaFilter.filter_desc_text = NULL

			CALL SaleAreaLookupFilterDataSource(recSaleAreaFilter.*) RETURNING arrSaleAreaList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_area_code"
		IF recSaleAreaFilter.filter_area_code IS NOT NULL THEN
			LET recSaleAreaFilter.filter_area_code = NULL
			CALL SaleAreaLookupFilterDataSource(recSaleAreaFilter.*) RETURNING arrSaleAreaList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recSaleAreaFilter.filter_desc_text IS NOT NULL THEN
			LET recSaleAreaFilter.filter_desc_text = NULL
			CALL SaleAreaLookupFilterDataSource(recSaleAreaFilter.*) RETURNING arrSaleAreaList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wSaleAreaLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pSaleAreaCode	
END FUNCTION				
		

########################################################################################
# FUNCTION saleareaLookup(pSaleAreaCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required SaleArea code area_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL SaleAreaLookupSearchDataSource(recSaleAreaFilter.*) RETURNING arrSaleAreaList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the SaleArea Code area_code
#
# Example:
# 			LET pr_SaleArea.area_code = SaleAreaLookup(pr_SaleArea.area_code)
########################################################################################
FUNCTION saleareaLookup(pSaleAreaCode)
	DEFINE pSaleAreaCode LIKE SaleArea.area_code
	DEFINE arrSaleAreaList DYNAMIC ARRAY OF t_recSaleArea
	DEFINE recSaleAreaSearch OF t_recSaleAreaSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wSaleAreaLookup WITH FORM "saleareaLookup"

	CALL SaleAreaLookupSearchDataSource(recSaleAreaSearch.*) RETURNING arrSaleAreaList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recSaleAreaSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL SaleAreaLookupSearchDataSource(recSaleAreaSearch.*) RETURNING arrSaleAreaList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrSaleAreaList TO scSaleAreaList.* 
		BEFORE ROW
			IF arrSaleAreaList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pSaleAreaCode = arrSaleAreaList[idx].area_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recSaleAreaSearch.filter_any_field IS NOT NULL

		THEN
			LET recSaleAreaSearch.filter_any_field = NULL

			CALL SaleAreaLookupSearchDataSource(recSaleAreaSearch.*) RETURNING arrSaleAreaList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_area_code"
		IF recSaleAreaSearch.filter_any_field IS NOT NULL THEN
			LET recSaleAreaSearch.filter_any_field = NULL
			CALL SaleAreaLookupSearchDataSource(recSaleAreaSearch.*) RETURNING arrSaleAreaList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wSaleAreaLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pSaleAreaCode	
END FUNCTION				

############################################
# FUNCTION import_salearea()
############################################
FUNCTION import_salearea()
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
	
	DEFINE rec_salearea OF t_recSaleArea_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wSaleAreaImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Sale Areas List Data (table: salearea)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_salearea
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_salearea(
    area_code CHAR(5),
    desc_text CHAR(30),
    dept_text CHAR(60)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_salearea	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wSaleAreaImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wSaleAreaImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/salearea-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_salearea
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_salearea
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_salearea
			LET importReport = importReport, "Code:", trim(rec_salearea.area_code) , "     -     Desc:", trim(rec_salearea.desc_text), "\n"
					
			INSERT INTO salearea VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_salearea.area_code,
			rec_salearea.desc_text,
			rec_salearea.dept_text
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_salearea.area_code) , "     -     Desc:", trim(rec_salearea.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wSaleAreaImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_saleareaRec(p_cmpy_code, p_area_code)
########################################################
FUNCTION exist_saleareaRec(p_cmpy_code, p_area_code)
	DEFINE p_cmpy_code LIKE salearea.cmpy_code
	DEFINE p_area_code LIKE salearea.area_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM salearea 
     WHERE cmpy_code = p_cmpy_code
     AND area_code = p_area_code

	DROP TABLE temp_salearea
	CLOSE WINDOW wSaleAreaImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_salearea()
###############################################################
FUNCTION unload_salearea(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)
	
	LET currentCompany = getCurrentUser_cmpy_code()	
	
	LET unloadFile = "unl/salearea-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 

	LET unloadFile1 = unloadFile CLIPPED, "_", getCurrentUser_cmpy_code()
	UNLOAD TO unloadFile1 
		SELECT 
	    #cmpy_code,
	    area_code,
	    desc_text,
	    dept_text
		FROM salearea 
		WHERE cmpy_code = currentCompany		
		ORDER BY area_code ASC

	----	
	LET unloadFile2 = 	unloadFile CLIPPED , "_all"
	UNLOAD TO unloadFile2 
		SELECT * 
		FROM salearea 
		ORDER BY cmpy_code, area_code ASC

	
	LET tmpMsg = "All salearea data were exported/written TO:\n", unloadFile1, "AND ", unloadFile2
	CALL fgl_winmessage("salearea Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_salearea_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_salearea_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE salearea.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wsaleareaImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "salearea Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing salearea table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM salearea
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table salearea!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table salearea where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wSaleAreaImport		
END FUNCTION	