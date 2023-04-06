GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getCartAreaCount()
# FUNCTION cartareaLookupFilterDataSourceCursor(pRecCartAreaFilter)
# FUNCTION cartareaLookupSearchDataSourceCursor(p_RecCartAreaSearch)
# FUNCTION CartAreaLookupFilterDataSource(pRecCartAreaFilter)
# FUNCTION cartareaLookup_filter(pCartAreaCode)
# FUNCTION import_cartarea()
# FUNCTION exist_cartareaRec(p_cmpy_code, p_cart_area_code)
# FUNCTION delete_cartarea_all()
# FUNCTION cartAreaMenu()						-- Offer different OPTIONS of this library via a menu

# CartArea record types
	DEFINE t_recCartArea  
		TYPE AS RECORD
			cart_area_code LIKE cartarea.cart_area_code,
			desc_text LIKE cartarea.desc_text
		END RECORD 

	DEFINE t_recCartAreaFilter  
		TYPE AS RECORD
			filter_cart_area_code LIKE cartarea.cart_area_code,
			filter_desc_text LIKE cartarea.desc_text
		END RECORD 

	DEFINE t_recCartAreaSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recCartArea_noCmpyId 
		TYPE AS RECORD 
    cart_area_code LIKE cartarea.cart_area_code,
    desc_text LIKE cartarea.desc_text
	END RECORD	


	
########################################################################################
# FUNCTION cartAreaMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION cartAreaMenu()
	MENU
		ON ACTION "Import"
			CALL import_cartarea()
		ON ACTION "Export"
			CALL unload_cartarea()
		#ON ACTION "Import"
		#	CALL import_cartarea()
		ON ACTION "Delete All"
			CALL delete_cartarea_all()
		ON ACTION "Count"
			CALL getCartAreaCount() --Count all cartarea rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getCartAreaCount()
#-------------------------------------------------------
# Returns the number of CartArea entries for the current company
########################################################################################
FUNCTION getCartAreaCount()
	DEFINE ret_CartAreaCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_CartArea CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM CartArea ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_CartArea.DECLARE(sqlQuery) #CURSOR FOR getCartArea
	CALL c_CartArea.SetResults(ret_CartAreaCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_CartArea.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_CartAreaCount = -1
	ELSE
		CALL c_CartArea.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Cart Areas:", trim(ret_CartAreaCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Cart Area Count", tempMsg,"info") 	
	END IF

	RETURN ret_CartAreaCount
END FUNCTION

########################################################################################
# FUNCTION cartareaLookupFilterDataSourceCursor(pRecCartAreaFilter)
#-------------------------------------------------------
# Returns the CartArea CURSOR for the lookup query
########################################################################################
FUNCTION cartareaLookupFilterDataSourceCursor(pRecCartAreaFilter)
	DEFINE pRecCartAreaFilter OF t_recCartAreaFilter
	DEFINE sqlQuery STRING
	DEFINE c_CartArea CURSOR
	
	LET sqlQuery =	"SELECT ",
									"cartarea.cart_area_code, ", 
									"cartarea.desc_text ",
									"FROM cartarea ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecCartAreaFilter.filter_cart_area_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND cart_area_code LIKE '", pRecCartAreaFilter.filter_cart_area_code CLIPPED, "%' "  
	END IF									

	IF pRecCartAreaFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecCartAreaFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY cart_area_code"

	CALL c_cartarea.DECLARE(sqlQuery)
		
	RETURN c_cartarea
END FUNCTION



########################################################################################
# cartareaLookupSearchDataSourceCursor(p_RecCartAreaSearch)
#-------------------------------------------------------
# Returns the CartArea CURSOR for the lookup query
########################################################################################
FUNCTION cartareaLookupSearchDataSourceCursor(p_RecCartAreaSearch)
	DEFINE p_RecCartAreaSearch OF t_recCartAreaSearch  
	DEFINE sqlQuery STRING
	DEFINE c_CartArea CURSOR
	
	LET sqlQuery =	"SELECT ",
									"cartarea.cart_area_code, ", 
									"cartarea.desc_text ",
 
									"FROM cartarea ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecCartAreaSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((cart_area_code LIKE '", p_RecCartAreaSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecCartAreaSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecCartAreaSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY cart_area_code"

	CALL c_cartarea.DECLARE(sqlQuery) #CURSOR FOR cartarea
	
	RETURN c_cartarea
END FUNCTION


########################################################################################
# FUNCTION CartAreaLookupFilterDataSource(pRecCartAreaFilter)
#-------------------------------------------------------
# CALLS CartAreaLookupFilterDataSourceCursor(pRecCartAreaFilter) with the CartAreaFilter data TO get a CURSOR
# Returns the CartArea list array arrCartAreaList
########################################################################################
FUNCTION CartAreaLookupFilterDataSource(pRecCartAreaFilter)
	DEFINE pRecCartAreaFilter OF t_recCartAreaFilter
	DEFINE recCartArea OF t_recCartArea
	DEFINE arrCartAreaList DYNAMIC ARRAY OF t_recCartArea 
	DEFINE c_CartArea CURSOR
	DEFINE retError SMALLINT
		
	CALL CartAreaLookupFilterDataSourceCursor(pRecCartAreaFilter.*) RETURNING c_CartArea
	
	CALL arrCartAreaList.CLEAR()

	CALL c_CartArea.SetResults(recCartArea.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_CartArea.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_CartArea.FetchNext()=0)
		CALL arrCartAreaList.append([recCartArea.cart_area_code, recCartArea.desc_text])
	END WHILE	

	END IF
	
	IF arrCartAreaList.getSize() = 0 THEN
		ERROR "No cartarea's found with the specified filter criteria"
	END IF
	
	RETURN arrCartAreaList
END FUNCTION	

########################################################################################
# FUNCTION CartAreaLookupSearchDataSource(pRecCartAreaFilter)
#-------------------------------------------------------
# CALLS CartAreaLookupSearchDataSourceCursor(pRecCartAreaFilter) with the CartAreaFilter data TO get a CURSOR
# Returns the CartArea list array arrCartAreaList
########################################################################################
FUNCTION CartAreaLookupSearchDataSource(p_recCartAreaSearch)
	DEFINE p_recCartAreaSearch OF t_recCartAreaSearch	
	DEFINE recCartArea OF t_recCartArea
	DEFINE arrCartAreaList DYNAMIC ARRAY OF t_recCartArea 
	DEFINE c_CartArea CURSOR
	DEFINE retError SMALLINT	
	CALL CartAreaLookupSearchDataSourceCursor(p_recCartAreaSearch) RETURNING c_CartArea
	
	CALL arrCartAreaList.CLEAR()

	CALL c_CartArea.SetResults(recCartArea.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_CartArea.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_CartArea.FetchNext()=0)
		CALL arrCartAreaList.append([recCartArea.cart_area_code, recCartArea.desc_text])
	END WHILE	

	END IF
	
	IF arrCartAreaList.getSize() = 0 THEN
		ERROR "No cartarea's found with the specified filter criteria"
	END IF
	
	RETURN arrCartAreaList
END FUNCTION


########################################################################################
# FUNCTION cartareaLookup_filter(pCartAreaCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required CartArea code cart_area_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CartAreaLookupFilterDataSource(recCartAreaFilter.*) RETURNING arrCartAreaList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the CartArea Code cart_area_code
#
# Example:
# 			LET pr_CartArea.cart_area_code = CartAreaLookup(pr_CartArea.cart_area_code)
########################################################################################
FUNCTION cartareaLookup_filter(pCartAreaCode)
	DEFINE pCartAreaCode LIKE CartArea.cart_area_code
	DEFINE arrCartAreaList DYNAMIC ARRAY OF t_recCartArea
	DEFINE recCartAreaFilter OF t_recCartAreaFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCartAreaLookup WITH FORM "CartAreaLookup_filter"


	CALL CartAreaLookupFilterDataSource(recCartAreaFilter.*) RETURNING arrCartAreaList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCartAreaFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL CartAreaLookupFilterDataSource(recCartAreaFilter.*) RETURNING arrCartAreaList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCartAreaList TO scCartAreaList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCartAreaCode = arrCartAreaList[idx].cart_area_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCartAreaFilter.filter_cart_area_code IS NOT NULL
			OR recCartAreaFilter.filter_desc_text IS NOT NULL

		THEN
			LET recCartAreaFilter.filter_cart_area_code = NULL
			LET recCartAreaFilter.filter_desc_text = NULL

			CALL CartAreaLookupFilterDataSource(recCartAreaFilter.*) RETURNING arrCartAreaList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_cart_area_code"
		IF recCartAreaFilter.filter_cart_area_code IS NOT NULL THEN
			LET recCartAreaFilter.filter_cart_area_code = NULL
			CALL CartAreaLookupFilterDataSource(recCartAreaFilter.*) RETURNING arrCartAreaList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recCartAreaFilter.filter_desc_text IS NOT NULL THEN
			LET recCartAreaFilter.filter_desc_text = NULL
			CALL CartAreaLookupFilterDataSource(recCartAreaFilter.*) RETURNING arrCartAreaList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCartAreaLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCartAreaCode	
END FUNCTION				
		

########################################################################################
# FUNCTION cartareaLookup(pCartAreaCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required CartArea code cart_area_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CartAreaLookupSearchDataSource(recCartAreaFilter.*) RETURNING arrCartAreaList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the CartArea Code cart_area_code
#
# Example:
# 			LET pr_CartArea.cart_area_code = CartAreaLookup(pr_CartArea.cart_area_code)
########################################################################################
FUNCTION cartareaLookup(pCartAreaCode)
	DEFINE pCartAreaCode LIKE CartArea.cart_area_code
	DEFINE arrCartAreaList DYNAMIC ARRAY OF t_recCartArea
	DEFINE recCartAreaSearch OF t_recCartAreaSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCartAreaLookup WITH FORM "cartareaLookup"

	CALL CartAreaLookupSearchDataSource(recCartAreaSearch.*) RETURNING arrCartAreaList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCartAreaSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL CartAreaLookupSearchDataSource(recCartAreaSearch.*) RETURNING arrCartAreaList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCartAreaList TO scCartAreaList.* 
		BEFORE ROW
			IF arrCartAreaList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCartAreaCode = arrCartAreaList[idx].cart_area_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCartAreaSearch.filter_any_field IS NOT NULL

		THEN
			LET recCartAreaSearch.filter_any_field = NULL

			CALL CartAreaLookupSearchDataSource(recCartAreaSearch.*) RETURNING arrCartAreaList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_cart_area_code"
		IF recCartAreaSearch.filter_any_field IS NOT NULL THEN
			LET recCartAreaSearch.filter_any_field = NULL
			CALL CartAreaLookupSearchDataSource(recCartAreaSearch.*) RETURNING arrCartAreaList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCartAreaLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCartAreaCode	
END FUNCTION				

############################################
# FUNCTION import_cartarea()
############################################
FUNCTION import_cartarea()
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
	
	DEFINE rec_cartarea OF t_recCartArea_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wCartAreaImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Cart Area List Data (table: cartarea)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_cartarea
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_cartarea(	    
    cart_area_code CHAR(3),
    desc_text CHAR(40)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_cartarea	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wCartAreaImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wCartAreaImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/cartarea-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_cartarea
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_cartarea
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_cartarea
			LET importReport = importReport, "Code:", trim(rec_cartarea.cart_area_code) , "     -     Desc:", trim(rec_cartarea.desc_text), "\n"
					
			INSERT INTO cartarea VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_cartarea.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_cartarea.cart_area_code) , "     -     Desc:", trim(rec_cartarea.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wCartAreaImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_cartareaRec(p_cmpy_code, p_cart_area_code)
########################################################
FUNCTION exist_cartareaRec(p_cmpy_code, p_cart_area_code)
	DEFINE p_cmpy_code LIKE cartarea.cmpy_code
	DEFINE p_cart_area_code LIKE cartarea.cart_area_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM cartarea 
     WHERE cmpy_code = p_cmpy_code
     AND cart_area_code = p_cart_area_code

	DROP TABLE temp_cartarea
	CLOSE WINDOW wCartAreaImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_cartarea()
###############################################################
FUNCTION unload_cartarea(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/cartarea-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM cartarea ORDER BY cmpy_code, cart_area_code ASC
	
	LET tmpMsg = "All cartarea data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("cartarea Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_cartarea_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_cartarea_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE cartarea.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wcartareaImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "cartarea Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing cartarea table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM cartarea
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table cartarea!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table cartarea where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wCartAreaImport		
END FUNCTION	