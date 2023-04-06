GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getPricingCount()
# FUNCTION pricingLookupFilterDataSourceCursor(precPricingFilter)
# FUNCTION pricingLookupSearchDataSourceCursor(p_recPricingSearch)
# FUNCTION pricingLookupFilterDataSource(precPricingFilter)
# FUNCTION pricingLookup_filter(pPricingCode)
# FUNCTION import_pricing()
# FUNCTION exist_pricingRec(p_cmpy_code, p_offer_code)
# FUNCTION delete_pricing_all()
# FUNCTION pricingMenu()						-- Offer different OPTIONS of this library via a menu

# Pricing record types
	DEFINE t_recPricing  
		TYPE AS RECORD
			offer_code LIKE pricing.offer_code,
			desc_text LIKE pricing.desc_text
		END RECORD 

	DEFINE t_recPricingFilter  
		TYPE AS RECORD
			filter_offer_code LIKE pricing.offer_code,
			filter_desc_text LIKE pricing.desc_text
		END RECORD 

	DEFINE t_recPricingSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recPricing_noCmpyId 
		TYPE AS RECORD 
    offer_code LIKE pricing.offer_code,
    desc_text LIKE pricing.desc_text,    
    type_ind LIKE pricing.type_ind,
    start_date LIKE pricing.start_date,
    end_date LIKE pricing.end_date,
    maingrp_code LIKE pricing.maingrp_code,
    prodgrp_code LIKE pricing.prodgrp_code,
    part_code LIKE pricing.part_code,
    disc_price_amt LIKE pricing.disc_price_amt,
    disc_per LIKE pricing.disc_per,
    uom_code LIKE pricing.uom_code,
    class_code LIKE pricing.class_code,
    list_level_ind LIKE pricing.list_level_ind,
    prom1_text LIKE pricing.prom1_text,
    prom2_text LIKE pricing.prom2_text,
    ware_code LIKE pricing.ware_code
    
    
    
	END RECORD	


	
########################################################################################
# FUNCTION pricingMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION pricingMenu()
	MENU
		ON ACTION "Import"
			CALL import_pricing()
		ON ACTION "Export"
			CALL unload_pricing()
		#ON ACTION "Import"
		#	CALL import_pricing()
		ON ACTION "Delete All"
			CALL delete_pricing_all()
		ON ACTION "Count"
			CALL getPricingCount() --Count all pricing rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getPricingCount()
#-------------------------------------------------------
# Returns the number of Pricing entries for the current company
########################################################################################
FUNCTION getPricingCount()
	DEFINE ret_PricingCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Pricing CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Pricing ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Pricing.DECLARE(sqlQuery) #CURSOR FOR getPricing
	CALL c_Pricing.SetResults(ret_PricingCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Pricing.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_PricingCount = -1
	ELSE
		CALL c_Pricing.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Warehouse Groups:", trim(ret_PricingCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Warehouse Group Count", tempMsg,"info") 	
	END IF

	RETURN ret_PricingCount
END FUNCTION

########################################################################################
# FUNCTION pricingLookupFilterDataSourceCursor(precPricingFilter)
#-------------------------------------------------------
# Returns the Pricing CURSOR for the lookup query
########################################################################################
FUNCTION pricingLookupFilterDataSourceCursor(precPricingFilter)
	DEFINE precPricingFilter OF t_recPricingFilter
	DEFINE sqlQuery STRING
	DEFINE c_Pricing CURSOR
	
	LET sqlQuery =	"SELECT ",
									"pricing.offer_code, ", 
									"pricing.desc_text ",
									"FROM pricing ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF precPricingFilter.filter_offer_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND offer_code LIKE '", precPricingFilter.filter_offer_code CLIPPED, "%' "  
	END IF									

	IF precPricingFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", precPricingFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY offer_code"

	CALL c_pricing.DECLARE(sqlQuery)
		
	RETURN c_pricing
END FUNCTION



########################################################################################
# pricingLookupSearchDataSourceCursor(p_recPricingSearch)
#-------------------------------------------------------
# Returns the Pricing CURSOR for the lookup query
########################################################################################
FUNCTION pricingLookupSearchDataSourceCursor(p_recPricingSearch)
	DEFINE p_recPricingSearch OF t_recPricingSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Pricing CURSOR
	
	LET sqlQuery =	"SELECT ",
									"pricing.offer_code, ", 
									"pricing.desc_text ",
 
									"FROM pricing ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_recPricingSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((offer_code LIKE '", p_recPricingSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_recPricingSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_recPricingSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY offer_code"

	CALL c_pricing.DECLARE(sqlQuery) #CURSOR FOR pricing
	
	RETURN c_pricing
END FUNCTION


########################################################################################
# FUNCTION PricingLookupFilterDataSource(precPricingFilter)
#-------------------------------------------------------
# CALLS PricingLookupFilterDataSourceCursor(precPricingFilter) with the PricingFilter data TO get a CURSOR
# Returns the Pricing list array arrPricingList
########################################################################################
FUNCTION PricingLookupFilterDataSource(precPricingFilter)
	DEFINE precPricingFilter OF t_recPricingFilter
	DEFINE recPricing OF t_recPricing
	DEFINE arrPricingList DYNAMIC ARRAY OF t_recPricing 
	DEFINE c_Pricing CURSOR
	DEFINE retError SMALLINT
		
	CALL PricingLookupFilterDataSourceCursor(precPricingFilter.*) RETURNING c_Pricing
	
	CALL arrPricingList.CLEAR()

	CALL c_Pricing.SetResults(recPricing.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Pricing.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Pricing.FetchNext()=0)
		CALL arrPricingList.append([recPricing.offer_code, recPricing.desc_text])
	END WHILE	

	END IF
	
	IF arrPricingList.getSize() = 0 THEN
		ERROR "No pricing's found with the specified filter criteria"
	END IF
	
	RETURN arrPricingList
END FUNCTION	

########################################################################################
# FUNCTION PricingLookupSearchDataSource(precPricingFilter)
#-------------------------------------------------------
# CALLS PricingLookupSearchDataSourceCursor(precPricingFilter) with the PricingFilter data TO get a CURSOR
# Returns the Pricing list array arrPricingList
########################################################################################
FUNCTION PricingLookupSearchDataSource(p_recPricingSearch)
	DEFINE p_recPricingSearch OF t_recPricingSearch	
	DEFINE recPricing OF t_recPricing
	DEFINE arrPricingList DYNAMIC ARRAY OF t_recPricing 
	DEFINE c_Pricing CURSOR
	DEFINE retError SMALLINT	
	CALL PricingLookupSearchDataSourceCursor(p_recPricingSearch) RETURNING c_Pricing
	
	CALL arrPricingList.CLEAR()

	CALL c_Pricing.SetResults(recPricing.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Pricing.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Pricing.FetchNext()=0)
		CALL arrPricingList.append([recPricing.offer_code, recPricing.desc_text])
	END WHILE	

	END IF
	
	IF arrPricingList.getSize() = 0 THEN
		ERROR "No pricing's found with the specified filter criteria"
	END IF
	
	RETURN arrPricingList
END FUNCTION


########################################################################################
# FUNCTION pricingLookup_filter(pPricingCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Pricing code offer_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL PricingLookupFilterDataSource(recPricingFilter.*) RETURNING arrPricingList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Pricing Code offer_code
#
# Example:
# 			LET pr_Pricing.offer_code = PricingLookup(pr_Pricing.offer_code)
########################################################################################
FUNCTION pricingLookup_filter(pPricingCode)
	DEFINE pPricingCode LIKE Pricing.offer_code
	DEFINE arrPricingList DYNAMIC ARRAY OF t_recPricing
	DEFINE recPricingFilter OF t_recPricingFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wPricingLookup WITH FORM "PricingLookup_filter"


	CALL PricingLookupFilterDataSource(recPricingFilter.*) RETURNING arrPricingList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recPricingFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL PricingLookupFilterDataSource(recPricingFilter.*) RETURNING arrPricingList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrPricingList TO scPricingList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pPricingCode = arrPricingList[idx].offer_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recPricingFilter.filter_offer_code IS NOT NULL
			OR recPricingFilter.filter_desc_text IS NOT NULL

		THEN
			LET recPricingFilter.filter_offer_code = NULL
			LET recPricingFilter.filter_desc_text = NULL

			CALL PricingLookupFilterDataSource(recPricingFilter.*) RETURNING arrPricingList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_offer_code"
		IF recPricingFilter.filter_offer_code IS NOT NULL THEN
			LET recPricingFilter.filter_offer_code = NULL
			CALL PricingLookupFilterDataSource(recPricingFilter.*) RETURNING arrPricingList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recPricingFilter.filter_desc_text IS NOT NULL THEN
			LET recPricingFilter.filter_desc_text = NULL
			CALL PricingLookupFilterDataSource(recPricingFilter.*) RETURNING arrPricingList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wPricingLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pPricingCode	
END FUNCTION				
		

########################################################################################
# FUNCTION pricingLookup(pPricingCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Pricing code offer_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL PricingLookupSearchDataSource(recPricingFilter.*) RETURNING arrPricingList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Pricing Code offer_code
#
# Example:
# 			LET pr_Pricing.offer_code = PricingLookup(pr_Pricing.offer_code)
########################################################################################
FUNCTION pricingLookup(pPricingCode)
	DEFINE pPricingCode LIKE Pricing.offer_code
	DEFINE arrPricingList DYNAMIC ARRAY OF t_recPricing
	DEFINE recPricingSearch OF t_recPricingSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wPricingLookup WITH FORM "pricingLookup"

	CALL PricingLookupSearchDataSource(recPricingSearch.*) RETURNING arrPricingList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recPricingSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL PricingLookupSearchDataSource(recPricingSearch.*) RETURNING arrPricingList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrPricingList TO scPricingList.* 
		BEFORE ROW
			IF arrPricingList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pPricingCode = arrPricingList[idx].offer_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recPricingSearch.filter_any_field IS NOT NULL

		THEN
			LET recPricingSearch.filter_any_field = NULL

			CALL PricingLookupSearchDataSource(recPricingSearch.*) RETURNING arrPricingList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_offer_code"
		IF recPricingSearch.filter_any_field IS NOT NULL THEN
			LET recPricingSearch.filter_any_field = NULL
			CALL PricingLookupSearchDataSource(recPricingSearch.*) RETURNING arrPricingList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wPricingLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pPricingCode	
END FUNCTION				

############################################
# FUNCTION import_pricing()
############################################
FUNCTION import_pricing()
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
	
	DEFINE rec_pricing OF t_recPricing_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wPricingImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Warehouse Group List Data (table: pricing)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_pricing
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_pricing(	    
	    offer_code CHAR(6),
	    desc_text CHAR(40),
	    type_ind SMALLINT,
	    start_date DATE,
	    end_date DATE,
	    maingrp_code CHAR(3),
	    prodgrp_code CHAR(3),
	    part_code CHAR(15),
	    disc_price_amt DECIMAL(16,4),
	    disc_per DECIMAL(6,3),
	    uom_code CHAR(4),
	    class_code CHAR(8),
	    list_level_ind CHAR(1),
	    prom1_text CHAR(60),
	    prom2_text CHAR(60),
	    ware_code CHAR(3)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_pricing	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wPricingImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wPricingImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/pricing-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_pricing
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_pricing
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_pricing
			LET importReport = importReport, "Code:", trim(rec_pricing.offer_code) , "     -     Desc:", trim(rec_pricing.desc_text), "\n"
					
			INSERT INTO pricing VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_pricing.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_pricing.offer_code) , "     -     Desc:", trim(rec_pricing.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wPricingImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_pricingRec(p_cmpy_code, p_offer_code)
########################################################
FUNCTION exist_pricingRec(p_cmpy_code, p_offer_code)
	DEFINE p_cmpy_code LIKE pricing.cmpy_code
	DEFINE p_offer_code LIKE pricing.offer_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM pricing 
     WHERE cmpy_code = p_cmpy_code
     AND offer_code = p_offer_code

	DROP TABLE temp_pricing
	CLOSE WINDOW wPricingImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_pricing()
###############################################################
FUNCTION unload_pricing(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/pricing-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM pricing ORDER BY cmpy_code, offer_code ASC
	
	LET tmpMsg = "All pricing data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("pricing Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_pricing_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_pricing_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE pricing.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wpricingImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "pricing Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing pricing table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM pricing
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table pricing!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table pricing where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wPricingImport		
END FUNCTION	