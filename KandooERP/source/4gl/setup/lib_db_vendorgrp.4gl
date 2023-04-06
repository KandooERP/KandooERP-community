GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getVendorGrpCount()
# FUNCTION vendorgrpLookupFilterDataSourceCursor(pRecVendorGrpFilter)
# FUNCTION vendorgrpLookupSearchDataSourceCursor(p_RecVendorGrpSearch)
# FUNCTION VendorGrpLookupFilterDataSource(pRecVendorGrpFilter)
# FUNCTION vendorgrpLookup_filter(pVendorGrpCode)
# FUNCTION import_vendorgrp()
# FUNCTION exist_vendorgrpRec(p_cmpy_code, p_mast_vend_code)
# FUNCTION delete_vendorgrp_all()
# FUNCTION vendorGroupMenu()						-- Offer different OPTIONS of this library via a menu

# VendorGrp record types
	DEFINE t_recVendorGrp  
		TYPE AS RECORD
			mast_vend_code LIKE vendorgrp.mast_vend_code,
			desc_text LIKE vendorgrp.desc_text
		END RECORD 

	DEFINE t_recVendorGrpFilter  
		TYPE AS RECORD
			filter_mast_vend_code LIKE vendorgrp.mast_vend_code,
			filter_desc_text LIKE vendorgrp.desc_text
		END RECORD 

	DEFINE t_recVendorGrpSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recVendorGrp_noCmpyId 
		TYPE AS RECORD 
    mast_vend_code LIKE vendorgrp.mast_vend_code,
    desc_text LIKE vendorgrp.desc_text,
    vend_code LIKE vendorgrp.vend_code
	END RECORD	

	
########################################################################################
# FUNCTION vendorGroupMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION vendorGrpMenu()
	MENU
		ON ACTION "Import"
			CALL import_vendorgrp()
		ON ACTION "Export"
			CALL unload_vendorgrp()
		#ON ACTION "Import"
		#	CALL import_vendorgrp()
		ON ACTION "Delete All"
			CALL delete_vendorgrp_all()
		ON ACTION "Count"
			CALL getVendorGrpCount() --Count all vendorgrp rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getVendorGrpCount()
#-------------------------------------------------------
# Returns the number of VendorGrp entries for the current company
########################################################################################
FUNCTION getVendorGrpCount()
	DEFINE ret_VendorGrpCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_VendorGrp CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM VendorGrp ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_VendorGrp.DECLARE(sqlQuery) #CURSOR FOR getVendorGrp
	CALL c_VendorGrp.SetResults(ret_VendorGrpCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_VendorGrp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_VendorGrpCount = -1
	ELSE
		CALL c_VendorGrp.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Vendor Group:", trim(ret_VendorGrpCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Vendor Group Count", tempMsg,"info") 	
	END IF

	RETURN ret_VendorGrpCount
END FUNCTION

########################################################################################
# FUNCTION vendorgrpLookupFilterDataSourceCursor(pRecVendorGrpFilter)
#-------------------------------------------------------
# Returns the VendorGrp CURSOR for the lookup query
########################################################################################
FUNCTION vendorgrpLookupFilterDataSourceCursor(pRecVendorGrpFilter)
	DEFINE pRecVendorGrpFilter OF t_recVendorGrpFilter
	DEFINE sqlQuery STRING
	DEFINE c_VendorGrp CURSOR
	
	LET sqlQuery =	"SELECT ",
									"vendorgrp.mast_vend_code, ", 
									"vendorgrp.desc_text ",
									"FROM vendorgrp ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecVendorGrpFilter.filter_mast_vend_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND mast_vend_code LIKE '", pRecVendorGrpFilter.filter_mast_vend_code CLIPPED, "%' "  
	END IF									

	IF pRecVendorGrpFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecVendorGrpFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY mast_vend_code"

	CALL c_vendorgrp.DECLARE(sqlQuery)
		
	RETURN c_vendorgrp
END FUNCTION



########################################################################################
# vendorgrpLookupSearchDataSourceCursor(p_RecVendorGrpSearch)
#-------------------------------------------------------
# Returns the VendorGrp CURSOR for the lookup query
########################################################################################
FUNCTION vendorgrpLookupSearchDataSourceCursor(p_RecVendorGrpSearch)
	DEFINE p_RecVendorGrpSearch OF t_recVendorGrpSearch  
	DEFINE sqlQuery STRING
	DEFINE c_VendorGrp CURSOR
	
	LET sqlQuery =	"SELECT ",
									"vendorgrp.mast_vend_code, ", 
									"vendorgrp.desc_text ",
 
									"FROM vendorgrp ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecVendorGrpSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((mast_vend_code LIKE '", p_RecVendorGrpSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecVendorGrpSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecVendorGrpSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY mast_vend_code"

	CALL c_vendorgrp.DECLARE(sqlQuery) #CURSOR FOR vendorgrp
	
	RETURN c_vendorgrp
END FUNCTION


########################################################################################
# FUNCTION VendorGrpLookupFilterDataSource(pRecVendorGrpFilter)
#-------------------------------------------------------
# CALLS VendorGrpLookupFilterDataSourceCursor(pRecVendorGrpFilter) with the VendorGrpFilter data TO get a CURSOR
# Returns the VendorGrp list array arrVendorGrpList
########################################################################################
FUNCTION VendorGrpLookupFilterDataSource(pRecVendorGrpFilter)
	DEFINE pRecVendorGrpFilter OF t_recVendorGrpFilter
	DEFINE recVendorGrp OF t_recVendorGrp
	DEFINE arrVendorGrpList DYNAMIC ARRAY OF t_recVendorGrp 
	DEFINE c_VendorGrp CURSOR
	DEFINE retError SMALLINT
		
	CALL VendorGrpLookupFilterDataSourceCursor(pRecVendorGrpFilter.*) RETURNING c_VendorGrp
	
	CALL arrVendorGrpList.CLEAR()

	CALL c_VendorGrp.SetResults(recVendorGrp.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_VendorGrp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_VendorGrp.FetchNext()=0)
		CALL arrVendorGrpList.append([recVendorGrp.mast_vend_code, recVendorGrp.desc_text])
	END WHILE	

	END IF
	
	IF arrVendorGrpList.getSize() = 0 THEN
		ERROR "No vendorgrp's found with the specified filter criteria"
	END IF
	
	RETURN arrVendorGrpList
END FUNCTION	

########################################################################################
# FUNCTION VendorGrpLookupSearchDataSource(pRecVendorGrpFilter)
#-------------------------------------------------------
# CALLS VendorGrpLookupSearchDataSourceCursor(pRecVendorGrpFilter) with the VendorGrpFilter data TO get a CURSOR
# Returns the VendorGrp list array arrVendorGrpList
########################################################################################
FUNCTION VendorGrpLookupSearchDataSource(p_recVendorGrpSearch)
	DEFINE p_recVendorGrpSearch OF t_recVendorGrpSearch	
	DEFINE recVendorGrp OF t_recVendorGrp
	DEFINE arrVendorGrpList DYNAMIC ARRAY OF t_recVendorGrp 
	DEFINE c_VendorGrp CURSOR
	DEFINE retError SMALLINT	
	CALL VendorGrpLookupSearchDataSourceCursor(p_recVendorGrpSearch) RETURNING c_VendorGrp
	
	CALL arrVendorGrpList.CLEAR()

	CALL c_VendorGrp.SetResults(recVendorGrp.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_VendorGrp.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_VendorGrp.FetchNext()=0)
		CALL arrVendorGrpList.append([recVendorGrp.mast_vend_code, recVendorGrp.desc_text])
	END WHILE	

	END IF
	
	IF arrVendorGrpList.getSize() = 0 THEN
		ERROR "No vendorgrp's found with the specified filter criteria"
	END IF
	
	RETURN arrVendorGrpList
END FUNCTION


########################################################################################
# FUNCTION vendorgrpLookup_filter(pVendorGrpCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required VendorGrp code mast_vend_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL VendorGrpLookupFilterDataSource(recVendorGrpFilter.*) RETURNING arrVendorGrpList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the VendorGrp Code mast_vend_code
#
# Example:
# 			LET pr_VendorGrp.mast_vend_code = VendorGrpLookup(pr_VendorGrp.mast_vend_code)
########################################################################################
FUNCTION vendorgrpLookup_filter(pVendorGrpCode)
	DEFINE pVendorGrpCode LIKE VendorGrp.mast_vend_code
	DEFINE arrVendorGrpList DYNAMIC ARRAY OF t_recVendorGrp
	DEFINE recVendorGrpFilter OF t_recVendorGrpFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wVendorGrpLookup WITH FORM "VendorGrpLookup_filter"


	CALL VendorGrpLookupFilterDataSource(recVendorGrpFilter.*) RETURNING arrVendorGrpList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recVendorGrpFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL VendorGrpLookupFilterDataSource(recVendorGrpFilter.*) RETURNING arrVendorGrpList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrVendorGrpList TO scVendorGrpList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pVendorGrpCode = arrVendorGrpList[idx].mast_vend_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recVendorGrpFilter.filter_mast_vend_code IS NOT NULL
			OR recVendorGrpFilter.filter_desc_text IS NOT NULL

		THEN
			LET recVendorGrpFilter.filter_mast_vend_code = NULL
			LET recVendorGrpFilter.filter_desc_text = NULL

			CALL VendorGrpLookupFilterDataSource(recVendorGrpFilter.*) RETURNING arrVendorGrpList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_mast_vend_code"
		IF recVendorGrpFilter.filter_mast_vend_code IS NOT NULL THEN
			LET recVendorGrpFilter.filter_mast_vend_code = NULL
			CALL VendorGrpLookupFilterDataSource(recVendorGrpFilter.*) RETURNING arrVendorGrpList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recVendorGrpFilter.filter_desc_text IS NOT NULL THEN
			LET recVendorGrpFilter.filter_desc_text = NULL
			CALL VendorGrpLookupFilterDataSource(recVendorGrpFilter.*) RETURNING arrVendorGrpList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wVendorGrpLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pVendorGrpCode	
END FUNCTION				
		

########################################################################################
# FUNCTION vendorgrpLookup(pVendorGrpCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required VendorGrp code mast_vend_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL VendorGrpLookupSearchDataSource(recVendorGrpFilter.*) RETURNING arrVendorGrpList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the VendorGrp Code mast_vend_code
#
# Example:
# 			LET pr_VendorGrp.mast_vend_code = VendorGrpLookup(pr_VendorGrp.mast_vend_code)
########################################################################################
FUNCTION vendorgrpLookup(pVendorGrpCode)
	DEFINE pVendorGrpCode LIKE VendorGrp.mast_vend_code
	DEFINE arrVendorGrpList DYNAMIC ARRAY OF t_recVendorGrp
	DEFINE recVendorGrpSearch OF t_recVendorGrpSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wVendorGrpLookup WITH FORM "vendorgrpLookup"

	CALL VendorGrpLookupSearchDataSource(recVendorGrpSearch.*) RETURNING arrVendorGrpList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recVendorGrpSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL VendorGrpLookupSearchDataSource(recVendorGrpSearch.*) RETURNING arrVendorGrpList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrVendorGrpList TO scVendorGrpList.* 
		BEFORE ROW
			IF arrVendorGrpList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pVendorGrpCode = arrVendorGrpList[idx].mast_vend_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recVendorGrpSearch.filter_any_field IS NOT NULL

		THEN
			LET recVendorGrpSearch.filter_any_field = NULL

			CALL VendorGrpLookupSearchDataSource(recVendorGrpSearch.*) RETURNING arrVendorGrpList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_mast_vend_code"
		IF recVendorGrpSearch.filter_any_field IS NOT NULL THEN
			LET recVendorGrpSearch.filter_any_field = NULL
			CALL VendorGrpLookupSearchDataSource(recVendorGrpSearch.*) RETURNING arrVendorGrpList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wVendorGrpLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pVendorGrpCode	
END FUNCTION				

############################################
# FUNCTION import_vendorgrp()
############################################
FUNCTION import_vendorgrp()
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
	
	DEFINE rec_vendorgrp OF t_recVendorGrp_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wVendorGrpImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Vendor Group List Data (table: vendorgrp)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_vendorgrp
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_vendorgrp(
	    mast_vend_code CHAR(8),
	    desc_text CHAR(30),
	    vend_code CHAR(8)	
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_vendorgrp	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wVendorGrpImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wVendorGrpImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/vendorgrp-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_vendorgrp
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_vendorgrp
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_vendorgrp
			LET importReport = importReport, "Code:", trim(rec_vendorgrp.mast_vend_code) , "     -     Desc:", trim(rec_vendorgrp.desc_text), "\n"
					
			INSERT INTO vendorgrp VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_vendorgrp.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_vendorgrp.mast_vend_code) , "     -     Desc:", trim(rec_vendorgrp.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wVendorGrpImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_vendorgrpRec(p_cmpy_code, p_mast_vend_code)
########################################################
FUNCTION exist_vendorgrpRec(p_cmpy_code, p_mast_vend_code)
	DEFINE p_cmpy_code LIKE vendorgrp.cmpy_code
	DEFINE p_mast_vend_code LIKE vendorgrp.mast_vend_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM vendorgrp 
     WHERE cmpy_code = p_cmpy_code
     AND mast_vend_code = p_mast_vend_code

	DROP TABLE temp_vendorgrp
	CLOSE WINDOW wVendorGrpImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_vendorgrp()
###############################################################
FUNCTION unload_vendorgrp(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/vendorgrp-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM vendorgrp ORDER BY cmpy_code, mast_vend_code ASC
	
	LET tmpMsg = "All vendorgrp data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("vendorgrp Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_vendorgrp_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_vendorgrp_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE vendorgrp.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wvendorgrpImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Vendor Group (vendorgrp) Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing vendorgrp table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM vendorgrp
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table vendorgrp!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table vendorgrp where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wVendorGrpImport		
END FUNCTION	