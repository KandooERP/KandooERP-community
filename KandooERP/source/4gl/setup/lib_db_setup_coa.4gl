##########################################################
# GLOBAL Scope Variables
##########################################################
GLOBALS "../common/glob_GLOBALS.4gl"
GLOBALS "../setup/lib_db_setup_GLOBALS.4gl"
{
# Coa record types
	DEFINE t_recCoa  
		TYPE AS RECORD
			acct_code LIKE coa.acct_code,
			desc_text LIKE coa.desc_text,
			group_code LIKE coa.group_code
		END RECORD 

	DEFINE t_recCoaFilter  
		TYPE AS RECORD
			filter_acct_code LIKE coa.acct_code,
			filter_desc_text LIKE coa.desc_text,
			filter_group_code LIKE coa.group_code
		END RECORD 

	DEFINE t_recCoaSearch  
		TYPE AS RECORD
			filter_any_field STRING,
			filter_group_code LIKE coa.group_code
		END RECORD 		
}		
################################################################################################################################################################################
# FUNCTION coaMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
################################################################################################################################################################################
FUNCTION coaMenu(p_silentMode)
	DEFINE p_silentMode SMALLINT
	DEFINE l_setupRec 
		RECORD
			silentMode SMALLINT,											--run operations in silent mode (NOT display TO..., no windows, AND if possible, no ui interactions
			fiscal_startDate DATE,
			fiscal_period_size SMALLINT,  --fiscal tax period 1=year 4=Quarter Yearly 12=Monthly  
			start_year_num LIKE coa.start_year_num,
			start_period_num LIKE coa.start_period_num,
			end_year_num  LIKE coa.end_year_num, 
			end_period_num  LIKE coa.end_period_num,
			industry_type STRING,										--Can be used TO allow for different lookup/list-data imports
			unl_file_extension STRING		--file extension for exporting/unloading AND loading/importing database table data 
		END RECORD	

	LET l_setupRec.silentMode = p_silentMode
			
	MENU
		ON ACTION "Import"
			CALL db_coa_import5(l_setupRec.silentMode,l_setupRec.start_year_num,l_setupRec.start_period_num,l_setupRec.end_year_num,l_setupRec.end_period_num)
		ON ACTION "Export"
			CALL db_coa_unload(TRUE,NULL)
		#ON ACTION "Import"
		#	CALL import_class()
		ON ACTION "Delete All"
			CALL db_coa_delete_all()
		ON ACTION "Count"
			CALL db_coa_get_count_silent(l_setupRec.silentMode) --Count all class rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
{
########################################################################################
# FUNCTION db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter)
#-------------------------------------------------------
# Returns the Coa CURSOR for the lookup query
########################################################################################
FUNCTION db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter)
	DEFINE pRecCoaFilter OF t_recCoaFilter
	DEFINE sqlQuery STRING
	DEFINE c_Coa CURSOR
	
	LET sqlQuery =	"SELECT ",
									"coa.acct_code, ", 
									"coa.desc_text, ",
									"coa.group_code ", 
									"FROM coa ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecCoaFilter.filter_acct_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND acct_code LIKE '", pRecCoaFilter.filter_acct_code CLIPPED, "%' "  
	END IF									

	IF pRecCoaFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecCoaFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
	IF pRecCoaFilter.filter_group_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND group_code LIKE '", pRecCoaFilter.filter_group_code CLIPPED, "%' "  
	END IF	
			
	LET sqlQuery = sqlQuery, " ORDER BY acct_code"

	CALL c_coa.DECLARE(sqlQuery)
		
	RETURN c_coa
END FUNCTION



########################################################################################
# FUNCTION db_coa_get_lookupSearchDataSourceCursor(p_RecCoaSearch)
#-------------------------------------------------------
# Returns the Coa CURSOR for the lookup query
########################################################################################
FUNCTION db_coa_get_lookupSearchDataSourceCursor(p_RecCoaSearch)
	DEFINE p_RecCoaSearch OF t_recCoaSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Coa CURSOR
	
	LET sqlQuery =	"SELECT ",
									"coa.acct_code, ", 
									"coa.desc_text, ",
									"coa.group_code ", 
									"FROM coa ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecCoaSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((acct_code LIKE '", p_RecCoaSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecCoaSearch.filter_any_field CLIPPED, "%') "  
		#LET sqlQuery = sqlQuery, "OR group_code LIKE '",  p_RecCoaSearch.filter_any_field CLIPPED, "%' )"  						
	END IF

	
	IF p_RecCoaSearch.filter_group_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND group_code LIKE '", p_RecCoaSearch.filter_group_code CLIPPED, "%' "  
	END IF	

	IF p_RecCoaSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY acct_code"

	CALL c_coa.DECLARE(sqlQuery) #CURSOR FOR COA
	
	RETURN c_coa
END FUNCTION


########################################################################################
# FUNCTION db_coa_get_lookupFilterDataSource(pRecCoaFilter)
#-------------------------------------------------------
# CALLS db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter) with the CoaFilter data TO get a CURSOR
# Returns the Coa list array arrCoaList
########################################################################################
FUNCTION db_coa_get_lookupFilterDataSource(pRecCoaFilter)
	DEFINE pRecCoaFilter OF t_recCoaFilter
	DEFINE recCoa OF t_recCoa
	DEFINE arrCoaList DYNAMIC ARRAY OF t_recCoa 
	DEFINE c_Coa CURSOR
	DEFINE retError SMALLINT
		
	CALL db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter.*) RETURNING c_Coa
	
	CALL arrCoaList.CLEAR()

	CALL c_Coa.SetResults(recCoa.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Coa.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Coa.FetchNext()=0)
		CALL arrCoaList.append([recCoa.acct_code, recCoa.desc_text,recCoa.group_code])
	END WHILE	

	END IF
	
	IF arrCoaList.getSize() = 0 THEN
		ERROR "No COA's found with the specified filter criteria"
	END IF
	
	RETURN arrCoaList
END FUNCTION	

########################################################################################
# FUNCTION db_coa_get_lookupSearchDataSource(pRecCoaFilter)
#-------------------------------------------------------
# CALLS db_coa_get_lookupSearchDataSourceCursor(pRecCoaFilter) with the CoaFilter data TO get a CURSOR
# Returns the Coa list array arrCoaList
########################################################################################
FUNCTION db_coa_get_lookupSearchDataSource(p_recCoaSearch)
	DEFINE p_recCoaSearch OF t_recCoaSearch	
	DEFINE recCoa OF t_recCoa
	DEFINE arrCoaList DYNAMIC ARRAY OF t_recCoa 
	DEFINE c_Coa CURSOR
	DEFINE retError SMALLINT	
	CALL db_coa_get_lookupSearchDataSourceCursor(p_recCoaSearch.*) RETURNING c_Coa
	
	CALL arrCoaList.CLEAR()

	CALL c_Coa.SetResults(recCoa.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Coa.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Coa.FetchNext()=0)
		CALL arrCoaList.append([recCoa.acct_code, recCoa.desc_text,recCoa.group_code])
	END WHILE	

	END IF
	
	IF arrCoaList.getSize() = 0 THEN
		ERROR "No COA's found with the specified filter criteria"
	END IF
	
	RETURN arrCoaList
END FUNCTION


########################################################################################
# FUNCTION db_coa_get_lookup_filter(pCoaCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Coa code acct_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Coa Code acct_code
#
# Example:
# 			LET pr_Coa.acct_code = db_coa_get_lookup(pr_Coa.acct_code)
########################################################################################
FUNCTION db_coa_get_lookup_filter(pCoaCode)
	DEFINE pCoaCode LIKE Coa.acct_code
	DEFINE arrCoaList DYNAMIC ARRAY OF t_recCoa
	DEFINE recCoaFilter OF t_recCoaFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCoaLookup WITH FORM "G116"   # used to be "db_coa_get_lookup_filter" (G116 or G117 will be used)
  #needs sorting if we use this
	CALL comboList_groupCode("group_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
	CALL comboList_groupCode("filter_group_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

	CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCoaFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCoaList TO scCoaList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCoaCode = arrCoaList[idx].acct_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCoaFilter.filter_acct_code IS NOT NULL
			OR recCoaFilter.filter_desc_text IS NOT NULL
			OR recCoaFilter.filter_group_code IS NOT NULL
		THEN
			LET recCoaFilter.filter_acct_code = NULL
			LET recCoaFilter.filter_desc_text = NULL
			LET recCoaFilter.filter_group_code = NULL
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_acct_code"
		IF recCoaFilter.filter_acct_code IS NOT NULL THEN
			LET recCoaFilter.filter_acct_code = NULL
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recCoaFilter.filter_desc_text IS NOT NULL THEN
			LET recCoaFilter.filter_desc_text = NULL
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_group_code"
		IF recCoaFilter.filter_group_code IS NOT NULL THEN		
			LET recCoaFilter.filter_group_code = NULL
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF			
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCoaLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCoaCode	
END FUNCTION				
		

########################################################################################
# FUNCTION db_coa_get_lookup(pCoaCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Coa code acct_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL db_coa_get_lookupSearchDataSource(recCoaFilter.*) RETURNING arrCoaList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Coa Code acct_code
#
# Example:
# 			LET pr_Coa.acct_code = db_coa_get_lookup(pr_Coa.acct_code)
########################################################################################
FUNCTION db_coa_get_lookup(pCoaCode)
	DEFINE pCoaCode LIKE Coa.acct_code
	DEFINE arrCoaList DYNAMIC ARRAY OF t_recCoa
	DEFINE recCoaSearch OF t_recCoaSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCoaLookup WITH FORM "G116" #used to be "db_coa_get_lookup" (G116 or G117 will be used)

	CALL comboList_groupCode("group_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
	CALL comboList_groupCode("filter_group_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

	CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCoaSearch.* WITHOUT DEFAULTS 
		ON CHANGE filter_any_field,filter_group_code
			CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
					
		#ON ACTION "UPDATE-FILTER"
		#	CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList
		#	CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCoaList TO scCoaList.* 
		BEFORE ROW
			IF arrCoaList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCoaCode = arrCoaList[idx].acct_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "UPDATE-FILTER"
		CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList
		CALL ui.interface.refresh()
			
	ON ACTION "clearFilter_all"
		IF recCoaSearch.filter_any_field IS NOT NULL
			OR recCoaSearch.filter_group_code IS NOT NULL
		THEN
			LET recCoaSearch.filter_any_field = NULL

			LET recCoaSearch.filter_group_code = NULL
			CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_acct_code"
		IF recCoaSearch.filter_any_field IS NOT NULL THEN
			LET recCoaSearch.filter_any_field = NULL
			CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_group_code"
		IF recCoaSearch.filter_group_code IS NOT NULL THEN		
			LET recCoaSearch.filter_group_code = NULL
			CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF			
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCoaLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCoaCode	
END FUNCTION				
}
############################################
# FUNCTION db_coa_import5(p_silentMode,p_start_year_num,p_start_period_num,p_end_year_num,p_end_period_num)
############################################
FUNCTION db_coa_import5(p_silentMode,p_start_year_num,p_start_period_num,p_end_year_num,p_end_period_num)
	DEFINE p_silentMode SMALLINT
	DEFINE p_start_year_num LIKE coa.start_year_num
	DEFINE p_start_period_num LIKE coa.start_period_num
	DEFINE p_end_year_num LIKE coa.end_year_num
	DEFINE p_end_period_num LIKE coa.start_period_num
		 
	DEFINE l_rec_setup_company RECORD LIKE company.*
	DEFINE l_setupRec 
		RECORD
			silentMode SMALLINT,											--run operations in silent mode (NOT display TO..., no windows, AND if possible, no ui interactions
			fiscal_startDate DATE,
			fiscal_period_size SMALLINT,  --fiscal tax period 1=year 4=Quarter Yearly 12=Monthly  
			start_year_num LIKE coa.start_year_num,
			start_period_num LIKE coa.start_period_num,
			end_year_num  LIKE coa.end_year_num, 
			end_period_num  LIKE coa.end_period_num,
			industry_type STRING,										--Can be used TO allow for different lookup/list-data imports
			unl_file_extension STRING		--file extension for exporting/unloading AND loading/importing database table data 
		END RECORD	
		
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
	#DEFINE p_country_code LIKE country.country_code
	DEFINE p_country_text LIKE country.country_text
	#DEFINE p_language_code LIKE company.language_code
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_coa RECORD 
		acct_code							LIKE coa.acct_code,
		desc_text							LIKE coa.desc_text,
		type_ind							LIKE coa.type_ind,
		group_code						LIKE coa.group_code,
		analy_req_flag				LIKE coa.analy_req_flag,
		analy_prompt_text			LIKE coa.analy_prompt_text,
		qty_flag							LIKE coa.qty_flag,
		uom_code							LIKE coa.uom_code,
		tax_code							LIKE coa.tax_code



	END RECORD	

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_coa
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_coa(
			acct_code            CHAR(18),
			desc_text            CHAR(40),
			type_ind             CHAR(1),
			group_code           CHAR(7),
			analy_req_flag       CHAR(1),
			analy_prompt_text    CHAR(20),
			qty_flag             CHAR(1),
			uom_code             CHAR(4),
			tax_code             CHAR(3)
	)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_coa	#we need TO INITIALIZE it, delete all rows
		END IF
		
		WHENEVER ERROR STOP	
----------------------------------------------	

	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF l_rec_setup_company.cmpy_code IS NOT NULL THEN
		CALL get_company_info (l_rec_setup_company.cmpy_code) 
		RETURNING p_desc_text,l_rec_setup_company.country_code,p_country_text,l_rec_setup_company.language_code,p_language_text
		CASE 
		WHEN l_rec_setup_company.country_code = "NUL"
			LET msgString = "Company's country code ->",trim(l_rec_setup_company.cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
			LET cmpy_code_provided = FALSE
			RETURN		
		WHEN l_rec_setup_company.country_code = "0"
			--company code comp_code does NOT exist
			LET msgString = "Company code ->",trim(l_rec_setup_company.cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			LET cmpy_code_provided = FALSE
			RETURN
		OTHERWISE
			LET cmpy_code_provided = TRUE
		END CASE				

	END IF

--------------------------------------------------------------- before ---------------------------------------------------------------------
	#NOT checking/validating the table in silent mode (initial main installer - this table IS NOT populated at this time)
	IF p_silentMode = 0 THEN	
		
		OPEN WINDOW wCoaImport WITH FORM "per/setup/db_coa_input"
		DISPLAY "Chart of Accounts Import" TO header_text
	
		IF cmpy_code_provided = FALSE THEN

			INPUT l_rec_setup_company.cmpy_code, l_rec_setup_company.country_code,l_rec_setup_company.language_code,p_start_year_num, p_start_period_num, p_end_year_num, p_end_period_num 
			WITHOUT DEFAULTS 
			FROM inputRec.*
			
			AFTER FIELD cmpy_code
				CALL get_company_info (l_rec_setup_company.cmpy_code)
				RETURNING p_desc_text,l_rec_setup_company.country_code,p_country_text,l_rec_setup_company.language_code,p_language_text
				CASE 
				WHEN l_rec_setup_company.country_code = "NUL"
					LET msgString = "Company's country code ->",trim(l_rec_setup_company.cmpy_code), "<-does NOT exist"
					CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
					LET cmpy_code_provided = FALSE
					RETURN		
				WHEN l_rec_setup_company.country_code = "0"
					--company code comp_code does NOT exist
					LET msgString = "Company code ->",trim(l_rec_setup_company.cmpy_code), "<-does NOT exist"
					CALL fgl_winmessage("Company does NOT exist",msgString,"error")
					LET cmpy_code_provided = FALSE
					RETURN
				OTHERWISE
					LET cmpy_code_provided = TRUE
					DISPLAY p_desc_text,l_rec_setup_company.country_code,p_country_text,l_rec_setup_company.language_code,p_language_text 
					TO company.name_text,country_code,country_text,language_code,language_text
				END CASE 
		END INPUT

	ELSE
		DISPLAY l_rec_setup_company.cmpy_code TO cmpy_code
		INPUT l_rec_setup_company.cmpy_code, l_rec_setup_company.country_code,l_rec_setup_company.language_code,p_start_year_num, p_start_period_num, p_end_year_num, p_end_period_num
		WITHOUT DEFAULTS 
		FROM inputRec.*  
		END INPUT
	
	END IF

	END IF  --Only if slient mode IS OFF
	
	let load_file = "unl/coa-",l_rec_setup_company.country_code CLIPPED,".unl"
	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",l_rec_setup_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_coa
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_coa
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_coa
			LET importReport = importReport, "Code:", trim(rec_coa.acct_code) , "     -     Desc:", trim(rec_coa.desc_text), "\n"
					
			INSERT INTO coa VALUES(
			l_rec_setup_company.cmpy_code,
			rec_coa.acct_code,
			rec_coa.desc_text,
			gl_setupRec.start_year_num, 
			gl_setupRec.start_period_num, 
			gl_setupRec.end_year_num, 
			gl_setupRec.end_period_num,
			rec_coa.group_code,
			rec_coa.analy_req_flag,
			rec_coa.analy_prompt_text,
			rec_coa.qty_flag,  --"",
			rec_coa.uom_code, --"",
			rec_coa.type_ind,  	 	
			rec_coa.tax_code --""
			)
			CASE
			WHEN STATUS =0
				LET count_rows_inserted = count_rows_inserted + 1
			WHEN STATUS = -268 OR STATUS = -239
				LET importReport = importReport, "Code:", trim(rec_coa.acct_code) , "     -     Desc:", trim(rec_coa.desc_text), " ->DUPLICATE = Ignored !\n"
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


	IF p_silentMode = 0 THEN  --only ui / input if silent mode IS off		
		DISPLAY BY NAME count_rows_processed
		DISPLAY BY NAME count_rows_inserted
		DISPLAY BY NAME count_insert_errors
		DISPLAY BY NAME count_already_exist
		
		INPUT BY NAME importReport WITHOUT DEFAULTS
			ON ACTION "Done"
				EXIT INPUT
		END INPUT
		
		CLOSE WINDOW wCoaImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION



###############################################################
# FUNCTION db_coa_unload(p_silentMode,p_fileExtension)
#
#
###############################################################
FUNCTION db_coa_unload(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE l_rec_setup_company RECORD LIKE company.*
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	IF p_fileExtension IS NULL THEN
		LET p_fileExtension = "*.unl"
	END IF
	
	LET unloadFile = "unl/coa-", trim(l_rec_setup_company.country_code), ".", p_fileExtension 

	UNLOAD TO "unl/coa.unl" 
		SELECT * 
		FROM coa ORDER BY cmpy_code, acct_code ASC

	UNLOAD TO unloadFile 
		SELECT
			acct_code,desc_text,type_ind,group_code,analy_req_flag,
			analy_prompt_text,qty_flag,uom_code,tax_code
		FROM coa ORDER BY cmpy_code, acct_code ASC

	
	LET tmpMsg = "All COA data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("coa Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION





{
###############################################################
# FUNCTION db_coa_delete_all()  NOTE: Delete ALL
###############################################################
FUNCTION db_coa_delete_all()

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING
	
	IF l_rec_setup_company.cmpy_code IS NOT NULL THEN
		IF NOT exist_company(l_rec_setup_company.cmpy_code) THEN  --company code comp_code does NOT exist
			LET msgString = "Company code ->",trim(l_rec_setup_company.cmpy_code), "<-does NOT exist"
			
			IF gl_setupRec.silentMode = 0 THEN
				CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			END IF
			
			RETURN
		END IF
		
		LET cmpy_code_provided = TRUE
	ELSE
		LET cmpy_code_provided = FALSE				
	END IF
	
		IF gl_setupRec.silentMode <> 0 AND cmpy_code_provided = FALSE THEN
			CALL fgl_winmessage("No valid cmpy_code argument","Function db_coa_delete_all was called\nin silent mode without a cmpy_code argument","error")
			RETURN
		END IF

		IF gl_setupRec.silentMode = 0 THEN
		
			OPEN WINDOW wCoaImport WITH FORM "per/setup/lib_db_data_import_01"
			DISPLAY "COA Delete" TO header_text
		END IF		
				
	END IF

	IF cmpy_code_provided = FALSE THEN

		INPUT l_rec_setup_company.cmpy_code WITHOUT DEFAULTS FROM cmpy_code 
		END INPUT

	ELSE

		IF gl_setupRec.silentMode = FALSE THEN	
			DISPLAY l_rec_setup_company.cmpy_code TO cmpy_code
		END IF	
	END IF

	
	IF gl_setupRec.silentMode = FALSE THEN --no ui
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM coa
		WHENEVER ERROR STOP
	END IF	
		
	IF gl_setupRec.silentMode = FALSE THEN --no ui
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the COA table!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			LET tmpMsg = "All data in the table COA where deleted"		
			CALL fgl_winmessage("Success",tmpMsg,"info")					
		END IF		

	END IF

	IF gl_setupRec.silentMode = 0 THEN
		CLOSE WINDOW wCoaImport
	END IF
			
END FUNCTION	

}

###############################################################
# FUNCTION db_coa_delete_all()  NOTE: Delete ALL
###############################################################
FUNCTION db_coa_delete_all()
	DEFINE l_rec_setup_company RECORD LIKE company.*
	DEFINE gl_setupRec 
		RECORD
			silentMode SMALLINT,											--run operations in silent mode (NOT display TO..., no windows, AND if possible, no ui interactions
			fiscal_startDate DATE,
			fiscal_period_size SMALLINT,  --fiscal tax period 1=year 4=Quarter Yearly 12=Monthly  
			start_year_num LIKE coa.start_year_num,
			start_period_num LIKE coa.start_period_num,
			end_year_num  LIKE coa.end_year_num, 
			end_period_num  LIKE coa.end_period_num,
			industry_type STRING,										--Can be used TO allow for different lookup/list-data imports
			unl_file_extension STRING		--file extension for exporting/unloading AND loading/importing database table data 
		END RECORD		
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE holdreas.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wCOAImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Delete ALL COA entries" TO header_text
	END IF

	
	IF l_rec_setup_company.cmpy_code IS NOT NULL THEN
#		IF NOT exist_company(l_rec_setup_company.cmpy_code) THEN  --company code comp_code does NOT exist
		IF NOT db_company_pk_exists(UI_OFF,l_rec_setup_company.cmpy_code) THEN
			LET msgString = "Company code ->",trim(l_rec_setup_company.cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			RETURN
		END IF
			LET cmpy_code_provided = TRUE
	ELSE
			LET cmpy_code_provided = FALSE				

	END IF

	IF cmpy_code_provided = FALSE THEN

		INPUT l_rec_setup_company.cmpy_code WITHOUT DEFAULTS FROM cmpy_code 
		END INPUT

	ELSE

		IF gl_setupRec.silentMode = 0 THEN 	
			DISPLAY l_rec_setup_company.cmpy_code TO cmpy_code
		END IF	
	END IF

	
	IF gl_setupRec.silentMode = 0 THEN --no ui
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing COA table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM coa WHERE 1=1
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table coa!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table coa where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wCOAImport		
END FUNCTION	



############################################
# FUNCTION db_coa_import_for_new_company(p_cmpy_code)
############################################
FUNCTION db_coa_import_for_new_company(p_cmpy_code)
	DEFINE msgString STRING
	DEFINE importReport STRING
		
  DEFINE driver_error  STRING
  DEFINE native_error  STRING
  DEFINE native_code  INTEGER
  
	DEFINE p_cmpy_code LIKE coa.cmpy_code
	DEFINE l_start_year_num LIKE coa.start_year_num
	DEFINE l_start_period_num LIKE coa.start_period_num
	DEFINE l_end_year_num  LIKE coa.end_year_num 
	DEFINE l_end_period_num  LIKE coa.end_period_num 
	
	DEFINE count_rows_processed INT
	DEFINE count_rows_inserted INT
	DEFINE count_insert_errors INT
	DEFINE count_already_exist INT
	 
	DEFINE cmpy_code_provided BOOLEAN
	DEFINE p_desc_text LIKE company.name_text
	DEFINE p_country_code LIKE country.country_code
	DEFINE p_country_text LIKE country.country_text
	DEFINE p_language_code LIKE company.language_code
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING

{ keep this, in case we support 2 different kinds of UNL file FORMAT 	
	DEFINE rec_coa RECORD 
		acct_code            CHAR(18),
		desc_text            CHAR(40),
		type_ind             CHAR(1),
		group_code           CHAR(7),
		analy_req_flag       CHAR(1),
		analy_prompt_text    CHAR(20)--,
	END RECORD	
		
	CREATE TEMP TABLE temp_coa(
		acct_code            CHAR(18),
		desc_text            CHAR(40),
		type_ind             CHAR(1),
		group_code           CHAR(7),
		analy_req_flag       CHAR(1),
		analy_prompt_text    CHAR(20)--,
	)
}
	DEFINE rec_coa RECORD LIKE coa.* 
#		acct_code            CHAR(18),
#		desc_text            CHAR(40),
#		type_ind             CHAR(1),
#		group_code           CHAR(7),
#		analy_req_flag       CHAR(1),
#		analy_prompt_text    CHAR(20)--,
#	END RECORD	
		
	CREATE TEMP TABLE temp_coa(
		cmpy_code            char(2),
		acct_code            nchar(18),
		desc_text            nvarchar(40,0),
		start_year_num       smallint,
		start_period_num     smallint,
		end_year_num         smallint,
		end_period_num       smallint,
		group_code           nchar(7),
		analy_req_flag       char(1),
		analy_prompt_text    nvarchar(20,0),
		qty_flag             char(1),
		uom_code             nchar(4),
		type_ind             nchar(1),
		tax_code             nchar(3)
	)



	# for certain tables, we need TO know the country code TO identify the right data SET in the templates
	IF p_cmpy_code IS NOT NULL THEN
		CALL get_company_info (p_cmpy_code) 
		RETURNING p_desc_text,p_country_code,p_country_text,p_language_code,p_language_text
		CASE 
		WHEN p_country_code = "NUL"
			LET msgString = "Company's country code ->",trim(p_cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
			LET cmpy_code_provided = FALSE
			RETURN		
		WHEN p_country_code = "0"
			--company code comp_code does NOT exist
			LET msgString = "Company code ->",trim(p_cmpy_code), "<-does NOT exist"
			CALL fgl_winmessage("Company does NOT exist",msgString,"error")
			LET cmpy_code_provided = FALSE
			RETURN
		OTHERWISE
			LET cmpy_code_provided = TRUE
		END CASE				

	END IF

--------------------------------------------------------------- before ---------------------------------------------------------------------
	
	
		OPEN WINDOW wCoaImport WITH FORM "per/setup/db_coa_input"
		DISPLAY "Chart of Accounts Import" TO header_text
	
	
	IF cmpy_code_provided = FALSE THEN

			INPUT p_cmpy_code, p_country_code,p_language_code,l_start_year_num, l_start_period_num, l_end_year_num, l_end_period_num 
			WITHOUT DEFAULTS 
			FROM inputRec.*
			
			AFTER FIELD cmpy_code
				CALL get_company_info (p_cmpy_code)
				RETURNING p_desc_text,p_country_code,p_country_text,p_language_code,p_language_text
				CASE 
				WHEN p_country_code = "NUL"
					LET msgString = "Company's country code ->",trim(p_cmpy_code), "<-does NOT exist"
					CALL fgl_winmessage("Company country code does NOT exist",msgString,"error")
					LET cmpy_code_provided = FALSE
					RETURN		
				WHEN p_country_code = "0"
					--company code comp_code does NOT exist
					LET msgString = "Company code ->",trim(p_cmpy_code), "<-does NOT exist"
					CALL fgl_winmessage("Company does NOT exist",msgString,"error")
					LET cmpy_code_provided = FALSE
					RETURN
				OTHERWISE
					LET cmpy_code_provided = TRUE
					DISPLAY p_desc_text,p_country_code,p_country_text,p_language_code,p_language_text 
					TO desc_text,country_code,country_text,language_code,language_text
				END CASE 
		END INPUT

	ELSE
		DISPLAY p_cmpy_code TO cmpy_code
		INPUT p_cmpy_code, p_country_code,p_language_code,l_start_year_num, l_start_period_num, l_end_year_num, l_end_period_num
		WITHOUT DEFAULTS 
		FROM inputRec.*  
		END INPUT
	
	END IF

	let load_file = "unl/coa-",p_country_code CLIPPED,".unl"
	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",p_country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_coa
		DECLARE template_cur_coa_new_cmpy CURSOR FOR 
		SELECT * FROM temp_coa
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur_coa_new_cmpy INTO rec_coa
			#DISPLAY rec_coa.*
			# IF NOT db_coa_pk_exists(p_cmpy_code,rec_coa.acct_code) THEN
			LET importReport = importReport, "Code:", trim(rec_coa.acct_code) , "     -     Desc:", trim(rec_coa.desc_text), "\n"
					
			INSERT INTO coa VALUES(
			p_cmpy_code,
			rec_coa.acct_code,
			rec_coa.desc_text,
			l_start_year_num, 
			l_start_period_num, 
			l_end_year_num, 
			l_end_period_num,
			rec_coa.group_code,
			rec_coa.analy_req_flag,
			rec_coa.analy_prompt_text,
			"",
			"",
			rec_coa.type_ind,  	 	
			""
			)
			CASE
			WHEN STATUS =0
				LET count_rows_inserted = count_rows_inserted + 1
			WHEN STATUS = -268 OR STATUS = -239
				LET importReport = importReport, "Code:", trim(rec_coa.acct_code) , "     -     Desc:", trim(rec_coa.desc_text), " ->DUPLICATE = Ignored !\n"
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


		
	DISPLAY BY NAME count_rows_processed
	DISPLAY BY NAME count_rows_inserted
	DISPLAY BY NAME count_insert_errors
	DISPLAY BY NAME count_already_exist
	
	INPUT BY NAME importReport WITHOUT DEFAULTS
		ON ACTION "Done"
			EXIT INPUT
	END INPUT
	CLOSE WINDOW wCoaImport
	RETURN count_rows_inserted
END FUNCTION

{

GLOBALS "lib_db_globals.4gl"

# FUNCTION db_coa_get_count_silent()
# FUNCTION db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter)
# FUNCTION db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter)
# FUNCTION db_coa_get_lookupFilterDataSource(pRecCoaFilter)
# FUNCTION db_coa_get_lookup_filter(pCoaCode)
# FUNCTION db_coa_import() 
# FUNCTION db_coa_pk_exists(p_cmpy_code, p_acct_code)
# FUNCTION db_coa_delete_all()

# Coa record types
	DEFINE t_recCoa  
		TYPE AS RECORD
			acct_code LIKE coa.acct_code,
			desc_text LIKE coa.desc_text,
			group_code LIKE coa.group_code
		END RECORD 

	DEFINE t_recCoaFilter  
		TYPE AS RECORD
			filter_acct_code LIKE coa.acct_code,
			filter_desc_text LIKE coa.desc_text,
			filter_group_code LIKE coa.group_code
		END RECORD 

	DEFINE t_recCoaSearch  
		TYPE AS RECORD
			filter_any_field STRING,
			filter_group_code LIKE coa.group_code
		END RECORD 		


########################################################################################
# FUNCTION coaMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION coaMenu()
	MENU
		ON ACTION "Import"
			CALL db_coa_import()
		ON ACTION "Export"
			CALL db_coa_unload(TRUE,NULL)
		#ON ACTION "Import"
		#	CALL import_class()
		ON ACTION "Delete All"
			CALL db_coa_delete_all()
		ON ACTION "Count"
			CALL db_coa_get_count_silent() --Count all class rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION

########################################################################################
# FUNCTION db_coa_get_count_silent()
#-------------------------------------------------------
# Returns the number of Coa entries for the current company
########################################################################################
FUNCTION db_coa_get_count_silent()
	DEFINE ret_CoaCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Coa CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Coa ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Coa.DECLARE(sqlQuery) #CURSOR FOR getCoa
	CALL c_Coa.SetResults(ret_CoaCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Coa.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_CoaCount = -1
	ELSE
		CALL c_Coa.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of COA entries:", trim(ret_CoaCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("COA Count", tempMsg,"info") 	
	END IF


	RETURN ret_CoaCount
END FUNCTION

########################################################################################
# FUNCTION db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter)
#-------------------------------------------------------
# Returns the Coa CURSOR for the lookup query
########################################################################################
FUNCTION db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter)
	DEFINE pRecCoaFilter OF t_recCoaFilter
	DEFINE sqlQuery STRING
	DEFINE c_Coa CURSOR
	
	LET sqlQuery =	"SELECT ",
									"coa.acct_code, ", 
									"coa.desc_text, ",
									"coa.group_code ", 
									"FROM coa ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecCoaFilter.filter_acct_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND acct_code LIKE '", pRecCoaFilter.filter_acct_code CLIPPED, "%' "  
	END IF									

	IF pRecCoaFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecCoaFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
	IF pRecCoaFilter.filter_group_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND group_code LIKE '", pRecCoaFilter.filter_group_code CLIPPED, "%' "  
	END IF	
			
	LET sqlQuery = sqlQuery, " ORDER BY acct_code"

	CALL c_coa.DECLARE(sqlQuery)
		
	RETURN c_coa
END FUNCTION



########################################################################################
# FUNCTION db_coa_get_lookupSearchDataSourceCursor(p_RecCoaSearch)
#-------------------------------------------------------
# Returns the Coa CURSOR for the lookup query
########################################################################################
FUNCTION db_coa_get_lookupSearchDataSourceCursor(p_RecCoaSearch)
	DEFINE p_RecCoaSearch OF t_recCoaSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Coa CURSOR
	
	LET sqlQuery =	"SELECT ",
									"coa.acct_code, ", 
									"coa.desc_text, ",
									"coa.group_code ", 
									"FROM coa ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecCoaSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((acct_code LIKE '", p_RecCoaSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecCoaSearch.filter_any_field CLIPPED, "%') "  
		#LET sqlQuery = sqlQuery, "OR group_code LIKE '",  p_RecCoaSearch.filter_any_field CLIPPED, "%' )"  						
	END IF

	
	IF p_RecCoaSearch.filter_group_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND group_code LIKE '", p_RecCoaSearch.filter_group_code CLIPPED, "%' "  
	END IF	

	IF p_RecCoaSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY acct_code"

	CALL c_coa.DECLARE(sqlQuery) #CURSOR FOR COA
	
	RETURN c_coa
END FUNCTION


########################################################################################
# FUNCTION db_coa_get_lookupFilterDataSource(pRecCoaFilter)
#-------------------------------------------------------
# CALLS db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter) with the CoaFilter data TO get a CURSOR
# Returns the Coa list array arrCoaList
########################################################################################
FUNCTION db_coa_get_lookupFilterDataSource(pRecCoaFilter)
	DEFINE pRecCoaFilter OF t_recCoaFilter
	DEFINE recCoa OF t_recCoa
	DEFINE arrCoaList DYNAMIC ARRAY OF t_recCoa 
	DEFINE c_Coa CURSOR
	DEFINE retError SMALLINT
		
	CALL db_coa_get_lookupFilterDataSourceCursor(pRecCoaFilter.*) RETURNING c_Coa
	
	CALL arrCoaList.CLEAR()

	CALL c_Coa.SetResults(recCoa.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Coa.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Coa.FetchNext()=0)
		CALL arrCoaList.append([recCoa.acct_code, recCoa.desc_text,recCoa.group_code])
	END WHILE	

	END IF
	
	IF arrCoaList.getSize() = 0 THEN
		ERROR "No COA's found with the specified filter criteria"
	END IF
	
	RETURN arrCoaList
END FUNCTION	

########################################################################################
# FUNCTION db_coa_get_lookupSearchDataSource(pRecCoaFilter)
#-------------------------------------------------------
# CALLS db_coa_get_lookupSearchDataSourceCursor(pRecCoaFilter) with the CoaFilter data TO get a CURSOR
# Returns the Coa list array arrCoaList
########################################################################################
FUNCTION db_coa_get_lookupSearchDataSource(p_recCoaSearch)
	DEFINE p_recCoaSearch OF t_recCoaSearch	
	DEFINE recCoa OF t_recCoa
	DEFINE arrCoaList DYNAMIC ARRAY OF t_recCoa 
	DEFINE c_Coa CURSOR
	DEFINE retError SMALLINT	
	CALL db_coa_get_lookupSearchDataSourceCursor(p_recCoaSearch.*) RETURNING c_Coa
	
	CALL arrCoaList.CLEAR()

	CALL c_Coa.SetResults(recCoa.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Coa.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Coa.FetchNext()=0)
		CALL arrCoaList.append([recCoa.acct_code, recCoa.desc_text,recCoa.group_code])
	END WHILE	

	END IF
	
	IF arrCoaList.getSize() = 0 THEN
		ERROR "No COA's found with the specified filter criteria"
	END IF
	
	RETURN arrCoaList
END FUNCTION


########################################################################################
# FUNCTION db_coa_get_lookup_filter(pCoaCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Coa code acct_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Coa Code acct_code
#
# Example:
# 			LET pr_Coa.acct_code = db_coa_get_lookup(pr_Coa.acct_code)
########################################################################################
FUNCTION db_coa_get_lookup_filter(pCoaCode)
	DEFINE pCoaCode LIKE Coa.acct_code
	DEFINE arrCoaList DYNAMIC ARRAY OF t_recCoa
	DEFINE recCoaFilter OF t_recCoaFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCoaLookup WITH FORM "G116" #used to be "db_coa_get_lookup_filter" (G116 or G117 will be used)
  #needs sorting if we use this
	CALL comboList_groupCode("group_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
	CALL comboList_groupCode("filter_group_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

	CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCoaFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCoaList TO scCoaList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCoaCode = arrCoaList[idx].acct_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCoaFilter.filter_acct_code IS NOT NULL
			OR recCoaFilter.filter_desc_text IS NOT NULL
			OR recCoaFilter.filter_group_code IS NOT NULL
		THEN
			LET recCoaFilter.filter_acct_code = NULL
			LET recCoaFilter.filter_desc_text = NULL
			LET recCoaFilter.filter_group_code = NULL
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_acct_code"
		IF recCoaFilter.filter_acct_code IS NOT NULL THEN
			LET recCoaFilter.filter_acct_code = NULL
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recCoaFilter.filter_desc_text IS NOT NULL THEN
			LET recCoaFilter.filter_desc_text = NULL
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_group_code"
		IF recCoaFilter.filter_group_code IS NOT NULL THEN		
			LET recCoaFilter.filter_group_code = NULL
			CALL db_coa_get_lookupFilterDataSource(recCoaFilter.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF			
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCoaLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCoaCode	
END FUNCTION				
		

########################################################################################
# FUNCTION db_coa_get_lookup(pCoaCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Coa code acct_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL db_coa_get_lookupSearchDataSource(recCoaFilter.*) RETURNING arrCoaList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Coa Code acct_code
#
# Example:
# 			LET pr_Coa.acct_code = db_coa_get_lookup(pr_Coa.acct_code)
########################################################################################
FUNCTION db_coa_get_lookup(pCoaCode)
	DEFINE pCoaCode LIKE Coa.acct_code
	DEFINE arrCoaList DYNAMIC ARRAY OF t_recCoa
	DEFINE recCoaSearch OF t_recCoaSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCoaLookup WITH FORM "G116" #used to be "db_coa_get_lookup"

	CALL comboList_groupCode("group_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 
	CALL comboList_groupCode("filter_group_code", COMBO_FIRST_ARG_IS_VALUE,combo_sort_by_value,COMBO_VALUE_AND_LABEL,COMBO_LABEL_IS_LABEL,null,COMBO_NULL_NOT) 

	CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCoaSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCoaList TO scCoaList.* 
		BEFORE ROW
			IF arrCoaList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCoaCode = arrCoaList[idx].acct_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCoaSearch.filter_any_field IS NOT NULL
			OR recCoaSearch.filter_group_code IS NOT NULL
		THEN
			LET recCoaSearch.filter_any_field = NULL

			LET recCoaSearch.filter_group_code = NULL
			CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_acct_code"
		IF recCoaSearch.filter_any_field IS NOT NULL THEN
			LET recCoaSearch.filter_any_field = NULL
			CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_group_code"
		IF recCoaSearch.filter_group_code IS NOT NULL THEN		
			LET recCoaSearch.filter_group_code = NULL
			CALL db_coa_get_lookupSearchDataSource(recCoaSearch.*) RETURNING arrCoaList
			CALL ui.interface.refresh()
		END IF			
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCoaLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCoaCode	
END FUNCTION				

############################################
# FUNCTION db_coa_import()
############################################
FUNCTION db_coa_import() 
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
	#DEFINE p_country_code LIKE country.country_code
	DEFINE p_country_text LIKE country.country_text
	#DEFINE p_language_code LIKE company.language_code
	DEFINE p_language_text LIKE language.language_text
	DEFINE load_file STRING
	DEFINE tmpMsg STRING
	
	DEFINE rec_coa RECORD 
		acct_code							LIKE coa.acct_code,
		desc_text							LIKE coa.desc_text,
		type_ind							LIKE coa.type_ind,
		group_code						LIKE coa.group_code,
		analy_req_flag				LIKE coa.analy_req_flag,
		analy_prompt_text			LIKE coa.analy_prompt_text,
		qty_flag							LIKE coa.qty_flag,
		uom_code							LIKE coa.uom_code,
		tax_code							LIKE coa.tax_code



	END RECORD	

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	SELECT COUNT(*) INTO recCount FROM temp_coa
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_coa(
			acct_code            CHAR(18),
			desc_text            CHAR(40),
			type_ind             CHAR(1),
			group_code           CHAR(7),
			analy_req_flag       CHAR(1),
			analy_prompt_text    CHAR(20),
			qty_flag             CHAR(1),
			uom_code             CHAR(4),
			tax_code             CHAR(3)
	)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_coa	#we need TO INITIALIZE it, delete all rows
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
	#NOT checking/validating the table in silent mode (initial main installer - this table IS NOT populated at this time)
	IF gl_setupRec.silentMode = 0 THEN	
		
		OPEN WINDOW wCoaImport WITH FORM "per/setup/db_coa_input"
		DISPLAY "Chart of Accounts Import" TO header_text
	
		IF cmpy_code_provided = FALSE THEN

			INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code,gl_setupRec.start_year_num, gl_setupRec.start_period_num, gl_setupRec.end_year_num, gl_setupRec.end_period_num 
			WITHOUT DEFAULTS 
			FROM inputRec.*
			
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
		DISPLAY gl_setupRec_default_company.cmpy_code TO cmpy_code
		INPUT gl_setupRec_default_company.cmpy_code, gl_setupRec_default_company.country_code,gl_setupRec_default_company.language_code,gl_setupRec.start_year_num, gl_setupRec.start_period_num, gl_setupRec.end_year_num, gl_setupRec.end_period_num
		WITHOUT DEFAULTS 
		FROM inputRec.*  
		END INPUT
	
	END IF

	END IF  --Only if slient mode IS OFF
	
	let load_file = "unl/coa-",gl_setupRec_default_company.country_code CLIPPED,".unl"
	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_coa
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_coa
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_coa
			LET importReport = importReport, "Code:", trim(rec_coa.acct_code) , "     -     Desc:", trim(rec_coa.desc_text), "\n"
					
			INSERT INTO coa VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_coa.acct_code,
			rec_coa.desc_text,
			gl_setupRec.start_year_num, 
			gl_setupRec.start_period_num, 
			gl_setupRec.end_year_num, 
			gl_setupRec.end_period_num,
			rec_coa.group_code,
			rec_coa.analy_req_flag,
			rec_coa.analy_prompt_text,
			rec_coa.qty_flag,  --"",
			rec_coa.uom_code, --"",
			rec_coa.type_ind,  	 	
			rec_coa.tax_code --""
			)
			CASE
			WHEN STATUS =0
				LET count_rows_inserted = count_rows_inserted + 1
			WHEN STATUS = -268 OR STATUS = -239
				LET importReport = importReport, "Code:", trim(rec_coa.acct_code) , "     -     Desc:", trim(rec_coa.desc_text), " ->DUPLICATE = Ignored !\n"
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


	IF gl_setupRec.silentMode = 0 THEN  --only ui / input if silent mode IS off		
		DISPLAY BY NAME count_rows_processed
		DISPLAY BY NAME count_rows_inserted
		DISPLAY BY NAME count_insert_errors
		DISPLAY BY NAME count_already_exist
		
		INPUT BY NAME importReport WITHOUT DEFAULTS
			ON ACTION "Done"
				EXIT INPUT
		END INPUT
		
		CLOSE WINDOW wCoaImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION



###############################################################
# FUNCTION db_coa_unload(p_silentMode,p_fileExtension)
###############################################################
FUNCTION db_coa_unload(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/coa-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 

	UNLOAD TO "unl/coa.unl" 
		SELECT * 
		FROM coa ORDER BY cmpy_code, acct_code ASC

	UNLOAD TO unloadFile 
		SELECT
			acct_code,desc_text,type_ind,group_code,analy_req_flag,
			analy_prompt_text,qty_flag,uom_code,tax_code
		FROM coa ORDER BY cmpy_code, acct_code ASC

	
	LET tmpMsg = "All COA data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("coa Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION


######################################################
# FUNCTION db_coa_pk_exists(p_cmpy_code, p_acct_code)
######################################################
FUNCTION db_coa_pk_exists(p_cmpy_code, p_acct_code)
	DEFINE p_cmpy_code LIKE coa.cmpy_code
	DEFINE p_acct_code LIKE coa.acct_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM coa 
     WHERE cmpy_code = p_cmpy_code
     AND acct_code = p_acct_code

	DROP TABLE temp_coa
	#CLOSE WINDOW wCoaImport
	
	RETURN recCount

END FUNCTION



###############################################################
# FUNCTION db_coa_delete_all()  NOTE: Delete ALL
###############################################################
#FUNCTION db_coa_delete_all()
#
#	DEFINE cmpy_code_provided BOOLEAN		
#	DEFINE answ STRING
#	DEFINE tmpMsg,msgString STRING
#	
#	IF gl_setupRec_default_company.cmpy_code IS NOT NULL THEN
#		IF NOT exist_company(gl_setupRec_default_company.cmpy_code) THEN  --company code comp_code does NOT exist
#			LET msgString = "Company code ->",trim(gl_setupRec_default_company.cmpy_code), "<-does NOT exist"
#			
#			IF gl_setupRec.silentMode = 0 THEN
#				CALL fgl_winmessage("Company does NOT exist",msgString,"error")
#			END IF
#			
#			RETURN
#		END IF
#		
#		LET cmpy_code_provided = TRUE
#	ELSE
#		LET cmpy_code_provided = FALSE				
#	END IF
#	
#		IF gl_setupRec.silentMode <> 0 AND cmpy_code_provided = FALSE THEN
#			CALL fgl_winmessage("No valid cmpy_code argument","Function db_coa_delete_all was called\nin silent mode without a cmpy_code argument","error")
#			RETURN
#		END IF
#
#		IF gl_setupRec.silentMode = 0 THEN
#		
#			OPEN WINDOW wCoaImport WITH FORM "per/setup/lib_db_data_import_01"
#			DISPLAY "COA Delete" TO header_text
#		END IF		
#				
#	END IF
#
#	IF cmpy_code_provided = FALSE THEN
#
#		INPUT gl_setupRec_default_company.cmpy_code WITHOUT DEFAULTS FROM cmpy_code 
#		END INPUT
#
#	ELSE
#
#		IF gl_setupRec.silentMode = FALSE THEN	
#			DISPLAY gl_setupRec_default_company.cmpy_code TO cmpy_code
#		END IF	
#	END IF
#
#	
#	IF gl_setupRec.silentMode = FALSE THEN --no ui
#		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
#	ELSE
#		LET answ = "Yes"		
#	END IF
#	
#	IF answ = "Yes" THEN
#		WHENEVER ERROR CONTINUE
#			DELETE FROM coa
#		WHENEVER ERROR STOP
#	END IF	
#		
#	IF gl_setupRec.silentMode = FALSE THEN --no ui
#		
#		IF sqlca.sqlcode <> 0 THEN
#			LET tmpMsg = "Error when trying TO delete all data in the COA table!"
#				CALL fgl_winmessage("Error",tmpMsg,"error")
#		ELSE
#			LET tmpMsg = "All data in the table COA where deleted"		
#			CALL fgl_winmessage("Success",tmpMsg,"info")					
#		END IF		
#
#	END IF
#
#	IF gl_setupRec.silentMode = 0 THEN
#		CLOSE WINDOW wCoaImport
#	END IF
#			
#END FUNCTION	


###############################################################
# FUNCTION db_coa_delete_all()  NOTE: Delete ALL
###############################################################
FUNCTION db_coa_delete_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE holdreas.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wCOAImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Delete ALL COA entries" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing COA table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM coa WHERE 1=1
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table coa!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table coa where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wCOAImport		
END FUNCTION	

}