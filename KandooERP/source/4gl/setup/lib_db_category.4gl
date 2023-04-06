GLOBALS "lib_db_globals.4gl"

# HUHO 03.02.2018 Created   (for setup)

# FUNCTION getCategoryCount()
# FUNCTION categoryLookupFilterDataSourceCursor(pRecCategoryFilter)
# FUNCTION categoryLookupSearchDataSourceCursor(p_RecCategorySearch)
# FUNCTION CategoryLookupFilterDataSource(pRecCategoryFilter)
# FUNCTION categoryLookup_filter(pCategoryCode)
# FUNCTION import_category()
# FUNCTION exist_categoryRec(p_cmpy_code, p_cat_code)
# FUNCTION delete_category_all()
# FUNCTION categoryMenu()						-- Offer different OPTIONS of this library via a menu

# Category record types
	DEFINE t_recCategory  
		TYPE AS RECORD
			cat_code LIKE category.cat_code,
			desc_text LIKE category.desc_text
		END RECORD 

	DEFINE t_recCategoryFilter  
		TYPE AS RECORD
			filter_cat_code LIKE category.cat_code,
			filter_desc_text LIKE category.desc_text
		END RECORD 

	DEFINE t_recCategorySearch  
		TYPE AS RECORD
			filter_any_field STRING
		END RECORD 		

	DEFINE t_recCategory_noCmpyId 
		TYPE AS RECORD 
    cat_code LIKE category.cat_code,
    desc_text LIKE category.desc_text,

    price1_per LIKE category.price1_per,
    price2_per LIKE category.price2_per,
    price3_per LIKE category.price3_per,
    price4_per LIKE category.price4_per,
    price5_per LIKE category.price5_per,
    price6_per LIKE category.price6_per,
    price7_per LIKE category.price7_per,
    price8_per LIKE category.price8_per,
    price9_per LIKE category.price9_per,
    std_cost_mrkup_per LIKE category.std_cost_mrkup_per,
    oth_cost_fact_per LIKE category.oth_cost_fact_per,
    cost_list_ind LIKE category.cost_list_ind,
    def_cost_ind LIKE category.def_cost_ind,
    pur_acct_code LIKE category.pur_acct_code,
    ret_acct_code LIKE category.ret_acct_code,
    sale_acct_code LIKE category.sale_acct_code,
    cred_acct_code LIKE category.cred_acct_code,
    cogs_acct_code LIKE category.cogs_acct_code,
    stock_acct_code LIKE category.stock_acct_code,
    adj_acct_code LIKE category.adj_acct_code,
    price1_ind LIKE category.price1_ind,
    price2_ind LIKE category.price2_ind,
    price3_ind LIKE category.price3_ind,
    price4_ind LIKE category.price4_ind,
    price5_ind LIKE category.price5_ind,
    price6_ind LIKE category.price6_ind,
    price7_ind LIKE category.price7_ind,
    price8_ind LIKE category.price8_ind,
    price9_ind LIKE category.price9_ind,
    rounding_factor LIKE category.rounding_factor,
    rounding_ind LIKE category.rounding_ind,
    int_rev_acct_code LIKE category.int_rev_acct_code,
    int_cogs_acct_code LIKE category.int_cogs_acct_code
    
    
    
	END RECORD	


	
########################################################################################
# FUNCTION categoryMenu()
#-------------------------------------------------------
# Offer different OPTIONS of this library via a menu
########################################################################################
FUNCTION categoryMenu()
	MENU
		ON ACTION "Import"
			CALL import_category()
		ON ACTION "Export"
			CALL unload_category()
		#ON ACTION "Import"
		#	CALL import_category()
		ON ACTION "Delete All"
			CALL delete_category_all()
		ON ACTION "Count"
			CALL getCategoryCount() --Count all category rows FROM the current company	
		ON ACTION "Exit"
			EXIT MENU
	END MENU
			
END FUNCTION
	
########################################################################################
# FUNCTION getCategoryCount()
#-------------------------------------------------------
# Returns the number of Category entries for the current company
########################################################################################
FUNCTION getCategoryCount()
	DEFINE ret_CategoryCount SMALLINT
	DEFINE sqlQuery VARCHAR(500)
	DEFINE c_Category CURSOR
	DEFINE retError SMALLINT
	DEFINE tempMsg STRING

	
	LET sqlQuery =	"SELECT COUNT(*) ",
									"FROM Category ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "

	CALL c_Category.DECLARE(sqlQuery) #CURSOR FOR getCategory
	CALL c_Category.SetResults(ret_CategoryCount)  --define variable for result output
	
	WHENEVER ERROR CONTINUE
	LET retError = c_Category.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
		LET ret_CategoryCount = -1
	ELSE
		CALL c_Category.FetchNext()
	END IF

	IF gl_setupRec.silentMode = 0 THEN
		LET tempMsg = "Number of Product Categories:", trim(ret_CategoryCount) ,"\nCompany:", trim(getCurrentUser_cmpy_code())  
		CALL fgl_winmessage("Product Categories Count", tempMsg,"info") 	
	END IF

	RETURN ret_CategoryCount
END FUNCTION

########################################################################################
# FUNCTION categoryLookupFilterDataSourceCursor(pRecCategoryFilter)
#-------------------------------------------------------
# Returns the Category CURSOR for the lookup query
########################################################################################
FUNCTION categoryLookupFilterDataSourceCursor(pRecCategoryFilter)
	DEFINE pRecCategoryFilter OF t_recCategoryFilter
	DEFINE sqlQuery STRING
	DEFINE c_Category CURSOR
	
	LET sqlQuery =	"SELECT ",
									"category.cat_code, ", 
									"category.desc_text ",
									"FROM category ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
									
	IF pRecCategoryFilter.filter_cat_code IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND cat_code LIKE '", pRecCategoryFilter.filter_cat_code CLIPPED, "%' "  
	END IF									

	IF pRecCategoryFilter.filter_desc_text IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND desc_text LIKE '", pRecCategoryFilter.filter_desc_text CLIPPED, "%' "  
	END IF	
	
			
	LET sqlQuery = sqlQuery, " ORDER BY cat_code"

	CALL c_category.DECLARE(sqlQuery)
		
	RETURN c_category
END FUNCTION



########################################################################################
# categoryLookupSearchDataSourceCursor(p_RecCategorySearch)
#-------------------------------------------------------
# Returns the Category CURSOR for the lookup query
########################################################################################
FUNCTION categoryLookupSearchDataSourceCursor(p_RecCategorySearch)
	DEFINE p_RecCategorySearch OF t_recCategorySearch  
	DEFINE sqlQuery STRING
	DEFINE c_Category CURSOR
	
	LET sqlQuery =	"SELECT ",
									"category.cat_code, ", 
									"category.desc_text ",
 
									"FROM category ",
									"WHERE cmpy_code = '", trim(getCurrentUser_cmpy_code()), "' "
	
	IF p_RecCategorySearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, "AND ((cat_code LIKE '", p_RecCategorySearch.filter_any_field CLIPPED, "%' "  
		LET sqlQuery = sqlQuery, "OR desc_text LIKE '",   p_RecCategorySearch.filter_any_field CLIPPED, "%') "  
  						
	END IF


	IF p_RecCategorySearch.filter_any_field IS NOT NULL THEN
		LET sqlQuery = sqlQuery, ") "
	END IF
				
	LET sqlQuery = sqlQuery, "ORDER BY cat_code"

	CALL c_category.DECLARE(sqlQuery) #CURSOR FOR category
	
	RETURN c_category
END FUNCTION


########################################################################################
# FUNCTION CategoryLookupFilterDataSource(pRecCategoryFilter)
#-------------------------------------------------------
# CALLS CategoryLookupFilterDataSourceCursor(pRecCategoryFilter) with the CategoryFilter data TO get a CURSOR
# Returns the Category list array arrCategoryList
########################################################################################
FUNCTION CategoryLookupFilterDataSource(pRecCategoryFilter)
	DEFINE pRecCategoryFilter OF t_recCategoryFilter
	DEFINE recCategory OF t_recCategory
	DEFINE arrCategoryList DYNAMIC ARRAY OF t_recCategory 
	DEFINE c_Category CURSOR
	DEFINE retError SMALLINT
		
	CALL CategoryLookupFilterDataSourceCursor(pRecCategoryFilter.*) RETURNING c_Category
	
	CALL arrCategoryList.CLEAR()

	CALL c_Category.SetResults(recCategory.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Category.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Category.FetchNext()=0)
		CALL arrCategoryList.append([recCategory.cat_code, recCategory.desc_text])
	END WHILE	

	END IF
	
	IF arrCategoryList.getSize() = 0 THEN
		ERROR "No category's found with the specified filter criteria"
	END IF
	
	RETURN arrCategoryList
END FUNCTION	

########################################################################################
# FUNCTION CategoryLookupSearchDataSource(pRecCategoryFilter)
#-------------------------------------------------------
# CALLS CategoryLookupSearchDataSourceCursor(pRecCategoryFilter) with the CategoryFilter data TO get a CURSOR
# Returns the Category list array arrCategoryList
########################################################################################
FUNCTION CategoryLookupSearchDataSource(p_recCategorySearch)
	DEFINE p_recCategorySearch OF t_recCategorySearch	
	DEFINE recCategory OF t_recCategory
	DEFINE arrCategoryList DYNAMIC ARRAY OF t_recCategory 
	DEFINE c_Category CURSOR
	DEFINE retError SMALLINT	
	CALL CategoryLookupSearchDataSourceCursor(p_recCategorySearch) RETURNING c_Category
	
	CALL arrCategoryList.CLEAR()

	CALL c_Category.SetResults(recCategory.*)  --define variable for result output

	WHENEVER ERROR CONTINUE
	LET retError = c_Category.OPEN()
	WHENEVER ERROR STOP

	IF  retError <> 0 THEN
		MESSAGE "Error in Query - Could NOT OPEN CURSOR"
	ELSE
	
	WHILE  (c_Category.FetchNext()=0)
		CALL arrCategoryList.append([recCategory.cat_code, recCategory.desc_text])
	END WHILE	

	END IF
	
	IF arrCategoryList.getSize() = 0 THEN
		ERROR "No category's found with the specified filter criteria"
	END IF
	
	RETURN arrCategoryList
END FUNCTION


########################################################################################
# FUNCTION categoryLookup_filter(pCategoryCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Category code cat_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CategoryLookupFilterDataSource(recCategoryFilter.*) RETURNING arrCategoryList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Category Code cat_code
#
# Example:
# 			LET pr_Category.cat_code = CategoryLookup(pr_Category.cat_code)
########################################################################################
FUNCTION categoryLookup_filter(pCategoryCode)
	DEFINE pCategoryCode LIKE Category.cat_code
	DEFINE arrCategoryList DYNAMIC ARRAY OF t_recCategory
	DEFINE recCategoryFilter OF t_recCategoryFilter	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCategoryLookup WITH FORM "CategoryLookup_filter"


	CALL CategoryLookupFilterDataSource(recCategoryFilter.*) RETURNING arrCategoryList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCategoryFilter.* WITHOUT DEFAULTS 
				
		ON ACTION "UPDATE-FILTER"
			CALL CategoryLookupFilterDataSource(recCategoryFilter.*) RETURNING arrCategoryList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCategoryList TO scCategoryList.* 
		BEFORE ROW
			LET idx = arr_curr()
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCategoryCode = arrCategoryList[idx].cat_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCategoryFilter.filter_cat_code IS NOT NULL
			OR recCategoryFilter.filter_desc_text IS NOT NULL

		THEN
			LET recCategoryFilter.filter_cat_code = NULL
			LET recCategoryFilter.filter_desc_text = NULL

			CALL CategoryLookupFilterDataSource(recCategoryFilter.*) RETURNING arrCategoryList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_cat_code"
		IF recCategoryFilter.filter_cat_code IS NOT NULL THEN
			LET recCategoryFilter.filter_cat_code = NULL
			CALL CategoryLookupFilterDataSource(recCategoryFilter.*) RETURNING arrCategoryList
			CALL ui.interface.refresh()
		END IF
		
	ON ACTION "clearFilter_desc_text"
		IF recCategoryFilter.filter_desc_text IS NOT NULL THEN
			LET recCategoryFilter.filter_desc_text = NULL
			CALL CategoryLookupFilterDataSource(recCategoryFilter.*) RETURNING arrCategoryList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCategoryLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCategoryCode	
END FUNCTION				
		

########################################################################################
# FUNCTION categoryLookup(pCategoryCode)
#-------------------------------------------------------
# Displays a search list window TO retrieve/select the required Category code cat_code
# DateSoure AND Cursor are managed in other functions which are called
# CALL CategoryLookupSearchDataSource(recCategoryFilter.*) RETURNING arrCategoryList
# After select row - ACCEPT  (doubleClick OR OK)
# Returns the Category Code cat_code
#
# Example:
# 			LET pr_Category.cat_code = CategoryLookup(pr_Category.cat_code)
########################################################################################
FUNCTION categoryLookup(pCategoryCode)
	DEFINE pCategoryCode LIKE Category.cat_code
	DEFINE arrCategoryList DYNAMIC ARRAY OF t_recCategory
	DEFINE recCategorySearch OF t_recCategorySearch	
	DEFINE idx SMALLINT
	
	OPTIONS INPUT WRAP
	
	OPEN WINDOW wCategoryLookup WITH FORM "categoryLookup"

	CALL CategoryLookupSearchDataSource(recCategorySearch.*) RETURNING arrCategoryList

	#########################################
	DIALOG ATTRIBUTE(UNBUFFERED)

	INPUT BY NAME recCategorySearch.* WITHOUT DEFAULTS 
			
		ON ACTION "UPDATE-FILTER"
			CALL CategoryLookupSearchDataSource(recCategorySearch.*) RETURNING arrCategoryList
			CALL ui.interface.refresh()
			
	END INPUT
	
	DISPLAY ARRAY arrCategoryList TO scCategoryList.* 
		BEFORE ROW
			IF arrCategoryList.getSize() > 0 THEN
				LET idx = arr_curr()
			ELSE
				LET idx = 0
			END IF
			
	END DISPLAY

	ON ACTION "ACCEPT"
		IF idx > 0 THEN
			LET  pCategoryCode = arrCategoryList[idx].cat_code
			EXIT DIALOG
		END IF
		
	ON ACTION "CANCEL"
		EXIT DIALOG

	ON ACTION "clearFilter_all"
		IF recCategorySearch.filter_any_field IS NOT NULL

		THEN
			LET recCategorySearch.filter_any_field = NULL

			CALL CategoryLookupSearchDataSource(recCategorySearch.*) RETURNING arrCategoryList
			CALL ui.interface.refresh()			
		END IF

	ON ACTION "clearFilter_cat_code"
		IF recCategorySearch.filter_any_field IS NOT NULL THEN
			LET recCategorySearch.filter_any_field = NULL
			CALL CategoryLookupSearchDataSource(recCategorySearch.*) RETURNING arrCategoryList
			CALL ui.interface.refresh()
		END IF
		
								
	END DIALOG
	##########################################
		
	CLOSE WINDOW wCategoryLookup

	OPTIONS INPUT NO WRAP	
	
	RETURN pCategoryCode	
END FUNCTION				

############################################
# FUNCTION import_category()
############################################
FUNCTION import_category()
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
	
	DEFINE rec_category OF t_recCategory_noCmpyId

----------------------------------------------	
	WHENEVER ERROR CONTINUE	

	IF gl_setupRec.silentMode = 0 THEN	
		OPEN WINDOW wCategoryImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "Import Product Category List Data (table: category)" TO header_text
	END IF

	SELECT COUNT(*) INTO recCount FROM temp_category
		IF STATUS = -206 THEN  --table does NOT exist
		CREATE TEMP TABLE temp_category(	    
    cat_code CHAR(3),
    desc_text CHAR(30),
    price1_per DECIMAL(6,3),
    price2_per DECIMAL(6,3),
    price3_per DECIMAL(6,3),
    price4_per DECIMAL(6,3),
    price5_per DECIMAL(6,3),
    price6_per DECIMAL(6,3),
    price7_per DECIMAL(6,3),
    price8_per DECIMAL(6,3),
    price9_per DECIMAL(6,3),
    std_cost_mrkup_per DECIMAL(6,3),
    oth_cost_fact_per DECIMAL(6,3),
    cost_list_ind CHAR(1),
    def_cost_ind CHAR(1),
    pur_acct_code CHAR(18),
    ret_acct_code CHAR(18),
    sale_acct_code CHAR(18),
    cred_acct_code CHAR(18),
    cogs_acct_code CHAR(18),
    stock_acct_code CHAR(18),
    adj_acct_code CHAR(18),
    price1_ind CHAR(1),
    price2_ind CHAR(1),
    price3_ind CHAR(1),
    price4_ind CHAR(1),
    price5_ind CHAR(1),
    price6_ind CHAR(1),
    price7_ind CHAR(1),
    price8_ind CHAR(1),
    price9_ind CHAR(1),
    rounding_factor DECIMAL(16,4),
    rounding_ind CHAR(1),
    int_rev_acct_code CHAR(18),
    int_cogs_acct_code CHAR(18)
		)
		END IF

		IF recCount <> 0 THEN  #table exists AND has got data
			DELETE FROM temp_category	#we need TO INITIALIZE it, delete all rows
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
	#	OPEN WINDOW wCategoryImport WITH FORM "per/setup/lib_db_data_import_01"
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
					CLOSE WINDOW wCategoryImport
					RETURN
					
				END IF

			END IF

	
		END IF
	
	END IF
	
	LET load_file = "unl/category-",gl_setupRec_default_company.country_code CLIPPED,".unl"

	IF NOT os.path.exists(load_file) THEN
		LET tmpMsg = "The template file cannot be found:\n",load_file CLIPPED,"\nPlease check that this country code has a data SET: ",gl_setupRec_default_company.country_code
		CALL fgl_winmessage("Chart of Accounts Table Data load",tmpMsg ,"error")
	ELSE
		CALL fgl_putenv("DBDATE=dmy4.")
		LOAD FROM load_file INSERT INTO temp_category
		DECLARE template_cur CURSOR FOR 
		SELECT * FROM temp_category
		WHENEVER ERROR CONTINUE						
		
		LET count_rows_processed = 0
		LET count_rows_inserted = 0
		LET count_insert_errors = 0
		LET count_already_exist = 0
  
		FOREACH template_cur INTO rec_category
			LET importReport = importReport, "Code:", trim(rec_category.cat_code) , "     -     Desc:", trim(rec_category.desc_text), "\n"
					
			INSERT INTO category VALUES(
			gl_setupRec_default_company.cmpy_code,
			rec_category.*
			
			)

			CASE
				WHEN STATUS =0
					LET count_rows_inserted = count_rows_inserted + 1
				WHEN STATUS = -268 OR STATUS = -239
					LET importReport = importReport, "Code:", trim(rec_category.cat_code) , "     -     Desc:", trim(rec_category.desc_text), " ->DUPLICATE = Ignored !\n"
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
		
		CLOSE WINDOW wCategoryImport
	END IF
	
	RETURN count_rows_inserted
END FUNCTION


########################################################
# FUNCTION exist_categoryRec(p_cmpy_code, p_cat_code)
########################################################
FUNCTION exist_categoryRec(p_cmpy_code, p_cat_code)
	DEFINE p_cmpy_code LIKE category.cmpy_code
	DEFINE p_cat_code LIKE category.cat_code
	DEFINE recCount INT

		SELECT COUNT(*) INTO recCount FROM category 
     WHERE cmpy_code = p_cmpy_code
     AND cat_code = p_cat_code

	DROP TABLE temp_category
	CLOSE WINDOW wCategoryImport
	
	RETURN recCount

END FUNCTION

###############################################################
# FUNCTION unload_category()
###############################################################
FUNCTION unload_category(p_silentMode,p_fileExtension)
	DEFINE p_silentMode BOOLEAN
	DEFINE p_fileExtension STRING
	DEFINE tmpMsg STRING
	DEFINE unloadFile STRING
	
	LET unloadFile = "unl/category-", trim(gl_setupRec_default_company.country_code), ".", p_fileExtension 
	UNLOAD TO unloadFile 
		SELECT * FROM category ORDER BY cmpy_code, cat_code ASC
	
	LET tmpMsg = "All category data were exported/written TO:\n", unloadFile
	CALL fgl_winmessage("category Table Data Unloaded",tmpMsg ,"info")
		
END FUNCTION
###############################################################
# FUNCTION delete_category_all()  NOTE: Delete ALL
###############################################################
FUNCTION delete_category_all()
	DEFINE p_silentMode BOOLEAN
	#DEFINE p_cmpy_code LIKE category.cmpy_code

	DEFINE cmpy_code_provided BOOLEAN		
	DEFINE answ STRING
	DEFINE tmpMsg,msgString STRING

	IF gl_setupRec.silentMode = 0 THEN
		OPEN WINDOW wcategoryImport WITH FORM "per/setup/lib_db_data_import_01"
		DISPLAY "category Type Delete" TO header_text
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
		LET answ = fgl_winbutton("Delete all table data", "This operation will delete all existing category table data!\nDo you want TO continue with this operation?", "Yes", "Yes|No", "info", 1)
	ELSE
		LET answ = "Yes"		
	END IF
	
	IF answ = "Yes" THEN
		WHENEVER ERROR CONTINUE
			DELETE FROM category
		WHENEVER ERROR STOP
		
		IF sqlca.sqlcode <> 0 THEN
			LET tmpMsg = "Error when trying TO delete all data in the table category!"
				CALL fgl_winmessage("Error",tmpMsg,"error")
		ELSE
			IF p_silentMode = 0 THEN --no ui
				LET tmpMsg = "All data in the table category where deleted"		
				CALL fgl_winmessage("Success",tmpMsg,"info")
			END IF					
		END IF		
	END IF	


	CLOSE WINDOW wCategoryImport		
END FUNCTION	