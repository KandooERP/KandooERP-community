GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getClassCount()
# FUNCTION classLookupFilterDataSourceCursor(pRecClassFilter)
# FUNCTION classLookupSearchDataSourceCursor(p_RecClassSearch)
# FUNCTION ClassLookupFilterDataSource(pRecClassFilter)
# FUNCTION classLookup_filter(pClassCode)
# FUNCTION import_class()
# FUNCTION exist_classRec(p_cmpy_code, p_class_code)
# FUNCTION delete_class_all()
# FUNCTION classMenu()						-- Offer different OPTIONS of this library via a menu

# Class record types
	DEFINE t_recClass  
		TYPE AS RECORD
			class_code LIKE class.class_code,
			desc_text LIKE class.desc_text
		END RECORD 

	DEFINE t_recClassFilter  
		TYPE AS RECORD
			filter_class_code LIKE class.class_code,
			filter_desc_text LIKE class.desc_text
		END RECORD 

	DEFINE t_recClassSearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recClass_noCmpyId 
		TYPE AS RECORD 
    class_code LIKE class.class_code,
    desc_text LIKE class.desc_text,
    price_level_ind LIKE class.price_level_ind,
    ord_level_ind LIKE class.ord_level_ind ,
    stock_level_ind LIKE class.stock_level_ind ,
    desc_level_ind LIKE class.desc_level_ind
    
	END RECORD	

	
########################################################################################
# FUNCTION classMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION classMenu()
	MENU
		ON ACTION "Import"
			CALL import_class()
		ON ACTION "Export"
			CALL unload_class()
		#ON ACTION "Import"
		#	CALL import_class()
		ON ACTION "Delete All"
			CALL delete_class_all()
		ON ACTION "Count"
			CALL getClassCount() --Count all class rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getClassCount()
#-------------------------------------------------------
# Returns the number of Class entries for the current company
########################################################################################
FUNCTION getClassCount()
	DEFINE ret_ClassCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Class CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Class ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Class.DECLARE(sqlQuery) #CURSOR FOR getClass
	CALL c_Class.SetResults(ret_ClassCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Class.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_ClassCount = -1
	ELSE
		CALL c_Class.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Product CLASS:", trim(ret_ClassCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Product Class Type Count", tempMsg,"info") 	
	END IF

	RETURN ret_ClassCount
END FUNCTION

########################################################################################
# FUNCTION classLookupFilterDataSourceCursor(pRecClassFilter)
#-------------------------------------------------------
# Returns the Class CURSOR for the lookup query
########################################################################################
FUNCTION classLookupFilterDataSourceCursor(pRecClassFilter)
	DEFINE pRecClassFilter OF t_recClassFilter
	DEFINE sqlQuery STRING
	DEFINE c_Class CURSOR
	
	LET sqlQuery =	"SELECT ",
									"class.class_code, ", 
									"class.desc_text ",
									"FROM class ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecClassFilter.filter_class_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND class_code LIKE '", pRecClassFilter.filter_class_code CLIPPED, "%' "  
	END IF									

	IF pRecClassFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecClassFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY class_code"

	CALL c_class.DECLARE(sqlQuery)
		
	RETURN c_class
END FUNCTION



########################################################################################
# classLookupSearchDataSourceCursor(p_RecClassSearch)
#-------------------------------------------------------
# Returns the Class CURSOR for the lookup query
########################################################################################
FUNCTION classLookupSearchDataSourceCursor(p_RecClassSearch)
	DEFINE p_RecClassSearch OF t_recClassSearch  
	DEFINE sqlQuery STRING
	DEFINE c_Class CURSOR
	
	LET sqlQuery =	"SELECT ",
									"class.class_code, ", 
									"class.desc_text ",
 
									"FROM class ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecClassSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((class_code LIKE '", p_RecClassSearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecClassSearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecClassSearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY class_code"

	CALL c_class.DECLARE(sqlQuery) #CURSOR FOR class
	
	RETURN c_class
END FUNCTION


########################################################################################
# FUNCTION ClassLookupFilterDataSource(pRecClassFilter)
#-------------------------------------------------------
# CALLS ClassLookupFilterDataSourceCursor(pRecClassFilter) with the ClassFilter data TO get a CURSOR
# Returns the Class list array arrClassList
########################################################################################
FUNCTION ClassLookupFilterDataSource(pRecClassFilter)
	DEFINE pRecClassFilter OF t_recClassFilter
	DEFINE recClass OF t_recClass
	DEFINE arrClassList DYNAMIC ARRAY OF t_recClass 
	DEFINE c_Class CURSOR
	DEFINE retError SMALLINT
		
	CALL ClassLookupFilterDataSourceCursor(pRecClassFilter.*) RETURNING c_Class
	
	CALL arrClassList.CLEAR()

	CALL c_Class.SetResults(recClass.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Class.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Class.FetchNext()=0)
		CALL arrClassList.append([recClass.class_code, recClass.desc_text])
	END WHILE	

	END IF
	
	IF arrClassList.getSize() = 0 THEN
		ERROR "No class's found with the specified filter criteria"
	END IF
	
	RETURN arrClassList
END FUNCTION	

########################################################################################
# FUNCTION ClassLookupSearchDataSource(pRecClassFilter)
#-------------------------------------------------------
# CALLS ClassLookupSearchDataSourceCursor(pRecClassFilter) with the ClassFilter data TO get a CURSOR
# Returns the Class list array arrClassList
########################################################################################
FUNCTION ClassLookupSearchDataSource(p_recClassSearch)
	DEFINE p_recClassSearch OF t_recClassSearch	
	DEFINE recClass OF t_recClass
	DEFINE arrClassList DYNAMIC ARRAY OF t_recClass 
	DEFINE c_Class CURSOR
	DEFINE retError SMALLINT	
	CALL ClassLookupSearchDataSourceCursor(p_recClassSearch) RETURNING c_Class
	
	CALL arrClassList.CLEAR()

	CALL c_Class.SetResults(recClass.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Class.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Class.FetchNext()=0)
		CALL arrClassList.append([recClass.class_code, recClass.desc_text])
	END WHILE	

	END IF
	
	IF arrClassList.getSize() = 0 THEN
		ERROR "No class's found with the specified filter criteria"
	END IF
	
	RETURN arrClassList
END FUNCTION


########################################################################################
# FUNCTION classLookup_filter(pClassCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Class code class_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ClassLookupFilterDataSource(recClassFilter.*) RETURNING arrClassList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Class Code class_code
#
# Example:
# 			LET pr_Class.class_code = ClassLookup(pr_Class.class_code)
########################################################################################
FUNCTION classLookup_filter(pClassCode)
	DEFINE pClassCode LIKE Class.class_code
	DEFINE arrClassList DYNAMIC ARRAY OF t_recClass
	DEFINE recClassFilter OF t_recClassFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wClassLookup WITH FORM "ClassLookup_filter"


	CALL ClassLookupFilterDataSource(recClassFilter.*) RETURNING arrClassList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recClassFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL ClassLookupFilterDataSource(recClassFilter.*) RETURNING arrClassList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrClassList TO scClassList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pClassCode = arrClassList[idx].class_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recClassFilter.filter_class_code IS NOT NULL
			OR recClassFilter.filter_desc_text IS NOT NULL

		THEN
			LET recClassFilter.filter_class_code = NULL
			LET recClassFilter.filter_desc_text = NULL

			CALL ClassLookupFilterDataSource(recClassFilter.*) RETURNING arrClassList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_class_code"
		IF recClassFilter.filter_class_code IS NOT NULL THEN
			LET recClassFilter.filter_class_code = NULL
			CALL ClassLookupFilterDataSource(recClassFilter.*) RETURNING arrClassList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recClassFilter.filter_desc_text IS NOT NULL THEN
			LET recClassFilter.filter_desc_text = NULL
			CALL ClassLookupFilterDataSource(recClassFilter.*) RETURNING arrClassList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wClassLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pClassCode	
END FUNCTION				
		

########################################################################################
# FUNCTION classLookup(pClassCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Class code class_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL ClassLookupSearchDataSource(recClassFilter.*) RETURNING arrClassList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Class Code class_code
#
# Example:
# 			LET pr_Class.class_code = ClassLookup(pr_Class.class_code)
########################################################################################
FUNCTION classLookup(pClassCode)
	DEFINE pClassCode LIKE Class.class_code
	DEFINE arrClassList DYNAMIC ARRAY OF t_recClass
	DEFINE recClassSearch OF t_recClassSearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wClassLookup WITH FORM "classLookup"

	CALL ClassLookupSearchDataSource(recClassSearch.*) RETURNING arrClassList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recClassSearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL ClassLookupSearchDataSource(recClassSearch.*) RETURNING arrClassList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrClassList TO scClassList.* 
		BEFORE ROW
			IF arrClassList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pClassCode = arrClassList[idx].class_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recClassSearch.filter_any_field IS NOT NULL

		THEN
			LET recClassSearch.filter_any_field = NULL

			CALL ClassLookupSearchDataSource(recClassSearch.*) RETURNING arrClassList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_class_code"
		IF recClassSearch.filter_any_field IS NOT NULL THEN
			LET recClassSearch.filter_any_field = NULL
			CALL ClassLookupSearchDataSource(recClassSearch.*) RETURNING arrClassList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wClassLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pClassCode	
END FUNCTION				

############################################
# FUNCTION import_class()
############################################
FUNCTION import_class()
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
	
	DEFINE rec_class OF t_recClass_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wClassImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Vendor Type List Data (table: class)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_class
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_class(
    class_code CHAR(8),
    desc_text CHAR(30),
    price_level_ind SMALLINT,
    ord_level_ind SMALLINT,
    stock_level_ind SMALLINT,
    desc_level_ind SMALLINT	
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_class	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wClassImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wClassImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/class-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_class
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_class
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_class
			LET importReport = importReport, "Code:", trim(rec_class.class_code) , "     -     Desc:", trim(rec_class.desc_text), "\n"
					
			INSERT INTO class VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_class.*
			{class_code,
			rec_class.desc_text,
			rec_class.pay_acct_code,
			rec_class.freight_acct_code,
			rec_class.salestax_acct_code,
			rec_class.disc_acct_code,
			rec_class.exch_acct_code,
			rec_class.withhold_tax_ind,
			rec_class.tax_vend_code
			}
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_class.class_code) , "     -     Desc:", trim(rec_class.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wClassImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_classRec(p_cmpy_code, p_class_code)
########################################################
FUNCTION exist_classRec(p_cmpy_code, p_class_code)
	DEFINE p_cmpy_code LIKE class.cmpy_code
	DEFINE p_class_code LIKE class.class_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM class 
     WHERE cmpy_code = p_cmpy_code
     AND class_code = p_class_code

	DROP TABLE temp_class
	CLOSE WINDOW wClassImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_class()
###############################################################
FUNCTION unload_class(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/class-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM class ORDER BY cmpy_code, class_code ASC
	
	LET tmpMsg = "All class data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("class Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_class_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_class_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE class.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wclassImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "class Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing class table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM class
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table class!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table class where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wClassImport		
END FUNCTION	