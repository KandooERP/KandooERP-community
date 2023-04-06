GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getLabelheadCount()
# FUNCTION labelheadLookupFilterDataSourceCursor(pRecLabelheadFilter)
# FUNCTION labelheadLookupSearchDataSourceCursor(p_RecLabelheadSearch)
# FUNCTION LabelheadLookupFilterDataSource(pRecLabelheadFilter)
# FUNCTION labelheadLookup_filter(pLabelheadCode)
# FUNCTION import_labelhead()
# FUNCTION exist_labelheadRec(p_cmpy_code, p_label_code)
# FUNCTION delete_labelhead_all()
# FUNCTION labelHeadMenu()						-- Offer different OPTIONS of this library via a menu

# Labelhead record types
	DEFINE t_recLabelhead  
		TYPE AS RECORD
			label_code LIKE labelhead.label_code,
			desc_text LIKE labelhead.desc_text
		END RECORD 

	DEFINE t_recLabelheadFilter  
		TYPE AS RECORD
			filter_label_code LIKE labelhead.label_code,
			filter_desc_text LIKE labelhead.desc_text
		END RECORD 

	DEFINE t_recLabelheadSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recLabelhead_noCmpyId 
		TYPE AS RECORD 
    label_code LIKE labelhead.label_code,
    desc_text LIKE labelhead.desc_text,
    print_code LIKE labelhead.print_code
	END RECORD	

	
########################################################################################
# FUNCTION labelHeadMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION labelHeadMenu()
	MENU
		ON ACTION "Import"
			CALL import_labelhead()
		ON ACTION "Export"
			CALL unload_labelhead()
		#ON ACTION "Import"
		#	CALL import_labelhead()
		ON ACTION "Delete All"
			CALL delete_labelhead_all()
		ON ACTION "Count"
			CALL getLabelheadCount() --Count all labelhead rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getLabelheadCount()
#-------------------------------------------------------
# Returns the number of Labelhead entries for the current company
########################################################################################
FUNCTION getLabelheadCount()
	DEFINE ret_LabelheadCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Labelhead CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Labelhead ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Labelhead.DECLARE(sqlQuery) #CURSOR FOR getLabelhead
	CALL c_Labelhead.SetResults(ret_LabelheadCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Labelhead.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_LabelheadCount = -1
	ELSE
		CALL c_Labelhead.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Label Heads:", trim(ret_LabelheadCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Label Head Count", tempMsg,"info") 	
	END IF

	RETURN ret_LabelheadCount
END FUNCTION

########################################################################################
# FUNCTION labelheadLookupFilterDataSourceCursor(pRecLabelheadFilter)
#-------------------------------------------------------
# Returns the Labelhead CURSOR for the lookup query
########################################################################################
FUNCTION labelheadLookupFilterDataSourceCursor(pRecLabelheadFilter)
	DEFINE pRecLabelheadFilter OF t_recLabelheadFilter
	DEFINE sqlQuery STRING
	DEFINE c_Labelhead CURSOR
	
	LET sqlQuery =	"SELECT ",
									"labelhead.label_code, ", 
									"labelhead.desc_text ",
									"FROM labelhead ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecLabelheadFilter.filter_label_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND label_code LIKE '", pRecLabelheadFilter.filter_label_code CLIPPED, "%' "  
	END IF									

	IF pRecLabelheadFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecLabelheadFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY label_code"

	CALL c_labelhead.DECLARE(sqlQuery)
		
	RETURN c_labelhead
END FUNCTION



########################################################################################
# labelheadLookupSearchDataSourceCursor(p_RecLabelheadSearch)
#-------------------------------------------------------
# Returns the Labelhead CURSOR for the lookup query
########################################################################################
FUNCTION labelheadLookupSearchDataSourceCursor(p_RecLabelheadSearch)
	DEFINE p_RecLabelheadSearch OF t_recLabelheadSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Labelhead CURSOR
	
	LET sqlQuery =	"SELECT ",
									"labelhead.label_code, ", 
									"labelhead.desc_text ",
 
									"FROM labelhead ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecLabelheadSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((label_code LIKE '", p_RecLabelheadSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecLabelheadSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecLabelheadSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY label_code"

	CALL c_labelhead.DECLARE(sqlQuery) #CURSOR FOR labelhead
	
	RETURN c_labelhead
END FUNCTION


########################################################################################
# FUNCTION LabelheadLookupFilterDataSource(pRecLabelheadFilter)
#-------------------------------------------------------
# CALLS LabelheadLookupFilterDataSourceCursor(pRecLabelheadFilter) with the LabelheadFilter data TO get a CURSOR
# Returns the Labelhead list array arrLabelheadList
########################################################################################
FUNCTION LabelheadLookupFilterDataSource(pRecLabelheadFilter)
	DEFINE pRecLabelheadFilter OF t_recLabelheadFilter
	DEFINE recLabelhead OF t_recLabelhead
	DEFINE arrLabelheadList DYNAMIC ARRAY OF t_recLabelhead 
	DEFINE c_Labelhead CURSOR
	DEFINE retError SMALLINT
		
	CALL LabelheadLookupFilterDataSourceCursor(pRecLabelheadFilter.*) RETURNING c_Labelhead
	
	CALL arrLabelheadList.CLEAR()

	CALL c_Labelhead.SetResults(recLabelhead.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Labelhead.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Labelhead.FetchNext()=0)
		CALL arrLabelheadList.append([recLabelhead.label_code, recLabelhead.desc_text])
	END WHILE	

	END IF
	
	IF arrLabelheadList.getSize() = 0 THEN
		ERROR "No labelhead's found with the specified filter criteria"
	END IF
	
	RETURN arrLabelheadList
END FUNCTION	

########################################################################################
# FUNCTION LabelheadLookupSearchDataSource(pRecLabelheadFilter)
#-------------------------------------------------------
# CALLS LabelheadLookupSearchDataSourceCursor(pRecLabelheadFilter) with the LabelheadFilter data TO get a CURSOR
# Returns the Labelhead list array arrLabelheadList
########################################################################################
FUNCTION LabelheadLookupSearchDataSource(p_recLabelheadSearch)
	DEFINE p_recLabelheadSearch OF t_recLabelheadSearch	
	DEFINE recLabelhead OF t_recLabelhead
	DEFINE arrLabelheadList DYNAMIC ARRAY OF t_recLabelhead 
	DEFINE c_Labelhead CURSOR
	DEFINE retError SMALLINT	
	CALL LabelheadLookupSearchDataSourceCursor(p_recLabelheadSearch) RETURNING c_Labelhead
	
	CALL arrLabelheadList.CLEAR()

	CALL c_Labelhead.SetResults(recLabelhead.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Labelhead.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Labelhead.FetchNext()=0)
		CALL arrLabelheadList.append([recLabelhead.label_code, recLabelhead.desc_text])
	END WHILE	

	END IF
	
	IF arrLabelheadList.getSize() = 0 THEN
		ERROR "No labelhead's found with the specified filter criteria"
	END IF
	
	RETURN arrLabelheadList
END FUNCTION


########################################################################################
# FUNCTION labelheadLookup_filter(pLabelheadCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Labelhead code label_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL LabelheadLookupFilterDataSource(recLabelheadFilter.*) RETURNING arrLabelheadList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Labelhead Code label_code
#
# Example:
# 			LET pr_Labelhead.label_code = LabelheadLookup(pr_Labelhead.label_code)
########################################################################################
FUNCTION labelheadLookup_filter(pLabelheadCode)
	DEFINE pLabelheadCode LIKE labelhead.label_code
	DEFINE arrLabelheadList DYNAMIC ARRAY OF t_recLabelhead
	DEFINE recLabelheadFilter OF t_recLabelheadFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wLabelheadLookup WITH FORM "LabelheadLookup_filter"


	CALL LabelheadLookupFilterDataSource(recLabelheadFilter.*) RETURNING arrLabelheadList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recLabelheadFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL LabelheadLookupFilterDataSource(recLabelheadFilter.*) RETURNING arrLabelheadList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrLabelheadList TO scLabelheadList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pLabelheadCode = arrLabelheadList[idx].label_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recLabelheadFilter.filter_label_code IS NOT NULL
			OR recLabelheadFilter.filter_desc_text IS NOT NULL

		THEN
			LET recLabelheadFilter.filter_label_code = NULL
			LET recLabelheadFilter.filter_desc_text = NULL

			CALL LabelheadLookupFilterDataSource(recLabelheadFilter.*) RETURNING arrLabelheadList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_label_code"
		IF recLabelheadFilter.filter_label_code IS NOT NULL THEN
			LET recLabelheadFilter.filter_label_code = NULL
			CALL LabelheadLookupFilterDataSource(recLabelheadFilter.*) RETURNING arrLabelheadList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recLabelheadFilter.filter_desc_text IS NOT NULL THEN
			LET recLabelheadFilter.filter_desc_text = NULL
			CALL LabelheadLookupFilterDataSource(recLabelheadFilter.*) RETURNING arrLabelheadList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wLabelheadLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pLabelheadCode	
END FUNCTION				
		

########################################################################################
# FUNCTION labelheadLookup(pLabelheadCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Labelhead code label_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL LabelheadLookupSearchDataSource(recLabelheadFilter.*) RETURNING arrLabelheadList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Labelhead Code label_code
#
# Example:
# 			LET pr_Labelhead.label_code = LabelheadLookup(pr_Labelhead.label_code)
########################################################################################
FUNCTION labelheadLookup(pLabelheadCode)
	DEFINE pLabelheadCode LIKE labelhead.label_code
	DEFINE arrLabelheadList DYNAMIC ARRAY OF t_recLabelhead
	DEFINE recLabelheadSearch OF t_recLabelheadSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wLabelheadLookup WITH FORM "labelheadLookup"

	CALL LabelheadLookupSearchDataSource(recLabelheadSearch.*) RETURNING arrLabelheadList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recLabelheadSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL LabelheadLookupSearchDataSource(recLabelheadSearch.*) RETURNING arrLabelheadList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrLabelheadList TO scLabelheadList.* 
		BEFORE ROW
			IF arrLabelheadList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pLabelheadCode = arrLabelheadList[idx].label_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recLabelheadSearch.filter_any_field IS NOT NULL

		THEN
			LET recLabelheadSearch.filter_any_field = NULL

			CALL LabelheadLookupSearchDataSource(recLabelheadSearch.*) RETURNING arrLabelheadList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_label_code"
		IF recLabelheadSearch.filter_any_field IS NOT NULL THEN
			LET recLabelheadSearch.filter_any_field = NULL
			CALL LabelheadLookupSearchDataSource(recLabelheadSearch.*) RETURNING arrLabelheadList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wLabelheadLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pLabelheadCode	
END FUNCTION				

############################################
# FUNCTION import_labelhead()
############################################
FUNCTION import_labelhead()
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
	
	DEFINE rec_labelhead OF t_recLabelhead_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wLabelheadImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Label Head List Data (table: labelhead)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_labelhead
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_labelhead(
	    label_code CHAR(3),
	    desc_text CHAR(30),
	    print_code CHAR(20)		
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_labelhead	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wLabelheadImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wLabelheadImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/labelhead-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_labelhead
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_labelhead
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_labelhead
			LET importReport = importReport, "Code:", trim(rec_labelhead.label_code) , "     -     Desc:", trim(rec_labelhead.desc_text), "\n"
					
			INSERT INTO labelhead VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_labelhead.*
			{label_code,
			rec_labelhead.desc_text,
			rec_labelhead.pay_acct_code,
			rec_labelhead.freight_acct_code,
			rec_labelhead.salestax_acct_code,
			rec_labelhead.disc_acct_code,
			rec_labelhead.exch_acct_code,
			rec_labelhead.withhold_tax_ind,
			rec_labelhead.tax_vend_code
			}
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_labelhead.label_code) , "     -     Desc:", trim(rec_labelhead.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wLabelheadImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_labelheadRec(p_cmpy_code, p_label_code)
########################################################
FUNCTION exist_labelheadRec(p_cmpy_code, p_label_code)
	DEFINE p_cmpy_code LIKE labelhead.cmpy_code
	DEFINE p_label_code LIKE labelhead.label_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM labelhead 
     WHERE cmpy_code = p_cmpy_code
     AND label_code = p_label_code

	DROP TABLE temp_labelhead
	CLOSE WINDOW wLabelheadImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_labelhead()
###############################################################
FUNCTION unload_labelhead(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/labelhead-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM labelhead ORDER BY cmpy_code, label_code ASC
	
	LET tmpMsg = "All labelhead data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("labelhead Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_labelhead_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_labelhead_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE labelhead.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wlabelheadImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "labelhead Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing labelhead table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM labelhead
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table labelhead!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table labelhead where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wLabelheadImport		
END FUNCTION	