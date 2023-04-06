GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getLabelDetlCount()
# FUNCTION labeldetlLookupFilterDataSourceCursor(pRecLabelDetlFilter)
# FUNCTION labeldetlLookupSearchDataSourceCursor(p_RecLabelDetlSearch)
# FUNCTION LabelDetlLookupFilterDataSource(pRecLabelDetlFilter)
# FUNCTION labeldetlLookup_filter(pLabelDetlCode)
# FUNCTION import_labeldetl()
# FUNCTION exist_labeldetlRec(p_cmpy_code, p_label_code)
# FUNCTION delete_labeldetl_all()
# FUNCTION labelDetlMenu()						-- Offer different OPTIONS of this library via a menu

# LabelDetl record types
	DEFINE t_recLabelDetl  
		TYPE AS RECORD
			label_code LIKE labeldetl.label_code,
			line_text LIKE labeldetl.line_text
		END RECORD 

	DEFINE t_recLabelDetlFilter  
		TYPE AS RECORD
			filter_label_code LIKE labeldetl.label_code,
			filter_line_text LIKE labeldetl.line_text
		END RECORD 

	DEFINE t_recLabelDetlSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recLabelDetl_noCmpyId 
		TYPE AS RECORD 
    label_code LIKE labeldetl.label_code,
    line_num LIKE labeldetl.line_num,
    line_text LIKE labeldetl.line_text

	END RECORD	

	
########################################################################################
# FUNCTION labelDetlMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION labelDetlMenu()
	MENU
		ON ACTION "Import"
			CALL import_labeldetl()
		ON ACTION "Export"
			CALL unload_labeldetl()
		#ON ACTION "Import"
		#	CALL import_labeldetl()
		ON ACTION "Delete All"
			CALL delete_labeldetl_all()
		ON ACTION "Count"
			CALL getLabelDetlCount() --Count all labeldetl rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getLabelDetlCount()
#-------------------------------------------------------
# Returns the number of LabelDetl entries for the current company
########################################################################################
FUNCTION getLabelDetlCount()
	DEFINE ret_LabelDetlCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_LabelDetl CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM LabelDetl ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_LabelDetl.DECLARE(sqlQuery) #CURSOR FOR getLabelDetl
	CALL c_LabelDetl.SetResults(ret_LabelDetlCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_LabelDetl.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_LabelDetlCount = -1
	ELSE
		CALL c_LabelDetl.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Label Heads:", trim(ret_LabelDetlCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Label Head Count", tempMsg,"info") 	
	END IF

	RETURN ret_LabelDetlCount
END FUNCTION

########################################################################################
# FUNCTION labeldetlLookupFilterDataSourceCursor(pRecLabelDetlFilter)
#-------------------------------------------------------
# Returns the LabelDetl CURSOR for the lookup query
########################################################################################
FUNCTION labeldetlLookupFilterDataSourceCursor(pRecLabelDetlFilter)
	DEFINE pRecLabelDetlFilter OF t_recLabelDetlFilter
	DEFINE sqlQuery STRING
	DEFINE c_LabelDetl CURSOR
	
	LET sqlQuery =	"SELECT ",
									"labeldetl.label_code, ", 
									"labeldetl.line_text ",
									"FROM labeldetl ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecLabelDetlFilter.filter_label_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND label_code LIKE '", pRecLabelDetlFilter.filter_label_code CLIPPED, "%' "  
	END IF									

	IF pRecLabelDetlFilter.filter_line_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND line_text LIKE '", pRecLabelDetlFilter.filter_line_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY label_code"

	CALL c_labeldetl.DECLARE(sqlQuery)
		
	RETURN c_labeldetl
END FUNCTION



########################################################################################
# labeldetlLookupSearchDataSourceCursor(p_RecLabelDetlSearch)
#-------------------------------------------------------
# Returns the LabelDetl CURSOR for the lookup query
########################################################################################
FUNCTION labeldetlLookupSearchDataSourceCursor(p_RecLabelDetlSearch)
	DEFINE p_RecLabelDetlSearch OF t_recLabelDetlSearch  
	DEFINE sqlQuery STRING
	DEFINE c_LabelDetl CURSOR
	
	LET sqlQuery =	"SELECT ",
									"labeldetl.label_code, ", 
									"labeldetl.line_text ",
 
									"FROM labeldetl ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecLabelDetlSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((label_code LIKE '", p_RecLabelDetlSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR line_text LIKE '",   p_RecLabelDetlSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecLabelDetlSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY label_code"

	CALL c_labeldetl.DECLARE(sqlQuery) #CURSOR FOR labeldetl
	
	RETURN c_labeldetl
END FUNCTION


########################################################################################
# FUNCTION LabelDetlLookupFilterDataSource(pRecLabelDetlFilter)
#-------------------------------------------------------
# CALLS LabelDetlLookupFilterDataSourceCursor(pRecLabelDetlFilter) with the LabelDetlFilter data TO get a CURSOR
# Returns the LabelDetl list array arrLabelDetlList
########################################################################################
FUNCTION LabelDetlLookupFilterDataSource(pRecLabelDetlFilter)
	DEFINE pRecLabelDetlFilter OF t_recLabelDetlFilter
	DEFINE recLabelDetl OF t_recLabelDetl
	DEFINE arrLabelDetlList DYNAMIC ARRAY OF t_recLabelDetl 
	DEFINE c_LabelDetl CURSOR
	DEFINE retError SMALLINT
		
	CALL LabelDetlLookupFilterDataSourceCursor(pRecLabelDetlFilter.*) RETURNING c_LabelDetl
	
	CALL arrLabelDetlList.CLEAR()

	CALL c_LabelDetl.SetResults(recLabelDetl.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_LabelDetl.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_LabelDetl.FetchNext()=0)
		CALL arrLabelDetlList.append([recLabelDetl.label_code, recLabelDetl.line_text])
	END WHILE	

	END IF
	
	IF arrLabelDetlList.getSize() = 0 THEN
		ERROR "No labeldetl's found with the specified filter criteria"
	END IF
	
	RETURN arrLabelDetlList
END FUNCTION	

########################################################################################
# FUNCTION LabelDetlLookupSearchDataSource(pRecLabelDetlFilter)
#-------------------------------------------------------
# CALLS LabelDetlLookupSearchDataSourceCursor(pRecLabelDetlFilter) with the LabelDetlFilter data TO get a CURSOR
# Returns the LabelDetl list array arrLabelDetlList
########################################################################################
FUNCTION LabelDetlLookupSearchDataSource(p_recLabelDetlSearch)
	DEFINE p_recLabelDetlSearch OF t_recLabelDetlSearch	
	DEFINE recLabelDetl OF t_recLabelDetl
	DEFINE arrLabelDetlList DYNAMIC ARRAY OF t_recLabelDetl 
	DEFINE c_LabelDetl CURSOR
	DEFINE retError SMALLINT	
	CALL LabelDetlLookupSearchDataSourceCursor(p_recLabelDetlSearch) RETURNING c_LabelDetl
	
	CALL arrLabelDetlList.CLEAR()

	CALL c_LabelDetl.SetResults(recLabelDetl.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_LabelDetl.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_LabelDetl.FetchNext()=0)
		CALL arrLabelDetlList.append([recLabelDetl.label_code, recLabelDetl.line_text])
	END WHILE	

	END IF
	
	IF arrLabelDetlList.getSize() = 0 THEN
		ERROR "No labeldetl's found with the specified filter criteria"
	END IF
	
	RETURN arrLabelDetlList
END FUNCTION


########################################################################################
# FUNCTION labeldetlLookup_filter(pLabelDetlCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required LabelDetl code label_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL LabelDetlLookupFilterDataSource(recLabelDetlFilter.*) RETURNING arrLabelDetlList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the LabelDetl Code label_code
#
# Example:
# 			LET pr_LabelDetl.label_code = LabelDetlLookup(pr_LabelDetl.label_code)
########################################################################################
FUNCTION labeldetlLookup_filter(pLabelDetlCode)
	DEFINE pLabelDetlCode LIKE labeldetl.label_code
	DEFINE arrLabelDetlList DYNAMIC ARRAY OF t_recLabelDetl
	DEFINE recLabelDetlFilter OF t_recLabelDetlFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wLabelDetlLookup WITH FORM "LabelDetlLookup_filter"


	CALL LabelDetlLookupFilterDataSource(recLabelDetlFilter.*) RETURNING arrLabelDetlList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recLabelDetlFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL LabelDetlLookupFilterDataSource(recLabelDetlFilter.*) RETURNING arrLabelDetlList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrLabelDetlList TO scLabelDetlList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pLabelDetlCode = arrLabelDetlList[idx].label_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recLabelDetlFilter.filter_label_code IS NOT NULL
			OR recLabelDetlFilter.filter_line_text IS NOT NULL

		THEN
			LET recLabelDetlFilter.filter_label_code = NULL
			LET recLabelDetlFilter.filter_line_text = NULL

			CALL LabelDetlLookupFilterDataSource(recLabelDetlFilter.*) RETURNING arrLabelDetlList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_label_code"
		IF recLabelDetlFilter.filter_label_code IS NOT NULL THEN
			LET recLabelDetlFilter.filter_label_code = NULL
			CALL LabelDetlLookupFilterDataSource(recLabelDetlFilter.*) RETURNING arrLabelDetlList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_line_text"
		IF recLabelDetlFilter.filter_line_text IS NOT NULL THEN
			LET recLabelDetlFilter.filter_line_text = NULL
			CALL LabelDetlLookupFilterDataSource(recLabelDetlFilter.*) RETURNING arrLabelDetlList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wLabelDetlLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pLabelDetlCode	
END FUNCTION				
		

########################################################################################
# FUNCTION labeldetlLookup(pLabelDetlCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required LabelDetl code label_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL LabelDetlLookupSearchDataSource(recLabelDetlFilter.*) RETURNING arrLabelDetlList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the LabelDetl Code label_code
#
# Example:
# 			LET pr_LabelDetl.label_code = LabelDetlLookup(pr_LabelDetl.label_code)
########################################################################################
FUNCTION labeldetlLookup(pLabelDetlCode)
	DEFINE pLabelDetlCode LIKE labeldetl.label_code
	DEFINE arrLabelDetlList DYNAMIC ARRAY OF t_recLabelDetl
	DEFINE recLabelDetlSearch OF t_recLabelDetlSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wLabelDetlLookup WITH FORM "labeldetlLookup"

	CALL LabelDetlLookupSearchDataSource(recLabelDetlSearch.*) RETURNING arrLabelDetlList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recLabelDetlSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL LabelDetlLookupSearchDataSource(recLabelDetlSearch.*) RETURNING arrLabelDetlList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrLabelDetlList TO scLabelDetlList.* 
		BEFORE ROW
			IF arrLabelDetlList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pLabelDetlCode = arrLabelDetlList[idx].label_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recLabelDetlSearch.filter_any_field IS NOT NULL

		THEN
			LET recLabelDetlSearch.filter_any_field = NULL

			CALL LabelDetlLookupSearchDataSource(recLabelDetlSearch.*) RETURNING arrLabelDetlList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_label_code"
		IF recLabelDetlSearch.filter_any_field IS NOT NULL THEN
			LET recLabelDetlSearch.filter_any_field = NULL
			CALL LabelDetlLookupSearchDataSource(recLabelDetlSearch.*) RETURNING arrLabelDetlList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wLabelDetlLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pLabelDetlCode	
END FUNCTION				

############################################
# FUNCTION import_labeldetl()
############################################
FUNCTION import_labeldetl()
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
	DEFINE p_line_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_labeldetl OF t_recLabelDetl_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wLabelDetlImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Label Detail List Data (table: labeldetl)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_labeldetl
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_labeldetl(
	    label_code CHAR(3),
	    line_num SMALLINT,
	    line_text CHAR(70)	
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_labeldetl	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_line_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wLabelDetlImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_line_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_line_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wLabelDetlImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/labeldetl-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Label Detail Table Data load (labeldetl)",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_labeldetl
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_labeldetl
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_labeldetl
			LET importReport = importReport, "Code:", trim(rec_labeldetl.label_code) , "     -     Desc:", trim(rec_labeldetl.line_text), "\n"
					
			INSERT INTO labeldetl VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_labeldetl.*
			{label_code,
			rec_labeldetl.line_text,
			rec_labeldetl.pay_acct_code,
			rec_labeldetl.freight_acct_code,
			rec_labeldetl.salestax_acct_code,
			rec_labeldetl.disc_acct_code,
			rec_labeldetl.exch_acct_code,
			rec_labeldetl.withhold_tax_ind,
			rec_labeldetl.tax_vend_code
			}
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_labeldetl.label_code) , "     -     Desc:", trim(rec_labeldetl.line_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wLabelDetlImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_labeldetlRec(p_cmpy_code, p_label_code)
########################################################
FUNCTION exist_labeldetlRec(p_cmpy_code, p_label_code)
	DEFINE p_cmpy_code LIKE labeldetl.cmpy_code
	DEFINE p_label_code LIKE labeldetl.label_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM labeldetl 
     WHERE cmpy_code = p_cmpy_code
     AND label_code = p_label_code

	DROP TABLE temp_labeldetl
	CLOSE WINDOW wLabelDetlImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_labeldetl()
###############################################################
FUNCTION unload_labeldetl(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/labeldetl-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM labeldetl ORDER BY cmpy_code, label_code ASC
	
	LET tmpMsg = "All labeldetl data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("labeldetl Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_labeldetl_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_labeldetl_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE labeldetl.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wlabeldetlImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "labeldetl Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing labeldetl table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM labeldetl
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table labeldetl!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table labeldetl where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wLabelDetlImport		
END FUNCTION	