GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getRmsparmCount()
# FUNCTION rmsparmLookupFilterDataSourceCursor(pRecRmsparmFilter)
# FUNCTION rmsparmLookupSearchDataSourceCursor(p_RecRmsparmSearch)
# FUNCTION RmsparmLookupFilterDataSource(pRecRmsparmFilter)
# FUNCTION rmsparmLookup_filter(pRmsparmCode)
# FUNCTION import_rmsparm()
# FUNCTION exist_rmsparmRec(p_cmpy_code, p_order_hold_flag)
# FUNCTION delete_rmsparm_all()
# FUNCTION rmsParmMenu()						-- Offer different OPTIONS of this library via a menu

# Rmsparm record types
	DEFINE t_recRmsparm  
		TYPE AS RECORD
			order_hold_flag LIKE rmsparm.order_hold_flag,
			order_print_text LIKE rmsparm.order_print_text
		END RECORD 

	DEFINE t_recRmsparmFilter  
		TYPE AS RECORD
			filter_order_hold_flag LIKE rmsparm.order_hold_flag,
			filter_order_print_text LIKE rmsparm.order_print_text
		END RECORD 

	DEFINE t_recRmsparmSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recRmsparm_noCmpyId 
		TYPE AS RECORD 
    order_hold_flag LIKE rmsParm.order_hold_flag,
    order_print_text LIKE rmsParm.order_print_text,
    inv_hold_flag LIKE rmsParm.inv_hold_flag,
    inv_print_text LIKE rmsParm.inv_print_text,
    inv_print_qty LIKE rmsParm.inv_print_qty,
    next_report_num LIKE rmsParm.next_report_num,
    rw_print_text LIKE rmsParm.rw_print_text
    
	END RECORD	

	
########################################################################################
# FUNCTION rmsParmMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION rmsParmMenu()
	MENU
		ON ACTION "Import"
			CALL import_rmsparm()
		ON ACTION "Export"
			CALL unload_rmsparm()
		#ON ACTION "Import"
		#	CALL import_rmsparm()
		ON ACTION "Delete All"
			CALL delete_rmsparm_all()
		ON ACTION "Count"
			CALL getRmsparmCount() --Count all rmsparm rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getRmsparmCount()
#-------------------------------------------------------
# Returns the number of Rmsparm entries for the current company
########################################################################################
FUNCTION getRmsparmCount()
	DEFINE ret_RmsparmCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Rmsparm CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM rmsparm ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Rmsparm.DECLARE(sqlQuery) #CURSOR FOR getRmsparm
	CALL c_Rmsparm.SetResults(ret_RmsparmCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Rmsparm.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_RmsparmCount = -1
	ELSE
		CALL c_Rmsparm.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of RMS Parameters (rmsparm):", trim(ret_RmsparmCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("RMS Parameters Count", tempMsg,"info") 	
	END IF

	RETURN ret_RmsparmCount
END FUNCTION

########################################################################################
# FUNCTION rmsparmLookupFilterDataSourceCursor(pRecRmsparmFilter)
#-------------------------------------------------------
# Returns the Rmsparm CURSOR for the lookup query
########################################################################################
FUNCTION rmsparmLookupFilterDataSourceCursor(pRecRmsparmFilter)
	DEFINE pRecRmsparmFilter OF t_recRmsparmFilter
	DEFINE sqlQuery STRING
	DEFINE c_Rmsparm CURSOR
	
	LET sqlQuery =	"SELECT ",
									"rmsparm.order_hold_flag, ", 
									"rmsparm.order_print_text ",
									"FROM rmsparm ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecRmsparmFilter.filter_order_hold_flag IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND order_hold_flag LIKE '", pRecRmsparmFilter.filter_order_hold_flag CLIPPED, "%' "  
	END IF									

	IF pRecRmsparmFilter.filter_order_print_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND order_print_text LIKE '", pRecRmsparmFilter.filter_order_print_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY order_hold_flag"

	CALL c_rmsparm.DECLARE(sqlQuery)
		
	RETURN c_rmsparm
END FUNCTION



########################################################################################
# rmsparmLookupSearchDataSourceCursor(p_RecRmsparmSearch)
#-------------------------------------------------------
# Returns the Rmsparm CURSOR for the lookup query
########################################################################################
FUNCTION rmsparmLookupSearchDataSourceCursor(p_RecRmsparmSearch)
	DEFINE p_RecRmsparmSearch OF t_recRmsparmSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Rmsparm CURSOR
	
	LET sqlQuery =	"SELECT ",
									"rmsparm.order_hold_flag, ", 
									"rmsparm.order_print_text ",
 
									"FROM rmsparm ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecRmsparmSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((order_hold_flag LIKE '", p_RecRmsparmSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR order_print_text LIKE '",   p_RecRmsparmSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecRmsparmSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY order_hold_flag"

	CALL c_rmsparm.DECLARE(sqlQuery) #CURSOR FOR rmsparm
	
	RETURN c_rmsparm
END FUNCTION


########################################################################################
# FUNCTION RmsparmLookupFilterDataSource(pRecRmsparmFilter)
#-------------------------------------------------------
# CALLS RmsparmLookupFilterDataSourceCursor(pRecRmsparmFilter) with the RmsparmFilter data TO get a CURSOR
# Returns the Rmsparm list array arrRmsparmList
########################################################################################
FUNCTION RmsparmLookupFilterDataSource(pRecRmsparmFilter)
	DEFINE pRecRmsparmFilter OF t_recRmsparmFilter
	DEFINE recRmsparm OF t_recRmsparm
	DEFINE arrRmsparmList DYNAMIC ARRAY OF t_recRmsparm 
	DEFINE c_Rmsparm CURSOR
	DEFINE retError SMALLINT
		
	CALL RmsparmLookupFilterDataSourceCursor(pRecRmsparmFilter.*) RETURNING c_Rmsparm
	
	CALL arrRmsparmList.CLEAR()

	CALL c_Rmsparm.SetResults(recRmsparm.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Rmsparm.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Rmsparm.FetchNext()=0)
		CALL arrRmsparmList.append([recRmsparm.order_hold_flag, recRmsparm.order_print_text])
	END WHILE	

	END IF
	
	IF arrRmsparmList.getSize() = 0 THEN
		ERROR "No rmsparm's found with the specified filter criteria"
	END IF
	
	RETURN arrRmsparmList
END FUNCTION	

########################################################################################
# FUNCTION RmsparmLookupSearchDataSource(pRecRmsparmFilter)
#-------------------------------------------------------
# CALLS RmsparmLookupSearchDataSourceCursor(pRecRmsparmFilter) with the RmsparmFilter data TO get a CURSOR
# Returns the Rmsparm list array arrRmsparmList
########################################################################################
FUNCTION RmsparmLookupSearchDataSource(p_recRmsparmSearch)
	DEFINE p_recRmsparmSearch OF t_recRmsparmSearch	
	DEFINE recRmsparm OF t_recRmsparm
	DEFINE arrRmsparmList DYNAMIC ARRAY OF t_recRmsparm 
	DEFINE c_Rmsparm CURSOR
	DEFINE retError SMALLINT	
	CALL RmsparmLookupSearchDataSourceCursor(p_recRmsparmSearch) RETURNING c_Rmsparm
	
	CALL arrRmsparmList.CLEAR()

	CALL c_Rmsparm.SetResults(recRmsparm.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Rmsparm.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Rmsparm.FetchNext()=0)
		CALL arrRmsparmList.append([recRmsparm.order_hold_flag, recRmsparm.order_print_text])
	END WHILE	

	END IF
	
	IF arrRmsparmList.getSize() = 0 THEN
		ERROR "No rmsparm's found with the specified filter criteria"
	END IF
	
	RETURN arrRmsparmList
END FUNCTION


########################################################################################
# FUNCTION rmsparmLookup_filter(pRmsparmCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Rmsparm code order_hold_flag
# DateSoure AND Cursor are managed in other functions which are called
# CALL RmsparmLookupFilterDataSource(recRmsparmFilter.*) RETURNING arrRmsparmList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Rmsparm Code order_hold_flag
#
# Example:
# 			LET pr_Rmsparm.order_hold_flag = RmsparmLookup(pr_Rmsparm.order_hold_flag)
########################################################################################
FUNCTION rmsparmLookup_filter(pRmsparmCode)
	DEFINE pRmsparmCode LIKE Rmsparm.order_hold_flag
	DEFINE arrRmsparmList DYNAMIC ARRAY OF t_recRmsparm
	DEFINE recRmsparmFilter OF t_recRmsparmFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wRmsparmLookup WITH FORM "RmsparmLookup_filter"


	CALL RmsparmLookupFilterDataSource(recRmsparmFilter.*) RETURNING arrRmsparmList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recRmsparmFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL RmsparmLookupFilterDataSource(recRmsparmFilter.*) RETURNING arrRmsparmList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrRmsparmList TO scRmsparmList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pRmsparmCode = arrRmsparmList[idx].order_hold_flag
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recRmsparmFilter.filter_order_hold_flag IS NOT NULL
			OR recRmsparmFilter.filter_order_print_text IS NOT NULL

		THEN
			LET recRmsparmFilter.filter_order_hold_flag = NULL
			LET recRmsparmFilter.filter_order_print_text = NULL

			CALL RmsparmLookupFilterDataSource(recRmsparmFilter.*) RETURNING arrRmsparmList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_order_hold_flag"
		IF recRmsparmFilter.filter_order_hold_flag IS NOT NULL THEN
			LET recRmsparmFilter.filter_order_hold_flag = NULL
			CALL RmsparmLookupFilterDataSource(recRmsparmFilter.*) RETURNING arrRmsparmList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_order_print_text"
		IF recRmsparmFilter.filter_order_print_text IS NOT NULL THEN
			LET recRmsparmFilter.filter_order_print_text = NULL
			CALL RmsparmLookupFilterDataSource(recRmsparmFilter.*) RETURNING arrRmsparmList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wRmsparmLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pRmsparmCode	
END FUNCTION				
		

########################################################################################
# FUNCTION rmsparmLookup(pRmsparmCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Rmsparm code order_hold_flag
# DateSoure AND Cursor are managed in other functions which are called
# CALL RmsparmLookupSearchDataSource(recRmsparmFilter.*) RETURNING arrRmsparmList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Rmsparm Code order_hold_flag
#
# Example:
# 			LET pr_Rmsparm.order_hold_flag = RmsparmLookup(pr_Rmsparm.order_hold_flag)
########################################################################################
FUNCTION rmsparmLookup(pRmsparmCode)
	DEFINE pRmsparmCode LIKE Rmsparm.order_hold_flag
	DEFINE arrRmsparmList DYNAMIC ARRAY OF t_recRmsparm
	DEFINE recRmsparmSearch OF t_recRmsparmSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wRmsparmLookup WITH FORM "rmsparmLookup"

	CALL RmsparmLookupSearchDataSource(recRmsparmSearch.*) RETURNING arrRmsparmList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recRmsparmSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL RmsparmLookupSearchDataSource(recRmsparmSearch.*) RETURNING arrRmsparmList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrRmsparmList TO scRmsparmList.* 
		BEFORE ROW
			IF arrRmsparmList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pRmsparmCode = arrRmsparmList[idx].order_hold_flag
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recRmsparmSearch.filter_any_field IS NOT NULL

		THEN
			LET recRmsparmSearch.filter_any_field = NULL

			CALL RmsparmLookupSearchDataSource(recRmsparmSearch.*) RETURNING arrRmsparmList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_order_hold_flag"
		IF recRmsparmSearch.filter_any_field IS NOT NULL THEN
			LET recRmsparmSearch.filter_any_field = NULL
			CALL RmsparmLookupSearchDataSource(recRmsparmSearch.*) RETURNING arrRmsparmList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wRmsparmLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pRmsparmCode	
END FUNCTION				

############################################
# FUNCTION import_rmsparm()
############################################
FUNCTION import_rmsparm()
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
	DEFINE p_order_print_text LIKE company.name_text
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_rmsparm OF t_recRmsparm_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wRmsparmImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import RMS Parameter List Data (table: rmsparm)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_rmsparm
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_rmsparm(
	    order_hold_flag CHAR(1),
	    order_print_text CHAR(20),
	    inv_hold_flag CHAR(1),
	    inv_print_text CHAR(20),
	    inv_print_qty SMALLINT,
	    next_report_num INTEGER,
	    rw_print_text CHAR(2)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_rmsparm	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------		

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (gl_setupRec_default_company.cmpy_code) 
		RETURNING p_order_print_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
	#	OPEN WINDOW wRmsparmImport WITH FORM "per/setup/lib_db_data_import_01"
	#	DISPLAY "Chart of Accounts Import" TO header_text

	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code 
			WITHOUT DEFAULTS 
			FROM inputRec3.*
			
				AFTER FIELD cmpy_code
					CALL get_company_info (gl_setupRec_default_company.cmpy_code)
					RETURNING p_order_print_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text

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
							DISPLAY p_order_print_text,gl_setupRec_default_company.country_code,p_country_text,gl_setupRec_default_company.language_code,p_language_text 
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
					CLOSE WINDOW wRmsparmImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/rmsparm-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		LOAD FROM load_file INSERT INTO temp_rmsparm
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_rmsparm
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_rmsparm
			LET importReport = importReport, "Code:", trim(rec_rmsparm.order_hold_flag) , "     -     Desc:", trim(rec_rmsparm.order_print_text), "\n"
					
			INSERT INTO rmsparm VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_rmsparm.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_rmsparm.order_hold_flag) , "     -     Desc:", trim(rec_rmsparm.order_print_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wRmsparmImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_rmsparmRec(p_cmpy_code, p_order_hold_flag)
########################################################
FUNCTION exist_rmsparmRec(p_cmpy_code, p_order_hold_flag)
	DEFINE p_cmpy_code LIKE rmsparm.cmpy_code
	DEFINE p_order_hold_flag LIKE rmsparm.order_hold_flag
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM rmsparm 
     WHERE cmpy_code = p_cmpy_code
     AND order_hold_flag = p_order_hold_flag

	DROP TABLE temp_rmsparm
	CLOSE WINDOW wRmsparmImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_rmsparm()
###############################################################
FUNCTION unload_rmsparm(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/rmsparm-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM rmsparm ORDER BY cmpy_code, order_hold_flag ASC
	
	LET tmpMsg = "All rmsparm data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("rmsparm Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_rmsparm_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_rmsparm_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE rmsparm.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wrmsparmImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "rmsparm Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing rmsparm table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM rmsparm
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table rmsparm!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table rmsparm where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wRmsparmImport		
END FUNCTION	