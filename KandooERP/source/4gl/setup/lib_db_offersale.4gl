GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getofferSaleCount()
# FUNCTION offersaleLookupFilterDataSourceCursor(pRecofferSaleFilter)
# FUNCTION offersaleLookupSearchDataSourceCursor(p_RecofferSaleSearch)
# FUNCTION offerSaleLookupFilterDataSource(pRecofferSaleFilter)
# FUNCTION offersaleLookup_filter(pofferSaleCode)
# FUNCTION import_offersale()
# FUNCTION exist_offersaleRec(p_cmpy_code, p_offer_code)
# FUNCTION delete_offersale_all()
# FUNCTION offersaleMenu()						-- Offer different OPTIONS of this library via a menu

# offerSalerecord types
	DEFINE t_recofferSale 
		TYPE AS RECORD
			offer_code LIKE offersale.offer_code,
			desc_text LIKE offersale.desc_text
		END RECORD 

	DEFINE t_recofferSaleFilter  
		TYPE AS RECORD
			filter_offer_code LIKE offersale.offer_code,
			filter_desc_text LIKE offersale.desc_text
		END RECORD 

	DEFINE t_recofferSaleSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recofferSale_noCmpyId 
		TYPE AS RECORD 
    #cmpy_code LIKE offersale.cmpy_code,
    offer_code LIKE offersale.offer_code,
    desc_text LIKE offersale.desc_text,
    start_date LIKE offersale.start_date,
    end_date LIKE offersale.end_date,
    bonus_check_per LIKE offersale.bonus_check_per,
    bonus_check_amt LIKE offersale.bonus_check_amt,
    disc_check_per LIKE offersale.disc_check_per,
    disc_per LIKE offersale.disc_per,
    checkrule_ind LIKE offersale.checkrule_ind,
    disc_rule_ind LIKE offersale.disc_rule_ind,
    checktype_ind LIKE offersale.checktype_ind,
    auto_prod_flag LIKE offersale.auto_prod_flag,
    prodline_disc_flag LIKE offersale.prodline_disc_flag,
    grp_disc_flag LIKE offersale.grp_disc_flag,
    min_sold_amt LIKE offersale.min_sold_amt,
    min_order_amt LIKE offersale.min_order_amt
            
	END RECORD	

	
########################################################################################
# FUNCTION offersaleMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION offersaleMenu()
	MENU
		ON ACTION "Import"
			CALL import_offersale()
		ON ACTION "Export"
			CALL unload_offersale(FALSE,"exp")
		#ON ACTION "Import"
		#	CALL import_offersale()
		ON ACTION "Delete All"
			CALL delete_offersale_all()
		ON ACTION "Count"
			CALL getofferSaleCount() --Count all offersalerows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getofferSaleCount()
#-------------------------------------------------------
# Returns the number of offerSaleentries for the current company
########################################################################################
FUNCTION getofferSaleCount()
	DEFINE ret_offerSaleCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_offerSale CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM offersale ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_offerSale.DECLARE(sqlQuery) #CURSOR FOR getofferSale
	CALL c_offerSale.SetResults(ret_offerSaleCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_offerSale.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_offerSaleCount = -1
	ELSE
		CALL c_offerSale.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Territories (offersale):", trim(ret_offerSaleCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Territories (offersale) Count", tempMsg,"info") 	
	END IF

	RETURN ret_offerSaleCount
END FUNCTION

########################################################################################
# FUNCTION offersaleLookupFilterDataSourceCursor(pRecofferSaleFilter)
#-------------------------------------------------------
# Returns the offerSalecursor for the lookup query
########################################################################################
FUNCTION offersaleLookupFilterDataSourceCursor(pRecofferSaleFilter)
	DEFINE pRecofferSaleFilter OF t_recofferSaleFilter
	DEFINE sqlQuery STRING
	DEFINE c_offerSale CURSOR
	
	LET sqlQuery =	"SELECT ",
									"offersale.offer_code, ", 
									"offersale.desc_text ",
									"FROM offersale ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecofferSaleFilter.filter_offer_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND offer_code LIKE '", pRecofferSaleFilter.filter_offer_code CLIPPED, "%' "  
	END IF									

	IF pRecofferSaleFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecofferSaleFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY offer_code"

	CALL c_offersale.DECLARE(sqlQuery)
		
	RETURN c_offersale
END FUNCTION



########################################################################################
# offersaleLookupSearchDataSourceCursor(p_RecofferSaleSearch)
#-------------------------------------------------------
# Returns the offerSalecursor for the lookup query
########################################################################################
FUNCTION offersaleLookupSearchDataSourceCursor(p_RecofferSaleSearch)
	DEFINE p_RecofferSaleSearch OF t_recofferSaleSearch  
	DEFINE sqlQuery STRING
	DEFINE c_offerSale CURSOR
	
	LET sqlQuery =	"SELECT ",
									"offersale.offer_code, ", 
									"offersale.desc_text ",
 
									"FROM offersale ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecofferSaleSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((offer_code LIKE '", p_RecofferSaleSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecofferSaleSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecofferSaleSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, " ORDER BY offer_code "

	CALL c_offersale.DECLARE(sqlQuery) #CURSOR FOR offersale
	
	RETURN c_offersale
END FUNCTION


########################################################################################
# FUNCTION offerSaleLookupFilterDataSource(pRecofferSaleFilter)
#-------------------------------------------------------
# CALLS offerSaleLookupFilterDataSourceCursor(pRecofferSaleFilter) with the offerSaleFilter data TO get a CURSOR
# Returns the offerSalelist array arrofferSaleList
########################################################################################
FUNCTION offerSaleLookupFilterDataSource(pRecofferSaleFilter)
	DEFINE pRecofferSaleFilter OF t_recofferSaleFilter
	DEFINE recofferSale OF t_recofferSale
	DEFINE arrofferSaleList DYNAMIC ARRAY OF t_recofferSale
	DEFINE c_offerSale CURSOR
	DEFINE retError SMALLINT
		
	CALL offerSaleLookupFilterDataSourceCursor(pRecofferSaleFilter.*) RETURNING c_offerSale
	
	CALL arrofferSaleList.CLEAR()

	CALL c_offerSale.SetResults(recofferSale.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_offerSale.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_offerSale.FetchNext()=0)
		CALL arrofferSaleList.append([recofferSale.offer_code, recofferSale.desc_text])
	END WHILE	

	END IF
	
	IF arrofferSaleList.getSize() = 0 THEN
		ERROR "No offersale's found with the specified filter criteria"
	END IF
	
	RETURN arrofferSaleList
END FUNCTION	

########################################################################################
# FUNCTION offerSaleLookupSearchDataSource(pRecofferSaleFilter)
#-------------------------------------------------------
# CALLS offerSaleLookupSearchDataSourceCursor(pRecofferSaleFilter) with the offerSaleFilter data TO get a CURSOR
# Returns the offerSalelist array arrofferSaleList
########################################################################################
FUNCTION offerSaleLookupSearchDataSource(p_recofferSaleSearch)
	DEFINE p_recofferSaleSearch OF t_recofferSaleSearch	
	DEFINE recofferSale OF t_recofferSale
	DEFINE arrofferSaleList DYNAMIC ARRAY OF t_recofferSale
	DEFINE c_offerSale CURSOR
	DEFINE retError SMALLINT	
	CALL offerSaleLookupSearchDataSourceCursor(p_recofferSaleSearch) RETURNING c_offerSale
	
	CALL arrofferSaleList.CLEAR()

	CALL c_offerSale.SetResults(recofferSale.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_offerSale.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_offerSale.FetchNext()=0)
		CALL arrofferSaleList.append([recofferSale.offer_code, recofferSale.desc_text])
	END WHILE	

	END IF
	
	IF arrofferSaleList.getSize() = 0 THEN
		ERROR "No offersale's found with the specified filter criteria"
	END IF
	
	RETURN arrofferSaleList
END FUNCTION


########################################################################################
# FUNCTION offersaleLookup_filter(pofferSaleCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required offerSalecode offer_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL offerSaleLookupFilterDataSource(recofferSaleFilter.*) RETURNING arrofferSaleList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the offerSaleCode offer_code
#
# Example:
# 			LET pr_offerSale.offer_code = offerSaleLookup(pr_offerSale.offer_code)
########################################################################################
FUNCTION offersaleLookup_filter(pofferSaleCode)
	DEFINE pofferSaleCode LIKE offerSale.offer_code
	DEFINE arrofferSaleList DYNAMIC ARRAY OF t_recofferSale
	DEFINE recofferSaleFilter OF t_recofferSaleFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wofferSaleLookup WITH FORM "offerSaleLookup_filter"


	CALL offerSaleLookupFilterDataSource(recofferSaleFilter.*) RETURNING arrofferSaleList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recofferSaleFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL offerSaleLookupFilterDataSource(recofferSaleFilter.*) RETURNING arrofferSaleList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrofferSaleList TO scofferSaleList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pofferSaleCode = arrofferSaleList[idx].offer_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recofferSaleFilter.filter_offer_code IS NOT NULL
			OR recofferSaleFilter.filter_desc_text IS NOT NULL

		THEN
			LET recofferSaleFilter.filter_offer_code = NULL
			LET recofferSaleFilter.filter_desc_text = NULL

			CALL offerSaleLookupFilterDataSource(recofferSaleFilter.*) RETURNING arrofferSaleList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_offer_code"
		IF recofferSaleFilter.filter_offer_code IS NOT NULL THEN
			LET recofferSaleFilter.filter_offer_code = NULL
			CALL offerSaleLookupFilterDataSource(recofferSaleFilter.*) RETURNING arrofferSaleList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recofferSaleFilter.filter_desc_text IS NOT NULL THEN
			LET recofferSaleFilter.filter_desc_text = NULL
			CALL offerSaleLookupFilterDataSource(recofferSaleFilter.*) RETURNING arrofferSaleList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wofferSaleLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pofferSaleCode	
END FUNCTION				
		

########################################################################################
# FUNCTION offersaleLookup(pofferSaleCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required offerSalecode offer_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL offerSaleLookupSearchDataSource(recofferSaleFilter.*) RETURNING arrofferSaleList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the offerSaleCode offer_code
#
# Example:
# 			LET pr_offerSale.offer_code = offerSaleLookup(pr_offerSale.offer_code)
########################################################################################
FUNCTION offersaleLookup(pofferSaleCode)
	DEFINE pofferSaleCode LIKE offerSale.offer_code
	DEFINE arrofferSaleList DYNAMIC ARRAY OF t_recofferSale
	DEFINE recofferSaleSearch OF t_recofferSaleSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wofferSaleLookup WITH FORM "offersaleLookup"

	CALL offerSaleLookupSearchDataSource(recofferSaleSearch.*) RETURNING arrofferSaleList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recofferSaleSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL offerSaleLookupSearchDataSource(recofferSaleSearch.*) RETURNING arrofferSaleList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrofferSaleList TO scofferSaleList.* 
		BEFORE ROW
			IF arrofferSaleList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pofferSaleCode = arrofferSaleList[idx].offer_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recofferSaleSearch.filter_any_field IS NOT NULL

		THEN
			LET recofferSaleSearch.filter_any_field = NULL

			CALL offerSaleLookupSearchDataSource(recofferSaleSearch.*) RETURNING arrofferSaleList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_offer_code"
		IF recofferSaleSearch.filter_any_field IS NOT NULL THEN
			LET recofferSaleSearch.filter_any_field = NULL
			CALL offerSaleLookupSearchDataSource(recofferSaleSearch.*) RETURNING arrofferSaleList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wofferSaleLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pofferSaleCode	
END FUNCTION				

############################################
# FUNCTION import_offersale()
############################################
FUNCTION import_offersale()
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
	
	DEFINE rec_offersale OF t_recofferSale_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wofferSaleImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Territories List Data (table: offersale)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_offersale
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_offersale(
		
    #cmpy_code CHAR(2),
    offer_code CHAR(3),
    desc_text CHAR(30),
    start_date DATE,
    end_date DATE,
    bonus_check_per DECIMAL(5,2),
    bonus_check_amt DECIMAL(16,2),
    disc_check_per DECIMAL(5,2),
    disc_per DECIMAL(5,2),
    checkrule_ind CHAR(1),
    disc_rule_ind CHAR(1),
    checktype_ind CHAR(1),
    auto_prod_flag CHAR(1),
    prodline_disc_flag CHAR(1),
    grp_disc_flag CHAR(1),
    min_sold_amt DECIMAL(16,2),
    min_order_amt DECIMAL(16,2)
    
    
    
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_offersale	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wofferSaleImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wofferSaleImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/offersale-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_offersale
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_offersale
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_offersale
			LET importReport = importReport, "Code:", trim(rec_offersale.offer_code) , "     -     Desc:", trim(rec_offersale.desc_text), "\n"
					
			INSERT INTO offersale VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_offersale.*
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_offersale.offer_code) , "     -     Desc:", trim(rec_offersale.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wofferSaleImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_offersaleRec(p_cmpy_code, p_offer_code)
########################################################
FUNCTION exist_offersaleRec(p_cmpy_code, p_offer_code)
	DEFINE p_cmpy_code LIKE offersale.cmpy_code
	DEFINE p_offer_code LIKE offersale.offer_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM offersale
     WHERE cmpy_code = p_cmpy_code
     AND offer_code = p_offer_code

	DROP TABLE temp_offersale
	CLOSE WINDOW wofferSaleImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_offersale()
###############################################################
FUNCTION unload_offersale(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile, unloadFile1, unloadFile2 STRING
	DEFINE currentCompany VARCHAR(20)

	LET currentCompany = getCurrentUser_cmpy_code()	
	
	LET unloadFile = "unl/offersale-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 

	LET unloadFile1 = unloadFile CLIPPED, "_", getCurrentUser_cmpy_code()
	UNLOAD TO unloadFile1
		SELECT  
    #cmpy_code,
    offer_code,
    desc_text,
    start_date,
    end_date,
    bonus_check_per,
    bonus_check_amt,
    disc_check_per,
    disc_per,
    checkrule_ind,
    disc_rule_ind,
    checktype_ind,
    auto_prod_flag,
    prodline_disc_flag,
    grp_disc_flag,
    min_sold_amt,
    min_order_amt	
		FROM offersale 
		WHERE cmpy_code = currentCompany	
		ORDER BY cmpy_code, offer_code ASC
	

	LET unloadFile2 = 	unloadFile CLIPPED , "_all"
	UNLOAD TO unloadFile2 
		SELECT * FROM offersale ORDER BY cmpy_code, offer_code ASC


	LET tmpMsg = "All offersaledata were exported/written TO:\n", unloadFile1, " AND ", unloadFile2
	CALL fgl_winmessage("offersale Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_offersale_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_offersale_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE offersale.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW woffersaleImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "offersale Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing offersale table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM offersale
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table offersale!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table offersale where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wofferSaleImport		
END FUNCTION	